# Diagnostic de la normalisation

Diagnostic de `normalization.xsl` réalisé le 2026-10-04, par sondage de cas pièges : catalogage muséal, références, artefacts de saisie, langues mêlées, frontières entre éléments. Les cas ont été traités par la feuille sans modifier le corpus.

**Bilan :** la feuille est sûre sur la prose française courante. Le risque principal concernait les **identifiants** (numéros d’inventaire, ISSN, articles de loi), qu’une règle pouvait altérer sans le signaler.

État des actions : ✅ fait · ⬜ à faire.

## 1. Ce qui fonctionne

- **Idempotence :** un second passage ne change rien.
- **Ponctuation de part et d’autre d’un élément :** `<hi>mot</hi>:`, `<ref>lien</ref>?`.
- **Changement de langue :** `foreign xml:lang="en"` reçoit la typographie anglaise ; les autres langues ne reçoivent que la normalisation NFC.
- **Parties épargnées :** URL, courriels, DOI, `code`, `idno`.
- **Faux positifs évités :** dates ISO, ISBN complets, noms propres (Goethe, Roeder, Moeller, Phoebe).
- **Avertissement** en cas de guillemets non équilibrés.

## 2. Risques constatés

### A. Corruption de données (grave)

| Entrée | Sortie avant correction | Problème | État |
|---|---|---|---|
| `inv. 1953-12`, `n° d’inventaire 2005-3` | `1953–12`, `2005–3` | lu comme un intervalle | ✅ |
| `ISSN 0035-2950` | `0035–2950` | identifiant altéré | ✅ |
| `art. L. 122-5` | `122–5` | numéro d’article altéré | ✅ |
| `12.345` (inventaire), `1.500` | `12 345`, `1 500` | point lu comme séparateur de milliers | ⬜ |
| *(en)* `a 3d printer`, `5e edition` | `3rd printer`, `5th edition` | « 3D » devient un ordinal | ⬜ |
| `'bonjour'` | `'bonjour’` | paire de guillemets simples convertie à moitié | ✅ |
| *(en)* `'s-Hertogenbosch`, `rock 'n' roll` | `‘s-…`, `‘n’` | une élision devient un guillemet ouvrant | ✅ |

Ces altérations étaient silencieuses : le rapport les comptait comme des corrections réussies.

### B. Faux positifs typographiques

- **Titre anglais non balisé dans un texte français :** il reçoit la typographie française (`<title>The Museum of the Future : A Reader</title>`). Ce cas est fréquent dans les bibliographies d’auteurs.
- **Citations de sources anciennes :** elles sont modernisées (œ, apostrophes), alors qu’une édition savante peut vouloir conserver leur forme diplomatique.
- **`teiHeader` :** il est normalisé lui aussi. C’est sans conséquence aujourd’hui, mais cela n’a pas été validé délibérément.

### C. Lacunes : défauts laissés en place sans signalement

- **Capitales non accentuées :** *Ecole, Etat, A propos*. L’Imprimerie nationale exige l’accent, mais une correction automatique serait risquée.
- **Espaces fautives :** doubles espaces, espace avant une virgule, `( entre parenthèses )`, `mot ,virgule`.
- **Caractères invisibles hérités de Word :** trait d’union conditionnel (U+00AD), espace sans chasse (U+200B).
- **Appels de note en exposant Unicode :** `.¹`.
- **Ponctuation doublée :** `..`, `etc..`.
- **Espaces insécables manquantes** après *c.*, *ca*, *§*, *éd.*, devant *J.-C.* et dans *3,5 millions*.
- **Formes non corrigées :** `120 x 80 cm` (au lieu de ×), *2nde* (au lieu de *2de*).
- **Intervalles coupés par des éléments :** `<date>1914</date>-<date>1918</date>`, `XVIIe-XVIIIe`.
- **Guillemets de second niveau :** un `«` imbriqué à côté d’un lien n’est pas converti en `“`. L’avertissement s’affiche, mais rien n’est corrigé.

## 3. Limites de conception

1. **Pas de sémantique :** les règles sont des expressions régulières. Elles ne savent pas qu’un nombre est un identifiant ; seul le contexte immédiat peut les en avertir.
2. **Pas d’échappatoire locale :** en dehors de 4 éléments protégés, l’éditeur ne peut pas indiquer « ne pas toucher ici ».
3. **Langue :** elle dépend entièrement de `xml:lang`. Un passage non balisé hérite de la langue du texte.
4. **Correction silencieuse :** en édition savante, une règle ambiguë doit signaler plutôt que corriger.
5. **Tests :** ils ne couvrent que les paramètres par défaut et peu de cas adverses.

## 4. Améliorations, par priorité

### P1 — avant d’appliquer la normalisation à tout le corpus

- ✅ **Intervalles :** un tiret entre deux nombres n’est converti que si l’intervalle est plausible (pas de zéro initial, second nombre complété plus grand) et qu’il ne suit pas un mot annonçant un identifiant (`inv.`, `inventaire`, `accession`, `cote`, `ISSN`, `ISBN`, `art.`, `L.`, `R.`, `D.`). Fonctions `nucma:ranges` et `nucma:is-range`, variable `re-identifier`. En contrepartie, « art. 5-7 », les scores (`3-1`) et `12-12` ne sont plus convertis.
- ⬜ **Point séparateur de milliers en français :** ne plus regrouper `12.345`, seulement le signaler.
- ⬜ **Ordinaux anglais :** supprimer la conversion `2d`/`3d` (et `5e` en anglais), ou la remplacer par un signalement.
- ✅ **Apostrophes :** la paire `'mot'` reste entière en français et est signalée dans le résumé (« guillemets droits " ou ' ») ; ’s-Hertogenbosch et ’t Hooft dans les deux langues ; en anglais, ’n’, ’tis, ’twas, ’em, ’cause, ’til.

### P2 — maîtrise éditoriale

- ⬜ **Marqueur d’exclusion locale :** par exemple `@rend="verbatim"`, `<seg type="verbatim">` ou une instruction de traitement.
- ⬜ **Paramètre optionnel** pour exclure de la modernisation (œ, apostrophes) les citations diplomatiques.

### P3 — Schematron typographique, qui signale sans corriger

- ⬜ Il signalerait :
  - les capitales sans accent (liste fermée : Ecole, Etat, Eglise, A + espace…) ;
  - les espaces fautives et les caractères invisibles ;
  - les exposants Unicode ;
  - les guillemets droits restants et `..` ;
  - les tirets entre nombres non convertis et `x` entre dimensions ;
  - les titres probablement anglais sans `xml:lang` (heuristique fondée sur les mots outils).

### P4 — règles sûres à ajouter

- ⬜ Supprimer U+00AD et U+200B à l’étape NFC, avec un compte dans le rapport.
- ⬜ Espace insécable après *§*, *c.*, *ca*, *éd.* et devant *J.-C.*.
- ⬜ *2nde* → *2de* ; × dans `nombre x nombre unité`.

### P5 — processus

- ⬜ **Relire les modifications** comme étape de validation, avec `git diff --word-diff` ou le rapport `report=detail`.
- ⬜ **Tests de régression adverses :** convertir en XSpec les cas de ce diagnostic.
- ⬜ **Tests des paramètres** non par défaut.

## Ambiguïtés acceptées

- `514-987` est pris pour un intervalle.
- `p. 12 345` est pris pour un nombre.
- `10 $` devient `$10` en anglais.
