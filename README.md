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

├── schemas/
│   ├── odd
│   └── ...
├── LICENCE
└── README.md
```

## Outils et chaîne de traitement

Les textes sont produits et contrôlés avec des outils rangés dans deux dépôts distincts, chacun documenté dans son propre README :

| Dépôt | Rôle |
|---|---|
| [nucma-profile](https://github.com/ouvroir/nucma-profile) | Profil `nucma` des TEI Stylesheets : conversion des entrées Word en TEI, en-tête rempli, nettoyage des artefacts de Word. |
| [typesetter](https://codeberg.org/Factoton/typesetter) | Normalisation Unicode et typographique (`src/normalization.xsl`), nettoyage d’un TEI déjà importé, sérialisation, contrôle typographique (`schematron/typography.sch`). |

Ce dépôt-ci contient les textes, les référentiels (`meta/`) et les schémas propres à l’encyclopédie (`schemas/` : `nucma.rng`, `nucma-quality.sch`).

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

5. **Pour importer des textes depuis MS Word seulement** : les [TEI Stylesheets](https://github.com/TEIC/Stylesheets) et Ant (`brew install ant`), puis le profil déclaré par un lien symbolique ; voir le README de nucma-profile :

   ```sh
   git clone https://github.com/TEIC/Stylesheets.git ~/TEIC/Stylesheets
   export PATH=~/TEIC/Stylesheets/bin:$PATH
   ln -s ~/ouvroir/nucma-profile ~/TEIC/Stylesheets/profiles/nucma
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
4. **Contrôle typographique** (typesetter) : voir ci-dessous. Corriger ce qui doit l’être, compléter le balisage suggéré. Commit.
5. **Contrôle de l’encodage** : validation par `nucma.rng` et `nucma-quality.sch` (voir « Contrôle de l’encodage »). Commit.

Pour un fichier déjà importé autrement que par le profil, les étapes de sérialisation et de nettoyage sont décrites dans le README de typesetter (« Utilisation »).

### Contrôle typographique

`$TYPESETTER/schematron/typography.sch` signale ce qui contrevient aux règles typographiques de la langue de chaque passage (Imprimerie nationale pour le français, Chicago Manual of Style pour l’anglais), avec une consigne de correction, et suggère le balisage des passages entre guillemets ou en italique. Il ne modifie rien. Les messages terminés par « (auto) » signalent ce que la normalisation corrige d’elle-même. Le détail des règles, des listes et des paramètres est dans le README de typesetter (« Contrôle typographique »).

**Dans oXygen** : ouvrir l’entrée, *Document › Validate › Validate with…*, choisir `typography.sch` dans le dossier `schematron/` de typesetter. La boîte de dialogue permet de choisir une phase pour ne contrôler qu’un thème (`punctuation`, `quotes`, `capitals`, `persons`, `markup`…). Les messages sont reliés à l’endroit concerné ; leur icône distingue les erreurs, les avertissements et les informations.

Pour associer durablement le schéma à une entrée, on peut ajouter une instruction en tête de fichier ; le chemin dépend de l’emplacement de typesetter sur le poste (ici depuis `fr/acquisition/`, avec typesetter dans `~/factoton/`) :

```xml
<?xml-model href="../../../../factoton/typesetter/schematron/typography.sch" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"?>
```

**En ligne de commande** : compiler le schéma une fois, et après toute mise à jour de typesetter, puis contrôler les entrées.

```sh
saxon -s:$TYPESETTER/schematron/typography.sch -xsl:$HOME/xspec/lib/schxslt2/transpile.xsl -o:/tmp/typography.xsl

for f in fr/acquisition/*.xml; do
  saxon -s:$f -xsl:/tmp/typography.xsl -o:/tmp/typo.svrl && saxon -s:/tmp/typo.svrl -xsl:$TYPESETTER/schematron/svrl-report.xsl document=$f
done
```

Le rapport donne pour chaque message le niveau, la règle, l’emplacement (`body/div[2]/p[3]`), la consigne et un extrait. Options utiles :

- `level=warning` à la fin de la seconde commande : masque les informations (suggestions de balisage, espaces multiples) ;
- `'?check-bibliography=true()'` à la fin de la première commande `saxon -s:$f …` : contrôle aussi la bibliographie, exclue par défaut ;
- `'{http://dmaus.name/ns/2023/schxslt}phase=markup'` à la fin de la compilation : un seul thème.

La langue de chaque passage vient de son `xml:lang` ; à défaut, de `text/@xml:lang` (posé par le profil d’import), de `langUsage`, puis du dossier `fr/` ou `en/` du fichier ; c’est la même règle que pour la normalisation. Pour contrôler une copie rangée ailleurs (une version normalisée dans `/tmp`, par exemple), ajouter `default-lang=fr` ou `default-lang=en`.

### Journaux de normalisation

La normalisation écrit son bilan sur la console et dans un journal, `logs/<entrée>-<date>.log`, à la racine de ce dépôt (un passage le même jour remplace le journal). Avec `report=detail`, le journal liste chaque modification, ce qui aide à relire le diff.

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

**En ligne de commande**, avec Saxon et SchXslt2 (voir « Installation ») : compiler le Schematron une fois (et après chaque modification), puis contrôler les fichiers depuis la racine du dépôt ; `schemas/svrl-text.xsl` met le rapport en forme.

```sh
saxon -s:schemas/nucma-quality.sch -xsl:$HOME/xspec/lib/schxslt2/transpile.xsl -o:/tmp/nucma-quality.xsl

for f in meta/authors.xml fr/acquisition/*.xml; do
  saxon -s:$f -xsl:/tmp/nucma-quality.xsl -o:/tmp/rapport.svrl && saxon -s:/tmp/rapport.svrl -xsl:schemas/svrl-text.xsl document=$f
done
```
