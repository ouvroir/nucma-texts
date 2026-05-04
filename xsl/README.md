# Feuilles XSLT de NUCMA

Ce dossier contient la chaîne de traitement des textes TEI de l’Encyclopédie : import depuis Word, nettoyage, normalisation typographique.

| Fichier | Rôle |
|---|---|
| `profile/docx/from.xsl` | Profil `nucma` des TEI Stylesheets : conversion d’un `.docx` en TEI, en-tête rempli à partir du document, nettoyage des artefacts de Word et sortie indentée. |
| `nettoyage-import.xsl` | Même nettoyage, pour un fichier TEI déjà importé. |
| `serialisation.xsl` | Copie à l’identique : sérialise un fichier comme le font les autres feuilles, sans en modifier le contenu. |
| `normalisation.xsl` | Normalisation Unicode (NFC) et typographie française et anglaise. |
| `tests/` | Tests XSpec des feuilles (voir « Tests »). |

Chaque feuille est documentée en détail dans son en-tête (`xd:doc`, format de documentation d’oXygen).

## Prérequis

- **Saxon 12** (l’alias `saxon` lance `java -jar …/saxon-he-12.3.jar`).
- **TEI Stylesheets** installées avec Ant et disponibles dans le PATH (cf. https://github.com/teic/stylesheets)

- Déclarer le profile par un lien symbolique dans vos XSL Stylesheets :

  ```sh
  ln -s /path/to/nucma-textes/xsl/profile /path/to/TEIC/Stylesheets/profiles/nucma
  ```

  Le profil doit être appelé par ce lien : `from.xsl` importe `../../../docx/from/docxtotei.xsl`, chemin relatif aux Stylesheets.

- Le profil lit `meta/authors.xml` au chemin indiqué par le paramètre `nucma-authors` de `from.xsl` (chemin du dépôt sur le poste d’Emmanuel Château-Dutier). Sur un autre poste, modifier ce chemin ou le donner par une variable d’environnement :

  ```sh
  NUCMA_AUTHORS=file:///chemin/vers/nucma-textes/meta/authors.xml docxtotei --profile=nucma Entree.docx entree.xml
  ```

## Importer un nouveau texte

1. **Conversion et nettoyage** :

   ```sh
   docxtotei --profile=nucma Variabilite.docx variabilite.xml
   ```

   Le TEI produit est déjà nettoyé et indenté, et son en-tête est rempli (titre, auteurs, identifiant). Le chapitre de l’identifiant vaut `acquisition` par défaut ; pour un autre chapitre :

   ```sh
   NUCMA_CHAPTER=mediation docxtotei --profile=nucma Entree.docx entree.xml
   ```

   La conversion est notée dans `revisionDesc` (`<change when="…" resp="#ECD">Conversion depuis Word (profil nucma)</change>`). La personne responsable vaut `ECD` par défaut ; pour une autre : `NUCMA_RESP=RC docxtotei --profile=nucma …`.

2. **Structuration manuelle** dans oXygen (en-tête, `div`, `q`, `soCalled`, `bibl`…). Commiter.

3. **Normalisation** :

   ```sh
   saxon -s:variabilite.xml -xsl:xsl/normalisation.xsl -o:variabilite.tmp && mv variabilite.tmp variabilite.xml
   ```
4. Consulter le diff

   ```sh
   git diff --stat
   git diff --word-diff
   ```

   le diff ne montre que les corrections typographiques.

5. Commiter

## Normaliser des fichiers existants

Pour un fichier déjà importé et mis en forme par oXygen, on sépare chaque étape dans son propre commit, pour que les diffs restent lisibles :

```sh
# 1. sérialisation seule : remet sur une ligne les balises qu’oXygen coupe ; contenu inchangé
for f in fr/acquisition/{coacquisition,protocoles,variabilite}.xml; do saxon -s:$f -xsl:xsl/serialisation.xsl -o:$f.tmp && mv $f.tmp $f; done
# commit

# 2. nettoyage des artefacts de l’import (inutile si le fichier vient du profil nucma)
for f in fr/acquisition/{coacquisition,protocoles,variabilite}.xml; do saxon -s:$f -xsl:xsl/nettoyage-import.xsl -o:$f.tmp && mv $f.tmp $f; done
# commit

# 3. normalisation typographique
for f in fr/acquisition/{coacquisition,protocoles,variabilite}.xml; do saxon -s:$f -xsl:xsl/normalisation.xsl -o:$f.tmp && mv $f.tmp $f; done
# commit
```

Il faut toujours écrire dans un fichier temporaire (`-o:$f.tmp`), jamais dans le fichier lu. `git diff --word-diff` rend les corrections plus visibles.

## Ce que font les feuilles

### En-tête (`from.xsl` seulement)

Le profil lit le bloc d’en-tête écrit au début du document Word, en français ou en anglais, le retire du texte et remplit le `teiHeader` :

```text
Titre de l’entrée :                        Entry Title:
Négocier la variabilité                    Collections in Shared Ownership
Titre court : Variabilité                  Short Title: Co-acquisition
Auteur·rices :                             Authors:
• Anne Bénichou, professeure, UQAM         • Jessica Minier, PhD Candidate, UQO
```

- **Titre** : un seul `<title>` sans `@type` ; s’il est suivi d’un sous-titre, `<title type="main">` et `<title type="sub">`.
- **Titre court** : il sert de nom de fichier et d’identifiant de l’entrée, sans majuscule ni diacritique, sur `sourceDesc` : `<sourceDesc xml:id="nucma.fr.acquisition.variabilite">`. La langue vient des étiquettes (`fr` ou `en`), le chapitre de `NUCMA_CHAPTER`.
- **Auteurs** : chaque ligne « Nom, rôle, affiliation » devient un `<author>` avec `persName`, `roleName` et `affiliation`. L’auteur est cherché dans `meta/authors.xml` : s’il y figure, il reçoit son `@ref` (`#benichouAnne`), son prénom et son nom tels qu’ils y sont découpés, et ses identifiants (ORCID, ISNI…). Sinon, le dernier mot du nom est pris comme nom de famille et un `<!-- @todo -->` demande de vérifier.
- **Contributeurs** : les personnes listées sous un sous-titre du bloc des auteurs (« Research Assistant: », « Assistante de recherche : ») ne sont pas des auteurs : elles deviennent des `<respStmt>` (`<resp>Research Assistant</resp>`, `persName` avec `roleName`, `orgName` pour l’affiliation), cherchées elles aussi dans `meta/authors.xml` (liste « Autres contributeurs »).
- Les puces tapées à la main (« ● Julie Bawin, … ») et les espaces insécables dans les étiquettes (« Titre⍽de l’entrée⍽: ») sont acceptées.
- **Reste de l’en-tête** : complété d’après le modèle des entrées du corpus, en français ou en anglais : `publicationStmt` (éditeur, année, licence CC BY 4.0, DOI à compléter), `seriesStmt` (« Chapitre Acquisition », en anglais « Chapter: Acquisition », titre de l’encyclopédie, URI), `sourceDesc` (« Fichier nativement numérique ») et `profileDesc/langUsage`. L’`editionStmt` vide produit par la conversion est supprimé.
- **Langue** : posée sur `<text xml:lang="fr">` (ou `en`) d’après les étiquettes ; `normalisation.xsl` applique ensuite la typographie de cette langue, quel que soit le dossier du fichier.

### Nettoyage de l’import (`from.xsl`, `nettoyage-import.xsl`)

- Retrait des propriétés `font-family` et `font-size` des `@style`.
- Déballage des `<hi>` sans rendu ou ne contenant que des espaces, et des `<seg>` ne contenant que des espaces.
- Suppression de `@xml:space="preserve"`.
- Commentaires de Word (`<note place="comment">`) remplacés par un commentaire XML au même endroit, juste après le passage commenté, avec l’auteur, la date et le passage cité ; les ancres `commentRangeStart` et `commentRangeEnd` sont supprimées :

  ```xml
  <!-- @todo Aux encodeur·euses : ne pas oublier de mettre ce lien [Josée Desforges, 2026-05-25, sur « la pièce chorégraphique Trio A »] -->
  ```
- Notes du texte (de bas de page, de fin…, sauf les commentaires) regroupées dans `<back>`, créé après `<body>` s’il n’existe pas, à l’intérieur d’une `<div type="notes">` placée en tête de `back`. Chaque note est remplacée dans le texte par un appel qui pointe vers elle, et reçoit un identifiant `note` suivi de son numéro sur deux chiffres (`note01`, `note02`…), qui remplace celui de Word (`ftn0`) ; les références à l’ancien identifiant sont mises à jour. Son contenu est placé dans un ou plusieurs paragraphes :

  ```xml
  <p>L’actualisation<ref type="note" target="#note01">1</ref> implique…</p>
  …
  <back>
    <div type="notes">
      <note place="foot" n="1" xml:id="note01"><p>Le terme « activation »…</p></note>
    </div>
  ```
- Suppression des ancres laissées par Word (signets, délimiteurs de commentaires) vers lesquelles aucun lien ne pointe, et des intertitres vides qu’elles occupaient (`<head><anchor xml:id="2z3fk6gdwmkd"/></head>`).
- `@type="external"` sur les hyperliens (`<ref target="https://…">`), sauf ceux qui pointent vers `nucma.ca` : ce sont des renvois entre entrées de l’encyclopédie, pas des liens externes.
- Suppression des attributs de mise en page de `<graphic>` (`@n`, `@width`, `@height`, `@rend`) : la taille et la position des images relèvent de la publication.
- Remplacement par une espace ordinaire de l’espace insécable que Word place à l’intérieur des guillemets, restée orpheline après leur conversion en `<q>`, `<soCalled>`, etc. (`<q>garde négociée</q>⍽est`).

### Normalisation (`normalisation.xsl`)

La langue de chaque passage est déterminée par l’`xml:lang` le plus proche. À défaut, elle est déduite de l’`xml:lang` de `<TEI>`, puis du dossier (`fr/` ou `en/`). Les autres langues (`lat`, `de`…) ne reçoivent que la normalisation NFC.

| | Français (Imprimerie nationale) | Anglais (Chicago) |
|---|---|---|
| Ponctuation haute | espace fine insécable avant `; ! ?`, insécable avant `:` | aucune espace |
| Guillemets | « » (espace insécable), puis “ ” | “ ”, puis ‘ ’ ; virgule et point à l’intérieur |
| Apostrophe | ’ | ’, ‘ ouvrant, ’60s |
| Tirets d’incise | mot – incise – suite | word—word |
| Intervalles | 1914–1918, p. 45–52 | idem |
| Nombres | 10 000 (U+202F), 50 %, 10 € | 10,000, 50%, €10 |
| Heures | 10 h 30 | 10:30, 10 a.m. |
| Ordinaux, siècles | 3<sup>e</sup>, xviii<sup>e</sup> siècle (petites capitales), n<sup>o</sup> | 3rd, 18th century |
| Divers | ligature œ, M. Dupont, t. II, 12 cm, …, […] | Mr. Smith, 12 cm, … |

**Parties épargnées** : identifiants et adresses (`idno`, `ptr`, `code`, `email`), URL, DOI et adresses électroniques dans le texte, attributs, commentaires. La bibliographie (`div[@type='bibliography']`) n’est normalisée qu’en NFC, sauf si l’on active `process-bibliography`.

**Paramètres** (à ajouter en fin de commande Saxon) :

```bash
saxon -s:$f -xsl:xsl/normalisation.xsl -o:$f.tmp '?process-bibliography=true()'
```

| Paramètre | Défaut | Effet |
|---|---|---|
| `'?process-bibliography=true()'` | non | normalise aussi la bibliographie |
| `'?fr-centuries-small-caps=false()'` | petites capitales | siècles en capitales (XVIII<sup>e</sup>) |
| `'?fr-guillemets-narrow-space=true()'` | espace insécable | espace fine insécable dans « » |
| `'?en-ordinals-superscript=true()'` | non | 18<sup>th</sup> |
| `'?en-centuries-in-words=true()'` | non | eighteenth century |
| `'?en-punctuation-inside-quotes=false()'` | usage américain | usage britannique : “hello”, |
| `'?default-lang="en"'` | déduite | impose la langue du document |
| `report=detail` / `report=none` | `summary` | rapport sur la console et dans le journal : bilan, bilan et chaque modification, ou rien |
| `log-dir=…` | `logs/` | dossier des journaux ; vide pour ne pas en écrire |

### Rapport

`normalisation.xsl` écrit sur la console (sortie d’erreur, jamais dans le fichier) un bilan par fichier, et des avertissements sur ce qui demande une relecture :

```text
[normalisation] coacquisition.xml (langue par défaut : fr)
[normalisation]   NFC : 0 nœud(s) recomposé(s)
[normalisation]   exposants d’ordinaux intégrés au texte : 2
[normalisation]   segments de texte : 401 traités, 13 modifiés
[normalisation]     apostrophes 2 · abréviations 0 · nombres 0 · ponctuation 2 · guillemets 0 · ligatures 0 · espaces 7 · ordinaux 3
[normalisation]   avertissement : guillemets non équilibrés dans l’élément p : « Il dit "bonjour sans fermer.… »
```

Avec `report=detail`, chaque modification est affichée (`espaces : « …variés : parfois… » → « …variés⍽: parfois… »`) ; avec `report=none`, rien. Attention : ce paramètre est une chaîne, il s’écrit sans `?` (`report=detail`), contrairement aux paramètres booléens (`'?process-bibliography=true()'`).

**Journal** : les mêmes lignes sont écrites dans un fichier texte, un par fichier normalisé, dans le dossier `logs/` du dépôt : `logs/variabilite-2026-10-01.log` (nom du fichier et date ; un second passage le même jour remplace le journal). La première ligne indique l’heure et le chemin complet du fichier traité. Le journal suit le niveau de `report` (aucun avec `report=none`). Pour un autre dossier : `log-dir=/chemin/vers/logs` (chemin absolu, chemin relatif à la racine du dépôt, ou URI `file:///…`) ; pour ne pas écrire de journal : `log-dir=`.

## Tests

Le dossier `tests/` contient des tests XSpec :

| Fichier | Contenu |
|---|---|
| `tests/normalisation.xspec` | 101 vérifications : chaque règle typographique (français et anglais), ses pièges connus (« Vers », « Louis XIV », `3D`, dates ISO, ISBN…), son idempotence, et la portée de la normalisation sur des documents entiers (bibliographie, `idno`, liens, langue). |
| `tests/nettoyage-import.xspec` | 11 vérifications sur des documents qui reproduisent les artefacts de Word : styles, `hi` et `seg` vides, ancres, intertitres vides, liens, `graphic`, commentaires, notes. Elles décrivent aussi le comportement attendu du profil `nucma`, qui applique les mêmes règles. |
| `tests/docs/` | Documents de test. |

Installer XSpec une fois, puis lancer les tests :

```sh
git clone https://github.com/xspec/xspec.git ~/xspec
export SAXON_CP=/Library/Java/Extensions/SaxonHE12-3J/saxon-he-12.3.jar

~/xspec/bin/xspec.sh xsl/tests/normalisation.xspec
~/xspec/bin/xspec.sh xsl/tests/nettoyage-import.xspec
```

Chaque lancement se termine par un bilan, qui doit indiquer `failed: 0` :

```text
passed: 101 / pending: 0 / failed: 0 / total: 101
Report available at xsl/tests/xspec/normalisation-result.html
```

Le rapport HTML détaille chaque vérification, et montre pour un échec la valeur attendue et la valeur obtenue. Les rapports et les feuilles compilées sont écrits dans `xsl/tests/xspec/`, exclu de git par le `.gitignore` du dépôt. Les tests ont été validés avec XSpec 4.1.2 et Saxon HE 12.3.

Dans oXygen, ouvrir un fichier `.xspec` et lancer le scénario « Run XSpec Test ».

**Après toute modification d’une feuille, relancer les tests.** Si un changement de comportement est voulu, mettre à jour la valeur attendue du test concerné, et ajouter un test pour chaque nouvelle règle.

## Bonnes pratiques

- **Baliser la langue** : un titre anglais dans un texte français doit porter `xml:lang="en"` (`<title xml:lang="en">`), sans quoi il reçoit la typographie française (« Modern Art : Who Cares ? »).
- **Relire le diff** : les règles évitent les faux positifs connus (« Vers », « Louis XIV », `3D`, dates ISO, ISBN…), mais quelques cas restent ambigus : « 514-987 » est pris pour un intervalle, « p. 12 345 » pour un nombre, `3d printing` deviendrait « 3rd printing ».
- **Les feuilles sont idempotentes** : les relancer sur un fichier déjà traité ne change rien.

## Maintenance

- Les règles de nettoyage existent en deux exemplaires, dans `profile/docx/from.xsl` et dans `nettoyage-import.xsl`. Toute modification doit être faite dans les deux.
- `serialisation.xsl`, `nettoyage-import.xsl` et `normalisation.xsl` partagent la même sérialisation (`indent="no"`, prologue restitué ligne par ligne). Si l’une change, les autres doivent suivre, sans quoi les diffs mélangeront mise en forme et contenu.
- Après toute modification, relancer les tests XSpec (voir « Tests »).
