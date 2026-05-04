<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.tei-c.org/ns/1.0"
  xpath-default-namespace="http://www.tei-c.org/ns/1.0"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:nucma="https://nucma.ca/ns"
  exclude-result-prefixes="xs xd nucma"
  version="3.0">

  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Cleanup of NUCMA TEI texts after their conversion from a word
        processor.</xd:b></xd:p>
      <xd:p>Removes the artifacts of the conversion, which have nothing to do with the
        content: font family and size in <xd:i>@style</xd:i>, <xd:i>hi</xd:i> elements
        without rendition, <xd:i>@xml:space</xd:i>, layout attributes of
        <xd:i>graphic</xd:i>, anchors that nothing points to, empty headings,
        word-processor comments (turned into XML comments), the
        no-break spaces left by
        converted guillemets around phrase elements; and it gathers the notes in the back
        matter. Run it once after the import, before
        <xd:i>normalization.xsl</xd:i>, which only deals with Unicode and typography.</xd:p>
      <xd:p>The same rules are applied during the conversion by the <xd:i>nucma</xd:i>
        profile of the TEI Stylesheets (<xd:i>profile/docx/from.xsl</xd:i>): files converted
        with <xd:i>docxtotei --profile=nucma</xd:i> are already clean. Any change to these
        rules must be made in both stylesheets.</xd:p>
      <xd:p>The transformation is a pipeline of three modes. Each one builds a temporary tree
        that the next one takes as input, so that the text around an unwrapped element is
        merged before the spaces are checked.</xd:p>
      <xd:ol>
        <xd:li><xd:b>cleanup</xd:b>: styles, <xd:i>hi</xd:i>, <xd:i>@xml:space</xd:i>,
          <xd:i>graphic</xd:i> attributes, anchors, empty headings, hyperlinks and
          comments;</xd:li>
        <xd:li><xd:b>boundary-spaces</xd:b>: no-break spaces around phrase elements;</xd:li>
        <xd:li><xd:b>notes</xd:b>: notes moved to <xd:i>back/div[@type='notes']</xd:i> and
          replaced by a note call.</xd:li>
      </xd:ol>
      <xd:p>The whole document is processed, bibliography included, except the text of
        identifiers and addresses (see <xd:ref name="protected-elements"
        type="variable"/>). The transformation is idempotent.</xd:p>
      <xd:p>Usage (Saxon 12; write to a temporary file, not to the source):</xd:p>
      <xd:pre>saxon -s:fr/acquisition/variabilite.xml -xsl:xsl/import-cleanup.xsl -o:variabilite.tmp</xd:pre>
      <xd:p><xd:b>Author:</xd:b> Emmanuel Château-Dutier</xd:p>
    </xd:desc>
  </xd:doc>

  <xd:doc>
    <xd:desc>Same output settings as <xd:i>normalization.xsl</xd:i>: no indentation, so that
      the source layout is kept and the files can be cleaned in place with readable
      diffs.</xd:desc>
  </xd:doc>
  <xsl:output method="xml" indent="no" encoding="UTF-8"/>

  <!-- Pipeline modes, in order of application; anything not matched is copied. -->
  <xsl:mode on-no-match="shallow-copy"/>
  <xsl:mode name="cleanup" on-no-match="shallow-copy"/>
  <xsl:mode name="boundary-spaces" on-no-match="shallow-copy"/>
  <xsl:mode name="notes" on-no-match="shallow-copy"/>


  <!-- ================================================================== -->
  <!-- Configuration                                                      -->
  <!-- ================================================================== -->

  <xd:doc>
    <xd:desc>CSS properties inherited from the word processor and dropped from
      <xd:i>@style</xd:i>: the font is set by the publication, not by the text.</xd:desc>
  </xd:doc>
  <xsl:variable name="dropped-style-properties" as="xs:string+" select="('font-family', 'font-size')"/>

  <xd:doc>
    <xd:desc>Inline elements that replace quotation marks or mark a phrase. The word
      processor puts a no-break space inside guillemets (« garde négociée »); when the
      guillemets were converted into these elements, that space was left between the
      element and the next or previous word, where nothing justifies it.</xd:desc>
  </xd:doc>
  <xsl:variable name="phrase-elements" as="xs:string+"
    select="('q', 'soCalled', 'title', 'foreign', 'mentioned', 'term', 'emph', 'hi')"/>

  <xd:doc>
    <xd:desc>Elements whose text is never modified: identifiers and addresses.</xd:desc>
  </xd:doc>
  <xsl:variable name="protected-elements" as="xs:string+" select="('idno', 'ptr', 'code', 'email')"/>

  <xd:doc>
    <xd:desc>Elements that may stand as blocks in a note; any other content of a note is
      wrapped in a paragraph.</xd:desc>
  </xd:doc>
  <xsl:variable name="note-blocks" as="xs:string+"
    select="('p', 'list', 'table', 'quote', 'lg', 'figure', 'ab', 'listBibl', 'bibl')"/>

  <xd:doc>
    <xd:desc>Regular expression for a no-break space: U+00A0 or U+202F.</xd:desc>
  </xd:doc>
  <xsl:variable name="re-nbsp" select="'[&#xA0;&#x202F;]'"/>

  <xd:doc>
    <xd:desc>Regular expression for the French and English titles that justify a no-break
      space before a name (M., MM., Mme, Mlle, Mgr, Me, Dr, Pr, Mr, Mrs, Ms, Prof., St.).
      The same list is used for both languages: a title is kept attached to the name in any
      case.</xd:desc>
  </xd:doc>
  <xsl:variable name="re-title"
    select="'(?:MM\.|M\.|Mmes|Mme|Mlles|Mlle|Mgr|Me|Dr\.?|Pr\.?|Mrs\.?|Mr\.?|Ms\.?|Prof\.|St\.)'"/>


  <!-- ================================================================== -->
  <!-- Utilities                                                          -->
  <!-- ================================================================== -->

  <xd:doc>
    <xd:desc>Removes the dropped properties from a CSS declaration list.</xd:desc>
    <xd:param name="style">The value of a <xd:i>@style</xd:i> attribute
      (<xd:i>font-family:Helvetica Neue;font-size:12pt;color:red</xd:i>).</xd:param>
    <xd:return>The remaining declarations, normalized and separated by
      <xd:i>;</xd:i> (<xd:i>color:red</xd:i>), or an empty string. See
      <xd:ref name="dropped-style-properties" type="variable"/>.</xd:return>
  </xd:doc>
  <xsl:function name="nucma:clean-style" as="xs:string">
    <xsl:param name="style" as="xs:string"/>
    <xsl:sequence select="string-join(
      tokenize($style, ';')[normalize-space()]
        [not(lower-case(normalize-space(substring-before(., ':'))) = $dropped-style-properties)]
        ! normalize-space(.),
      ';')"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Text of the XML comment that replaces a word-processor comment.</xd:desc>
    <xd:param name="note">A <xd:i>note[@place='comment']</xd:i>, with its author in
      <xd:i>@resp</xd:i> (<xd:i>#Josée_Desforges</xd:i>), its date in
      <xd:i>date/@when</xd:i> and its number in <xd:i>@n</xd:i>, which links it to the
      <xd:i>commentRangeStart</xd:i> and <xd:i>commentRangeEnd</xd:i> anchors.</xd:param>
    <xd:return>
      <xd:i> @todo Aux encodeur·euses : ne pas oublier de mettre ce lien [Josée Desforges,
        2026-05-25, sur « la pièce chorégraphique Trio A »] </xd:i>. Author, date and
      passage are left out when missing. Double hyphens, forbidden in XML comments, are
      separated.</xd:return>
  </xd:doc>
  <xsl:function name="nucma:todo-comment" as="xs:string">
    <xsl:param name="note" as="element()"/>
    <xsl:variable name="start" select="$note/preceding::anchor[@type = 'commentRangeStart'][@n = $note/@n][1]"/>
    <xsl:variable name="end" select="($note/preceding::anchor[@type = 'commentRangeEnd'][@n = $note/@n][1],
                                      $note/following::anchor[@type = 'commentRangeEnd'][@n = $note/@n][1])[1]"/>
    <xsl:variable name="passage" select="
      if ($start and $end)
      then normalize-space(string-join(root($note)//text()[. &gt;&gt; $start][. &lt;&lt; $end]
                                                         [not(ancestor::note[@place = 'comment'])]))
      else ''"/>
    <xsl:variable name="source" select="string-join((
      replace(substring-after($note/@resp, '#'), '_', ' ')[normalize-space()],
      substring($note/date/@when, 1, 10)[normalize-space()],
      ('sur « ' || $passage || ' »')[$passage]), ', ')"/>
    <xsl:variable name="text" select="(: the paragraphs of a comment are separated by a space :)
      normalize-space(string-join($note/(node() except date) ! string(.), ' '))
      || (if ($source) then ' [' || $source || ']' else '')"/>
    <xsl:sequence select="' @todo ' || replace($text, '--', '- -') => replace('--', '- -') => replace('-$', '- ') || ' '"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Tells whether a note is to be moved to the back matter.</xd:desc>
    <xd:param name="note">A <xd:i>note</xd:i> element.</xd:param>
    <xd:return>True for a note of the text (footnote, endnote…), except comments, notes
      nested in another note and notes already in <xd:i>div[@type='notes']</xd:i>.</xd:return>
  </xd:doc>
  <xsl:function name="nucma:is-movable-note" as="xs:boolean">
    <xsl:param name="note" as="element()"/>
    <xsl:sequence select="exists($note/ancestor::text)
      and not($note/@place = 'comment')
      and not($note/ancestor::note)
      and not($note/ancestor::div[@type = 'notes'])"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Identifier of a moved note, shared by the note and its call.</xd:desc>
    <xd:param name="note">A note to be moved.</xd:param>
    <xd:return><xd:i>note</xd:i> followed by the number of the note on two digits
      (<xd:i>@n</xd:i>, or its position among the notes to move): <xd:i>note01</xd:i>,
      <xd:i>note02</xd:i>… The former identifier (<xd:i>ftn0</xd:i>) is replaced; if the new
      one is already used in the document, a suffix makes it unique.</xd:return>
  </xd:doc>
  <xsl:function name="nucma:note-id" as="xs:string">
    <xsl:param name="note" as="element()"/>
    <xsl:variable name="number" select="
      if ($note/@n castable as xs:integer) then xs:integer($note/@n)
      else count($note/preceding::note[nucma:is-movable-note(.)]) + 1"/>
    <xsl:variable name="id" select="'note' || format-integer($number, '00')"/>
    <xsl:sequence select="
      if (root($note)//*[@xml:id = $id] except $note) then $id || '-' || generate-id($note)
      else $id"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Tells whether an element is a phrase element whose surrounding no-break spaces
      come from converted guillemets.</xd:desc>
    <xd:param name="element">Any element.</xd:param>
    <xd:return>True for the elements listed in
      <xd:ref name="phrase-elements" type="variable"/>, except superscripts and small
      capitals, which belong to ordinals and centuries.</xd:return>
  </xd:doc>
  <xsl:function name="nucma:is-phrase" as="xs:boolean">
    <xsl:param name="element" as="element()"/>
    <xsl:sequence select="local-name($element) = $phrase-elements
      and not(tokenize($element/@rend) = ('superscript', 'sup', 'smallcaps'))"/>
  </xsl:function>


  <!-- ================================================================== -->
  <!-- Pipeline                                                           -->
  <!-- ================================================================== -->

  <xd:doc>
    <xd:desc>Chains the three modes: cleanup, boundary-spaces, notes.</xd:desc>
  </xd:doc>
  <xsl:template match="/">
    <xsl:variable name="cleaned">
      <xsl:apply-templates mode="cleanup"/>
    </xsl:variable>
    <xsl:variable name="spaced">
      <xsl:apply-templates select="$cleaned" mode="boundary-spaces"/>
    </xsl:variable>
    <!-- the line breaks between the top-level nodes (XML declaration, comments, processing
         instructions, root element) are not part of the tree: they are written back -->
    <xsl:for-each select="$spaced/node()">
      <xsl:text>&#10;</xsl:text>
      <xsl:apply-templates select="." mode="notes"/>
    </xsl:for-each>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>


  <!-- ================================================================== -->
  <!-- 1. cleanup: word-processor artifacts, hyperlinks, comments        -->
  <!-- ================================================================== -->

  <xd:doc>
    <xd:desc>Unwraps <xd:i>hi</xd:i> elements that carry no rendition once their style is
      cleaned (<xd:i>&lt;hi style="font-family:Helvetica Neue;font-size:12pt"&gt;</xd:i>, or
      no attribute at all).</xd:desc>
  </xd:doc>
  <xsl:template mode="cleanup"
    match="hi[not(@* except (@style, @xml:space))][nucma:clean-style(string(@style)) = '']">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xd:doc>
    <xd:desc>Unwraps whitespace-only <xd:i>hi</xd:i> and <xd:i>seg</xd:i> elements
      (<xd:i>&lt;seg&gt;  &lt;/seg&gt;</xd:i> after a note call). The whitespace is reduced
      to a single space (or to nothing if the neighbouring text already has one) and merges
      with the surrounding text, so that the typography of
      <xd:i>normalization.xsl</xd:i> can fix
      <xd:i>contemporain&lt;hi&gt; &lt;/hi&gt;?</xd:i>.</xd:desc>
  </xd:doc>
  <xsl:template mode="cleanup" priority="1" match="(hi | seg)[not(*)][matches(., '^[\s\p{Zs}]+$')]">
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
  <xsl:template mode="cleanup" match="@style">
    <xsl:variable name="style" select="nucma:clean-style(.)"/>
    <xsl:if test="$style">
      <xsl:attribute name="style" select="$style"/>
    </xsl:if>
  </xsl:template>

  <xd:doc>
    <xd:desc>Drops <xd:i>@xml:space="preserve"</xd:i> left by the conversion.</xd:desc>
  </xd:doc>
  <xsl:template mode="cleanup" match="@xml:space[. = 'preserve']"/>

  <xd:doc>
    <xd:desc>Drops the layout attributes of <xd:i>graphic</xd:i> set by the word processor
      (<xd:i>@n</xd:i>, <xd:i>@width</xd:i>, <xd:i>@height</xd:i>, <xd:i>@rend</xd:i>): the
      size and placement of images are set by the publication.</xd:desc>
  </xd:doc>
  <xsl:template mode="cleanup" match="graphic/@n | graphic/@width | graphic/@height | graphic/@rend"/>

  <xd:doc>
    <xd:desc>Replaces a word-processor comment (<xd:i>note[@place='comment']</xd:i>) with an
      XML comment at the same place, that is just after the commented passage:
      <xd:i>&lt;!-- @todo text [author, date, sur « commented passage »] --&gt;</xd:i>. See
      <xd:ref name="nucma:todo-comment" type="function"/>.</xd:desc>
  </xd:doc>
  <xsl:template mode="cleanup" match="note[@place = 'comment']">
    <xsl:comment select="nucma:todo-comment(.)"/>
  </xsl:template>

  <xd:doc>
    <xd:desc>Drops the anchors left by the word processor that nothing points to: the
      anchors that delimit the passage of a comment (quoted in the XML comment that replaces
      the note, which is built from the source tree, so before they are dropped) and the
      bookmarks (<xd:i>&lt;anchor xml:id="2z3fk6gdwmkd"/&gt;</xd:i>). An anchor that is the
      target of a link (<xd:i>#id</xd:i>) is kept.</xd:desc>
  </xd:doc>
  <xsl:template mode="cleanup" match="anchor[nucma:is-dropped-anchor(.)]"/>

  <xd:doc>
    <xd:desc>Tells whether an anchor is dropped: nothing points to it.</xd:desc>
    <xd:param name="anchor">An <xd:i>anchor</xd:i> element.</xd:param>
  </xd:doc>
  <xsl:function name="nucma:is-dropped-anchor" as="xs:boolean">
    <xsl:param name="anchor" as="element()"/>
    <xsl:sequence select="not($anchor/@xml:id and root($anchor)//@*[. = '#' || $anchor/@xml:id])"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Drops the empty headings of the word processor: no text, and no element other
      than dropped anchors.</xd:desc>
  </xd:doc>
  <xsl:template mode="cleanup"
    match="head[not(normalize-space())][every $e in * satisfies $e/self::anchor[nucma:is-dropped-anchor(.)]]"/>

  <xd:doc>
    <xd:desc>Hyperlinks: <xd:i>@type="external"</xd:i> on a <xd:i>ref</xd:i> whose target is
      a web or e-mail address (<xd:i>http(s):</xd:i>, <xd:i>ftp:</xd:i>,
      <xd:i>mailto:</xd:i>, <xd:i>www.</xd:i>), unless it already has a type. Links to the
      encyclopedia itself (<xd:i>nucma.ca</xd:i> and its subdomains) are left untyped: they
      are cross-references between entries, not external links.</xd:desc>
  </xd:doc>
  <xsl:template mode="cleanup" match="ref[not(@type)][matches(@target, '^(https?:|ftp:|mailto:|www\.)', 'i')]
      [not(matches(@target, '^(https?://)?([a-z0-9-]+\.)*nucma\.ca([/:?#]|$)', 'i'))]">
    <xsl:copy>
      <xsl:attribute name="type" select="'external'"/>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>


  <!-- ================================================================== -->
  <!-- 2. boundary-spaces: no-break spaces around phrase elements         -->
  <!-- ================================================================== -->

  <xd:doc>
    <xd:desc>
      <xd:p>Replaces with an ordinary space a no-break space (U+00A0 or U+202F) left between
        a word and a phrase element (see <xd:ref name="phrase-elements" type="variable"/>):</xd:p>
      <xd:ul>
        <xd:li>at the start of a text node, after a phrase element and before a letter
          (<xd:i>&lt;/q&gt;⍽est</xd:i> → <xd:i>&lt;/q&gt; est</xd:i>), unless the element
          ends with a digit or a period (<xd:i>&lt;hi&gt;10&lt;/hi&gt;⍽cm</xd:i>,
          <xd:i>&lt;hi&gt;M.&lt;/hi&gt;⍽Dupont</xd:i>);</xd:li>
        <xd:li>at the end of a text node, after a letter and before a phrase element
          (<xd:i>et⍽&lt;q&gt;</xd:i> → <xd:i>et &lt;q&gt;</xd:i>), unless the word is a
          title (see <xd:ref name="re-title" type="variable"/>).</xd:li>
      </xd:ul>
      <xd:p>No-break spaces before punctuation, after an abbreviation or a number are
        kept.</xd:p>
    </xd:desc>
  </xd:doc>
  <xsl:template mode="boundary-spaces"
    match="text()[not(ancestor::*[local-name() = $protected-elements])]">
    <xsl:variable name="after-phrase" select="exists(preceding-sibling::node()[1][self::*]
      [nucma:is-phrase(.)][not(matches(string(.), '[\p{N}.]$'))])"/>
    <xsl:variable name="before-phrase" select="exists(following-sibling::node()[1][self::*]
      [nucma:is-phrase(.)])"/>
    <xsl:variable name="start" select="
      if ($after-phrase) then replace(., '^' || $re-nbsp || '(\p{L})', ' $1') else string(.)"/>
    <xsl:value-of select="
      if ($before-phrase and not(matches($start, '(^|[^\p{L}])' || $re-title || $re-nbsp || '$')))
      then replace($start, '(\p{L})' || $re-nbsp || '$', '$1 ')
      else $start"/>
  </xsl:template>


  <!-- ================================================================== -->
  <!-- 3. notes: notes gathered in the back matter                        -->
  <!-- ================================================================== -->

  <xd:doc>
    <xd:desc>Notes to be moved, by their former identifier.</xd:desc>
  </xd:doc>
  <xsl:key name="movable-note-by-id" match="note[nucma:is-movable-note(.)][@xml:id]" use="@xml:id"/>

  <xd:doc>
    <xd:desc>Updates a reference to the former identifier of a moved note
      (<xd:i>#ftn0</xd:i> → <xd:i>#note01</xd:i>).</xd:desc>
  </xd:doc>
  <xsl:template mode="notes"
    match="@target[starts-with(., '#')][key('movable-note-by-id', substring(., 2))]">
    <xsl:attribute name="target" select="'#' || nucma:note-id(key('movable-note-by-id', substring(., 2))[1])"/>
  </xsl:template>

  <xd:doc>
    <xd:desc>Replaces a note of the text with a note call that points to it:
      <xd:i>&lt;ref type="note" target="#ftn0"&gt;1&lt;/ref&gt;</xd:i>. The call shows the
      number of the note (<xd:i>@n</xd:i>, or its position).</xd:desc>
  </xd:doc>
  <xsl:template mode="notes" match="note[nucma:is-movable-note(.)]">
    <ref type="note" target="#{nucma:note-id(.)}">
      <xsl:value-of select="(@n, count(preceding::note[nucma:is-movable-note(.)]) + 1)[1]"/>
    </ref>
  </xsl:template>

  <xd:doc>
    <xd:desc>Adds a back matter after the body, holding the notes, when the text has notes
      to move and no back matter.</xd:desc>
  </xd:doc>
  <xsl:template mode="notes" match="text[not(back)][.//note[nucma:is-movable-note(.)]]">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
      <back>
        <xsl:call-template name="notes-div">
          <xsl:with-param name="text" select="."/>
        </xsl:call-template>
      </back>
      <xsl:text>&#10;</xsl:text>
    </xsl:copy>
  </xsl:template>

  <xd:doc>
    <xd:desc>Adds the notes division at the start of an existing back matter, when it has
      none yet.</xd:desc>
  </xd:doc>
  <xsl:template mode="notes"
    match="text/back[not(div[@type = 'notes'])][..//note[nucma:is-movable-note(.)]]">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:call-template name="notes-div">
        <xsl:with-param name="text" select="parent::text"/>
      </xsl:call-template>
      <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xd:doc>
    <xd:desc>Appends the new notes to an existing notes division.</xd:desc>
  </xd:doc>
  <xsl:template mode="notes"
    match="text/back/div[@type = 'notes'][ancestor::text[1]//note[nucma:is-movable-note(.)]]">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
      <xsl:apply-templates select="ancestor::text[1]//note[nucma:is-movable-note(.)]"
        mode="notes-content"/>
    </xsl:copy>
  </xsl:template>

  <xd:doc>
    <xd:desc>The notes division: <xd:i>&lt;div type="notes"&gt;</xd:i> holding the notes of
      the text, in document order.</xd:desc>
    <xd:param name="text">The <xd:i>text</xd:i> element whose notes are moved.</xd:param>
  </xd:doc>
  <xsl:template name="notes-div">
    <xsl:param name="text" as="element()"/>
    <div type="notes">
      <xsl:apply-templates select="$text//note[nucma:is-movable-note(.)]" mode="notes-content"/>
      <xsl:text>&#10;</xsl:text>
    </div>
  </xsl:template>

  <xd:doc>
    <xd:desc>A moved note: its attributes, a valid identifier (see
      <xd:ref name="nucma:note-id" type="function"/>), and its content in one or more
      paragraphs: the blocks listed in <xd:ref name="note-blocks" type="variable"/> are kept,
      and any other run of content (text, inline elements) is wrapped in a
      <xd:i>p</xd:i>.</xd:desc>
  </xd:doc>
  <xsl:template mode="notes-content" match="note">
    <xsl:text>&#10;</xsl:text>
    <xsl:copy>
      <xsl:apply-templates select="@* except @xml:id" mode="notes"/>
      <xsl:attribute name="xml:id" select="nucma:note-id(.)"/>
      <xsl:for-each-group select="node()" group-adjacent="local-name() = $note-blocks">
        <xsl:choose>
          <xsl:when test="current-grouping-key() or not(normalize-space(string-join(current-group())))">
            <xsl:apply-templates select="current-group()" mode="notes"/>
          </xsl:when>
          <xsl:otherwise>
            <p><xsl:apply-templates select="current-group()" mode="notes"/></p>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
