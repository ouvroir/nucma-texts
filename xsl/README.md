# Feuilles XSLT de NUCMA

Ce dossier contient la chaîne de traitement des textes TEI de l’Encyclopédie : import depuis Word, nettoyage, normalisation typographique.

| Fichier | Rôle |
|---|---|
| `profile/docx/from.xsl` | Profil `nucma` des TEI Stylesheets : conversion d’un `.docx` en TEI, nettoyage des artefacts de Word et sortie indentée. |
| `nettoyage-import.xsl` | Même nettoyage, pour un fichier TEI déjà importé. |
| `serialisation.xsl` | Copie à l’identique : sérialise un fichier comme le font les autres feuilles, sans en modifier le contenu. |
| `normalisation.xsl` | Normalisation Unicode (NFC) et typographie française et anglaise. |

Chaque feuille est documentée en détail dans son en-tête (`xd:doc`, format de documentation d’oXygen).

## Prérequis

- **Saxon 12** (l’alias `saxon` lance `java -jar …/saxon-he-12.3.jar`).
- **TEI Stylesheets** installées avec Ant et disponibles dans le PATH (cf. https://github.com/teic/stylesheets)

- Déclarer le profile par un lien symbolique dans vos XSL Stylesheets :

  ```sh
  ln -s /path/to/nucma-textes/xsl/profile /path/to/TEIC/Stylesheets/profiles/nucma
  ```

  Le profil doit être appelé par ce lien : `from.xsl` importe `../../../docx/from/docxtotei.xsl`, chemin relatif aux Stylesheets.

## Importer un nouveau texte

1. **Conversion et nettoyage** :

   ```sh
   docxtotei --profile=nucma Variabilite.docx variabilite.xml
   ```

   Le TEI produit est déjà nettoyé et indenté.

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

### Nettoyage de l’import (`from.xsl`, `nettoyage-import.xsl`)

- Retrait des propriétés `font-family` et `font-size` des `@style`.
- Déballage des `<hi>` sans rendu ou ne contenant que des espaces.
- Suppression de `@xml:space="preserve"`.
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

## Bonnes pratiques

- **Baliser la langue** : un titre anglais dans un texte français doit porter `xml:lang="en"` (`<title xml:lang="en">`), sans quoi il reçoit la typographie française (« Modern Art : Who Cares ? »).
- **Relire le diff** : les règles évitent les faux positifs connus (« Vers », « Louis XIV », `3D`, dates ISO, ISBN…), mais quelques cas restent ambigus : « 514-987 » est pris pour un intervalle, « p. 12 345 » pour un nombre, `3d printing` deviendrait « 3rd printing ».
- **Les feuilles sont idempotentes** : les relancer sur un fichier déjà traité ne change rien.

## Maintenance

- Les règles de nettoyage existent en deux exemplaires, dans `profile/docx/from.xsl` et dans `nettoyage-import.xsl`. Toute modification doit être faite dans les deux.
- `serialisation.xsl`, `nettoyage-import.xsl` et `normalisation.xsl` partagent la même sérialisation (`indent="no"`, prologue restitué ligne par ligne). Si l’une change, les autres doivent suivre, sans quoi les diffs mélangeront mise en forme et contenu.
- Après toute modification, vérifier que la sortie est inchangée sur des fichiers de référence et que la feuille reste idempotente (un second passage ne change rien).
