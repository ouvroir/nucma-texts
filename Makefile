# Chaîne de traitement de NUCMA.
#
#   make schemas         génère les schémas RelaxNG à partir des ODD (chaîne d’ODD),
#                        dans schemas/ (non versionnés)
#   make documentation   génère la documentation HTML dans documentation/ (non versionné)
#   make clean-schemas   supprime les schémas générés et l’étage commun compilé
#   make clean-documentation   supprime documentation/
#
# Prérequis : TEI Stylesheets et Ant ; l’ODD de Commons Publishing dans
# $(COMMONS_PUBLISHING) ; une connexion à internet (éléments repris de tei:4.11.0).

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
