# Textes de NUCMA, Encyclopédie des Nouveaux usages des collections dans les musées d’art

NUCMA – Encyclopédie des Nouveaux usages des collections dans les musées d’art est un projet du groupe de recherche CIÉCO réalisé dans le cadre du Partenariat *Des nouveaux usages des collections dans les musées d’art*.

## Organisation des fichiers

Le présent dépôt contient les textes, les référentiels (`meta/`) et les schémas propres à l’encyclopédie : les ODD (`odd/`), les schémas qui en sont générés et le Schematron d’encodage (`schemas/`).

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
├── oxygen/               framework oXygen NUCMA (frameworks/nucma/, voir « Valider »)
├── nucma-texts.xpr       projet oXygen
├── Makefile              génération des schémas et de leur documentation, contrôles
├── LICENCE
└── README.md
```

## Outils et chaîne de traitement

Les textes sont encodés avec la Text Encoding Initiative (TEI). Ils sont documentés par des schémas ODD et peuvent être validés par des schémas RelaxNG et des fichiers Schematron. Un Makefile automatise la production des schémas RelaxNG, la conversion des documents depuis docx et leur validation.

La conversion des fichiers docx utilise un profil pour les TEI Stylesheets qui est traité dans un dépôt distinct. Le contrôle typographique des fichiers par Schematron utilise également un répertoire distinct :

| Dépôt | Rôle |
|---|---|
| [nucma-profile](https://github.com/ouvroir/nucma-profile) | Profil `nucma` des TEI Stylesheets : conversion des fichiers MS Word en XML-TEI, création des en-tête rempli, nettoyage des artefacts du traitement de texte. |
| [typesetter](https://codeberg.org/Factoton/typesetter) | Normalisation Unicode et typographique (`src/normalization.xsl`), nettoyage d’un TEI déjà importé, sérialisation, contrôle typographique (`schematron/typography.sch`). |

### Installation

L’installation utilise des logiciels libres et open source. Les commandes sont données pour MacOS ; les outils fonctionnent aussi sous Linux et Windows.

1. **Java** : vérifier que java est installé (`java -version`), sinon l’installer (par exemple `brew install openjdk`).

2. **Saxon HE 12** (processeur XSLT) : télécharger `saxon-he-12.*.jar` depuis les [versions de Saxon-HE](https://github.com/Saxonica/Saxon-HE/releases) et créer un alias `saxon` dans votre `~/.zshrc` ou votre `~/.zprofile` :

   ```sh
   alias saxon='java -jar /chemin/vers/saxon-he-12.3.jar'
   ```

   La chaîne a été testée avec Saxon HE 12.3. Homebrew installe une version plus récente (`brew install saxon`, Saxon 13), qui n’a pas été testée.

3. **XSpec** (outil de test des feuilles XSLT et des Schematron) : fournit aussi SchXslt2, le compilateur de Schematron utilisé pour le contrôle des fichiers. Le cloner dans `~/xspec`, chemin attendu par ces commandes, et se placer sur la version testée :

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

7. **oXygen** (facultatif, version 28 ou suivante) : le projet `nucma-texts.xpr` charge le framework NUCMA (`oxygen/frameworks/nucma/`), qui ajoute au framework TEI P5 l’autocomplétion des renvois et la navigation vers leur cible (voir « Autocomplétion et navigation des renvois dans oXygen »). À faire une seule fois :

   1. *Project › Open Project…* et ouvrir `nucma-texts.xpr` à la racine du dépôt ; travailler ensuite depuis ce projet.
   2. Dans *Options › Préferences › Association de type de document, sélectionner en bas du panneau « Options projet » ; puis dans le sous-menu Emplacement, ajouter dans « Répertoire additionnel des frameworks » `${pd}/oxygen/frameworks` (`${pd}` : chemin du dossier du projet ; `${pdu}`, son URL, n’est pas reconnu dans ce champ).
   3. Redémarrer oXygen, puis vérifier que **NUCMA** figure dans la liste de l’association de type de document et rouvrir les documents déjà ouverts. oXygen compile lui-même le script du framework (`oxygen/frameworks/nucma/nucma.exf`) : il n’y a rien à produire.

   Le projet déclare aussi `fr/_corpus.xml` et `en/_corpus.xml` comme fichiers principaux (*Main Files*, en tête de la vue *Project*) : c’est dans les fichiers qu’ils incluent qu’oXygen cherche la cible d’un renvoi.

   Le framework s’applique ensuite à tous les fichiers TEI `.xml` ouverts dans le projet. Pour l’utiliser depuis un autre projet oXygen, y ajouter à l’étape 2 le chemin du dossier `oxygen/frameworks` de ce dépôt.

## Importation des entrées

Toutes les commandes se lancent depuis la racine de ce dépôt. Chaque étape devrait faire l’objet de son propre commit sur une branche dédiée.

### 1. Import depuis MS Word (`nucma-profile`, installé à l’étape 5 de « Installation »).

Le document MS Word doit commencer par le bloc d’en-tête : titre de l’entrée, titre court, auteurs (documenté dans `README` de nucma-profile, « En-tête »).

Créer une **branche pour l’importation** du texte

```sh
git co -b import/titre-court-article
```

**Convertir le document** avec la recette Make

```sh
make import LANGUAGE=fr CHAPTER=acquisition DOCX=~/chemin/vers/Variabilite.docx
```

La langue, le chapitre et le chemin du document sont obligatoires. Le fichier est rangé dans `<langue>/<chapitre>/`, sous le titre court du document, sans majuscule ni diacritique (`Variabilité` → `fr/acquisition/variabilite.xml`) ; L’option `NAME=…` permet de fournir un autre nom qui est également utilisé pour l’identifiant de l’entrée (`sourceDesc/@xml:id`). La commande s’arrête si la langue du bloc d’en-tête n’est pas celle annoncée, ou si le fichier existe déjà à moins d’avoir l’option `FORCE=yes` ; elle signale les `@todo` à traiter et donne l’inclusion à ajouter au `_corpus.xml` du chapitre.

Sans make, la commande équivalente est :

```sh
NUCMA_AUTHORS=file://$PWD/meta/authors.xml NUCMA_CHAPTER=acquisition docxtotei --profile=nucma ~/chemin/vers/Variabilite.docx fr/acquisition/variabilite.xml
```

`NUCMA_AUTHORS` indique au profil où trouver `meta/authors.xml`, pour donner à chaque auteur son `@ref` et ses identifiants ; `NUCMA_CHAPTER` donne le chapitre de l’identifiant de l’entrée. Les autres variables sont décrites dans le README de nucma-profile (« Importer un texte »).

Le fichier produit est nettoyé, son en-tête est rempli, et il est associé à `nucma-text.rng` et à `nucma-quality.sch`. 

### 2. Structuration dans oXygen des éléments manquants : 

Ensuite :

- chercher les `<!-- @todo -->` : un auteur absent de `meta/authors.xml` a été découpé au jugé (dernier mot pris comme nom de famille) ; l’ajouter au référentiel ou corriger l’entrée ;

- relire l’en-tête `<teiHeader>` (titre, auteurs, contributeurs) ;

- vérifier que le code de langue est bien présent sur `<text>`

- Contrôle de la macro-structure du texte : `<front>`, `<body>`, `<back>`, `<div>`, notes et bibliographie

- ajouter l’entrée au `_corpus.xml` du chapitre :

  ```xml
  <xi:include href="./variabilite.xml" parse="xml">
     <xi:fallback xml:lang="fr">Fichier non trouvé / File not found</xi:fallback>
  </xi:include>
  ```

- Encodage des contenus éditoriaux : `<soCalled>`, `<title>`, liens internes `<ref>`, externes, renvois.
- Traitement des références bibliographiques `<bibl>`
- Marquage des personnes, des œuvres, des expositions et des institutions , `<persName>`, `<orgName>`, `<placeName>`
- Saisie des index dans `meta/`
- Insertion des contenus éditoriaux
- Validation du fichier
- Faire un commit. 

### 3. Normalisation (`typesetter`) :

```sh
f=fr/acquisition/coacquisition.xml
make normalize TARGET=$f
git diff --word-diff $f
```

Le diff ne doit montrer que des corrections typographiques. Commit.

### 4. Contrôle typographique (typesetter) :

```sh
make typography TARGET=$f
```

(voir ci-dessous). Corriger ce qui doit l’être, compléter le balisage suggéré. Commit.

### 5. Contrôle de l’encodage

`make validate TARGET=$f` et `make quality TARGET=$f`, validation par `nucma-text.rng` et `nucma-quality.sch` (voir « Schémas » et « Contrôle de l’encodage »). Commit.

Pour un fichier déjà importé autrement que par le profil, ou modifié à la main depuis, passer d’abord par la sérialisation et le nettoyage (voir ci-dessous).

## Nettoyer et normaliser des entrées (`typesetter`)

Les trois étapes de typesetter se lancent depuis la racine de ce dépôt, chacune suivie d’une relecture du diff et d’un commit :

```sh
f=fr/acquisition/coacquisition.xml
make serialize TARGET=$f   # 1. remet sur une ligne les balises coupées par un éditeur XML ; contenu inchangé
make cleanup TARGET=$f     # 2. nettoie les artefacts de Word (déjà fait par le profil à l’import)
make normalize TARGET=$f   # 3. normalisation Unicode et typographique ; journal dans logs/
git diff --word-diff $f    # 4. relire, puis commit, avant l’étape suivante
```

Elles transforment les fichiers sur place. Pour éviter les accidents :

- `TARGET` (un fichier ou un dossier) est obligatoire ;
- seules les entrées de `fr/` et `en/` sont traitées, pas les `_corpus.xml` ni les référentiels de `meta/` ;
- un fichier qui a des modifications non commitées est laissé de côté, pour que le diff ne montre que l’effet de l’étape (`FORCE=yes` le traite quand même) ;
- en cas d’échec de la feuille, le fichier n’est pas modifié.

Le nettoyage d’un fichier déjà importé reste utile : il remplace par des espaces ordinaires les espaces insécables laissés par des guillemets remplacés à la main par `q` ou `soCalled`.

| Option | Étape | Effet |
|---|---|---|
| `FORCE=yes` | toutes | traite aussi les fichiers qui ont des modifications non commitées |
| `BIBLIOGRAPHY=yes` | normalize | traite aussi la bibliographie, exclue par défaut |
| `DEFAULT_LANG=fr` | normalize | langue d’un fichier rangé hors de `fr/` ou `en/` |
| `DETAIL=yes` | normalize | journal détaillé : chaque segment modifié, avant et après |

#### Relire les changements entre deux étapes

Chaque étape part d’un fichier commité : le diff montre donc exactement ce qu’elle a changé.

```sh
git diff --stat $f                 # combien de lignes ont changé
git diff --word-diff $f            # le détail, mot à mot : [-avant-]{+après+}
git diff --word-diff=color $f      # le même, en couleur (rouge : retiré, vert : ajouté)
```

Beaucoup de corrections portent sur des espaces insécables, invisibles dans le diff : la ligne avant et la ligne après paraissent identiques. Pour les voir, remplacer l’espace insécable par `⍽` et l’espace fine insécable par `⸱` à l’affichage (le fichier n’est pas modifié) :

```sh
git diff --word-diff $f | perl -CSD -pe 's/\x{00A0}/\x{237D}/g; s/\x{202F}/\x{2E31}/g'
```

Le journal de la normalisation (`logs/`, ou affiché dans le terminal) compte les changements par règle ; avec `DETAIL=yes`, il donne chaque segment modifié, avant et après, ce qui aide à comprendre un changement inattendu.

Puis, selon la relecture :

| Décision | Commande |
|---|---|
| tout garder | `git commit -m "normalisation de coacquisition" $f` (un message par étape ; seul `$f` est commité) |
| tout annuler | `git restore $f` : le fichier revient au dernier commit |
| garder une partie | `git add -p $f` (pour chaque bloc : `y` garder, `n` écarter, `s` découper), puis `git commit`, puis `git restore $f` pour abandonner le reste |
| corriger à la main | modifier le fichier, puis `git commit -m "…" $f` |

Un changement qu’on écarte à chaque passage (faux positif) est à signaler dans typesetter plutôt qu’à corriger dans le texte : la règle doit être affinée, ou le passage protégé par `rend="verbatim"`.

Dans VS Code, le panneau *Source Control* montre les mêmes changements côte à côte, et permet de garder ou d’annuler un bloc (*Stage Selected Ranges*, *Revert Selected Ranges*). Une fois le commit fait, `git log -p --word-diff $f` retrace les étapes successives d’un fichier.

### Lancer les contrôles avec make

Les trois contrôles se lancent depuis la racine de ce dépôt :

```sh
make validate     # validation par les schémas RelaxNG (Jing)
make quality      # contrôle de l’encodage (schemas/nucma-quality.sch)
make typography   # contrôle typographique (typography.sch de typesetter)
make check        # les trois à la suite
make help         # liste des recettes et des options (aussi : make sans argument)
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
    ├── odd/nucma-text.odd          entrées (fr/, en/) et _corpus.xml   → schemas/nucma-text.rng
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

- **en-tête** : collection (`seriesStmt`), identifiant de l’entrée et lien vers sa version dans l’autre langue (`sourceDesc/@xml:id`, `@corresp`), responsable d’une révision (`change/@who`, seul admis), type des titres de l’en-tête (`title/@type` : `main` ou `sub`, règle Schematron intégrée au schéma) ;
- **identifiants** : types d’`idno` en liste fermée et en minuscules (`orcid`, `isni`, `viaf`, `wikidata`, `bnf`, `loc`, `ulan`, `zkm`, `artblocks`, `artefact`, `doi`, `isbn`, `issn`, `uri`, `url`, `callNumber`) ;
- **noms** : renvoi aux référentiels par `@ref` sur `persName`, `orgName`, `placeName`, `objectName`, `author` et `bibl` ; fonction (`roleName`) ;
- **rendu** : `hi/@rend` en liste fermée de valeurs combinables (`italic`, `bold`, `sup`, `sub`, `smallcaps`, `allcaps`, `strikethrough`, `underline`, `verbatim` ; le profil d’import convertit `superscript` et `subscript` des TEI Stylesheets en `sup` et `sub`), `rend="verbatim"` sur tout élément (passage à garder tel quel) ;
- **phrase** : `abbr` (`type="acronym"`), `emph`, `foreign`, `q`, `soCalled`, `title` ;
- **dates** : formes ISO 8601 du W3C (`2026`, `2026-10`, `2026-10-16`…) sur `@when`, sur `date/@from` et `date/@to` (texte libre dans Commons Publishing), et sur `@notBefore` et `@notAfter`, rétablis pour les dates approximatives ;
- **listes retirées** : `TEI/@change` (valeurs `commons_*`) et `text/@type`, propres à la chaîne Métopes.

Le schéma des entrées (`nucma-text.odd`) ajoute l’assemblage des chapitres (`teiCorpus`), les types de liens (`ref/@type` : `internal`, `external`, `crossref`, `note`, `figure`), les types de divisions (`div/@type` : `bibliography`, `notes`, `appendix`, `acknowledgments`), retire les types de notes de Métopes (`note/@type`) et rend obligatoires l’identifiant de l’entrée (`sourceDesc/@xml:id`), la langue du texte (`text/@xml:lang`) et au moins un auteur avec `@ref`.

Les schémas des référentiels ajoutent leurs listes d’entités (personnes et organismes, lieux, œuvres, expositions, bibliographie structurée). Ce sont des **premières versions souples** : les éléments nécessaires sont admis, sans ordre imposé ; leur structure sera resserrée ensuite. Les exigences propres aux auteurs (ORCID, affiliation) restent contrôlées par le Schematron d’encodage.

**Règle de maintenance** : un schéma ne s’élargit que pour un besoin du projet, jamais pour faire valider une donnée fautive. Une erreur de validation sur une donnée (type d’`idno` en capitales, attribut vide, `@xml:id` sur un `idno`…) se corrige dans la donnée.

### Générer les schémas et leur documentation

```sh
make schemas               # génère les schémas de schemas/ à partir des ODD
make documentation         # génère la documentation HTML dans documentation/
make clean-schemas         # supprime les schémas générés et l’étage commun compilé
make clean-documentation   # supprime documentation/
```

Les schémas générés (`schemas/nucma-text.rng`, `schemas/nucma-*.rng`) ne sont pas versionnés : **avant de valider, chacun génère les schémas avec `make schemas`**, et le refait après une mise à jour des ODD. `make` compile d’abord l’étage commun (`odd/nucma-common.compiled.odd`, fichier intermédiaire lui aussi non versionné), puis produit chaque schéma ; il ne régénère que ce qui a changé. Il faut les TEI Stylesheets et le dépôt Commons Publishing (voir « Installation ») et une connexion à internet : les éléments repris de la TEI viennent de sa version 4.11.0, figée pour que la génération soit reproductible. Les chemins se changent par des variables : `make schemas TEI_STYLESHEETS=… COMMONS_PUBLISHING=…`.

La documentation HTML, dans `documentation/` (non versionné : chacun la régénère), comprend `nucma-common.html` pour les règles communes, puis une page par schéma. Elle présente la prose de chaque ODD et la référence de ses éléments et attributs : c’est le guide d’encodage du projet.

Après une modification d’un ODD : `make schemas`, puis valider les fichiers concernés.

### Valider

**Dans oXygen**, la validation est automatique grâce aux instructions `xml-model`, une fois les schémas générés (`make schemas`). Les fichiers `_corpus.xml` assemblent les entrées par `xi:include` : oXygen résout les inclusions avant de valider.

**En ligne de commande** : `make validate` (voir « Lancer les contrôles avec make »), ou directement avec [Jing](https://relaxng.org/jclark/jing.html) (`brew install jing-trang`) :

```sh
jing schemas/nucma-text.rng fr/acquisition/variabilite.xml
jing schemas/nucma-persons.rng meta/authors.xml meta/names.xml
xmllint --xinclude fr/acquisition/_corpus.xml > /tmp/corpus.xml && jing schemas/nucma-text.rng /tmp/corpus.xml
```

Jing ne résout pas les `xi:include` : pour un fichier `_corpus.xml`, les développer d’abord avec `xmllint --xinclude`.

### Autocomplétion et navigation des renvois dans oXygen

Le projet `nucma-texts.xpr` charge le framework `oxygen/frameworks/nucma/`, qui étend le framework TEI P5. Dans les fichiers `.xml`, Ctrl+Espace sur un `@ref` ou un `@target` propose les identifiants du bon référentiel, avec leur libellé :

| Élément | Propositions |
|---|---|
| `persName`, `author` | personnes (`meta/authors.xml`, `meta/names.xml`) |
| `orgName` | organismes (`meta/names.xml`) |
| `placeName` | lieux (`meta/places.xml`) |
| `objectName` | œuvres (`meta/artworks.xml`) |
| `title` | expositions (`meta/exhibitions.xml`) |
| `bibl` | références (`meta/bibliography.xml`) |
| `ref`, `ptr` | `type="figure"` : figures (`meta/medias.xml`) ; `type="internal"` ou `"crossref"` : identifiants des entrées de la langue ; sans type : les deux |

Les valeurs viennent des fichiers déclarés dans `fr/_corpus.xml` ou `en/_corpus.xml` (selon le dossier du fichier), dont les `xi:include` sont suivis ; à défaut, de `meta/`. Elles sont relues à chaque appel : un ajout enregistré dans un référentiel est proposé aussitôt.

**Navigation.** Cmd+clic (Ctrl+clic hors macOS) sur un renvoi `#identifiant` mène à sa cible, dans le document, dans une autre entrée ou dans un référentiel de `meta/` ; *Search Declarations* (menu contextuel) fait de même. oXygen cherche la cible dans les fichiers inclus par les fichiers principaux du projet (`fr/_corpus.xml`, `en/_corpus.xml`) : une entrée ou un référentiel absent du corpus n’est pas atteint. Le framework TEI ne suit que `@target` ; l’extension Java du framework NUCMA (`oxygen/frameworks/nucma/nucma.jar`) traite de la même façon `@ref`, `@corresp` et `@who`.

oXygen compile au démarrage le script du framework, `oxygen/frameworks/nucma/nucma.exf` : une modification du script est prise en compte au redémarrage ; celles de `resources/cc_config.xml` et `resources/ref-values.xsl`, au redémarrage ou par *Refresh* (F5).

L’extension Java (sources dans `oxygen/java/`) est versionnée compilée : il n’y a rien à faire pour l’utiliser. Après une modification des sources ou une mise à jour majeure d’oXygen, la recompiler depuis la racine du dépôt avec `make oxygen-jar` (JDK 17 ou suivant ; `OXYGEN=…` si oXygen n’est pas dans `/Applications/Oxygen XML Editor`), puis redémarrer oXygen. La recette exécute :

```sh
OXYGEN="/Applications/Oxygen XML Editor"
javac --release 17 -d build/oxygen-classes -cp "$OXYGEN/lib/oxygen.jar:$OXYGEN/lib/oxygen-annotations.jar:$OXYGEN/frameworks/tei/tei.jar" oxygen/java/src/ca/nucma/oxygen/*.java
jar --create --file oxygen/frameworks/nucma/nucma.jar -C build/oxygen-classes .
```

L’extension hérite de la classe du framework TEI d’oXygen (`TEIP5ExtensionsBundle`), qu’oXygen marque comme interne : une mise à jour majeure peut demander de l’adapter.

## Contrôle de l’encodage (Schematron)

`schemas/nucma-quality.sch` complète la validation par le schéma (`nucma-text.rng`) : il vérifie ce qu’une grammaire ne peut pas vérifier. Ses messages sont de deux niveaux : **erreur** (encodage incohérent, à corriger) et **avertissement** (information manquante ou forme à harmoniser).

Contrôles actuels :

| Où | Contrôle | Niveau |
|---|---|---|
| Entrées | chaque `author` a un `@ref` qui renvoie à une personne de `meta/authors.xml` | erreur |
| Entrées | chaque `respStmt` a un `resp` et un `@ref` valide (`@ref` absent : avertissement) | erreur |
| Entrées | l’auteur a un ORCID, dans l’entrée ou dans `meta/authors.xml` | avertissement |
| Entrées | l’ORCID de l’entrée est le même que celui de `meta/authors.xml` | erreur |
| Entrées | le prénom et le nom sont ceux de `meta/authors.xml` | avertissement |
| Entrées | `change/@who` renvoie à une personne connue | avertissement |
| Textes | chaque `@ref="#…"` d’une entité renvoie à une notice du bon référentiel : `persName` → personne de `meta/authors.xml` ou `meta/names.xml`, `orgName` → organisme de `meta/names.xml`, `placeName` → `meta/places.xml`, `objectName` → `meta/artworks.xml`, `title` → exposition, œuvre ou référence, `bibl` → `meta/bibliography.xml` (les URL, comme celles de Zotero, ne sont pas contrôlées) | erreur |
| Textes | chaque `ref/@target="#…"` renvoie à un `@xml:id` du document (sauf `type="crossref"`, qui vise une autre entrée ; pour `type="figure"`, aussi dans `meta/medias.xml`) | erreur |
| Textes | `ref type="note"` vise une `note` du document ; `type="figure"` une `figure` du document ou de `meta/medias.xml` ; `type="internal"` un `#identifiant` du document ; `type="external"` une URL `http(s)` | erreur |
| Textes | `ref type="internal"` qui vise une note ou une figure (employer `type="note"` ou `type="figure"`) | avertissement |
| `meta/authors.xml` | chaque personne a un `@xml:id` unique, un prénom et un nom ; homonymes signalés | erreur |
| `meta/authors.xml` | chaque personne a un ORCID | avertissement |
| `meta/authors.xml` | un même identifiant (ORCID, ISNI…) n’est pas attribué à plusieurs personnes | erreur |
| `meta/authors.xml` | identifiants vides, sans type ou de type inconnu (`insi` pour `isni`…) | avertissement |
| Partout | ORCID valide (forme et chiffre de contrôle), écrit sous forme d’URL `https://orcid.org/…`, `type="orcid"` en minuscules ; ISNI de la forme `https://isni.org/isni/…` | erreur / avertissement |

`meta/authors.xml` est retrouvé à partir de l’emplacement du fichier contrôlé (dossier `fr/`, `en/` ou `meta/` du dépôt).

**Dans oXygen** : *Document › Validate › Validate with…* et choisir `schemas/nucma-quality.sch` ; les messages apparaissent dans le panneau des résultats et sont reliés à l’endroit concerné. On peut aussi l’associer durablement aux fichiers par une instruction de traitement, à côté de celle de `nucma-text.rng` :

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
