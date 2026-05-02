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
      <xd:p>Removes the artefacts of the conversion, which have nothing to do with the
        content: font family and size in <xd:i>@style</xd:i>, <xd:i>hi</xd:i> elements
        without rendition, <xd:i>@xml:space</xd:i>, and the no-break spaces left by
        converted guillemets around phrase elements. Run it once after the import, before
        <xd:i>normalisation.xsl</xd:i>, which only deals with Unicode and typography.</xd:p>
      <xd:p>The same rules are applied during the conversion by the <xd:i>nucma</xd:i>
        profile of the TEI Stylesheets (<xd:i>profile/docx/from.xsl</xd:i>): files converted
        with <xd:i>docxtotei --profile=nucma</xd:i> are already clean. Any change to these
        rules must be made in both stylesheets.</xd:p>
      <xd:p>The transformation is a pipeline of two modes. Each one builds a temporary tree
        that the next one takes as input, so that the text around an unwrapped element is
        merged before the spaces are checked.</xd:p>
      <xd:ol>
        <xd:li><xd:b>cleanup</xd:b>: styles, <xd:i>hi</xd:i> and
          <xd:i>@xml:space</xd:i>;</xd:li>
        <xd:li><xd:b>boundary-spaces</xd:b>: no-break spaces around phrase elements.</xd:li>
      </xd:ol>
      <xd:p>The whole document is processed, bibliography included, except the text of
        identifiers and addresses (see <xd:ref name="protected-elements"
        type="variable"/>). The transformation is idempotent.</xd:p>
      <xd:p>Usage (Saxon 12; write to a temporary file, not to the source):</xd:p>
      <xd:pre>saxon -s:fr/acquisition/variabilite.xml -xsl:xsl/nettoyage-import.xsl -o:variabilite.tmp</xd:pre>
      <xd:p><xd:b>Author:</xd:b> Emmanuel Château-Dutier</xd:p>
    </xd:desc>
  </xd:doc>

  <xd:doc>
    <xd:desc>Same output settings as <xd:i>normalisation.xsl</xd:i>: no indentation, so that
      the source layout is kept and the files can be cleaned in place with readable
      diffs.</xd:desc>
  </xd:doc>
  <xsl:output method="xml" indent="no" encoding="UTF-8"/>

  <!-- Pipeline modes, in order of application; anything not matched is copied. -->
  <xsl:mode on-no-match="shallow-copy"/>
  <xsl:mode name="cleanup" on-no-match="shallow-copy"/>
  <xsl:mode name="boundary-spaces" on-no-match="shallow-copy"/>


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
    <xd:return>The remaining declarations, normalised and separated by
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
    <xd:desc>Chains the two modes: cleanup, boundary-spaces.</xd:desc>
  </xd:doc>
  <xsl:template match="/">
    <xsl:variable name="cleaned">
      <xsl:apply-templates mode="cleanup"/>
    </xsl:variable>
    <!-- the line breaks between the top-level nodes (XML declaration, comments, processing
         instructions, root element) are not part of the tree: they are written back -->
    <xsl:for-each select="$cleaned/node()">
      <xsl:text>&#10;</xsl:text>
      <xsl:apply-templates select="." mode="boundary-spaces"/>
    </xsl:for-each>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>


  <!-- ================================================================== -->
  <!-- 1. cleanup: styles, hi and xml:space                               -->
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
    <xd:desc>Unwraps whitespace-only <xd:i>hi</xd:i> elements. The whitespace is kept and
      merges with the surrounding text, so that the typography of
      <xd:i>normalisation.xsl</xd:i> can fix
      <xd:i>contemporain&lt;hi&gt; &lt;/hi&gt;?</xd:i>.</xd:desc>
  </xd:doc>
  <xsl:template mode="cleanup" priority="1" match="hi[not(*)][matches(., '^[\s\p{Zs}]+$')]">
    <xsl:apply-templates mode="#current"/>
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
</xsl:stylesheet>
