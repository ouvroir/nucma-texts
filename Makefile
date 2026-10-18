# Chaîne de traitement de NUCMA.
#
#   make help            affiche cette aide (aussi : make sans argument)
#
#   make import LANGUAGE=fr CHAPTER=acquisition DOCX=chemin/vers/Entree.docx
#                        importe un document Word avec le profil nucma dans
#                        <langue>/<chapitre>/<nom>.xml
#     NAME=nom-court     nom du fichier et de l’identifiant (défaut : titre court du document)
#     FORCE=yes          remplace un fichier existant
#
#   make schemas         génère les schémas RelaxNG à partir des ODD (chaîne d’ODD),
#                        dans schemas/ (non versionnés)
#   make documentation   génère la documentation HTML dans documentation/ (non versionné)
#   make clean-schemas   supprime les schémas générés et l’étage commun compilé
#   make clean-documentation   supprime documentation/
#
#   make validate        valide par les schémas RelaxNG (Jing)
#   make quality         contrôle de l’encodage (schemas/nucma-quality.sch)
#   make typography      contrôle typographique (typography.sch de typesetter)
#   make check           les trois contrôles à la suite
#   make clean-check     supprime les Schematron compilés (build/) et les rapports (reports/)
#
#   make oxygen-jar      compile l’extension Java du framework oXygen NUCMA
#                        (oxygen/java/ → oxygen/frameworks/nucma/nucma.jar, versionné)
#     OXYGEN=…           dossier d’installation d’oXygen (défaut : /Applications/Oxygen XML Editor)
#
#   make serialize TARGET=…  1. remet sur une ligne les balises coupées (typesetter)
#   make cleanup TARGET=…    2. nettoie les artefacts de Word (typesetter)
#   make normalize TARGET=…  3. normalisation typographique (typesetter)
#                        transforment sur place les entrées de fr/ et en/ ; un commit après
#                        chaque étape ; les fichiers non commités sont laissés de côté
#     FORCE=yes          traite aussi les fichiers qui ont des modifications non commitées
#     BIBLIOGRAPHY=yes   normalize : traite aussi la bibliographie
#     DEFAULT_LANG=fr    normalize : langue d’un fichier rangé hors de fr/ ou en/
#     DETAIL=yes         normalize : journal détaillé (chaque segment modifié)
#
# Options des contrôles :
#   TARGET=fr/acquisition            un dossier ou un fichier (défaut : fr en meta pour
#                                    validate, fr en meta/authors.xml pour quality, fr en
#                                    pour typography)
#   REPORT=yes                       écrit aussi le rapport dans reports/
#   LEVEL=warning                    typography : masque les informations (info, warning, error)
#   PHASE=markup                     typography : un seul thème
#   BIBLIOGRAPHY=yes                 typography : contrôle aussi la bibliographie
#   DEFAULT_LANG=fr                  typography : langue d’un fichier rangé hors de fr/ ou en/
#
# Exemples :
#   make import LANGUAGE=fr CHAPTER=acquisition DOCX=~/Documents/GardePartagee.docx
#   make check TARGET=fr/acquisition/variabilite.xml
#   make typography TARGET=fr/acquisition LEVEL=warning REPORT=yes
#   make validate TARGET=meta
#
# Prérequis : TEI Stylesheets et Ant ; pour l’import, le profil nucma déclaré dans les
# Stylesheets (lien profiles/nucma) ; pour les schémas, l’ODD de Commons Publishing dans
# COMMONS_PUBLISHING ; une connexion à internet (éléments repris de tei:4.11.0).
# Pour les contrôles : Jing et xmllint ; Saxon (SAXON_CP), SchXslt2 (XSpec) et typesetter.
# Détails : README.md, sections « Lancer les contrôles avec make » et « Schémas (ODD ».

# make sans argument affiche l’aide
.DEFAULT_GOAL := help

.PHONY: help

# aide : le commentaire d’en-tête de ce fichier, jusqu’à la première ligne vide
help:
	@sed -n '/^$$/q; s/^# \{0,1\}//p' $(firstword $(MAKEFILE_LIST))

TEI_STYLESHEETS ?= $(HOME)/TEIC/Stylesheets
COMMONS_PUBLISHING ?= ../tei-commons-publishing/odd/commons-publishing-metopes-compiled.odd
TEITOODD := $(TEI_STYLESHEETS)/bin/teitoodd
TEITORNG := $(TEI_STYLESHEETS)/bin/teitorng
TEITOHTML := $(TEI_STYLESHEETS)/bin/teitohtml
DOCXTOTEI := $(TEI_STYLESHEETS)/bin/docxtotei

# --- Import ----------------------------------------------------------------------------

.PHONY: import

# Conversion dans build/import.xml, puis rangement dans <langue>/<chapitre>/<nom>.xml. Le nom
# est NAME, sinon le titre court du document Word, que le profil pose dans
# sourceDesc/@xml:id (nucma.fr.acquisition.variabilite → variabilite) ; avec NAME,
# l’identifiant est aligné sur le nom du fichier. La langue du bloc d’en-tête du document
# doit être LANGUAGE. Un fichier existant n’est remplacé qu’avec FORCE=yes. Le profil lit
# meta/authors.xml de ce dépôt.
import:
	@test -n "$(LANGUAGE)" -a -n "$(CHAPTER)" -a -n "$(DOCX)" || { echo "Usage : make import LANGUAGE=fr CHAPTER=acquisition DOCX=chemin/vers/Entree.docx [NAME=nom-court] [FORCE=yes]"; exit 1; }
	@case "$(LANGUAGE)" in fr|en) ;; *) echo "LANGUAGE : fr ou en"; exit 1 ;; esac
	@case "$(CHAPTER)$(NAME)" in *[!a-z0-9-]*) echo "CHAPTER et NAME : minuscules sans diacritique, chiffres, tirets"; exit 1 ;; esac
	@test -x "$(DOCXTOTEI)" || { echo "docxtotei introuvable : TEI_STYLESHEETS=$(TEI_STYLESHEETS)"; exit 1; }
	@test -e "$(TEI_STYLESHEETS)/profiles/nucma" || { echo "profil nucma non déclaré dans $(TEI_STYLESHEETS)/profiles (voir README, Installation)"; exit 1; }
	@docx="$(DOCX)"; \
	case $$docx in "~/"*) docx="$$HOME/$${docx#\~/}" ;; esac; \
	case $$docx in /*) ;; *) docx="$$PWD/$$docx" ;; esac; \
	test -f "$$docx" || { echo "document introuvable : $$docx"; exit 1; }; \
	mkdir -p build; rm -f build/import.xml; \
	echo "== conversion de $$docx"; \
	NUCMA_AUTHORS="file://$(CURDIR)/meta/authors.xml" NUCMA_CHAPTER="$(CHAPTER)" \
	  "$(DOCXTOTEI)" --profile=nucma "$$docx" "$(CURDIR)/build/import.xml" > build/import.log 2>&1; \
	test -s build/import.xml || { cat build/import.log; echo "échec de la conversion (journal : build/import.log)"; exit 1; }; \
	id=$$(xmllint --xpath "string(//*[local-name()='sourceDesc']/@*[local-name()='id'])" build/import.xml 2> /dev/null); \
	test -n "$$id" || { echo "pas d’identifiant sur sourceDesc : vérifier le bloc d’en-tête du document Word (résultat dans build/import.xml)"; exit 1; }; \
	lang=$$(echo "$$id" | cut -d. -f2); \
	test "$$lang" = "$(LANGUAGE)" || { echo "le bloc d’en-tête du document est en « $$lang », pas en « $(LANGUAGE) » (résultat dans build/import.xml)"; exit 1; }; \
	name="$(or $(NAME),$$(echo "$$id" | sed 's/.*\.//'))"; \
	newid="nucma.$(LANGUAGE).$(CHAPTER).$$name"; \
	if [ "$$newid" != "$$id" ]; then \
	  sed "s/\"$$(echo "$$id" | sed 's/\./\\./g')\"/\"$$newid\"/g" build/import.xml > build/import.tmp && mv build/import.tmp build/import.xml; \
	  echo "   identifiant $$id → $$newid"; \
	fi; \
	out="$(LANGUAGE)/$(CHAPTER)/$$name.xml"; \
	if [ -e "$$out" ] && [ "$(FORCE)" != yes ]; then \
	  echo "$$out existe déjà : FORCE=yes pour le remplacer, ou NAME=… (résultat dans build/import.xml)"; exit 1; \
	fi; \
	mkdir -p "$(LANGUAGE)/$(CHAPTER)" && mv build/import.xml "$$out"; \
	echo "== $$out ($$newid)"; \
	todo=$$(grep -c '@todo' "$$out"); \
	if [ "$$todo" -gt 0 ]; then echo "   $$todo commentaire(s) @todo à traiter (auteurs absents de meta/authors.xml, DOI…)"; fi; \
	corpus="$(LANGUAGE)/$(CHAPTER)/_corpus.xml"; \
	if ! grep -qs "href=\"\./$$name\.xml\"" "$$corpus"; then \
	  echo "   à ajouter dans $$corpus :"; \
	  echo "   <xi:include href=\"./$$name.xml\" parse=\"xml\">"; \
	  echo "      <xi:fallback xml:lang=\"$(LANGUAGE)\">Fichier non trouvé / File not found</xi:fallback>"; \
	  echo "   </xi:include>"; \
	fi; \
	echo "   ensuite : relire l’en-tête, puis make check TARGET=$$out"

# ODD qui s’appuient sur l’étage commun (odd/nucma-common.odd) : un schéma chacun
SCHEMAS := nucma-text nucma-persons nucma-places nucma-artworks nucma-exhibitions nucma-bibliography nucma-medias
# seulement ceux dont l’ODD existe
RNG := $(patsubst odd/%.odd,schemas/%.rng,$(wildcard $(SCHEMAS:%=odd/%.odd)))
COMMON := odd/nucma-common.compiled.odd
# documentation : étage commun, puis une page par schéma
DOC := documentation/nucma-common.html $(patsubst odd/%.odd,documentation/%.html,$(wildcard $(SCHEMAS:%=odd/%.odd)))

.PHONY: schemas documentation clean-schemas clean-documentation

schemas: $(RNG)

# étage commun compilé : chaque ODD spécifique s’appuie sur lui (schemaSpec/@source)
$(COMMON): odd/nucma-common.odd $(COMMONS_PUBLISHING)
	cd odd && $(TEITOODD) nucma-common.odd nucma-common.compiled.odd > /dev/null

schemas/%.rng: odd/%.odd $(COMMON)
	cd odd && $(TEITORNG) --odd $*.odd ../$@ > /dev/null
	@echo "   $@"

# documentation HTML de chaque ODD : prose et référence des éléments et attributs
documentation: $(DOC)

documentation/%.html: odd/%.odd $(COMMON)
	@mkdir -p documentation
	cd odd && $(TEITOHTML) --odd --lang=fr $*.odd ../$@ > /dev/null
	@echo "   $@"

clean-schemas:
	rm -f $(COMMON) $(RNG)

clean-documentation:
	rm -rf documentation

# --- Framework oXygen ------------------------------------------------------------------

OXYGEN ?= /Applications/Oxygen XML Editor
OXYGEN_JAR := oxygen/frameworks/nucma/nucma.jar
OXYGEN_SOURCES := $(wildcard oxygen/java/src/ca/nucma/oxygen/*.java)
OXYGEN_CLASSPATH := $(OXYGEN)/lib/oxygen.jar:$(OXYGEN)/lib/oxygen-annotations.jar:$(OXYGEN)/frameworks/tei/tei.jar

.PHONY: oxygen-jar

oxygen-jar: $(OXYGEN_JAR)

# compilé contre l’API d’oXygen et le framework TEI de l’installation, pour Java 17
# (oXygen 28 embarque Java 21) : à refaire après une mise à jour majeure d’oXygen
$(OXYGEN_JAR): $(OXYGEN_SOURCES)
	@test -f "$(OXYGEN)/lib/oxygen.jar" || { echo "oXygen introuvable : OXYGEN=$(OXYGEN)"; exit 1; }
	@rm -rf build/oxygen-classes && mkdir -p build/oxygen-classes
	javac --release 17 -d build/oxygen-classes -cp "$(OXYGEN_CLASSPATH)" $(OXYGEN_SOURCES)
	jar --create --file $@ -C build/oxygen-classes .
	@rm -rf build/oxygen-classes
	@echo "   $@"

# --- Contrôles -------------------------------------------------------------------------

TYPESETTER ?= $(HOME)/factoton/typesetter
SCHXSLT ?= $(HOME)/xspec/lib/schxslt2/transpile.xsl
SAXON ?= java -jar $(SAXON_CP)
JING ?= jing

# fichiers contrôlés : tous les .xml du dossier ou le fichier désigné par TARGET
files = $(sort $(shell find $(or $(TARGET),$(1)) -name '*.xml' 2> /dev/null))
# les fichiers _corpus.xml assemblent des entrées déjà contrôlées une à une
entries = $(filter-out %/_corpus.xml _corpus.xml,$(call files,$(1)))

# rapport : reports/<contrôle>-<cible>-<date>.txt, ou rien
DATE := $(shell date +%F)
report = $(if $(filter yes,$(REPORT)),reports/$(1)-$(or $(subst /,-,$(patsubst %.xml,%,$(patsubst %/,%,$(TARGET)))),tout)-$(DATE).txt,/dev/null)

TYPOGRAPHY_SCH := $(TYPESETTER)/schematron/typography.sch
TYPOGRAPHY_XSL := build/typography$(if $(PHASE),-$(PHASE)).xsl
QUALITY_XSL := build/nucma-quality.xsl

.PHONY: validate quality typography check clean-check check-saxon check-target

# les trois contrôles, même si la validation échoue ; échoue ensuite si l’un a échoué
check:
	@status=0; \
	$(MAKE) --no-print-directory validate || status=1; \
	$(MAKE) --no-print-directory quality typography || status=1; \
	exit $$status

# Validation : le schéma dépend de l’emplacement du fichier (meta/authors.xml et
# meta/names.xml → nucma-persons, meta/<x>.xml → nucma-<x>, entrées → nucma) ; les
# xi:include des fichiers _corpus.xml sont développés avant la validation. Échoue si un
# fichier n’est pas valide.
validate: $(RNG) check-target
	@mkdir -p build $(if $(filter yes,$(REPORT)),reports); \
	out=$(call report,validate); : > $$out; status=0; ok=0; ko=0; \
	for f in $(call files,fr en meta); do \
	  case $$f in \
	    meta/authors.xml|meta/names.xml) rng=schemas/nucma-persons.rng ;; \
	    meta/*) rng=schemas/nucma-$$(basename $$f);  rng=$${rng%.xml}.rng ;; \
	    *) rng=schemas/nucma-text.rng ;; \
	  esac; \
	  case $$f in \
	    *_corpus.xml) xmllint --xinclude --nowarning $$f > build/corpus.xml 2> build/validate.txt \
	                    && $(JING) $$rng build/corpus.xml >> build/validate.txt 2>&1 ;; \
	    *) $(JING) $$rng $$f > build/validate.txt 2>&1 ;; \
	  esac \
	    && { ok=$$((ok + 1)); echo "== $$f : valide ($$rng)" | tee -a $$out; } \
	    || { status=1; ko=$$((ko + 1)); echo "== $$f : NON VALIDE ($$rng)" | tee -a $$out; \
	         sed 's|^$(CURDIR)/||; s|^|   |' build/validate.txt | tee -a $$out; }; \
	done; \
	echo "== bilan : $$ok valide(s), $$ko non valide(s)" | tee -a $$out; \
	$(if $(filter yes,$(REPORT)),echo "   rapport : $$out";) \
	exit $$status

# Contrôle de l’encodage (schemas/nucma-quality.sch)
quality: $(QUALITY_XSL) check-saxon check-target
	@mkdir -p build $(if $(filter yes,$(REPORT)),reports); \
	out=$(call report,quality); : > $$out; \
	for f in $(call entries,fr en meta/authors.xml); do \
	  $(SAXON) -s:$$f -xsl:$(QUALITY_XSL) -o:build/quality.svrl \
	    && $(SAXON) -s:build/quality.svrl -xsl:schemas/svrl-text.xsl document=$$f | tee -a $$out; \
	done; \
	$(if $(filter yes,$(REPORT)),echo "   rapport : $$out";) true

# Contrôle typographique (typography.sch de typesetter)
typography: $(TYPOGRAPHY_XSL) check-saxon check-target
	@mkdir -p build $(if $(filter yes,$(REPORT)),reports); \
	out=$(call report,typography$(if $(PHASE),-$(PHASE))); : > $$out; \
	for f in $(call entries,fr en); do \
	  $(SAXON) -s:$$f -xsl:$(TYPOGRAPHY_XSL) -o:build/typography.svrl \
	    $(if $(filter yes,$(BIBLIOGRAPHY)),'?check-bibliography=true()') \
	    $(if $(DEFAULT_LANG),default-lang=$(DEFAULT_LANG)) \
	    && $(SAXON) -s:build/typography.svrl -xsl:$(TYPESETTER)/schematron/svrl-report.xsl \
	         document=$$f level=$(or $(LEVEL),info) | tee -a $$out; \
	done; \
	$(if $(filter yes,$(REPORT)),echo "   rapport : $$out";) true

# Schematron compilés par SchXslt2 ; recompilés quand le schéma, ses modules ou ses
# listes changent
$(QUALITY_XSL): schemas/nucma-quality.sch | check-saxon
	@mkdir -p build
	$(SAXON) -s:$< -xsl:$(SCHXSLT) -o:$@

$(TYPOGRAPHY_XSL): $(TYPOGRAPHY_SCH) $(wildcard $(TYPESETTER)/schematron/rules/*/*.sch $(TYPESETTER)/schematron/lists/*.xml) | check-saxon
	@mkdir -p build
	$(SAXON) -s:$< -xsl:$(SCHXSLT) -o:$@ $(if $(PHASE),'{http://dmaus.name/ns/2023/schxslt}phase=$(PHASE)')

# --- Transformations (typesetter) ------------------------------------------------------

.PHONY: serialize cleanup normalize

# Transformation sur place des entrées de TARGET (fr/ et en/, sans les _corpus.xml) par
# une feuille de typesetter : $(1) nom de l’étape, $(2) feuille, $(3) paramètres. TARGET
# est obligatoire. Un fichier qui a des modifications non commitées est laissé de côté
# (sauf FORCE=yes), pour que le diff ne montre que l’effet de l’étape.
define transform
	@test -n "$(TARGET)" || { echo "Usage : make $(1) TARGET=fichier-ou-dossier [FORCE=yes]"; exit 1; }
	@mkdir -p build; status=0; n=0; \
	for f in $(filter fr/% en/%,$(call entries,)); do \
	  if [ "$(FORCE)" != yes ] && ! { git ls-files --error-unmatch $$f > /dev/null 2>&1 && git diff --quiet HEAD -- $$f; }; then \
	    echo "== $$f : modifications non commitées, laissé de côté (commit d’abord, ou FORCE=yes)"; status=1; continue; \
	  fi; \
	  echo "== $$f"; \
	  $(SAXON) -s:$$f -xsl:$(2) -o:build/$(1).xml $(3) \
	    && mv build/$(1).xml $$f && n=$$((n + 1)) \
	    || { echo "   échec : $$f n’est pas modifié"; status=1; }; \
	done; \
	echo "== $(1) : $$n fichier(s) traité(s)"; \
	if [ $$n -gt 0 ]; then git diff --stat -- $(TARGET); echo "   relire avec git diff --word-diff $(TARGET), puis commit"; fi; \
	exit $$status
endef

# 1. sérialisation : remet sur une ligne les balises coupées par un éditeur XML
serialize: check-saxon check-target
	$(call transform,serialize,$(TYPESETTER)/src/serialization.xsl,)

# 2. nettoyage des artefacts de Word (déjà fait par le profil pour un fichier importé)
cleanup: check-saxon check-target
	$(call transform,cleanup,$(TYPESETTER)/src/import-cleanup.xsl,)

# 3. normalisation Unicode et typographique ; journal dans logs/
normalize: check-saxon check-target
	$(call transform,normalize,$(TYPESETTER)/src/normalization.xsl,$(if $(filter yes,$(BIBLIOGRAPHY)),'?process-bibliography=true()') $(if $(DEFAULT_LANG),default-lang=$(DEFAULT_LANG)) $(if $(filter yes,$(DETAIL)),report=detail))

check-target:
	@$(if $(TARGET),test -e "$(TARGET)" || { echo "TARGET introuvable : $(TARGET)"; exit 1; })

check-saxon:
	@test -f "$(SAXON_CP)" || { echo "SAXON_CP doit désigner le fichier jar de Saxon (voir README, Installation)"; exit 1; }
	@test -f "$(TYPOGRAPHY_SCH)" || { echo "typesetter introuvable : TYPESETTER=$(TYPESETTER)"; exit 1; }

clean-check:
	rm -rf build reports
