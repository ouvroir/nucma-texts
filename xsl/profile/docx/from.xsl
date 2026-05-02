<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.tei-c.org/ns/1.0"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                xmlns:iso="http://www.iso.org/ns/1.0"
                xmlns:ve="http://schemas.openxmlformats.org/markup-compatibility/2006"
                xmlns:o="urn:schemas-microsoft-com:office:office"
                xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
                xmlns:rel="http://schemas.openxmlformats.org/package/2006/relationships"
                xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"
                xmlns:v="urn:schemas-microsoft-com:vml"
                xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
                xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
                xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"
                xmlns:w10="urn:schemas-microsoft-com:office:word"
                xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
                xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml"
                xmlns:mml="http://www.w3.org/1998/Math/MathML"
		xmlns:html="http://www.w3.org/1999/xhtml"
		xmlns:its="http://www.w3.org/2005/11/its"
                xmlns:tbx="http://www.lisa.org/TBX-Specification.33.0.html"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:nucma="https://nucma.ca/ns"
                version="3.0"
                exclude-result-prefixes="#all">
    <!-- import base conversion style -->

    <xsl:import href="../../../docx/from/docxtotei.xsl"/>
    
  <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet" type="stylesheet">
    <desc>
      <p> TEI stylesheet for simplifying TEI ODD markup </p>
      <p>This software is dual-licensed:

1. Distributed under a Creative Commons Attribution-ShareAlike 3.0
Unported License http://creativecommons.org/licenses/by-sa/3.0/ 

2. http://www.opensource.org/licenses/BSD-2-Clause
		


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

This software is provided by the copyright holders and contributors
"as is" and any express or implied warranties, including, but not
limited to, the implied warranties of merchantability and fitness for
a particular purpose are disclaimed. In no event shall the copyright
holder or contributors be liable for any direct, indirect, incidental,
special, exemplary, or consequential damages (including, but not
limited to, procurement of substitute goods or services; loss of use,
data, or profits; or business interruption) however caused and on any
theory of liability, whether in contract, strict liability, or tort
(including negligence or otherwise) arising in any way out of the use
of this software, even if advised of the possibility of such damage.
</p>
      <p>Author: See AUTHORS</p>
      
      <p>Copyright: 2013, TEI Consortium</p>
    </desc>
  </doc>
    

    <xsl:template match="@rend[.='Body Text']" mode="pass2"/>
    <xsl:template match="@rend[.='Body Text 2']" mode="pass2"/>
    <xsl:template match="@rend[.='Body Text 3']" mode="pass2"/>
    <xsl:template match="@rend[.='Text Body']" mode="pass2"/>
    <xsl:template match="@rend[.='Text body']" mode="pass2"/>
    <xsl:template match="@rend[.='Body Text Indent']" mode="pass2"/>


    <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>Indented output, overriding indent="no" in docxtotei.xsl, so that the converted
        file is readable and its later changes give readable diffs. Elements with mixed
        content are not indented: no whitespace is added inside the text.</desc>
    </doc>
    <xsl:output method="xml" encoding="UTF-8" indent="yes"
      suppress-indentation="tei:p tei:head tei:hi tei:q tei:note tei:item tei:cell tei:title
        tei:label tei:quote tei:l tei:ab tei:bibl tei:ref tei:foreign tei:soCalled tei:term
        tei:emph tei:mentioned tei:persName tei:orgName tei:placeName tei:name tei:date
        tei:author tei:editor tei:resp tei:licence tei:change tei:desc tei:gloss tei:seg"/>


    <!-- ============================================================== -->
    <!-- NUCMA: cleanup of the conversion artefacts                     -->
    <!-- Same rules as xsl/nettoyage-import.xsl, applied to the TEI     -->
    <!-- produced by docxtotei.xsl. Mode and variable names are in the  -->
    <!-- nucma namespace, so as not to clash with the TEI Stylesheets.  -->
    <!-- ============================================================== -->

    <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>Runs the conversion of docxtotei.xsl, then the two NUCMA cleanup modes
        (nucma:cleanup, nucma:boundary-spaces), each one on a new tree, so that the text
        around an unwrapped element is merged before the spaces are checked.</desc>
    </doc>
    <xsl:template match="/">
      <xsl:variable name="converted">
        <xsl:apply-imports/>
      </xsl:variable>
      <xsl:variable name="cleaned">
        <xsl:apply-templates select="$converted" mode="nucma:cleanup"/>
      </xsl:variable>
      <xsl:apply-templates select="$cleaned" mode="nucma:boundary-spaces"/>
    </xsl:template>

    <xsl:mode name="nucma:cleanup" on-no-match="shallow-copy"/>
    <xsl:mode name="nucma:boundary-spaces" on-no-match="shallow-copy"/>

    <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>CSS properties inherited from the word processor and dropped from @style: the
        font is set by the publication, not by the text.</desc>
    </doc>
    <xsl:variable name="nucma:dropped-style-properties" as="xs:string+" select="('font-family', 'font-size')"/>

    <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>Inline elements that replace quotation marks or mark a phrase. The word processor
        puts a no-break space inside guillemets; when the guillemets are converted into these
        elements, that space is left between the element and the next or previous word.</desc>
    </doc>
    <xsl:variable name="nucma:phrase-elements" as="xs:string+"
      select="('q', 'soCalled', 'title', 'foreign', 'mentioned', 'term', 'emph', 'hi')"/>

    <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>Elements whose text is never modified: identifiers and addresses.</desc>
    </doc>
    <xsl:variable name="nucma:protected-elements" as="xs:string+" select="('idno', 'ptr', 'code', 'email')"/>

    <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>Regular expression for a no-break space: U+00A0 or U+202F.</desc>
    </doc>
    <xsl:variable name="nucma:re-nbsp" select="'[&#xA0;&#x202F;]'"/>

    <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>Regular expression for the French and English titles that justify a no-break
        space before a name (M., MM., Mme, Mlle, Mgr, Me, Dr, Pr, Mr, Mrs, Ms, Prof., St.).</desc>
    </doc>
    <xsl:variable name="nucma:re-title"
      select="'(?:MM\.|M\.|Mmes|Mme|Mlles|Mlle|Mgr|Me|Dr\.?|Pr\.?|Mrs\.?|Mr\.?|Ms\.?|Prof\.|St\.)'"/>

    <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>Removes the dropped properties from a CSS declaration list
        (font-family:Helvetica Neue;font-size:12pt;color:red → color:red).</desc>
    </doc>
    <xsl:function name="nucma:clean-style" as="xs:string">
      <xsl:param name="style" as="xs:string"/>
      <xsl:sequence select="string-join(
        tokenize($style, ';')[normalize-space()]
          [not(lower-case(normalize-space(substring-before(., ':'))) = $nucma:dropped-style-properties)]
          ! normalize-space(.),
        ';')"/>
    </xsl:function>

    <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>Tells whether an element is a phrase element whose surrounding no-break spaces
        come from converted guillemets (superscripts and small capitals excluded).</desc>
    </doc>
    <xsl:function name="nucma:is-phrase" as="xs:boolean">
      <xsl:param name="element" as="element()"/>
      <xsl:sequence select="local-name($element) = $nucma:phrase-elements
        and not(tokenize($element/@rend) = ('superscript', 'sup', 'smallcaps'))"/>
    </xsl:function>

    <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>Unwraps hi elements that carry no rendition once their style is cleaned, or no
        attribute at all.</desc>
    </doc>
    <xsl:template mode="nucma:cleanup"
      match="tei:hi[not(@* except (@style, @xml:space))][nucma:clean-style(string(@style)) = '']">
      <xsl:apply-templates mode="#current"/>
    </xsl:template>

    <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>Unwraps whitespace-only hi elements; the whitespace merges with the surrounding
        text.</desc>
    </doc>
    <xsl:template mode="nucma:cleanup" priority="1" match="tei:hi[not(*)][matches(., '^[\s\p{Zs}]+$')]">
      <xsl:apply-templates mode="#current"/>
    </xsl:template>

    <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>Removes the font family and size from @style; the attribute is dropped when
        nothing remains.</desc>
    </doc>
    <xsl:template mode="nucma:cleanup" match="@style">
      <xsl:variable name="style" select="nucma:clean-style(.)"/>
      <xsl:if test="$style">
        <xsl:attribute name="style" select="$style"/>
      </xsl:if>
    </xsl:template>

    <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>Drops @xml:space="preserve" left by the conversion.</desc>
    </doc>
    <xsl:template mode="nucma:cleanup" match="@xml:space[. = 'preserve']"/>

    <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>Replaces with an ordinary space a no-break space left between a word and a phrase
        element: after the element and before a letter (unless the element ends with a digit
        or a period: 10 cm, M. Dupont), or after a letter and before the element (unless the
        word is a title). No-break spaces before punctuation are kept.</desc>
    </doc>
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
</xsl:stylesheet>
