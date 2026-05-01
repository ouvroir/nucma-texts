# Liste de contrôle pour l’importation

- [ ] Conversion des fichiers docx vers TEI
- [ ] Renommage du fichier et insertion dans l’arborescence
- [ ] Nettoyage du fichier avec la XSL
- [ ] Code lang
- [ ] Renseignement de l’entête du fichier
  - [ ] Titre
  - [ ] Auteurs
  - [ ] Identifiants
  - [ ] Changes
- [ ] Placement de la bibliographie dans le `<back>`
- [ ] Contrôle de la structure
- [ ] Traitement des commentaires
- [ ] Indexation personnes
- [ ] Indexation œuvres
- [ ] Indexation expositions
- [ ] Indexation lieux
- [ ] Traitement des figures
- [ ] Traitement de la bibliographie
- [ ] Traitement des rebonds
- [ ] Validation du fichier

Typographie

- [ ] Normaliser le fichier en NFC. 
  Certaines lettres accentuées peuvent être écrites en deux caractères : la lettre de base, puis un accent combinant (U+0300 grave, U+0301 aigu, U+0302 circonflexe). À l’écran rien ne se voit, mais la recherche, le tri, la comparaison de chaînes et l’indexation peuvent échouer.

```python
python3 -c "import unicodedata,sys;p=sys.argv[1];t=open(p,encoding='utf-8').read();open(p,'w',encoding='utf-8').write(unicodedata.normalize('NFC',t))" fr/acquisition/variabilite.xml
```

- [ ] Espaces insécables

| Signe                          | Espace avant (ou à l’intérieur)                              |
| ------------------------------ | ------------------------------------------------------------ |
| `;` `!` `?`                    | **espace fine insécable** (U+202F)                           |
| `:`                            | **espace mot insécable** (U+00A0), c'est-à-dire une espace de largeur normale |
| `« … »`                        | **espace mot insécable** (U+00A0) à l'intérieur des guillemets |
| `%`, unités, `n° 16`, `p. 137` | espace mot insécable (U+00A0)                                |

Attention, U+2009, espace fine pas insécable. U+2005, espace quart de cadratin

Appliquer la convention typographique française (espace fine avant `; ! ?`, espace insécable avant `:` et dans les guillemets), en laissant intacts entités, URL, attributs, commentaires, ainsi que les titres anglais, tout en corrigeant les espaces manquants dans les passages français.

ᵉ (U+1D49, lettre modificative) dans « XVIIIᵉ », harmoniser

