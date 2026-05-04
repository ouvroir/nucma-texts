<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.tei-c.org/ns/1.0"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:nucma="https://nucma.ca/ns"
  exclude-result-prefixes="#all"
  version="3.0">

  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>NUCMA profile of the TEI Stylesheets: conversion of a .docx file to
        TEI.</xd:b></xd:p>
      <xd:p>Runs the standard conversion (<xd:i>docx/from/docxtotei.xsl</xd:i>), then cleans
        its result in four steps, each one on a new tree:</xd:p>
      <xd:ol>
        <xd:li><xd:b>nucma:cleanup</xd:b>: removes the word-processor artifacts (font family
          and size in <xd:i>@style</xd:i>, <xd:i>hi</xd:i> without rendition,
          <xd:i>@xml:space</xd:i>, layout attributes of <xd:i>graphic</xd:i>, anchors that
          nothing points to, empty headings), types hyperlinks as external and turns the
          comments into XML comments;</xd:li>
        <xd:li><xd:b>nucma:header</xd:b>: moves the front matter written at the start of the
          document (entry title, short title, authors) to the TEI header, completes the header
          from the NUCMA model (publication, series, licence, language) and sets the language
          on <xd:i>text</xd:i>;</xd:li>
        <xd:li><xd:b>nucma:boundary-spaces</xd:b>: removes the no-break spaces left by
          converted guillemets around phrase elements (this step needs the text merged by
          the previous one);</xd:li>
        <xd:li><xd:b>nucma:notes</xd:b>: gathers the notes in
          <xd:i>back/div[@type='notes']</xd:i> and replaces them with note calls.</xd:li>
      </xd:ol>
      <xd:p>The output is indented. Typography is not dealt with here but by
        <xd:i>xsl/normalization.xsl</xd:i>.</xd:p>
      <xd:p>The same rules are applied to existing TEI files by
        <xd:i>xsl/import-cleanup.xsl</xd:i>: any change must be made in both
        stylesheets. Mode, variable and function names are in the <xd:i>nucma</xd:i>
        namespace, so as not to clash with those of the TEI Stylesheets.</xd:p>
      <xd:p>Usage, through the <xd:i>nucma</xd:i> link in the profiles of the TEI
        Stylesheets (the import below is relative to that location):</xd:p>
      <xd:pre>~/TEIC/Stylesheets/bin/docxtotei --profile=nucma article.docx article.xml
NUCMA_CHAPTER=mediation NUCMA_RESP=RC ~/TEIC/Stylesheets/bin/docxtotei --profile=nucma article.docx article.xml</xd:pre>
      <xd:p><xd:b>Author:</xd:b> Emmanuel Château-Dutier, based on the TEI Stylesheets
        (TEI Consortium).</xd:p>
    </xd:desc>
  </xd:doc>

  <xsl:import href="../../../docx/from/docxtotei.xsl"/>

  <xd:doc>
    <xd:desc>Indented output, overriding <xd:i>indent="no"</xd:i> in docxtotei.xsl. Elements
      with mixed content are not indented, so that no whitespace is added inside the
      text.</xd:desc>
  </xd:doc>
  <xsl:output method="xml" encoding="UTF-8" indent="yes"
    suppress-indentation="tei:p tei:head tei:hi tei:q tei:note tei:item tei:cell tei:title
      tei:label tei:quote tei:l tei:ab tei:bibl tei:ref tei:foreign tei:soCalled tei:term
      tei:emph tei:mentioned tei:persName tei:orgName tei:placeName tei:name tei:date
      tei:author tei:editor tei:resp tei:licence tei:change tei:desc tei:gloss tei:seg"/>

  <xsl:mode name="nucma:cleanup" on-no-match="shallow-copy"/>
  <xsl:mode name="nucma:header" on-no-match="shallow-copy"/>
  <xsl:mode name="nucma:boundary-spaces" on-no-match="shallow-copy"/>
  <xsl:mode name="nucma:notes" on-no-match="shallow-copy"/>
  <xsl:mode name="nucma:notes-content" on-no-match="shallow-copy"/>


  <!-- ================================================================ -->
  <!-- Pipeline                                                         -->
  <!-- ================================================================ -->

  <xd:doc>
    <xd:desc>Runs the conversion of docxtotei.xsl, then the four NUCMA steps.</xd:desc>
  </xd:doc>
  <xsl:template match="/">
    <xsl:variable name="converted">
      <xsl:apply-imports/>
    </xsl:variable>
    <xsl:variable name="cleaned">
      <xsl:apply-templates select="$converted" mode="nucma:cleanup"/>
    </xsl:variable>
    <xsl:variable name="headed">
      <xsl:apply-templates select="$cleaned" mode="nucma:header">
        <xsl:with-param name="front" tunnel="yes" select="nucma:front-matter($cleaned//tei:text[1])"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="spaced">
      <xsl:apply-templates select="$headed" mode="nucma:boundary-spaces"/>
    </xsl:variable>
    <xsl:apply-templates select="$spaced" mode="nucma:notes"/>
  </xsl:template>

  <xd:doc>
    <xd:desc>Paragraph styles of Word that carry no meaning: dropped during the standard
      conversion.</xd:desc>
  </xd:doc>
  <xsl:template mode="pass2" match="@rend[. = ('Body Text', 'Body Text 2', 'Body Text 3',
    'Text Body', 'Text body', 'Body Text Indent')]"/>


  <!-- ================================================================ -->
  <!-- Configuration                                                    -->
  <!-- ================================================================ -->

  <xd:doc>
    <xd:desc>Chapter of the entry, used in its identifier
      (<xd:i>nucma.fr.acquisition.variabilite</xd:i>). The docxtotei script does not pass
      stylesheet parameters: the value is taken from the <xd:i>NUCMA_CHAPTER</xd:i>
      environment variable, otherwise <xd:i>acquisition</xd:i>.</xd:desc>
  </xd:doc>
  <xsl:param name="nucma-chapter" as="xs:string"
    select="(environment-variable('NUCMA_CHAPTER')[normalize-space()], 'acquisition')[1]"/>

  <xd:doc>
    <xd:desc>Identifier of the person who converts the document, recorded in
      <xd:i>revisionDesc/change/@resp</xd:i>: taken from the <xd:i>NUCMA_RESP</xd:i>
      environment variable, otherwise <xd:i>ECD</xd:i> (Emmanuel Château-Dutier), who
      usually does the encoding.</xd:desc>
  </xd:doc>
  <xsl:param name="nucma-resp" as="xs:string"
    select="(environment-variable('NUCMA_RESP')[normalize-space()], 'ECD')[1]"/>

  <xd:doc>
    <xd:desc>Location of the list of the authors of the encyclopedia
      (<xd:i>meta/authors.xml</xd:i> in the corpus repository). The profile is read through
      the <xd:i>nucma</xd:i> link of the TEI Stylesheets, so a path relative to it cannot
      reach the corpus: the location is given by the <xd:i>NUCMA_AUTHORS</xd:i> environment
      variable, otherwise by the path below, to adapt to the local copy of the
      repository.</xd:desc>
  </xd:doc>
  <xsl:param name="nucma-authors" as="xs:string"
    select="(environment-variable('NUCMA_AUTHORS')[normalize-space()],
             'file:///Users/emmanuelchateau/ouvroir/nucma-textes/meta/authors.xml')[1]"/>

  <xd:doc>
    <xd:desc>The list of the authors, or nothing if it cannot be read (the authors are then
      only split from the document, with an @todo).</xd:desc>
  </xd:doc>
  <xsl:variable name="nucma:authors" as="document-node()?"
    select="let $uri := resolve-uri($nucma-authors, static-base-uri())
            return if (doc-available($uri)) then doc($uri) else ()"/>

  <xd:doc>
    <xd:desc>Wording of the NUCMA header model, by language: publisher, licence, series
      subtitle, chapter label (followed by the chapter name: « Chapitre Acquisition »,
      « Chapter: Acquisition »), source description and revision note. Taken from the header of the entries of
      the corpus, with two corrections (<xd:i>creativecommons.org</xd:i>,
      <xd:i>licence</xd:i>).</xd:desc>
  </xd:doc>
  <xsl:variable name="nucma:header-model" as="map(xs:string, map(xs:string, xs:string))" select="map{
    'fr': map{
      'publisher': 'Groupe de recherche et de réflexion CIÉCO',
      'licence': 'Ce contenu est mis à disposition sous licence Creative Commons Attribution 4.0.',
      'series': 'NUCMA, l’encyclopédie Des nouveaux usages des collections dans les musées d’art',
      'chapter': 'Chapitre ',
      'source': 'Fichier nativement numérique',
      'conversion': 'Conversion depuis Word (profil nucma)'},
    'en': map{
      'publisher': 'CIÉCO Research and Inquiry Group',
      'licence': 'This content is made available under a Creative Commons Attribution 4.0 licence.',
      'series': 'NUCMA, the encyclopedia of New Uses of Collections',
      'chapter': 'Chapter: ',
      'source': 'Born-digital file',
      'conversion': 'Conversion from Word (nucma profile)'}}"/>

  <xd:doc>
    <xd:desc>CSS properties dropped from <xd:i>@style</xd:i>: the font is set by the
      publication, not by the text.</xd:desc>
  </xd:doc>
  <xsl:variable name="nucma:dropped-style-properties" as="xs:string+" select="('font-family', 'font-size')"/>

  <xd:doc>
    <xd:desc>Elements that replace guillemets or mark a phrase. Word puts a no-break space
      inside guillemets (« garde négociée »); once the guillemets are converted into one of
      these elements, that space is left between the element and the next or previous
      word.</xd:desc>
  </xd:doc>
  <xsl:variable name="nucma:phrase-elements" as="xs:string+"
    select="('q', 'soCalled', 'title', 'foreign', 'mentioned', 'term', 'emph', 'hi')"/>

  <xd:doc>
    <xd:desc>Elements whose text is never modified: identifiers and addresses.</xd:desc>
  </xd:doc>
  <xsl:variable name="nucma:protected-elements" as="xs:string+" select="('idno', 'ptr', 'code', 'email')"/>

  <xd:doc>
    <xd:desc>Elements that may stand as blocks in a note; any other content of a note is
      wrapped in a paragraph.</xd:desc>
  </xd:doc>
  <xsl:variable name="nucma:note-blocks" as="xs:string+"
    select="('p', 'list', 'table', 'quote', 'lg', 'figure', 'ab', 'listBibl', 'bibl')"/>

  <xd:doc>
    <xd:desc>Regular expression for a bullet typed at the start of a line instead of a Word
      list (● Julie Bawin, …), with the spaces or tab that follow it.</xd:desc>
  </xd:doc>
  <xsl:variable name="nucma:re-bullet" select="'^[●•◦▪▫■□‣⁃∙·*–—\-][\s\p{Zs}]*'"/>

  <xd:doc>
    <xd:desc>Regular expression for a no-break space: U+00A0 or U+202F.</xd:desc>
  </xd:doc>
  <xsl:variable name="nucma:re-nbsp" select="'[&#xA0;&#x202F;]'"/>

  <xd:doc>
    <xd:desc>Regular expression for the French and English titles that justify a no-break
      space before a name (M., MM., Mme, Mlle, Mgr, Me, Dr, Pr, Mr, Mrs, Ms, Prof., St.).</xd:desc>
  </xd:doc>
  <xsl:variable name="nucma:re-title"
    select="'(?:MM\.|M\.|Mmes|Mme|Mlles|Mlle|Mgr|Me|Dr\.?|Pr\.?|Mrs\.?|Mr\.?|Ms\.?|Prof\.|St\.)'"/>


  <!-- ================================================================ -->
  <!-- 1. nucma:cleanup: word-processor artifacts and comments          -->
  <!-- ================================================================ -->

  <xd:doc>
    <xd:desc>Removes the dropped properties from a CSS declaration list.</xd:desc>
    <xd:param name="style">A <xd:i>@style</xd:i> value
      (<xd:i>font-family:Helvetica Neue;font-size:12pt;color:red</xd:i>).</xd:param>
    <xd:return>The remaining declarations (<xd:i>color:red</xd:i>), or an empty
      string.</xd:return>
  </xd:doc>
  <xsl:function name="nucma:clean-style" as="xs:string">
    <xsl:param name="style" as="xs:string"/>
    <xsl:sequence select="string-join(
      tokenize($style, ';')[normalize-space()]
        [not(lower-case(normalize-space(substring-before(., ':'))) = $nucma:dropped-style-properties)]
        ! normalize-space(.),
      ';')"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Unwraps a <xd:i>hi</xd:i> that carries no rendition once its style is cleaned,
      or no attribute at all.</xd:desc>
  </xd:doc>
  <xsl:template mode="nucma:cleanup"
    match="tei:hi[not(@* except (@style, @xml:space))][nucma:clean-style(string(@style)) = '']">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xd:doc>
    <xd:desc>Unwraps a <xd:i>hi</xd:i> or a <xd:i>seg</xd:i> that only contains whitespace
      (<xd:i>&lt;seg&gt;  &lt;/seg&gt;</xd:i> after a note call). It is replaced by a single
      space, or by nothing if the neighbouring text already has one.</xd:desc>
  </xd:doc>
  <xsl:template mode="nucma:cleanup" priority="1" match="(tei:hi | tei:seg)[not(*)][matches(., '^[\s\p{Zs}]+$')]">
    <!-- a single space, of the same kind as the first one, and none if the neighbouring
         text already has one -->
    <xsl:if test="not(matches(preceding-sibling::node()[1][self::text()], '[\s\p{Zs}]$')
                   or matches(following-sibling::node()[1][self::text()], '^[\s\p{Zs}]'))">
      <xsl:value-of select="substring(., 1, 1)"/>
    </xsl:if>
  </xsl:template>

  <xd:doc>
    <xd:desc>Removes the font family and size from <xd:i>@style</xd:i>; the attribute is
      dropped when nothing remains.</xd:desc>
  </xd:doc>
  <xsl:template mode="nucma:cleanup" match="@style">
    <xsl:variable name="style" select="nucma:clean-style(.)"/>
    <xsl:if test="$style">
      <xsl:attribute name="style" select="$style"/>
    </xsl:if>
  </xsl:template>

  <xd:doc>
    <xd:desc>Drops <xd:i>@xml:space="preserve"</xd:i>, and the layout attributes of
      <xd:i>graphic</xd:i> (the size and placement of images are set by the
      publication).</xd:desc>
  </xd:doc>
  <xsl:template mode="nucma:cleanup"
    match="@xml:space[. = 'preserve'] | tei:graphic/@n | tei:graphic/@width | tei:graphic/@height | tei:graphic/@rend"/>

  <xd:doc>
    <xd:desc>Replaces a Word comment with an XML comment at the same place, just after the
      commented passage.</xd:desc>
  </xd:doc>
  <xsl:template mode="nucma:cleanup" match="tei:note[@place = 'comment']">
    <xsl:comment select="nucma:todo-comment(.)"/>
  </xsl:template>

  <xd:doc>
    <xd:desc>Drops the anchors left by Word that nothing points to: the anchors that
      delimit the passage of a comment (quoted in the XML comment that replaces the note,
      which is built from the source tree, so before they are dropped) and the bookmarks
      (<xd:i>&lt;anchor xml:id="2z3fk6gdwmkd"/&gt;</xd:i>). An anchor that is the target of
      a link (<xd:i>#id</xd:i>) is kept.</xd:desc>
  </xd:doc>
  <xsl:template mode="nucma:cleanup" match="tei:anchor[nucma:is-dropped-anchor(.)]"/>

  <xd:doc>
    <xd:desc>Tells whether an anchor is dropped: nothing points to it.</xd:desc>
    <xd:param name="anchor">An <xd:i>anchor</xd:i> element.</xd:param>
  </xd:doc>
  <xsl:function name="nucma:is-dropped-anchor" as="xs:boolean">
    <xsl:param name="anchor" as="element()"/>
    <xsl:sequence select="not($anchor/@xml:id and root($anchor)//@*[. = '#' || $anchor/@xml:id])"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Drops the empty headings of Word: no text, and no element other than dropped
      anchors.</xd:desc>
  </xd:doc>
  <xsl:template mode="nucma:cleanup"
    match="tei:head[not(normalize-space())][every $e in * satisfies $e/self::tei:anchor[nucma:is-dropped-anchor(.)]]"/>

  <xd:doc>
    <xd:desc>Hyperlinks: <xd:i>@type="external"</xd:i> on a <xd:i>ref</xd:i> whose target is
      a web or e-mail address (<xd:i>http(s):</xd:i>, <xd:i>ftp:</xd:i>,
      <xd:i>mailto:</xd:i>, <xd:i>www.</xd:i>), unless it already has a type. Links to the
      encyclopedia itself (<xd:i>nucma.ca</xd:i> and its subdomains) are left untyped: they
      are cross-references between entries, not external links.</xd:desc>
  </xd:doc>
  <xsl:template mode="nucma:cleanup" match="tei:ref[not(@type)][matches(@target, '^(https?:|ftp:|mailto:|www\.)', 'i')]
      [not(matches(@target, '^(https?://)?([a-z0-9-]+\.)*nucma\.ca([/:?#]|$)', 'i'))]">
    <xsl:copy>
      <xsl:attribute name="type" select="'external'"/>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xd:doc>
    <xd:desc>Text of the XML comment that replaces a Word comment.</xd:desc>
    <xd:param name="note">A <xd:i>note[@place='comment']</xd:i>; its <xd:i>@n</xd:i> links it
      to the <xd:i>commentRangeStart</xd:i> and <xd:i>commentRangeEnd</xd:i>
      anchors.</xd:param>
    <xd:return><xd:i> @todo text [author, date, sur « passage »] </xd:i>: the author comes
      from <xd:i>@resp</xd:i>, the date from <xd:i>date/@when</xd:i>; what is missing is left
      out. Double hyphens, forbidden in XML comments, are separated.</xd:return>
  </xd:doc>
  <xsl:function name="nucma:todo-comment" as="xs:string">
    <xsl:param name="note" as="element()"/>
    <xsl:variable name="start" select="$note/preceding::tei:anchor[@type = 'commentRangeStart'][@n = $note/@n][1]"/>
    <xsl:variable name="end" select="($note/preceding::tei:anchor[@type = 'commentRangeEnd'][@n = $note/@n][1],
                                      $note/following::tei:anchor[@type = 'commentRangeEnd'][@n = $note/@n][1])[1]"/>
    <xsl:variable name="passage" select="
      if ($start and $end)
      then normalize-space(string-join(root($note)//text()[. &gt;&gt; $start][. &lt;&lt; $end]
                                                         [not(ancestor::tei:note[@place = 'comment'])]))
      else ''"/>
    <xsl:variable name="source" select="string-join((
      replace(substring-after($note/@resp, '#'), '_', ' ')[normalize-space()],
      substring($note/tei:date/@when, 1, 10)[normalize-space()],
      ('sur « ' || $passage || ' »')[$passage]), ', ')"/>
    <!-- the paragraphs of the comment are separated by a space -->
    <xsl:variable name="text" select="
      normalize-space(string-join($note/(node() except tei:date) ! string(.), ' '))
      || (if ($source) then ' [' || $source || ']' else '')"/>
    <!-- replaced twice, so that a run of three hyphens is separated too -->
    <xsl:sequence select="' @todo ' || replace($text, '--', '- -') => replace('--', '- -') || ' '"/>
  </xsl:function>


  <!-- ================================================================ -->
  <!-- 2. nucma:header: front matter moved to the TEI header            -->
  <!-- ================================================================ -->

  <xd:doc>
    <xd:desc>Kind of a front-matter label paragraph, in French or English.</xd:desc>
    <xd:param name="block">A block of the body.</xd:param>
    <xd:return><xd:i>title</xd:i> (« Titre de l’entrée : », « Entry Title: »),
      <xd:i>short</xd:i> (« Titre court : », « Short Title: »), <xd:i>authors</xd:i>
      (« Auteur·rices : », « Autrices : », « Authors: »…), or an empty string.</xd:return>
  </xd:doc>
  <xsl:function name="nucma:label" as="xs:string">
    <xsl:param name="block" as="element()"/>
    <!-- Word may write no-break spaces between the words and before the colon
         (« Titre⍽de l’entrée⍽: ») -->
    <xsl:variable name="s" select="normalize-unicode(normalize-space(replace($block, '\p{Zs}', ' ')))"/>
    <xsl:sequence select="
      if (not($block/self::tei:p)) then ''
      else if (matches($s, '^(Titre de l.entrée|Entry Title)[\s\p{Zs}]*:', 'i')) then 'title'
      else if (matches($s, '^(Titre court|Short Title|Sort Title)[\s\p{Zs}]*:', 'i')) then 'short'
      else if (matches($s, '^(Auteur|Autrice|Author)[^:]{0,12}:', 'i')) then 'authors'
      else ''"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Tells whether a block is a sub-label of the author list: a short line ending
      with a colon, without comma (« Research Assistant: », « Assistante de recherche : »).
      The persons listed after it are not authors but contributors (see
      <xd:ref name="nucma:resp-stmt" type="function"/>).</xd:desc>
    <xd:param name="block">A block of the body.</xd:param>
  </xd:doc>
  <xsl:function name="nucma:is-sub-label" as="xs:boolean">
    <xsl:param name="block" as="element()"/>
    <xsl:variable name="s" select="normalize-unicode(normalize-space($block))"/>
    <xsl:sequence select="exists($block/self::tei:p) and nucma:label($block) = ''
      and ends-with($s, ':') and not(contains($s, ',')) and string-length($s) lt 60"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Tells whether a block is a line of the author list:
      <xd:i>Name, role, affiliation</xd:i>, possibly preceded by a typed bullet.</xd:desc>
    <xd:param name="block">A block of the body.</xd:param>
  </xd:doc>
  <xsl:function name="nucma:is-author-line" as="xs:boolean">
    <xsl:param name="block" as="element()"/>
    <xsl:variable name="s" select="replace(normalize-unicode(normalize-space($block)), $nucma:re-bullet, '')"/>
    <xsl:sequence select="exists($block/self::tei:p) and nucma:label($block) = ''
      and contains($s, ',') and string-length($s) lt 250 and matches($s, '^\p{Lu}')"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>
      <xd:p>Reads the front matter written at the start of the document:</xd:p>
      <xd:pre>Titre de l’entrée :
Négocier la variabilité
Titre court : Variabilité
Auteur·rices :
• Anne Bénichou, professeure, Université du Québec à Montréal</xd:pre>
      <xd:p>A value is either on the label line, after the colon, or on the next non-empty
        block (a paragraph, or a heading when Word used a heading style). The title may be
        followed by a subtitle, on the next block, before the next label. The authors are the
        items of the list that follows the label, or the following paragraphs of the form
        <xd:i>Name, role, affiliation</xd:i>. Only the first fifteen blocks of the body are
        read.</xd:p>
    </xd:desc>
    <xd:param name="text">The <xd:i>text</xd:i> element of the converted document.</xd:param>
    <xd:return>A map: <xd:i>lang</xd:i> (<xd:i>fr</xd:i> or <xd:i>en</xd:i>, from the
      labels), <xd:i>titles</xd:i> (title, and subtitle if any), <xd:i>short</xd:i>,
      <xd:i>authors</xd:i> (one map per person: <xd:i>line</xd:i>, and <xd:i>resp</xd:i> for
      a person listed under a sub-label such as « Research Assistant: ») and
      <xd:i>blocks</xd:i> (the blocks to remove from the body). Empty when no label is
      found.</xd:return>
  </xd:doc>
  <xsl:function name="nucma:front-matter" as="map(*)">
    <xsl:param name="text" as="element()?"/>
    <!-- blocks of the body, in document order; empty ones (a heading holding only an
         anchor) are skipped -->
    <xsl:variable name="b" select="($text/tei:body//(tei:p | tei:head | tei:list)
      [not(ancestor::tei:note | ancestor::tei:list)][normalize-space()])[position() le 15]"/>
    <xsl:variable name="kinds" select="$b ! nucma:label(.)"/>
    <xsl:variable name="labels" select="index-of($kinds, 'title'), index-of($kinds, 'short'), index-of($kinds, 'authors')"/>
    <!-- value written on the label line, after the colon -->
    <xsl:variable name="inline" select="function($i) {
      normalize-unicode(normalize-space(substring-after(normalize-space($b[$i]), ':'))) }"/>
    <!-- blocks between a label and the next one -->
    <xsl:variable name="after" select="function($i) {
      let $next := min($labels[. gt $i])
      return if (exists($next)) then $b[position() gt $i and position() lt $next] else $b[$i + 1] }"/>
    <xsl:variable name="ti" select="index-of($kinds, 'title')[1]"/>
    <xsl:variable name="si" select="index-of($kinds, 'short')[1]"/>
    <xsl:variable name="ai" select="index-of($kinds, 'authors')[1]"/>
    <xsl:variable name="title-blocks" select="if (exists($ti) and not($inline($ti))) then $after($ti)[position() le 2] else ()"/>
    <xsl:variable name="short-blocks" select="if (exists($si) and not($inline($si))) then $after($si)[1] else ()"/>
    <!-- the author block: a list, author lines and sub-labels (« Research Assistant: »),
         in an order that keeps the first paragraph of the text out of it: after a list,
         only a sub-label may follow -->
    <xsl:variable name="author-blocks" as="element()*">
      <xsl:if test="exists($ai) and not($inline($ai))">
        <xsl:iterate select="$b[position() gt $ai]">
          <xsl:param name="previous" as="xs:string" select="'label'"/>
          <xsl:variable name="kind" select="
            if (self::tei:list) then 'list'
            else if (nucma:is-sub-label(.)) then 'sub'
            else if (nucma:is-author-line(.)) then 'line'
            else ''"/>
          <xsl:variable name="allowed" select="
            map{'label': ('list', 'line', 'sub'), 'line': ('line', 'sub'), 'list': 'sub', 'sub': ('list', 'line')}($previous)"/>
          <xsl:choose>
            <xsl:when test="$kind = $allowed">
              <xsl:sequence select="."/>
              <xsl:next-iteration>
                <xsl:with-param name="previous" select="$kind"/>
              </xsl:next-iteration>
            </xsl:when>
            <xsl:otherwise>
              <xsl:break/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:iterate>
      </xsl:if>
    </xsl:variable>
    <xsl:sequence select="
      if (empty($labels)) then map{}
      else map{
        'lang': if (matches(normalize-space($b[$labels[1]]), '^(Titre|Aut)', 'i')) then 'fr' else 'en',
        'titles': if (exists($ti)) then ($inline($ti)[.], $title-blocks ! normalize-unicode(normalize-space(.))) else (),
        'short': if (exists($si)) then ($inline($si)[.], $short-blocks ! normalize-unicode(normalize-space(.)))[1] else (),
        'authors': if (exists($ai))
                   then ($inline($ai)[.] ! map{'line': .},
                         for $block in $author-blocks[not(nucma:is-sub-label(.))]
                         return
                           let $resp := ($author-blocks[. &lt;&lt; $block][nucma:is-sub-label(.)])[last()]
                           return (if ($block/self::tei:list) then $block/tei:item else $block)
                                  ! map{'line': normalize-unicode(normalize-space(.)),
                                        'resp': $resp ! replace(normalize-unicode(normalize-space(.)), '[\s\p{Zs}]*:$', '')})
                   else (),
        'blocks': ($b[position() = $labels], $title-blocks, $short-blocks, $author-blocks)
      }"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Key used to compare names: lower case, without diacritics, with straight
      apostrophes and single spaces (<xd:i>Ève-Lyne Beaudry</xd:i> →
      <xd:i>eve-lyne beaudry</xd:i>).</xd:desc>
    <xd:param name="name">A personal name.</xd:param>
  </xd:doc>
  <xsl:function name="nucma:name-key" as="xs:string">
    <xsl:param name="name" as="xs:string"/>
    <xsl:sequence select="normalize-space(lower-case(
      replace(normalize-unicode($name, 'NFD'), '\p{Mn}', '') => translate('’', '''')))"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Identifier part made from a title: lower case, without diacritics, words
      joined by hyphens (<xd:i>Garde partagée</xd:i> → <xd:i>garde-partagee</xd:i>).</xd:desc>
    <xd:param name="title">A title.</xd:param>
  </xd:doc>
  <xsl:function name="nucma:slug" as="xs:string">
    <xsl:param name="title" as="xs:string"/>
    <xsl:sequence select="nucma:name-key($title) => replace('[^a-z0-9]+', '-') => replace('^-|-$', '')"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Persons of meta/authors.xml, by name key.</xd:desc>
  </xd:doc>
  <xsl:key name="nucma:person-by-name" match="tei:person"
    use="nucma:name-key(string-join((tei:persName/tei:forename, tei:persName/tei:surname), ' '))"/>

  <xd:doc>
    <xd:desc>Reads a line of the author list.</xd:desc>
    <xd:param name="line">A line: <xd:i>Name, role, affiliation</xd:i>, possibly preceded by
      a typed bullet. The first segment is the name, the last one the affiliation, and
      anything in between the role (which may itself contain commas).</xd:param>
    <xd:return>A map: <xd:i>name</xd:i>, <xd:i>role</xd:i>, <xd:i>affiliation</xd:i>, and
      <xd:i>person</xd:i>, the matching person of <xd:i>meta/authors.xml</xd:i> (authors and
      other contributors) if any.</xd:return>
  </xd:doc>
  <xsl:function name="nucma:person-line" as="map(*)">
    <xsl:param name="line" as="xs:string"/>
    <xsl:variable name="parts" select="tokenize(replace($line, $nucma:re-bullet, ''), '\s*,\s*')[normalize-space()]"/>
    <xsl:sequence select="map{
      'name': $parts[1],
      'role': string-join($parts[position() gt 1 and position() lt last()], ', '),
      'affiliation': if (count($parts) gt 1) then $parts[last()] else '',
      'person': if ($nucma:authors) then key('nucma:person-by-name', nucma:name-key($parts[1]), $nucma:authors)[1] else ()}"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Forename and surname of a person: from <xd:i>meta/authors.xml</xd:i> when the
      person is found there, otherwise the last word of the name as the surname.</xd:desc>
    <xd:param name="person-line">A map returned by
      <xd:ref name="nucma:person-line" type="function"/>.</xd:param>
  </xd:doc>
  <xsl:function name="nucma:name-parts" as="element()+">
    <xsl:param name="person-line" as="map(*)"/>
    <xsl:choose>
      <xsl:when test="exists($person-line?person)">
        <xsl:sequence select="$person-line?person/tei:persName/(tei:forename | tei:surname)"/>
      </xsl:when>
      <xsl:otherwise>
        <forename><xsl:value-of select="replace($person-line?name, '\s+\S+$', '')"/></forename>
        <surname><xsl:value-of select="replace($person-line?name, '^.*\s', '')"/></surname>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xd:doc>
    <xd:desc>An author of the entry.</xd:desc>
    <xd:param name="line">A line of the author list (see
      <xd:ref name="nucma:person-line" type="function"/>).</xd:param>
    <xd:return>An <xd:i>author</xd:i>. When the name is found in
      <xd:i>meta/authors.xml</xd:i>, the author points to the person
      (<xd:i>@ref</xd:i>) and takes its forename, surname, identifiers (ORCID…) and, if the
      line has none, its affiliation. Otherwise an <xd:i>@todo</xd:i> comment asks to check
      the forename and surname.</xd:return>
  </xd:doc>
  <xsl:function name="nucma:author" as="element()">
    <xsl:param name="line" as="xs:string"/>
    <xsl:variable name="p" select="nucma:person-line($line)"/>
    <author>
      <xsl:if test="exists($p?person)">
        <xsl:attribute name="ref" select="'#' || $p?person/@xml:id"/>
      </xsl:if>
      <persName>
        <xsl:sequence select="nucma:name-parts($p)"/>
      </persName>
      <xsl:if test="$p?role">
        <roleName><xsl:value-of select="$p?role"/></roleName>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="$p?affiliation">
          <affiliation><xsl:value-of select="$p?affiliation"/></affiliation>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$p?person//tei:affiliation[1]"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:sequence select="$p?person//tei:idno[normalize-space()]"/>
      <xsl:if test="empty($p?person)">
        <xsl:comment> @todo vérifier le prénom et le nom ; auteur absent de meta/authors.xml </xsl:comment>
      </xsl:if>
    </author>
  </xsl:function>

  <xd:doc>
    <xd:desc>A contributor listed under a sub-label (« Research Assistant: »), in the form
      used by the corpus for the other responsibilities:
      <xd:i>&lt;respStmt ref="#…"&gt;&lt;resp&gt;Research Assistant&lt;/resp&gt;&lt;persName&gt;…&lt;/persName&gt;&lt;/respStmt&gt;</xd:i>.
      Contributors are looked up in <xd:i>meta/authors.xml</xd:i> too (list « Autres
      contributeurs »). The role goes in <xd:i>persName/roleName</xd:i> and the affiliation
      in <xd:i>orgName</xd:i>, the forms allowed in <xd:i>respStmt</xd:i>.</xd:desc>
    <xd:param name="line">A line of the author list (see
      <xd:ref name="nucma:person-line" type="function"/>).</xd:param>
    <xd:param name="resp">The sub-label, without its colon.</xd:param>
  </xd:doc>
  <xsl:function name="nucma:resp-stmt" as="element()">
    <xsl:param name="line" as="xs:string"/>
    <xsl:param name="resp" as="xs:string"/>
    <xsl:variable name="p" select="nucma:person-line($line)"/>
    <respStmt>
      <xsl:if test="exists($p?person)">
        <xsl:attribute name="ref" select="'#' || $p?person/@xml:id"/>
      </xsl:if>
      <resp><xsl:value-of select="$resp"/></resp>
      <persName>
        <xsl:sequence select="nucma:name-parts($p)"/>
        <xsl:if test="$p?role">
          <roleName><xsl:value-of select="$p?role"/></roleName>
        </xsl:if>
      </persName>
      <xsl:if test="$p?affiliation">
        <orgName><xsl:value-of select="$p?affiliation"/></orgName>
      </xsl:if>
      <xsl:if test="empty($p?person)">
        <xsl:comment> @todo vérifier le prénom et le nom ; personne absente de meta/authors.xml </xsl:comment>
      </xsl:if>
    </respStmt>
  </xsl:function>

  <xd:doc>
    <xd:desc>Publication statement of the NUCMA model, followed by the series statement
      (the chapter comes from <xd:ref name="nucma-chapter" type="parameter"/>). DOI to be
      added when available.</xd:desc>
  </xd:doc>
  <xsl:template mode="nucma:header" match="tei:fileDesc/tei:publicationStmt">
    <xsl:param name="front" tunnel="yes" as="map(*)"/>
    <xsl:choose>
      <xsl:when test="exists($front?lang)">
        <xsl:variable name="model" select="$nucma:header-model($front?lang)"/>
        <publicationStmt>
          <publisher><xsl:value-of select="$model?publisher"/></publisher>
          <date when="{year-from-date(current-date())}"><xsl:value-of select="year-from-date(current-date())"/></date>
          <xsl:comment> @todo &lt;idno type="DOI"&gt;…&lt;/idno&gt; </xsl:comment>
          <availability>
            <licence target="https://creativecommons.org/licenses/by/4.0/">
              <p><xsl:value-of select="$model?licence"/></p>
            </licence>
          </availability>
        </publicationStmt>
        <seriesStmt>
          <title xml:lang="{$front?lang}" type="main">
            <xsl:value-of select="$model?chapter || upper-case(substring($nucma-chapter, 1, 1)) || substring($nucma-chapter, 2)"/>
          </title>
          <title xml:lang="{$front?lang}" type="sub"><xsl:value-of select="$model?series"/></title>
          <idno type="URI">http://www.nucma.ca</idno>
          <xsl:comment> @todo &lt;idno type="DOI"&gt;…&lt;/idno&gt; </xsl:comment>
        </seriesStmt>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xd:doc>
    <xd:desc>Revision description: the change written by docxtotei.xsl (date and
      <xd:i>unknown author</xd:i>) is replaced with a dated note in the form used by the
      corpus: <xd:i>&lt;change when="2026-10-01" resp="#ECD"&gt;Conversion depuis Word (profil
      nucma)&lt;/change&gt;</xd:i>, in the language of the entry (French by default); see
      <xd:ref name="nucma-resp" type="parameter"/>.</xd:desc>
  </xd:doc>
  <xsl:template mode="nucma:header" match="tei:teiHeader/tei:revisionDesc">
    <xsl:param name="front" tunnel="yes" as="map(*)"/>
    <revisionDesc>
      <change when="{current-date() => format-date('[Y0001]-[M01]-[D01]')}" resp="#{$nucma-resp}">
        <xsl:value-of select="$nucma:header-model(($front?lang, 'fr')[1])?conversion"/>
      </change>
    </revisionDesc>
  </xsl:template>

  <xd:doc>
    <xd:desc>Drops the edition statement written by docxtotei.xsl (« unknown date »): the
      entries of the corpus have none.</xd:desc>
  </xd:doc>
  <xsl:template mode="nucma:header" match="tei:fileDesc/tei:editionStmt[contains(., 'unknown')]"/>

  <xd:doc>
    <xd:desc>Header of a document with front matter: a profile description with the
      language of the entry (<xd:i>langUsage</xd:i>) is added after the encoding
      description, when the header has none.</xd:desc>
  </xd:doc>
  <xsl:template mode="nucma:header" match="tei:teiHeader[not(tei:profileDesc)]">
    <xsl:param name="front" tunnel="yes" as="map(*)"/>
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates select="node()[not(self::tei:revisionDesc)]" mode="#current"/>
      <xsl:if test="exists($front?lang)">
        <profileDesc>
          <langUsage>
            <language ident="{$front?lang}"/>
          </langUsage>
        </profileDesc>
      </xsl:if>
      <xsl:apply-templates select="tei:revisionDesc" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xd:doc>
    <xd:desc>Language of the entry on <xd:i>text</xd:i>, read from the labels of the front
      matter; <xd:i>normalization.xsl</xd:i> then applies the typography of that
      language.</xd:desc>
  </xd:doc>
  <xsl:template mode="nucma:header" match="tei:TEI/tei:text">
    <xsl:param name="front" tunnel="yes" as="map(*)"/>
    <xsl:copy>
      <xsl:if test="exists($front?lang)">
        <xsl:attribute name="xml:lang" select="$front?lang"/>
      </xsl:if>
      <xsl:apply-templates select="@* except @xml:lang[exists($front?lang)] | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xd:doc>
    <xd:desc>Title statement made from the front matter: one <xd:i>title</xd:i> without
      type, or a <xd:i>main</xd:i> title and a <xd:i>sub</xd:i>title; then the authors.
      Left unchanged when the document has no front matter.</xd:desc>
  </xd:doc>
  <xsl:template mode="nucma:header" match="tei:titleStmt">
    <xsl:param name="front" tunnel="yes" as="map(*)"/>
    <xsl:choose>
      <xsl:when test="exists($front?titles) or exists($front?authors)">
        <xsl:copy>
          <xsl:for-each select="$front?titles">
            <title>
              <xsl:if test="count($front?titles) gt 1">
                <xsl:attribute name="type" select="if (position() = 1) then 'main' else 'sub'"/>
              </xsl:if>
              <xsl:value-of select="."/>
            </title>
          </xsl:for-each>
          <xsl:sequence select="$front?authors[empty(?resp)] ! nucma:author(?line)"/>
          <xsl:sequence select="$front?authors[exists(?resp)] ! nucma:resp-stmt(?line, ?resp)"/>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xd:doc>
    <xd:desc>Identifier of the entry on <xd:i>sourceDesc</xd:i>:
      <xd:i>nucma.{language}.{chapter}.{short title}</xd:i>
      (<xd:i>nucma.fr.acquisition.variabilite</xd:i>), see
      <xd:ref name="nucma-chapter" type="parameter"/>; the entry title is used when there is
      no short title. Its content is the source description of the NUCMA model.</xd:desc>
  </xd:doc>
  <xsl:template mode="nucma:header" match="tei:sourceDesc">
    <xsl:param name="front" tunnel="yes" as="map(*)"/>
    <xsl:variable name="name" select="($front?short, $front?titles)[1]"/>
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:if test="$name">
        <xsl:attribute name="xml:id"
          select="string-join(('nucma', $front?lang, $nucma-chapter, nucma:slug($name)), '.')"/>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="exists($front?lang)">
          <p><xsl:value-of select="$nucma:header-model($front?lang)?source"/></p>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <xd:doc>
    <xd:desc>Drops the front-matter blocks from the body: they are now in the
      header.</xd:desc>
  </xd:doc>
  <xsl:template mode="nucma:header" match="tei:p | tei:head | tei:list">
    <xsl:param name="front" tunnel="yes" as="map(*)"/>
    <xsl:if test="not(some $block in $front?blocks satisfies $block is .)">
      <xsl:next-match/>
    </xsl:if>
  </xsl:template>

  <xd:doc>
    <xd:desc>Drops a division left empty once its front-matter blocks are removed (a
      division that only held the entry title as a heading).</xd:desc>
  </xd:doc>
  <xsl:template mode="nucma:header" match="tei:body//tei:div[*][not(text()[normalize-space()])]">
    <xsl:param name="front" tunnel="yes" as="map(*)"/>
    <xsl:if test="exists(*[not(some $block in $front?blocks satisfies $block is .)])">
      <xsl:next-match/>
    </xsl:if>
  </xsl:template>


  <!-- ================================================================ -->
  <!-- 3. nucma:boundary-spaces: no-break spaces around phrase elements -->
  <!-- ================================================================ -->

  <xd:doc>
    <xd:desc>Tells whether an element is a phrase element (see
      <xd:ref name="nucma:phrase-elements" type="variable"/>); superscripts and small capitals,
      which belong to ordinals and centuries, are excluded.</xd:desc>
    <xd:param name="element">Any element.</xd:param>
  </xd:doc>
  <xsl:function name="nucma:is-phrase" as="xs:boolean">
    <xsl:param name="element" as="element()"/>
    <xsl:sequence select="local-name($element) = $nucma:phrase-elements
      and not(tokenize($element/@rend) = ('superscript', 'sup', 'smallcaps'))"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Replaces with an ordinary space a no-break space left between a word and a
      phrase element:
      <xd:ul>
        <xd:li>after the element, before a letter (<xd:i>&lt;/q&gt;⍽est</xd:i>), unless the
          element ends with a digit or a period (<xd:i>10⍽cm</xd:i>,
          <xd:i>M.⍽Dupont</xd:i>);</xd:li>
        <xd:li>after a letter, before the element (<xd:i>et⍽&lt;q&gt;</xd:i>), unless the
          word is a title.</xd:li>
      </xd:ul>
      No-break spaces before punctuation are kept.</xd:desc>
  </xd:doc>
  <xsl:template mode="nucma:boundary-spaces"
    match="text()[not(ancestor::*[local-name() = $nucma:protected-elements])]">
    <xsl:variable name="after-phrase" select="exists(preceding-sibling::node()[1][self::*]
      [nucma:is-phrase(.)][not(matches(string(.), '[\p{N}.]$'))])"/>
    <xsl:variable name="before-phrase" select="exists(following-sibling::node()[1][self::*]
      [nucma:is-phrase(.)])"/>
    <xsl:variable name="start" select="
      if ($after-phrase) then replace(., '^' || $nucma:re-nbsp || '(\p{L})', ' $1') else string(.)"/>
    <xsl:value-of select="
      if ($before-phrase
          and not(matches($start, '(^|[^\p{L}])' || $nucma:re-title || $nucma:re-nbsp || '$')))
      then replace($start, '(\p{L})' || $nucma:re-nbsp || '$', '$1 ')
      else $start"/>
  </xsl:template>


  <!-- ================================================================ -->
  <!-- 4. nucma:notes: notes gathered in the back matter                -->
  <!-- ================================================================ -->

  <xd:doc>
    <xd:desc>Tells whether a note is to be moved to the back matter: a note of the text
      (footnote, endnote…), except comments, notes nested in another note and notes already
      in <xd:i>div[@type='notes']</xd:i>.</xd:desc>
    <xd:param name="note">A <xd:i>note</xd:i> element.</xd:param>
  </xd:doc>
  <xsl:function name="nucma:is-movable-note" as="xs:boolean">
    <xsl:param name="note" as="element()"/>
    <xsl:sequence select="exists($note/ancestor::tei:text)
      and not($note/@place = 'comment')
      and not($note/ancestor::tei:note)
      and not($note/ancestor::tei:div[@type = 'notes'])"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Number of a note to be moved.</xd:desc>
    <xd:param name="note">A note to be moved.</xd:param>
    <xd:return>Its <xd:i>@n</xd:i> if it is an integer, otherwise its position among the
      notes to be moved.</xd:return>
  </xd:doc>
  <xsl:function name="nucma:note-number" as="xs:integer">
    <xsl:param name="note" as="element()"/>
    <xsl:sequence select="
      if ($note/@n castable as xs:integer) then xs:integer($note/@n)
      else count($note/preceding::tei:note[nucma:is-movable-note(.)]) + 1"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Identifier of a moved note, shared by the note and its call.</xd:desc>
    <xd:param name="note">A note to be moved.</xd:param>
    <xd:return><xd:i>note</xd:i> followed by its number on two digits (<xd:i>note01</xd:i>),
      replacing the identifier given by Word (<xd:i>ftn0</xd:i>); a suffix is added if that
      identifier is already used in the document.</xd:return>
  </xd:doc>
  <xsl:function name="nucma:note-id" as="xs:string">
    <xsl:param name="note" as="element()"/>
    <xsl:variable name="id" select="'note' || format-integer(nucma:note-number($note), '00')"/>
    <xsl:sequence select="
      if (root($note)//*[@xml:id = $id] except $note) then $id || '-' || generate-id($note)
      else $id"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Notes to be moved, by their former identifier.</xd:desc>
  </xd:doc>
  <xsl:key name="nucma:movable-note-by-id" match="tei:note[@xml:id][nucma:is-movable-note(.)]" use="@xml:id"/>

  <xd:doc>
    <xd:desc>Replaces a note of the text with a call that points to it:
      <xd:i>&lt;ref type="note" target="#note01"&gt;1&lt;/ref&gt;</xd:i>.</xd:desc>
  </xd:doc>
  <xsl:template mode="nucma:notes" match="tei:note[nucma:is-movable-note(.)]">
    <ref type="note" target="#{nucma:note-id(.)}">
      <xsl:value-of select="(@n, nucma:note-number(.))[1]"/>
    </ref>
  </xsl:template>

  <xd:doc>
    <xd:desc>Updates a reference to the former identifier of a moved note
      (<xd:i>#ftn0</xd:i> → <xd:i>#note01</xd:i>).</xd:desc>
  </xd:doc>
  <xsl:template mode="nucma:notes"
    match="@target[starts-with(., '#')][key('nucma:movable-note-by-id', substring(., 2))]">
    <xsl:attribute name="target" select="'#' || nucma:note-id(key('nucma:movable-note-by-id', substring(., 2))[1])"/>
  </xsl:template>

  <xd:doc>
    <xd:desc>Text with notes to move and no back matter: a back matter holding the notes is
      added after the body.</xd:desc>
  </xd:doc>
  <xsl:template mode="nucma:notes" match="tei:text[not(tei:back)][.//tei:note[nucma:is-movable-note(.)]]">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
      <back>
        <div type="notes">
          <xsl:apply-templates select=".//tei:note[nucma:is-movable-note(.)]" mode="nucma:notes-content"/>
        </div>
      </back>
    </xsl:copy>
  </xsl:template>

  <xd:doc>
    <xd:desc>Back matter without a notes division: the division is added at its start.</xd:desc>
  </xd:doc>
  <xsl:template mode="nucma:notes"
    match="tei:text/tei:back[not(tei:div[@type = 'notes'])][..//tei:note[nucma:is-movable-note(.)]]">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <div type="notes">
        <xsl:apply-templates select="..//tei:note[nucma:is-movable-note(.)]" mode="nucma:notes-content"/>
      </div>
      <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xd:doc>
    <xd:desc>Existing notes division: the new notes are appended to it.</xd:desc>
  </xd:doc>
  <xsl:template mode="nucma:notes"
    match="tei:text/tei:back/tei:div[@type = 'notes'][../..//tei:note[nucma:is-movable-note(.)]]">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
      <xsl:apply-templates select="../..//tei:note[nucma:is-movable-note(.)]" mode="nucma:notes-content"/>
    </xsl:copy>
  </xsl:template>

  <xd:doc>
    <xd:desc>A moved note: its attributes, its new identifier, and its content in one or
      more paragraphs: the blocks listed in <xd:ref name="nucma:note-blocks" type="variable"/>
      are kept, any other run of content (text, inline elements) is wrapped in a
      <xd:i>p</xd:i>.</xd:desc>
  </xd:doc>
  <xsl:template mode="nucma:notes-content" match="tei:note">
    <xsl:copy>
      <xsl:apply-templates select="@* except @xml:id" mode="nucma:notes"/>
      <xsl:attribute name="xml:id" select="nucma:note-id(.)"/>
      <xsl:for-each-group select="node()" group-adjacent="local-name() = $nucma:note-blocks">
        <xsl:choose>
          <xsl:when test="current-grouping-key() or not(normalize-space(string-join(current-group())))">
            <xsl:apply-templates select="current-group()" mode="nucma:notes"/>
          </xsl:when>
          <xsl:otherwise>
            <p><xsl:apply-templates select="current-group()" mode="nucma:notes"/></p>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
