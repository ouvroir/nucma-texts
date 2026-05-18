# Chaîne de traitement de NUCMA.
#
#   make help            affiche cette aide (aussi : make sans argument)
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
# Options des contrôles :
#   TARGET=fr/acquisition            un dossier ou un fichier (défaut : fr en meta pour
#                                    validate, fr en meta/authors.xml pour quality, fr en
#                                    pour typography)
#   REPORT=yes                       écrit aussi le rapport dans reports/
#   LEVEL=warning                    typography : masque les informations (info, warning, error)
#   PHASE=markup                     typography : un seul thème
#   BIBLIOGRAPHY=yes                 typography : contrôle aussi la bibliographie
#   DEFAULT_LANG=fr                  typography : langue d’un fichier rangé hors de fr/ ou en/
#
# Exemples :
#   make check TARGET=fr/acquisition/variabilite.xml
#   make typography TARGET=fr/acquisition LEVEL=warning REPORT=yes
#   make validate TARGET=meta
#
# Prérequis : TEI Stylesheets et Ant ; l’ODD de Commons Publishing dans
# COMMONS_PUBLISHING ; une connexion à internet (éléments repris de tei:4.11.0).
# Pour les contrôles : Jing et xmllint ; Saxon (SAXON_CP), SchXslt2 (XSpec) et typesetter.
# Détails : README.md, sections « Lancer les contrôles avec make » et « Schémas (ODD) ».

# make sans argument affiche l’aide
.DEFAULT_GOAL := help

.PHONY: help

# aide : le commentaire d’en-tête de ce fichier, jusqu’à la première ligne vide
help:
	@sed -n '/^$$/q; s/^# \{0,1\}//p' $(firstword $(MAKEFILE_LIST))

TEI_STYLESHEETS ?= $(HOME)/TEIC/Stylesheets
COMMONS_PUBLISHING ?= ../tei-commons-publishing/odd/commons-publishing-metopes-compiled.odd
TEITOODD := $(TEI_STYLESHEETS)/bin/teitoodd
TEITORNG := $(TEI_STYLESHEETS)/bin/teitorng
TEITOHTML := $(TEI_STYLESHEETS)/bin/teitohtml

# ODD qui s’appuient sur l’étage commun (odd/nucma-common.odd) : un schéma chacun
SCHEMAS := nucma nucma-persons nucma-places nucma-artworks nucma-exhibitions nucma-bibliography nucma-medias
# seulement ceux dont l’ODD existe
RNG := $(patsubst odd/%.odd,schemas/%.rng,$(wildcard $(SCHEMAS:%=odd/%.odd)))
COMMON := odd/nucma-common.compiled.odd
# documentation : étage commun, puis une page par schéma
DOC := documentation/nucma-common.html $(patsubst odd/%.odd,documentation/%.html,$(wildcard $(SCHEMAS:%=odd/%.odd)))

.PHONY: schemas documentation clean-schemas clean-documentation

schemas: $(RNG)

# étage commun compilé : chaque ODD spécifique s’appuie sur lui (schemaSpec/@source)
$(COMMON): odd/nucma-common.odd $(COMMONS_PUBLISHING)
	cd odd && $(TEITOODD) nucma-common.odd nucma-common.compiled.odd > /dev/null

schemas/%.rng: odd/%.odd $(COMMON)
	cd odd && $(TEITORNG) --odd $*.odd ../$@ > /dev/null
	@echo "   $@"

# documentation HTML de chaque ODD : prose et référence des éléments et attributs
documentation: $(DOC)

documentation/%.html: odd/%.odd $(COMMON)
	@mkdir -p documentation
	cd odd && $(TEITOHTML) --odd --lang=fr $*.odd ../$@ > /dev/null
	@echo "   $@"

clean-schemas:
	rm -f $(COMMON) $(RNG)

clean-documentation:
	rm -rf documentation

# --- Contrôles -------------------------------------------------------------------------

TYPESETTER ?= $(HOME)/factoton/typesetter
SCHXSLT ?= $(HOME)/xspec/lib/schxslt2/transpile.xsl
SAXON ?= java -jar $(SAXON_CP)
JING ?= jing

# fichiers contrôlés : tous les .xml du dossier ou le fichier désigné par TARGET
files = $(sort $(shell find $(or $(TARGET),$(1)) -name '*.xml' 2> /dev/null))
# les fichiers _corpus.xml assemblent des entrées déjà contrôlées une à une
entries = $(filter-out %/_corpus.xml _corpus.xml,$(call files,$(1)))

# rapport : reports/<contrôle>-<cible>-<date>.txt, ou rien
DATE := $(shell date +%F)
report = $(if $(filter yes,$(REPORT)),reports/$(1)-$(or $(subst /,-,$(patsubst %.xml,%,$(patsubst %/,%,$(TARGET)))),tout)-$(DATE).txt,/dev/null)

TYPOGRAPHY_SCH := $(TYPESETTER)/schematron/typography.sch
TYPOGRAPHY_XSL := build/typography$(if $(PHASE),-$(PHASE)).xsl
QUALITY_XSL := build/nucma-quality.xsl

.PHONY: validate quality typography check clean-check check-saxon check-target

# les trois contrôles, même si la validation échoue ; échoue ensuite si l’un a échoué
check:
	@status=0; \
	$(MAKE) --no-print-directory validate || status=1; \
	$(MAKE) --no-print-directory quality typography || status=1; \
	exit $$status

# Validation : le schéma dépend de l’emplacement du fichier (meta/authors.xml et
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
	    *) rng=schemas/nucma.rng ;; \
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

check-target:
	@$(if $(TARGET),test -e "$(TARGET)" || { echo "TARGET introuvable : $(TARGET)"; exit 1; })

check-saxon:
	@test -f "$(SAXON_CP)" || { echo "SAXON_CP doit désigner le fichier jar de Saxon (voir README, Installation)"; exit 1; }
	@test -f "$(TYPOGRAPHY_SCH)" || { echo "typesetter introuvable : TYPESETTER=$(TYPESETTER)"; exit 1; }

clean-check:
	rm -rf build reports
