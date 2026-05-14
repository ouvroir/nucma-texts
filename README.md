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

**En ligne de commande**, avec Saxon 12 (l’alias `saxon` lance `java -jar …/saxon-he-12.3.jar`) et SchXslt2, fourni par [XSpec](https://github.com/xspec/xspec) (`git clone https://github.com/xspec/xspec.git ~/xspec`) : compiler le Schematron une fois (et après chaque modification), puis contrôler les fichiers depuis la racine du dépôt ; `schemas/svrl-text.xsl` met le rapport en forme.

```sh
saxon -s:schemas/nucma-quality.sch -xsl:$HOME/xspec/lib/schxslt2/transpile.xsl -o:/tmp/nucma-quality.xsl

for f in meta/authors.xml fr/acquisition/*.xml; do
  saxon -s:$f -xsl:/tmp/nucma-quality.xsl -o:/tmp/rapport.svrl && saxon -s:/tmp/rapport.svrl -xsl:schemas/svrl-text.xsl document=$f
done
```
