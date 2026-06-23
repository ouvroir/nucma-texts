<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:nucma="https://nucma.ca/ns"
  queryBinding="xslt3" xml:lang="fr">

  <sch:title>NUCMA : contrôle de la cohérence de l’encodage</sch:title>

  <!--
    Ce ficher Schematron fournit une validation complémentaire au schema `nucma` pour les contraintes complexes qui ne peuvent être exprimés avec RelaxNG ou ODD. Il permet notamment de contrôler les renvois vers meta/authors.xml ou la validité des identifiants ORCID.

    Deux niveaux (@role) :
      error   : encodage incohérent, à corriger ;
      warning : information manquante ou forme à harmoniser.

    Les personnes (auteurs, autrices, contributeurs, encodeurs) sont décrites une seule
    fois, dans meta/authors.xml ; les entrées y renvoient par @ref="#identifiant". Le
    fichier est retrouvé à partir de l’emplacement du document contrôlé : le dossier fr/,
    en/ ou meta/ du dépôt.

    Utilisation : dans oXygen, associer ce schéma aux fichiers (Document › Validate › Validate with…, ou insérer une instruction de traitement `xml-model`) ; en ligne de commande, voir xsl/README.md.
  -->

  <sch:ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
  <sch:ns prefix="nucma" uri="https://nucma.ca/ns"/>
  <sch:ns prefix="xs" uri="http://www.w3.org/2001/XMLSchema"/>

  <!-- ================================================================ -->
  <!-- Variables et fonctions                                           -->
  <!-- ================================================================ -->

  <!-- meta/authors.xml : le document lui-même s’il s’agit de ce fichier -->
  <sch:let name="authors-uri" value="replace(base-uri(/), '/(fr|en|meta)/[^/]*(/.*)?$', '/meta/authors.xml')"/>
  <sch:let name="authors" value="if (doc-available($authors-uri)) then doc($authors-uri) else ()"/>

  <!-- types d’identifiants admis pour une personne -->
  <sch:let name="person-idno-types" value="('orcid', 'isni', 'wikidata', 'viaf', 'bnf', 'idref')"/>

  <xsl:function name="nucma:person" as="element()?">
    <!-- personne de meta/authors.xml désignée par un @ref (#identifiant) -->
    <xsl:param name="ref" as="xs:string?"/>
    <xsl:param name="authors" as="document-node()?"/>
    <xsl:sequence select="$authors//tei:person[@xml:id = substring-after($ref, '#')][1]"/>
  </xsl:function>

  <xsl:function name="nucma:name" as="xs:string">
    <!-- nom affiché dans les messages : prénom et nom séparés par une espace -->
    <xsl:param name="persName" as="element()*"/>
    <xsl:sequence select="normalize-space(string-join(($persName[1]/tei:forename, $persName[1]/tei:surname), ' '))"/>
  </xsl:function>

  <xsl:function name="nucma:orcid-digits" as="xs:string">
    <!-- les 16 caractères d’un ORCID, quelle que soit sa forme (URL ou numéro seul) -->
    <xsl:param name="orcid" as="xs:string"/>
    <xsl:sequence select="replace(normalize-space($orcid), '^(https?://orcid\.org/)?(\d{4})-(\d{4})-(\d{4})-(\d{3}[\dX])$', '$2$3$4$5')"/>
  </xsl:function>

  <xsl:function name="nucma:orcid-is-valid" as="xs:boolean">
    <!-- forme (URL ou numéro seul) et chiffre de contrôle ISO 7064 11-2 d’un ORCID -->
    <xsl:param name="orcid" as="xs:string"/>
    <xsl:variable name="d" select="nucma:orcid-digits($orcid)"/>
    <xsl:sequence select="
      matches($d, '^\d{15}[\dX]$')
      and (let $total := fold-left(string-to-codepoints(substring($d, 1, 15)) ! (. - 48), 0,
                                   function($t, $digit) { ($t + $digit) * 2 }),
               $check := (12 - $total mod 11) mod 11
           return substring($d, 16) = (if ($check = 10) then 'X' else string($check)))"/>
  </xsl:function>

  <!-- ================================================================ -->
  <!-- 1. Auteurs et contributeurs des entrées                          -->
  <!-- ================================================================ -->

  <sch:pattern id="entry-persons">

    <sch:rule context="tei:titleStmt/tei:author">
      <sch:let name="person" value="nucma:person(@ref, $authors)"/>
      <sch:let name="orcid" value="(tei:idno, $person//tei:idno)[lower-case(@type) = 'orcid'][normalize-space()]"/>
      <sch:assert role="error" test="@ref">
        Auteur sans @ref : « <sch:value-of select="nucma:name(tei:persName)"/> » doit renvoyer à sa notice de meta/authors.xml (@ref="#identifiant").
      </sch:assert>
      <sch:assert role="error" test="not(@ref) or empty($authors) or exists($person)">
        Le renvoi <sch:value-of select="@ref"/> ne correspond à aucune personne de meta/authors.xml.
      </sch:assert>
      <sch:assert role="warning" test="empty($person) or exists($orcid)">
        <sch:value-of select="nucma:name(tei:persName)"/> (<sch:value-of select="@ref"/>) n’a pas d’ORCID, ni dans l’entrée ni dans meta/authors.xml.
      </sch:assert>
      <sch:assert role="error"
        test="empty($person) or empty(tei:idno[lower-case(@type) = 'orcid'][normalize-space()])
              or empty($person//tei:idno[lower-case(@type) = 'orcid'][normalize-space()])
              or nucma:orcid-digits(tei:idno[lower-case(@type) = 'orcid'][1])
                 = nucma:orcid-digits($person//tei:idno[lower-case(@type) = 'orcid'][normalize-space()][1])">
        L’ORCID de <sch:value-of select="@ref"/> dans l’entrée diffère de celui de meta/authors.xml.
      </sch:assert>
      <sch:assert role="warning"
        test="empty($person)
              or (normalize-space(tei:persName/tei:forename) = normalize-space($person/tei:persName/tei:forename)
                  and normalize-space(tei:persName/tei:surname) = normalize-space($person/tei:persName/tei:surname))">
        Le nom de <sch:value-of select="@ref"/> (prénom « <sch:value-of select="normalize-space(tei:persName/tei:forename)"/> », nom « <sch:value-of select="normalize-space(tei:persName/tei:surname)"/> ») diffère de meta/authors.xml (« <sch:value-of select="nucma:name($person/tei:persName)"/> »).
      </sch:assert>
    </sch:rule>

    <sch:rule context="tei:titleStmt/tei:respStmt">
      <sch:assert role="error" test="normalize-space(tei:resp)">
        Contribution sans responsabilité : renseigner &lt;resp&gt; (« Encodage », « Research Assistant »…).
      </sch:assert>
      <sch:assert role="warning" test="@ref">
        Contributeur sans @ref : « <sch:value-of select="nucma:name(tei:persName)"/> » devrait renvoyer à sa notice de meta/authors.xml.
      </sch:assert>
      <sch:assert role="error" test="not(@ref) or empty($authors) or exists(nucma:person(@ref, $authors))">
        Le renvoi <sch:value-of select="@ref"/> ne correspond à aucune personne de meta/authors.xml.
      </sch:assert>
    </sch:rule>

    <sch:rule context="tei:revisionDesc/tei:change[@resp | @who]">
      <sch:let name="refs" value="tokenize(normalize-space(string-join((@resp, @who), ' ')), ' ')"/>
      <sch:assert role="warning"
        test="empty($authors) or (every $ref in $refs satisfies exists(nucma:person($ref, $authors)))">
        Révision attribuée à <sch:value-of select="string-join($refs, ', ')"/> : personne absente de meta/authors.xml.
      </sch:assert>
    </sch:rule>

    <sch:rule context="tei:TEI[not(tei:text//tei:listPerson)]/tei:teiHeader">
      <sch:assert role="warning" test="exists($authors)">
        meta/authors.xml est introuvable (cherché en <sch:value-of select="$authors-uri"/>) : les renvois vers les personnes ne sont pas contrôlés.
      </sch:assert>
    </sch:rule>

  </sch:pattern>

  <!-- ================================================================ -->
  <!-- 2. Notices des personnes (meta/authors.xml)                      -->
  <!-- ================================================================ -->

  <sch:pattern id="person-records">

    <sch:rule context="tei:listPerson/tei:person">
      <sch:assert role="error" test="@xml:id">
        Personne sans @xml:id : les entrées ne peuvent pas y renvoyer.
      </sch:assert>
      <sch:assert role="error" test="normalize-space(tei:persName/tei:forename) and normalize-space(tei:persName/tei:surname)">
        <sch:value-of select="@xml:id"/> : prénom ou nom manquant dans persName.
      </sch:assert>
      <sch:assert role="error" test="count(//tei:person[@xml:id = current()/@xml:id]) = 1">
        Identifiant <sch:value-of select="@xml:id"/> utilisé par plusieurs personnes.
      </sch:assert>
      <sch:report role="warning"
        test="count(//tei:person[normalize-space(string-join(tei:persName/(tei:forename, tei:surname), ' '))
                                 = nucma:name(current()/tei:persName)]) gt 1">
        <sch:value-of select="@xml:id"/> : une autre notice porte le même nom.
      </sch:report>
      <sch:assert role="warning" test=".//tei:idno[lower-case(@type) = 'orcid'][normalize-space()]">
        <sch:value-of select="@xml:id"/> (<sch:value-of select="nucma:name(tei:persName)"/>) n’a pas d’ORCID.
      </sch:assert>
    </sch:rule>

    <sch:rule context="tei:person//tei:idno">
      <sch:let name="who" value="ancestor::tei:person[1]/@xml:id"/>
      <sch:assert role="warning" test="normalize-space(.)">
        <sch:value-of select="$who"/> : identifiant <sch:value-of select="@type"/> vide (à compléter ou à supprimer).
      </sch:assert>
      <sch:assert role="warning" test="not(normalize-space(.)) or @type">
        <sch:value-of select="$who"/> : identifiant sans @type (« <sch:value-of select="normalize-space(.)"/> »).
      </sch:assert>
      <sch:assert role="error"
        test="not(lower-case(@type) = ('orcid', 'isni', 'wikidata', 'viaf', 'bnf', 'idref')) or not(normalize-space(.))
              or empty(//tei:person[@xml:id ne $who]//tei:idno[lower-case(@type) = lower-case(current()/@type)]
                                                     [normalize-space(.) = normalize-space(current())])">
        <sch:value-of select="$who"/> : l’identifiant <sch:value-of select="@type"/> « <sch:value-of select="normalize-space(.)"/> » est aussi attribué à <sch:value-of select="string-join(//tei:person[@xml:id ne $who][.//tei:idno[lower-case(@type) = lower-case(current()/@type)][normalize-space(.) = normalize-space(current())]]/@xml:id, ', ')"/>.
      </sch:assert>
      <sch:assert role="warning" test="not(@type) or lower-case(@type) = $person-idno-types">
        <sch:value-of select="$who"/> : type d’identifiant inconnu « <sch:value-of select="@type"/> » (types admis : <sch:value-of select="string-join($person-idno-types, ', ')"/>).
      </sch:assert>
    </sch:rule>

  </sch:pattern>

  <!-- ================================================================ -->
  <!-- 3. Forme des identifiants (entrées et meta/authors.xml)          -->
  <!-- ================================================================ -->

  <sch:pattern id="identifiers">

    <sch:rule context="tei:idno[lower-case(@type) = 'orcid'][normalize-space()]">
      <sch:assert role="error" test="nucma:orcid-is-valid(.)">
        ORCID invalide : « <sch:value-of select="normalize-space(.)"/> » (forme 0000-0000-0000-0000, chiffre de contrôle compris).
      </sch:assert>
      <sch:assert role="warning" test="not(nucma:orcid-is-valid(.)) or starts-with(normalize-space(.), 'https://orcid.org/')">
        ORCID à écrire sous forme d’URL : https://orcid.org/<sch:value-of select="normalize-space(.)"/>.
      </sch:assert>
      <sch:assert role="warning" test="@type = 'orcid'">
        Écrire le type en minuscules : type="orcid" (et non « <sch:value-of select="@type"/> »).
      </sch:assert>
    </sch:rule>

    <sch:rule context="tei:idno[lower-case(@type) = 'isni'][normalize-space()]">
      <sch:assert role="warning" test="matches(normalize-space(.), '^https://isni\.org/isni/\d{15}[\dX]$')">
        ISNI de forme inattendue : « <sch:value-of select="normalize-space(.)"/> » (attendu : https://isni.org/isni/ suivi de 16 caractères).
      </sch:assert>
    </sch:rule>

  </sch:pattern>

</sch:schema>
