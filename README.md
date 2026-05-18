# NUCMA – Encyclopédie des Nouveaux usages des collections dans les musées d’art

NUCMA – Encyclopédie des Nouveaux usages des collections dans les musées d’art est un projet du groupe de recherche CIÉCO réalisé dans le cadre du Partenariat *Des nouveaux usages des collections dans les musées d’art*.

## Organisation des fichiers

```bash
nucma/
├── _corpus.xml
├── fr
│   ├── _corpus.xml
│   ├── acquisition
│   │   ├── _corpus.xml
│   │   ├── coacquisition.xml
│   │   ├── protocoles.xml
│   │   └── ...
│   ├── documentation
│   ├── mise-a-vue
│   ├── mediation
│   ├── circulation
│   ├── alienation
│   └── complements
├── en
│   ├── _corpus.xml
│   ├── acquisition
│   ├── documentation
│   ├── display
│   ├── interpretation/
│   ├── circulation/
│   ├── deaccessioning/
│   └── supplements/
├── meta/
│   ├── _corpus.xml
│   ├── authors.xml
│   ├── artworks.xml
│   ├── bibliography.xml
│   ├── exhibitions.xml
│   ├── medias.xml
│   ├── names.xml
│   ├── places.xml
│   └── ...

├── odd/                  ODD : sources des schémas (voir « Schémas »)
├── schemas/              schémas générés par make schemas (.rng, non versionnés) et Schematron d’encodage
├── documentation/        documentation HTML générée par make documentation (non versionnée)
├── reports/              rapports des contrôles (make … REPORT=yes, non versionnés)
├── Makefile              génération des schémas et de leur documentation, contrôles
├── LICENCE
└── README.md
```

## Outils et chaîne de traitement

Les textes sont produits et contrôlés avec des outils rangés dans deux dépôts distincts, chacun documenté dans son propre README :

| Dépôt | Rôle |
|---|---|
| [nucma-profile](https://github.com/ouvroir/nucma-profile) | Profil `nucma` des TEI Stylesheets : conversion des entrées Word en TEI, en-tête rempli, nettoyage des artefacts de Word. |
| [typesetter](https://codeberg.org/Factoton/typesetter) | Normalisation Unicode et typographique (`src/normalization.xsl`), nettoyage d’un TEI déjà importé, sérialisation, contrôle typographique (`schematron/typography.sch`). |

Ce dépôt-ci contient les textes, les référentiels (`meta/`) et les schémas propres à l’encyclopédie : les ODD (`odd/`), les schémas qui en sont générés et le Schematron d’encodage (`schemas/`).

### Installation

À faire une fois par poste. Les commandes sont données pour macOS ; les outils fonctionnent aussi sous Linux et Windows.

1. **Java** : vérifier qu’il est installé (`java -version`), sinon l’installer (par exemple `brew install openjdk`).

2. **Saxon HE 12** (processeur XSLT) : télécharger `saxon-he-12.*.jar` depuis les [versions de Saxon-HE](https://github.com/Saxonica/Saxon-HE/releases) et créer un alias `saxon` dans votre `~/.zshrc` ou votre `~/.zprofile` :

   ```sh
   alias saxon='java -jar /chemin/vers/saxon-he-12.3.jar'
   ```

   La chaîne a été testée avec Saxon HE 12.3. Homebrew installe une version plus récente (`brew install saxon`, Saxon 13), qui n’a pas été testée.

3. **XSpec** (outil de test des feuilles XSLT et des Schematron) : il fournit aussi SchXslt2, le compilateur de Schematron qu’emploient les commandes de contrôle ci-dessous. Le cloner dans `~/xspec`, chemin attendu par ces commandes, et se placer sur la version testée :

   ```sh
   git clone https://github.com/xspec/xspec.git ~/xspec
   git -C ~/xspec checkout v4.1.2
   ```

   Pour lancer les tests des outils (dans typesetter, voir son README), XSpec doit savoir où trouver Saxon : ajouter dans `~/.zshrc` ou `~/.zprofile` le chemin du fichier jar de Saxon.

   ```sh
   export SAXON_CP=/chemin/vers/saxon-he-12.3.jar
   ```

   Vérifier : `~/xspec/bin/xspec.sh -h` affiche l’aide.

4. **Les outils** : cloner les deux dépôts, à l’emplacement de son choix, et désigner `typesetter` par une variable (dans `~/.zshrc` ou `~/.zprofile`), qu’emploient toutes les commandes ci-dessous :

   ```sh
   git clone https://codeberg.org/Factoton/typesetter.git ~/factoton/typesetter
   git clone https://github.com/ouvroir/nucma-profile.git ~/ouvroir/nucma-profile
   export TYPESETTER=~/factoton/typesetter
   ```

5. **Pour importer des textes depuis MS Word, ou pour régénérer les schémas** : les [TEI Stylesheets](https://github.com/TEIC/Stylesheets) et Ant (`brew install ant`) ; pour l’import, le profil déclaré par un lien symbolique (voir le README de nucma-profile) ; pour les schémas, l’ODD de [Commons Publishing](https://git.unicaen.fr/fnso/i-fair-ir/tei-commons-publishing) cloné à côté de ce dépôt :

   ```sh
   git clone https://github.com/TEIC/Stylesheets.git ~/TEIC/Stylesheets
   export PATH=~/TEIC/Stylesheets/bin:$PATH
   ln -s ~/ouvroir/nucma-profile ~/TEIC/Stylesheets/profiles/nucma
   git clone https://git.unicaen.fr/fnso/i-fair-ir/tei-commons-publishing.git ~/ouvroir/tei-commons-publishing
   ```

6. **Vérifier** depuis la racine de ce dépôt : la commande suivante affiche le bilan de normalisation d’une entrée, sans rien modifier.

   ```sh
   saxon -s:fr/acquisition/variabilite.xml -xsl:$TYPESETTER/src/normalization.xsl -o:/tmp/test.xml log-dir=
   ```

### Traiter une entrée

Toutes les commandes se lancent depuis la racine de ce dépôt. Chaque étape fait l’objet de son propre commit, pour que les diffs restent lisibles.

1. **Import depuis MS Word** (nucma-profile) : `docxtotei --profile=nucma Entree.docx fr/acquisition/entree.xml`. Le fichier produit est nettoyé, son en-tête est rempli, et il est associé à `nucma.rng` et à `nucma-quality.sch`. Commit.
2. **Structuration** dans oXygen : `div`, `q`, `soCalled`, `title`, `persName`, `orgName`, `placeName`, bibliographie… Commit.
3. **Normalisation** (typesetter) : toujours dans un fichier temporaire, puis remplacement.

   ```sh
   f=fr/acquisition/entree.xml
   saxon -s:$f -xsl:$TYPESETTER/src/normalization.xsl -o:$f.tmp && mv $f.tmp $f
   git diff --word-diff
   ```

   Le diff ne doit montrer que des corrections typographiques. Commit.
4. **Contrôle typographique** (typesetter) : `make typography TARGET=$f` (voir ci-dessous). Corriger ce qui doit l’être, compléter le balisage suggéré. Commit.
5. **Contrôle de l’encodage** : `make validate TARGET=$f` et `make quality TARGET=$f`, validation par `nucma.rng` et `nucma-quality.sch` (voir « Schémas » et « Contrôle de l’encodage »). Commit.

Pour un fichier déjà importé autrement que par le profil, les étapes de sérialisation et de nettoyage sont décrites dans le README de typesetter (« Utilisation »).

### Lancer les contrôles avec make

Les trois contrôles se lancent depuis la racine de ce dépôt :

```sh
make validate     # validation par les schémas RelaxNG (Jing)
make quality      # contrôle de l’encodage (schemas/nucma-quality.sch)
make typography   # contrôle typographique (typography.sch de typesetter)
make check        # les trois à la suite
```

Sans autre précision, `validate` contrôle `fr/`, `en/` et `meta/`, `quality` les entrées et `meta/authors.xml`, `typography` les entrées. `TARGET` désigne un dossier ou un fichier :

```sh
make typography TARGET=fr/acquisition
make check TARGET=fr/acquisition/variabilite.xml
```

Options :

| Option | Contrôle | Effet |
|---|---|---|
| `REPORT=yes` | tous | écrit aussi le rapport dans `reports/<contrôle>-<cible>-<date>.txt` (non versionné) |
| `LEVEL=warning` ou `LEVEL=error` | typography | masque les messages de niveau inférieur |
| `PHASE=markup` | typography | un seul thème (`punctuation`, `quotes`, `capitals`, `persons`…) |
| `BIBLIOGRAPHY=yes` | typography | contrôle aussi la bibliographie, exclue par défaut |
| `DEFAULT_LANG=fr` | typography | langue d’un fichier rangé hors de `fr/` ou `en/` |

`make validate` choisit le schéma d’après l’emplacement du fichier (comme les instructions `xml-model`), développe les `xi:include` des fichiers `_corpus.xml`, génère d’abord les schémas s’ils manquent ou ont changé, et se termine en erreur si un fichier n’est pas valide. Les Schematron sont compilés dans `build/` (non versionné) et recompilés quand ils changent, y compris après une mise à jour de typesetter. Les fichiers `_corpus.xml` ne passent que par la validation : les entrées qu’ils assemblent sont contrôlées une à une.

Chaque message commence par `fichier:ligne:colonne` : dans le terminal de VS Code (et d’autres terminaux), un clic sur cette référence ouvre le fichier à l’endroit concerné ; pour garder les liens en relisant un rapport enregistré, l’afficher dans le terminal (`cat reports/…`). Pour un fichier `_corpus.xml`, les lignes données par la validation sont celles du corpus développé (`build/corpus.xml`), pas celles des entrées.

Il faut Jing, Saxon désigné par `SAXON_CP`, XSpec dans `~/xspec` (pour SchXslt2) et typesetter dans `~/factoton/typesetter` ; d’autres emplacements se donnent par des variables : `make typography TYPESETTER=… SCHXSLT=…`. `make clean-check` supprime `build/` et `reports/`.

### Contrôle typographique

`$TYPESETTER/schematron/typography.sch` signale ce qui contrevient aux règles typographiques de la langue de chaque passage (Imprimerie nationale pour le français, Chicago Manual of Style pour l’anglais), avec une consigne de correction, et suggère le balisage des passages entre guillemets ou en italique. Il ne modifie rien. Les messages terminés par « (auto) » signalent ce que la normalisation corrige d’elle-même. Le détail des règles, des listes et des paramètres est dans le README de typesetter (« Contrôle typographique »).

**Dans oXygen** : ouvrir l’entrée, *Document › Validate › Validate with…*, choisir `typography.sch` dans le dossier `schematron/` de typesetter. La boîte de dialogue permet de choisir une phase pour ne contrôler qu’un thème (`punctuation`, `quotes`, `capitals`, `persons`, `markup`…). Les messages sont reliés à l’endroit concerné ; leur icône distingue les erreurs, les avertissements et les informations.

Pour associer durablement le schéma à une entrée, on peut ajouter une instruction en tête de fichier ; le chemin dépend de l’emplacement de typesetter sur le poste (ici depuis `fr/acquisition/`, avec typesetter dans `~/factoton/`) :

```xml
<?xml-model href="../../../../factoton/typesetter/schematron/typography.sch" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"?>
```

**En ligne de commande** : `make typography` (voir « Lancer les contrôles avec make »). Sans make, compiler le schéma une fois, et après toute mise à jour de typesetter, puis contrôler les entrées.

```sh
saxon -s:$TYPESETTER/schematron/typography.sch -xsl:$HOME/xspec/lib/schxslt2/transpile.xsl -o:/tmp/typography.xsl

for f in fr/acquisition/*.xml; do
  saxon -s:$f -xsl:/tmp/typography.xsl -o:/tmp/typo.svrl && saxon -s:/tmp/typo.svrl -xsl:$TYPESETTER/schematron/svrl-report.xsl document=$f
done
```

Le rapport donne pour chaque message le niveau, la règle, la référence `fichier:ligne:colonne`, l’emplacement (`body/div[2]/p[3]`), la consigne et un extrait. Options utiles :

- `level=warning` à la fin de la seconde commande : masque les informations (suggestions de balisage, espaces multiples) ;
- `'?check-bibliography=true()'` à la fin de la première commande `saxon -s:$f …` : contrôle aussi la bibliographie, exclue par défaut ;
- `'{http://dmaus.name/ns/2023/schxslt}phase=markup'` à la fin de la compilation : un seul thème.

La langue de chaque passage vient de son `xml:lang` ; à défaut, de `text/@xml:lang` (posé par le profil d’import), de `langUsage`, puis du dossier `fr/` ou `en/` du fichier ; c’est la même règle que pour la normalisation. Pour contrôler une copie rangée ailleurs (une version normalisée dans `/tmp`, par exemple), ajouter `default-lang=fr` ou `default-lang=en`.

### Journaux de normalisation

La normalisation écrit son bilan sur la console et dans un journal, `logs/<entrée>-<date>.log`, à la racine de ce dépôt (un passage le même jour remplace le journal). Avec `report=detail`, le journal liste chaque modification, ce qui aide à relire le diff.

## Schémas (ODD)

Les fichiers du projet sont validés par des schémas RelaxNG générés à partir d’ODD, avec les TEI Stylesheets. Les ODD forment une chaîne : un étage commun personnalise [Commons Publishing](https://tei-commons-publishing.readthedocs.io) (variante Métopes), et chaque schéma s’appuie sur cet étage commun.

```text
Commons Publishing (odd/commons-publishing-metopes-compiled.odd, dépôt tei-commons-publishing)
└── odd/nucma-common.odd            règles communes à tout le projet
    ├── odd/nucma.odd               entrées (fr/, en/) et _corpus.xml   → schemas/nucma.rng
    ├── odd/nucma-persons.odd       meta/authors.xml, meta/names.xml    → schemas/nucma-persons.rng
    ├── odd/nucma-places.odd        meta/places.xml                     → schemas/nucma-places.rng
    ├── odd/nucma-artworks.odd      meta/artworks.xml                   → schemas/nucma-artworks.rng
    ├── odd/nucma-exhibitions.odd   meta/exhibitions.xml                → schemas/nucma-exhibitions.rng
    ├── odd/nucma-bibliography.odd  meta/bibliography.xml               → schemas/nucma-bibliography.rng
    └── odd/nucma-medias.odd        meta/medias.xml                     → schemas/nucma-medias.rng
```

Chaque fichier désigne son schéma par une instruction `xml-model` en tête ; oXygen l’applique dès l’ouverture.

### Ce que les schémas ajoutent à Commons Publishing

L’étage commun (`nucma-common.odd`) reste aussi compatible que possible avec Commons Publishing et ne l’élargit que pour les besoins du projet :

- **en-tête** : collection (`seriesStmt`), identifiant de l’entrée et lien vers sa version dans l’autre langue (`sourceDesc/@xml:id`, `@corresp`), responsable d’une révision (`change/@resp`) ;
- **identifiants** : types d’`idno` en liste fermée et en minuscules (`orcid`, `isni`, `viaf`, `wikidata`, `bnf`, `loc`, `ulan`, `zkm`, `artblocks`, `artefact`, `doi`, `isbn`, `issn`, `uri`, `url`, `callNumber`) ;
- **noms** : renvoi aux référentiels par `@ref` sur `persName`, `orgName`, `placeName`, `objectName`, `author` et `bibl` ; fonction (`roleName`) ;
- **rendu** : `superscript` et `smallcaps` sur `hi` (produits par la normalisation), `rend="verbatim"` sur tout élément (passage à garder tel quel) ;
- **phrase** : `emph`, `foreign`, `q`, `soCalled`, `title`.

Les schémas des référentiels ajoutent leurs listes d’entités (personnes et organismes, lieux, œuvres, expositions, bibliographie structurée). Ce sont des **premières versions souples** : les éléments nécessaires sont admis, sans ordre imposé ; leur structure sera resserrée ensuite. Les exigences propres aux auteurs (ORCID, affiliation) restent contrôlées par le Schematron d’encodage.

**Règle de maintenance** : un schéma ne s’élargit que pour un besoin du projet, jamais pour faire valider une donnée fautive. Une erreur de validation sur une donnée (type d’`idno` en capitales, attribut vide, `@xml:id` sur un `idno`…) se corrige dans la donnée.

### Générer les schémas et leur documentation

```sh
make schemas               # génère les schémas de schemas/ à partir des ODD
make documentation         # génère la documentation HTML dans documentation/
make clean-schemas         # supprime les schémas générés et l’étage commun compilé
make clean-documentation   # supprime documentation/
```

Les schémas générés (`schemas/nucma.rng`, `schemas/nucma-*.rng`) ne sont pas versionnés : **avant de valider, chacun génère les schémas avec `make schemas`**, et le refait après une mise à jour des ODD. `make` compile d’abord l’étage commun (`odd/nucma-common.compiled.odd`, fichier intermédiaire lui aussi non versionné), puis produit chaque schéma ; il ne régénère que ce qui a changé. Il faut les TEI Stylesheets et le dépôt Commons Publishing (voir « Installation ») et une connexion à internet : les éléments repris de la TEI viennent de sa version 4.11.0, figée pour que la génération soit reproductible. Les chemins se changent par des variables : `make schemas TEI_STYLESHEETS=… COMMONS_PUBLISHING=…`.

La documentation HTML, dans `documentation/` (non versionné : chacun la régénère), comprend `nucma-common.html` pour les règles communes, puis une page par schéma. Elle présente la prose de chaque ODD et la référence de ses éléments et attributs : c’est le guide d’encodage du projet.

Après une modification d’un ODD : `make schemas`, puis valider les fichiers concernés.

### Valider

**Dans oXygen**, la validation est automatique grâce aux instructions `xml-model`, une fois les schémas générés (`make schemas`). Les fichiers `_corpus.xml` assemblent les entrées par `xi:include` : oXygen résout les inclusions avant de valider.

**En ligne de commande** : `make validate` (voir « Lancer les contrôles avec make »), ou directement avec [Jing](https://relaxng.org/jclark/jing.html) (`brew install jing-trang`) :

```sh
jing schemas/nucma.rng fr/acquisition/variabilite.xml
jing schemas/nucma-persons.rng meta/authors.xml meta/names.xml
xmllint --xinclude fr/acquisition/_corpus.xml > /tmp/corpus.xml && jing schemas/nucma.rng /tmp/corpus.xml
```

Jing ne résout pas les `xi:include` : pour un fichier `_corpus.xml`, les développer d’abord avec `xmllint --xinclude`.

## Contrôle de l’encodage (Schematron)

`schemas/nucma-quality.sch` complète la validation par le schéma (`nucma.rng`) : il vérifie ce qu’une grammaire ne peut pas vérifier. Ses messages sont de deux niveaux : **erreur** (encodage incohérent, à corriger) et **avertissement** (information manquante ou forme à harmoniser).

Contrôles actuels :

| Où | Contrôle | Niveau |
|---|---|---|
| Entrées | chaque `author` a un `@ref` qui renvoie à une personne de `meta/authors.xml` | erreur |
| Entrées | chaque `respStmt` a un `resp` et un `@ref` valide (`@ref` absent : avertissement) | erreur |
| Entrées | l’auteur a un ORCID, dans l’entrée ou dans `meta/authors.xml` | avertissement |
| Entrées | l’ORCID de l’entrée est le même que celui de `meta/authors.xml` | erreur |
| Entrées | le prénom et le nom sont ceux de `meta/authors.xml` | avertissement |
| Entrées | `change/@resp` (ou `@who`) renvoie à une personne connue | avertissement |
| `meta/authors.xml` | chaque personne a un `@xml:id` unique, un prénom et un nom ; homonymes signalés | erreur |
| `meta/authors.xml` | chaque personne a un ORCID | avertissement |
| `meta/authors.xml` | un même identifiant (ORCID, ISNI…) n’est pas attribué à plusieurs personnes | erreur |
| `meta/authors.xml` | identifiants vides, sans type ou de type inconnu (`insi` pour `isni`…) | avertissement |
| Partout | ORCID valide (forme et chiffre de contrôle), écrit sous forme d’URL `https://orcid.org/…`, `type="orcid"` en minuscules ; ISNI de la forme `https://isni.org/isni/…` | erreur / avertissement |

`meta/authors.xml` est retrouvé à partir de l’emplacement du fichier contrôlé (dossier `fr/`, `en/` ou `meta/` du dépôt).

**Dans oXygen** : *Document › Validate › Validate with…* et choisir `schemas/nucma-quality.sch` ; les messages apparaissent dans le panneau des résultats et sont reliés à l’endroit concerné. On peut aussi l’associer durablement aux fichiers par une instruction de traitement, à côté de celle de `nucma.rng` :

```xml
<?xml-model href="../../schemas/nucma-quality.sch" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"?>
```

**En ligne de commande** : `make quality` (voir « Lancer les contrôles avec make »). Sans make, avec Saxon et SchXslt2 (voir « Installation ») : compiler le Schematron une fois (et après chaque modification), puis contrôler les fichiers depuis la racine du dépôt ; `schemas/svrl-text.xsl` met le rapport en forme.

```sh
saxon -s:schemas/nucma-quality.sch -xsl:$HOME/xspec/lib/schxslt2/transpile.xsl -o:/tmp/nucma-quality.xsl

for f in meta/authors.xml fr/acquisition/*.xml; do
  saxon -s:$f -xsl:/tmp/nucma-quality.xsl -o:/tmp/rapport.svrl && saxon -s:/tmp/rapport.svrl -xsl:schemas/svrl-text.xsl document=$f
done
```
