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
      <xd:p><xd:b>Normalisation of NUCMA TEI texts</xd:b> (French and English).</xd:p>
      <xd:p>The transformation is a pipeline of four modes. Each one builds a temporary tree
        that the next one takes as input, so that adjacent text nodes are merged between
        steps.</xd:p>
      <xd:ol>
        <xd:li><xd:b>nfc</xd:b>: Unicode NFC normalisation of every text node and attribute
          (decomposed characters such as <xd:i>e</xd:i> + U+0301 become
          <xd:i>é</xd:i>).</xd:li>
        <xd:li><xd:b>cleanup</xd:b>: removal of word-processor artefacts (font family and
          size in <xd:i>@style</xd:i>, empty or whitespace-only <xd:i>hi</xd:i>,
          <xd:i>@xml:space</xd:i>).</xd:li>
        <xd:li><xd:b>unwrap-ordinals</xd:b>: ordinal superscripts
          (<xd:i>XVIII&lt;hi rend="superscript"&gt;e&lt;/hi&gt;</xd:i>) are folded into the
          text, so that the next step sees every ordinal as a single string.</xd:li>
        <xd:li><xd:b>typography</xd:b>: language-dependent typography, chosen from the nearest
          <xd:i>@xml:lang</xd:i>:
          <xd:ul>
            <xd:li>French and English: typographic apostrophe (<xd:i>l'art</xd:i> →
              l’art), en dash in numeric ranges (<xd:i>1914-1918</xd:i> → 1914–1918),
              no-break spaces after locators and titles (p. 45–52, t. II, M. Dupont) and
              before units (12 cm), ellipsis (<xd:i>...</xd:i> → …), straight double quotes
              turned into typographic quotes according to their nesting level.</xd:li>
            <xd:li>French (Imprimerie nationale): œ ligature (<xd:i>oeuvre</xd:i> → œuvre),
              digit grouping with U+202F (<xd:i>10 000</xd:i>, <xd:i>10.000</xd:i> → 10 000),
              no-break space before %, € and $, times (10 h 30), numéro with a superscript
              (n&lt;hi rend="superscript"&gt;o&lt;/hi&gt;),
              narrow no-break space (U+202F) before <xd:i>; ! ?</xd:i>, no-break space
              (U+00A0) before <xd:i>:</xd:i> and inside guillemets, « » then “ ” for nested
              quotes, en dash for parentheticals (mot – incise – suite), ordinals and
              centuries (xviiiᵉ siècle).</xd:li>
            <xd:li>English: opening single quote and elided decades (‘word’, the ’60s), no
              space before punctuation, “ ” then ‘ ’ for nested quotes, commas and periods
              inside closing quotes, closed em dash for parentheticals (word—word), digit
              grouping with commas (10,000), currency before the amount (€10), times (10:30,
              10 a.m.), unsuperscripted ordinals with a
              computed suffix (1st, 2nd, 3rd, 18th century).</xd:li>
            <xd:li>Other languages (lat, de…): left unchanged.</xd:li>
          </xd:ul>
        </xd:li>
      </xd:ol>
      <xd:p>Steps 3 and 4 only apply to nodes in scope (see
        <xd:ref name="nucma:in-scope" type="function"/>): identifiers (<xd:i>idno</xd:i>,
        <xd:i>ptr</xd:i>, <xd:i>code</xd:i>) and, unless
        <xd:ref name="process-bibliography" type="parameter"/> is set, the bibliography are
        left out. URLs, attributes, comments and processing instructions are never altered
        except by NFC normalisation.</xd:p>
      <xd:p>The transformation is idempotent: running it twice gives the same result.
        Missing spaces are added, but a space split across two text nodes cannot be
        detected.</xd:p>
      <xd:p>Usage (Saxon 12):</xd:p>
      <xd:pre>saxon -s:fr/acquisition/variabilite.xml -xsl:xsl/normalisation.xsl -o:out.xml
saxon -s:en/acquisition/Variability.xml -xsl:xsl/normalisation.xsl '?en-centuries-in-words=true()'</xd:pre>
      <xd:p><xd:b>Author:</xd:b> Emmanuel Château-Dutier</xd:p>
    </xd:desc>
  </xd:doc>

  <xd:doc>
    <xd:desc>No indentation, and no whitespace stripping: the source layout is kept as is,
      so that the files can be normalised in place with readable diffs. Line breaks inside
      start tags are not preserved by the XML serialiser.</xd:desc>
  </xd:doc>
  <xsl:output method="xml" indent="no" encoding="UTF-8"/>

  <xd:doc>
    <xd:desc>The source document is required: <xd:ref name="default-lang" type="parameter"/>
      is computed from it.</xd:desc>
  </xd:doc>
  <xsl:global-context-item as="document-node()" use="required"/>

  <!-- Pipeline modes, in order of application; anything not matched is copied. -->
  <xsl:mode on-no-match="shallow-copy"/>
  <xsl:mode name="nfc" on-no-match="shallow-copy"/>
  <xsl:mode name="cleanup" on-no-match="shallow-copy"/>
  <xsl:mode name="unwrap-ordinals" on-no-match="shallow-copy"/>
  <xsl:mode name="typography" on-no-match="shallow-copy"/>


  <!-- ================================================================== -->
  <!-- Parameters                                                         -->
  <!-- ================================================================== -->

  <xd:doc>
    <xd:desc>Document language, used when no <xd:i>@xml:lang</xd:i> is inherited. Defaults
      to <xd:i>TEI/@xml:lang</xd:i>, then <xd:i>profileDesc/langUsage/language/@ident</xd:i>,
      then the folder of the source file (<xd:i>…/en/…</xd:i> → <xd:i>en</xd:i>, otherwise
      <xd:i>fr</xd:i>). Adding <xd:i>@xml:lang</xd:i> to every <xd:i>TEI</xd:i> element is
      more reliable than relying on the folder.</xd:desc>
  </xd:doc>
  <xsl:param name="default-lang" as="xs:string" select="
    string((/TEI/@xml:lang,
            /TEI/teiHeader/profileDesc/langUsage/language[1]/@ident,
            if (contains(base-uri(/), '/en/')) then 'en' else 'fr')[1])"/>

  <xd:doc>
    <xd:desc>
      <xd:p>Also processes the bibliography (<xd:i>div[@type='bibliography']</xd:i>):
        spaces, ordinals and centuries. Defaults to <xd:i>false()</xd:i>, because
        bibliographic records contain titles in other languages and separators
        (<xd:i>Paris : Seuil</xd:i>) best handled in the reference manager.</xd:p>
      <xd:p>The bibliography is normalised to NFC in any case.</xd:p>
    </xd:desc>
  </xd:doc>
  <xsl:param name="process-bibliography" as="xs:boolean" select="false()"/>

  <xd:doc>
    <xd:desc>
      <xd:p>French: small capitals for the Roman numerals of centuries, as recommended by
        the Imprimerie nationale: <xd:i>&lt;hi rend="smallcaps"&gt;xviii&lt;/hi&gt;&lt;hi
        rend="superscript"&gt;e&lt;/hi&gt; siècle</xd:i>.</xd:p>
      <xd:p>Set to <xd:i>false()</xd:i> to keep capitals:
        <xd:i>XVIII&lt;hi rend="superscript"&gt;e&lt;/hi&gt; siècle</xd:i>.</xd:p>
    </xd:desc>
  </xd:doc>
  <xsl:param name="fr-centuries-small-caps" as="xs:boolean" select="true()"/>

  <xd:doc>
    <xd:desc>English: puts ordinal suffixes in superscript
      (<xd:i>18&lt;hi rend="superscript"&gt;th&lt;/hi&gt;</xd:i>). Defaults to
      <xd:i>false()</xd:i>, following the Chicago Manual of Style and Oxford usage
      (<xd:i>18th</xd:i>).</xd:desc>
  </xd:doc>
  <xsl:param name="en-ordinals-superscript" as="xs:boolean" select="false()"/>

  <xd:doc>
    <xd:desc>English: spells out centuries, as recommended by the Chicago Manual of Style
      (<xd:i>18th century</xd:i> → <xd:i>eighteenth century</xd:i>,
      <xd:i>21st-century</xd:i> → <xd:i>twenty-first-century</xd:i>). Takes precedence over
      <xd:ref name="en-ordinals-superscript" type="parameter"/> for centuries. A century at
      the start of a sentence is not capitalised.</xd:desc>
  </xd:doc>
  <xsl:param name="en-centuries-in-words" as="xs:boolean" select="false()"/>

  <xd:doc>
    <xd:desc>English: puts commas and periods inside closing quotation marks (American usage,
      Chicago Manual of Style): <xd:i>“hello”,</xd:i> → “hello,”. Colons and semicolons stay
      outside. Set to <xd:i>false()</xd:i> for British (logical) usage.</xd:desc>
  </xd:doc>
  <xsl:param name="en-punctuation-inside-quotes" as="xs:boolean" select="true()"/>

  <xd:doc>
    <xd:desc>French: uses a narrow no-break space (U+202F) inside guillemets instead of a
      no-break space (U+00A0), as many publishers do for screen and print
      (« mot » with a thinner space). Defaults to <xd:i>false()</xd:i>, following the
      Imprimerie nationale.</xd:desc>
  </xd:doc>
  <xsl:param name="fr-guillemets-narrow-space" as="xs:boolean" select="false()"/>


  <!-- ================================================================== -->
  <!-- Regular expressions (strings, prefixed with re-)                   -->
  <!-- ================================================================== -->

  <xd:doc>
    <xd:desc>Any space: XML whitespace (<xd:i>\s</xd:i>) and Unicode space separators
      (<xd:i>\p{Zs}</xd:i>: U+00A0, U+2009, U+202F…). Note that <xd:i>\s</xd:i> alone does
      not match U+00A0 in XPath.</xd:desc>
  </xd:doc>
  <xsl:variable name="re-space" select="'[\s\p{Zs}]'"/>

  <xd:doc>
    <xd:desc>A character that may directly precede high punctuation when a space is missing:
      letter, digit, closing bracket or quote, ellipsis. Other punctuation is excluded, so
      that <xd:i>?!</xd:i> stays together.</xd:desc>
  </xd:doc>
  <xsl:variable name="re-before-punct" select="'([\p{L}\p{N}\)\]’”…])'"/>

  <xd:doc>
    <xd:desc>A typewriter apostrophe: straight apostrophe (U+0027) or modifier letter
      apostrophe (U+02BC).</xd:desc>
  </xd:doc>
  <xsl:variable name="re-apostrophe" as="xs:string">['ʼ]</xsl:variable>

  <xd:doc>
    <xd:desc>A character wrongly used as an apostrophe between two letters: opening single
      quote (U+2018), acute accent (U+00B4) or grave accent (U+0060).</xd:desc>
  </xd:doc>
  <xsl:variable name="re-misused-apostrophe" as="xs:string">[‘´`]</xsl:variable>

  <xd:doc>
    <xd:desc>French word stems written with <xd:i>oe</xd:i> instead of the <xd:i>œ</xd:i>
      ligature (case-insensitive). Only listed stems are changed, so that
      <xd:i>coefficient</xd:i>, <xd:i>coexister</xd:i>, <xd:i>moelle</xd:i> or
      <xd:i>Noël</xd:i> are kept: œuvre (chef-d’œuvre, manœuvre, désœuvré), œil (œillet),
      œuf (bœuf), cœur (chœur, rancœur, écœurant), sœur, mœurs, nœud, vœu, fœtus, œsophage,
      œcuménique, œdème, Œdipe, œnologie, œstrogène.</xd:desc>
  </xd:doc>
  <xsl:variable name="re-oe-stems" select="'oeuvr|oeil|oeuf|coeur|choeur|soeur|moeur|noeud|voeu|foet|oesophag|oecum|oed[eè]m|oedip|oenolog|oestr'"/>

  <xd:doc>
    <xd:desc>A dash-like character used between two numbers: hyphen-minus, hyphen (U+2010),
      non-breaking hyphen (U+2011), figure dash (U+2012), en dash (U+2013) or em dash
      (U+2014).</xd:desc>
  </xd:doc>
  <xsl:variable name="re-range-dash" select="'[\-‐‑‒–—]'"/>

  <xd:doc>
    <xd:desc>
      <xd:p>A range of two numbers (pages, years, values). Groups:</xd:p>
      <xd:ol>
        <xd:li>the preceding boundary character;</xd:li>
        <xd:li>the first number;</xd:li>
        <xd:li>the second number;</xd:li>
        <xd:li>the following boundary character.</xd:li>
      </xd:ol>
      <xd:p>The boundaries exclude letters, digits, dashes, slashes and decimal separators,
        so that chains of three numbers or more (ISO dates <xd:i>2026-01-20</xd:i>, ISBN,
        telephone numbers), decimals (<xd:i>1,5-2,5</xd:i>) and codes
        (<xd:i>COVID-19</xd:i>, <xd:i>A4-5</xd:i>) are left unchanged.</xd:p>
    </xd:desc>
  </xd:doc>
  <xsl:variable name="re-number-range" select="
    '(^|[^\p{L}\p{N}/.,\-‐‑‒–—])(\d+)' || $re-space || '*' || $re-range-dash || $re-space
    || '*(\d+)([^\p{N}\-‐‑‒–—]|$)'"/>

  <xd:doc>
    <xd:desc>Locator abbreviations followed by a number (case-insensitive): p., pp., fig.,
      figs., vol., vols., t. (tome), ch., chap., col., pl., ill., cat., art. (article),
      n. (note), n°, nº, n°s, no.</xd:desc>
  </xd:doc>
  <xsl:variable name="re-locator" select="'(?:pp?|figs?|vols?|t|ch|chap|col|pl|ill|cat|art|n|no)\.|n[°º]s?'"/>

  <xd:doc>
    <xd:desc>Locator abbreviations that may be followed by a Roman numeral in capitals:
      t. (tome), vol., vols., ch., chap., liv. (livre), part., pl. (<xd:i>t. II</xd:i>,
      <xd:i>chap. XII</xd:i>).</xd:desc>
  </xd:doc>
  <xsl:variable name="re-locator-roman" select="'(?:[Tt]|[Vv]ols?|[Cc]h|[Cc]hap|[Ll]iv|[Pp]art|[Pp]l)\.'"/>

  <xd:doc>
    <xd:desc>French titles followed by a name: M., MM., Mme, Mmes, Mlle, Mlles, Mgr, Me
      (maître), Dr, Pr.</xd:desc>
  </xd:doc>
  <xsl:variable name="re-title-fr" select="'(?:MM\.|M\.|Mmes|Mme|Mlles|Mlle|Mgr|Me|Dr|Pr)'"/>

  <xd:doc>
    <xd:desc>English titles followed by a name: Mr, Mrs, Ms, Dr (with or without a period),
      Prof., St., and M. for French names.</xd:desc>
  </xd:doc>
  <xsl:variable name="re-title-en" select="'(?:Mrs\.?|Mr\.?|Ms\.?|Dr\.?|Prof\.|St\.|M\.)'"/>

  <xd:doc>
    <xd:desc>Unit symbols that cannot be mistaken for a word or a code: the no-break space
      is added even when the space is missing (<xd:i>12cm</xd:i> → 12 cm). Squares and
      cubes are included (m², cm³).</xd:desc>
  </xd:doc>
  <xsl:variable name="re-unit" select="'(?:mm|cm|dm|km|mg|kg|ml|cl|dl|[kKMGT]o|px|dpi|ppp|min|°C)[²³]?'"/>

  <xd:doc>
    <xd:desc>Short unit symbols, only handled when a space already separates them from the
      number, so that <xd:i>1980s</xd:i>, <xd:i>4K</xd:i> or <xd:i>9h-17h</xd:i> are left
      unchanged: m, g, l, L, s, h, W, kW, V, Hz, kHz, MHz, GHz, pt.</xd:desc>
  </xd:doc>
  <xsl:variable name="re-short-unit" select="'(?:m|g|l|L|s|h|k?W|V|[kMG]?Hz|pt)[²³]?'"/>

  <xd:doc>
    <xd:desc>The characters that may separate thousands in the source: any space, and in
      French also a period (<xd:i>10.000</xd:i>), since the French decimal separator is the
      comma.</xd:desc>
  </xd:doc>
  <xsl:variable name="re-group-separator-fr" select="'(?:' || $re-space || '|\.)'"/>

  <xd:doc>
    <xd:desc>A dash used as a parenthetical or a pause, between two spaces: hyphen-minus,
      double hyphen, en dash or em dash.</xd:desc>
  </xd:doc>
  <xsl:variable name="re-spaced-dash" select="$re-space || '+(?:--?|–|—)' || $re-space || '+'"/>

  <xd:doc>
    <xd:desc>A character after which a straight double quote opens a quotation: space,
      opening bracket, opening quote, dash or slash.</xd:desc>
  </xd:doc>
  <xsl:variable name="re-before-opening-quote" select="'[\s\p{Zs}(\[{«“‘—–/\-]'"/>

  <xd:doc>
    <xd:desc>The elements within which quotation marks are paired. Text in a nested block
      (a <xd:i>note</xd:i> inside a <xd:i>p</xd:i>) is paired separately.</xd:desc>
  </xd:doc>
  <xsl:variable name="quote-blocks" as="xs:string+"
    select="('p', 'head', 'note', 'item', 'cell', 'quote', 'l', 'ab', 'bibl', 'label')"/>

  <xd:doc>
    <xd:desc>A URL in running text, left untouched by the typography step.</xd:desc>
  </xd:doc>
  <xsl:variable name="re-url" select="'https?://[^\s\p{Zs}]+'"/>

  <xd:doc>
    <xd:desc>A Roman numeral from I to XXXIX (centuries, republics…). C, L and M are excluded
      so that <xd:i>Ce</xd:i>, <xd:i>Le</xd:i> or <xd:i>Me</xd:i> are not taken for
      ordinals.</xd:desc>
  </xd:doc>
  <xsl:variable name="re-roman" select="'(?:X{1,3}(?:IX|IV|V?I{0,3})|IX|IV|V?I{1,3}|V)'"/>

  <xd:doc>
    <xd:desc>A Roman or Arabic number.</xd:desc>
  </xd:doc>
  <xsl:variable name="re-number" select="'(?:' || $re-roman || '|\d+)'"/>

  <xd:doc>
    <xd:desc>A century number: Roman, or Arabic of one or two digits.</xd:desc>
  </xd:doc>
  <xsl:variable name="re-century-number" select="'(?:' || $re-roman || '|\d{1,2})'"/>

  <xd:doc>
    <xd:desc>French ordinal suffixes, longest first, including the modifier-letter forms
      (ᵉ, ᵉʳ, ʳᵉ…), incorrect forms (ème, ième, è) and plurals.</xd:desc>
  </xd:doc>
  <xsl:variable name="re-suffix-fr" select="'(?:ièmes|ième|èmes|ème|emes|eme|ères|ère|ers|res|er|re|es|des|de|ds|d|è|e|ᵉʳˢ|ʳᵉˢ|ᵈᵉˢ|ᵈᵉ|ᵈˢ|ᵉʳ|ʳᵉ|ᵉˢ|ᵈ|ᵉ)'"/>

  <xd:doc>
    <xd:desc>English ordinal suffixes, including <xd:i>d</xd:i> (2d, 3d), modifier letters
      (ᵗʰ, ˢᵗ…) and French forms inherited from the translation (e, ème, er…), but not
      <xd:i>de</xd:i> or <xd:i>es</xd:i>, which are ambiguous in English.</xd:desc>
  </xd:doc>
  <xsl:variable name="re-suffix-en" select="'(?:st|nd|rd|th|d|ˢᵗ|ⁿᵈ|ʳᵈ|ᵗʰ|ièmes?|èmes?|emes?|ère|er|re|è|e|ᵉʳ|ʳᵉ|ᵉ)'"/>

  <xd:doc>
    <xd:desc>
      <xd:p>French ordinals. Groups:</xd:p>
      <xd:ol>
        <xd:li>the preceding boundary character;</xd:li>
        <xd:li>a series of century ordinals, joined by <xd:i>- – à au et ,</xd:i>;</xd:li>
        <xd:li><xd:i>siècle</xd:i>, <xd:i>siècles</xd:i> or <xd:i>s.</xd:i>;</xd:li>
        <xd:li>otherwise, an isolated number;</xd:li>
        <xd:li>its suffix;</xd:li>
        <xd:li>the following boundary character;</xd:li>
        <xd:li>otherwise, the <xd:i>n</xd:i> of <xd:i>n°</xd:i>, <xd:i>nº</xd:i> (numéro);</xd:li>
        <xd:li>its plural <xd:i>s</xd:i>, if any;</xd:li>
        <xd:li>the following boundary character.</xd:li>
      </xd:ol>
    </xd:desc>
  </xd:doc>
  <xsl:variable name="re-ordinals-fr" select="
    let $ordinal := $re-century-number || $re-suffix-fr
    return '(^|[^\p{L}\p{N}])(?:('
      || $ordinal || '(?:' || $re-space || '*(?:-|–|à|au|et|,)' || $re-space || '*' || $ordinal || ')*)'
      || $re-space || '+(siècles?|s\.)'
      || '|(' || $re-number || ')(' || $re-suffix-fr || ')([^\p{L}\p{N}]|$)'
      || '|([Nn])[°ºᵒ](s?)([^\p{L}]|$))'"/>

  <xd:doc>
    <xd:desc>
      <xd:p>English ordinals. Groups:</xd:p>
      <xd:ol>
        <xd:li>the preceding boundary character;</xd:li>
        <xd:li>a series of century ordinals, joined by
          <xd:i>- – to (the) and (the) ,</xd:i>;</xd:li>
        <xd:li>the separator before <xd:i>century</xd:i> (spaces or hyphen);</xd:li>
        <xd:li><xd:i>century</xd:i> or <xd:i>centuries</xd:i>;</xd:li>
        <xd:li>otherwise, an isolated Arabic number;</xd:li>
        <xd:li>its suffix;</xd:li>
        <xd:li>the following boundary character.</xd:li>
      </xd:ol>
    </xd:desc>
  </xd:doc>
  <xsl:variable name="re-ordinals-en" select="
    let $ordinal := $re-century-number || $re-suffix-en
    return '(^|[^\p{L}\p{N}])(?:('
      || $ordinal || '(?:' || $re-space || '*(?:-|–|(?:to|and)(?:' || $re-space || '+the)?|,)'
      || $re-space || '*' || $ordinal || ')*)'
      || '(' || $re-space || '+|-)(centur(?:y|ies))'
      || '|(\d+)(' || $re-suffix-en || ')([^\p{L}\p{N}]|$))'"/>


  <!-- ================================================================== -->
  <!-- Utilities                                                          -->
  <!-- ================================================================== -->

  <xd:doc>
    <xd:desc>Effective language of a node.</xd:desc>
    <xd:param name="node">Any node.</xd:param>
    <xd:return>The primary language subtag, lower-cased, of the nearest
      <xd:i>@xml:lang</xd:i>, or <xd:ref name="default-lang" type="parameter"/>
      (<xd:i>fr-CA</xd:i> → <xd:i>fr</xd:i>, <xd:i>en-GB</xd:i> → <xd:i>en</xd:i>).</xd:return>
  </xd:doc>
  <xsl:function name="nucma:lang" as="xs:string">
    <xsl:param name="node" as="node()"/>
    <xsl:sequence select="lower-case(replace(string(
      ($node/ancestor-or-self::*[@xml:lang][1]/@xml:lang, $default-lang)[1]), '-.*$', ''))"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Tells whether a node may be modified by the unwrap-ordinals and typography
      steps. The nfc and cleanup steps apply to the whole document.</xd:desc>
    <xd:param name="node">Any node.</xd:param>
    <xd:return>False inside identifiers (<xd:i>idno</xd:i>, <xd:i>ptr</xd:i>,
      <xd:i>code</xd:i>) and, unless <xd:ref name="process-bibliography" type="parameter"/>
      is set, inside the bibliography.</xd:return>
  </xd:doc>
  <xsl:function name="nucma:in-scope" as="xs:boolean">
    <xsl:param name="node" as="node()"/>
    <xsl:sequence select="
      not($node/ancestor-or-self::*[self::idno or self::ptr or self::code])
      and ($process-bibliography or not($node/ancestor::div[@type = 'bibliography']))"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>The block within which the quotation marks of a node are paired.</xd:desc>
    <xd:param name="node">Any node.</xd:param>
    <xd:return>The nearest ancestor listed in
      <xd:ref name="quote-blocks" type="variable"/>, if any.</xd:return>
  </xd:doc>
  <xsl:function name="nucma:quote-block" as="element()?">
    <xsl:param name="node" as="node()"/>
    <xsl:sequence select="$node/ancestor::*[local-name() = $quote-blocks][1]"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Tells whether an element directly follows a number (Roman or Arabic) at the end
      of the preceding text node.</xd:desc>
    <xd:param name="element">Typically a superscript <xd:i>hi</xd:i>.</xd:param>
  </xd:doc>
  <xsl:function name="nucma:follows-number" as="xs:boolean">
    <xsl:param name="element" as="element()"/>
    <xsl:sequence select="exists($element/preceding-sibling::node()[1][self::text()]
      [matches(., '(^|[^\p{L}\p{N}])' || $re-number || '$')])"/>
  </xsl:function>


  <!-- ================================================================== -->
  <!-- Pipeline                                                           -->
  <!-- ================================================================== -->

  <xd:doc>
    <xd:desc>Chains the four modes: nfc, cleanup, unwrap-ordinals, typography.</xd:desc>
  </xd:doc>
  <xsl:template match="/">
    <xsl:variable name="nfc">
      <xsl:apply-templates mode="nfc"/>
    </xsl:variable>
    <xsl:variable name="cleaned">
      <xsl:apply-templates select="$nfc" mode="cleanup"/>
    </xsl:variable>
    <xsl:variable name="unwrapped">
      <xsl:apply-templates select="$cleaned" mode="unwrap-ordinals"/>
    </xsl:variable>
    <!-- the line breaks between the top-level nodes (XML declaration, comments, processing
         instructions, root element) are not part of the tree: they are written back -->
    <xsl:for-each select="$unwrapped/node()">
      <xsl:text>&#10;</xsl:text>
      <xsl:apply-templates select="." mode="typography"/>
    </xsl:for-each>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>


  <!-- ================================================================== -->
  <!-- 1. nfc: Unicode normalisation                                      -->
  <!-- ================================================================== -->

  <xd:doc>
    <xd:desc>NFC normalisation of text nodes.</xd:desc>
  </xd:doc>
  <xsl:template match="text()" mode="nfc">
    <xsl:value-of select="normalize-unicode(., 'NFC')"/>
  </xsl:template>

  <xd:doc>
    <xd:desc>NFC normalisation of attribute values.</xd:desc>
  </xd:doc>
  <xsl:template match="@*" mode="nfc">
    <xsl:attribute name="{name()}" namespace="{namespace-uri()}" select="normalize-unicode(., 'NFC')"/>
  </xsl:template>


  <!-- ================================================================== -->
  <!-- 2. cleanup: word-processor artefacts                               -->
  <!-- ================================================================== -->

  <xd:doc>
    <xd:desc>CSS properties inherited from the word processor and dropped from
      <xd:i>@style</xd:i>: the font is set by the publication, not by the text.</xd:desc>
  </xd:doc>
  <xsl:variable name="dropped-style-properties" as="xs:string+" select="('font-family', 'font-size')"/>

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
      merges with the surrounding text, so that the typography step can fix
      <xd:i>contemporain&lt;hi&gt; &lt;/hi&gt;?</xd:i>.</xd:desc>
  </xd:doc>
  <xsl:template mode="cleanup" priority="1"
    match="hi[not(*)][matches(., '^' || $re-space || '+$')]">
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
  <!-- 3. unwrap-ordinals: superscripts folded into the text              -->
  <!-- ================================================================== -->

  <xd:doc>
    <xd:desc>
      <xd:p>French: an ordinal superscript following a number
        (<xd:i>XVIII&lt;hi rend="superscript"&gt;e&lt;/hi&gt;</xd:i>,
        <xd:i>3&lt;hi rend="sup"&gt;e&lt;/hi&gt;</xd:i>) is replaced with Unicode modifier
        letters (ᵉ, ʳ, ˢ, ᵈ), which merge with the preceding text. The typography step then
        handles every form in the same way (3e, 3ᵉ, 3ème, 3&lt;hi&gt;e&lt;/hi&gt;…), and
        restores the superscript if the result is not an ordinal.</xd:p>
    </xd:desc>
  </xd:doc>
  <xsl:template mode="unwrap-ordinals" match="hi
      [tokenize(@rend) = ('superscript', 'sup')][not(*)]
      [nucma:lang(.) = 'fr'][matches(., '^' || $re-suffix-fr || '$')]
      [nucma:follows-number(.)][nucma:in-scope(.)]">
    <xsl:value-of select="translate(nucma:canonical-suffix-fr(.), 'ersd', 'ᵉʳˢᵈ')"/>
  </xsl:template>

  <xd:doc>
    <xd:desc>English: the ordinal superscript is unwrapped
      (<xd:i>18&lt;hi rend="superscript"&gt;th&lt;/hi&gt;</xd:i> → <xd:i>18th</xd:i>); the
      typography step then recomputes the suffix.</xd:desc>
  </xd:doc>
  <xsl:template mode="unwrap-ordinals" match="hi
      [tokenize(@rend) = ('superscript', 'sup')][not(*)]
      [nucma:lang(.) = 'en'][matches(., '^' || $re-suffix-en || '$')]
      [nucma:follows-number(.)][nucma:in-scope(.)]">
    <xsl:value-of select="."/>
  </xsl:template>


  <!-- ================================================================== -->
  <!-- 4. typography: dispatch by language                                -->
  <!-- ================================================================== -->

  <xd:doc>
    <xd:desc>
      <xd:p>Sends each French or English text node in scope through the rules of its
        language, in this order: apostrophes, abbreviations, numbers, punctuation, quotes,
        ligatures (French), spacing, ordinals. Text in other languages is left
        unchanged.</xd:p>
      <xd:p>The nesting level of quotation marks at the start of the node is computed from
        the text that precedes it in the same block (see
        <xd:ref name="nucma:quote-block" type="function"/>), so that a quotation may span
        several elements.</xd:p>
      <xd:p>URLs found in the text are copied as is; only the text around them is
        processed.</xd:p>
    </xd:desc>
  </xd:doc>
  <xsl:template mode="typography" match="text()[nucma:lang(.) = ('fr', 'en')][nucma:in-scope(.)]">
    <xsl:variable name="lang" select="nucma:lang(.)"/>
    <xsl:variable name="after-element" select="exists(preceding-sibling::node()[1][self::*])"/>
    <xsl:variable name="before-element" select="exists(following-sibling::node()[1][self::*])"/>
    <xsl:variable name="block" select="nucma:quote-block(.)"/>
    <xsl:variable name="quote-depth" as="xs:integer" select="
      if (empty($block)) then 0
      else nucma:quotes(
        string-join($block//text()[. &lt;&lt; current()][nucma:quote-block(.) is $block]),
        $lang, 0, false(), false())?depth"/>
    <xsl:analyze-string select="." regex="{$re-url}">
      <xsl:matching-substring>
        <xsl:value-of select="."/>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <!-- only the first substring of the node can directly follow an element -->
        <xsl:variable name="follows-element" select="$after-element and position() = 1"/>
        <xsl:variable name="precedes-element" select="$before-element and position() = last()"/>
        <xsl:variable name="text" select="
          nucma:quotes(
            nucma:apostrophes(., $lang, $follows-element)
            => nucma:abbreviations($lang)
            => nucma:numbers($lang)
            => nucma:punctuation($lang, $follows-element),
            $lang, $quote-depth, $follows-element, $precedes-element)?text"/>
        <xsl:choose>
          <xsl:when test="$lang = 'fr'">
            <xsl:sequence select="$text
              => nucma:ligatures-fr()
              => nucma:spacing-fr($follows-element)
              => nucma:ordinals-fr()"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="$text
              => nucma:spacing-en()
              => nucma:ordinals-en()"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>


  <!-- ================================================================== -->
  <!-- 4a. Apostrophes, abbreviations, numbers, punctuation and quotes     -->
  <!-- ================================================================== -->

  <xd:doc>
    <xd:desc>Typographic apostrophes and single quotes.</xd:desc>
    <xd:param name="s">The text to process (contains no URL).</xd:param>
    <xd:param name="lang">The language of the text: <xd:i>fr</xd:i> or
      <xd:i>en</xd:i>.</xd:param>
    <xd:param name="after-element">True when the text node directly follows an element: a
      leading straight apostrophe is then an elision or a possessive
      (<xd:i>&lt;/hi&gt;'s</xd:i>), not an opening quote.</xd:param>
    <xd:return>The text with:
      <xd:ul>
        <xd:li>’ (U+2019) for any typewriter apostrophe following a letter or a digit
          (<xd:i>l'art</xd:i>, <xd:i>aujourd'hui</xd:i>, <xd:i>it's</xd:i>,
          <xd:i>artists'</xd:i>, <xd:i>1980's</xd:i>), which is also the closing single
          quote;</xd:li>
        <xd:li>’ for an opening quote or accent wrongly used between two letters
          (<xd:i>l‘art</xd:i>, <xd:i>l´art</xd:i>);</xd:li>
        <xd:li>in English only, ’ before an elided decade (<xd:i>the '60s</xd:i>) and ‘
          (U+2018) for an opening single quote (<xd:i>'word'</xd:i> → ‘word’). French
          opening straight quotes are left as they are: French uses guillemets.</xd:li>
      </xd:ul>
    </xd:return>
  </xd:doc>
  <xsl:function name="nucma:apostrophes" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:param name="lang" as="xs:string"/>
    <xsl:param name="after-element" as="xs:boolean"/>
    <xsl:variable name="common" select="
      (if ($after-element) then replace($s, '^' || $re-apostrophe || '(\p{L})', '’$1') else $s)
      (: after a letter or a digit: apostrophe or closing single quote :)
      => replace('([\p{L}\p{N}])' || $re-apostrophe, '$1’')
      (: wrong character between two letters :)
      => replace('(\p{L})' || $re-misused-apostrophe || '(\p{L})', '$1’$2')"/>
    <xsl:sequence select="
      if ($lang = 'en')
      then $common
        (: elided decade: the ’60s :)
        => replace('(^|[^\p{L}\p{N}])' || $re-apostrophe || '(\d{2}s?)([^\p{L}\p{N}]|$)', '$1’$2$3')
        (: opening single quote :)
        => replace('(^|[\s\p{Zs}(\[“—–-])' || $re-apostrophe || '(\p{L})', '$1‘$2')
      else $common"/>
  </xsl:function>


  <xd:doc>
    <xd:desc>No-break space after locators and titles (French and English).</xd:desc>
    <xd:param name="s">The text to process (contains no URL).</xd:param>
    <xd:param name="lang">The language of the text: <xd:i>fr</xd:i> or
      <xd:i>en</xd:i>.</xd:param>
    <xd:return>The text with a no-break space (U+00A0), added when missing, between:
      <xd:ul>
        <xd:li>a locator and its number (<xd:i>p.12</xd:i>, <xd:i>p. 12</xd:i> → p. 12;
          fig. 1, vol. 3, n° 16), see <xd:ref name="re-locator" type="variable"/>;</xd:li>
        <xd:li>a locator and a Roman numeral in capitals (t. II, chap. XII), see
          <xd:ref name="re-locator-roman" type="variable"/>;</xd:li>
        <xd:li>a title and a capitalised name (M. Dupont, Mme Martin, Dr Smith), see
          <xd:ref name="re-title-fr" type="variable"/> and
          <xd:ref name="re-title-en" type="variable"/>. Here the space is only made
          non-breaking, never added.</xd:li>
      </xd:ul>
    </xd:return>
  </xd:doc>
  <xsl:function name="nucma:abbreviations" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:param name="lang" as="xs:string"/>
    <xsl:sequence select="$s
      (: locator + number :)
      => replace('(^|[^\p{L}])(' || $re-locator || ')' || $re-space || '*(\d)', '$1$2&#xA0;$3', 'i')
      (: locator + Roman numeral :)
      => replace('(^|[^\p{L}])(' || $re-locator-roman || ')' || $re-space || '*([IVXLC]+)([^\p{L}\p{N}]|$)',
                 '$1$2&#xA0;$3$4')
      (: title + name :)
      => replace('(^|[^\p{L}])(' || (if ($lang = 'fr') then $re-title-fr else $re-title-en) || ')'
                 || $re-space || '+(\p{Lu})', '$1$2&#xA0;$3')"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Numbers, ranges and units.</xd:desc>
    <xd:param name="s">The text to process (contains no URL).</xd:param>
    <xd:param name="lang">The language of the text: <xd:i>fr</xd:i> or
      <xd:i>en</xd:i>.</xd:param>
    <xd:return>The text with:
      <xd:ul>
        <xd:li>digit groups joined by a narrow no-break space in French (10 000) and by a
          comma in English (10,000), see
          <xd:ref name="nucma:group-digits" type="function"/>;</xd:li>
        <xd:li>times: in French, no-break spaces around <xd:i>h</xd:i>
          (<xd:i>10h30</xd:i> → 10 h 30, <xd:i>9h-17h</xd:i> → 9 h–17 h); in English,
          <xd:i>10 h 30</xd:i> → 10:30 and <xd:i>10 am</xd:i>, <xd:i>10 AM</xd:i> → 10 a.m.
          (no-break space);</xd:li>
        <xd:li>an en dash (U+2013) without spaces between the two numbers of a range
          (<xd:i>68-77</xd:i>, <xd:i>1914 - 1918</xd:i>, <xd:i>45—52</xd:i> → 68–77,
          1914–1918, 45–52), see <xd:ref name="re-number-range" type="variable"/>;</xd:li>
        <xd:li>a no-break space between a number and its unit (12 cm, 3 m, 20 °C), see
          <xd:ref name="re-unit" type="variable"/> and
          <xd:ref name="re-short-unit" type="variable"/>;</xd:li>
        <xd:li>in French, a no-break space before %, ‰, €, $ and £ (50 %, 10 €), added
          when missing; in English, no space before % (50%), and the currency symbol before
          the amount (<xd:i>10 €</xd:i> → €10, <xd:i>10 $ CA</xd:i> → CA$10).</xd:li>
      </xd:ul>
    </xd:return>
  </xd:doc>
  <xsl:function name="nucma:numbers" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:param name="lang" as="xs:string"/>
    <xsl:variable name="grouped" select="nucma:group-digits($s, $lang)"/>
    <xsl:variable name="times" select="
      if ($lang = 'fr')
      then $grouped
        (: 9h-17h → 9 h–17 h :)
        => replace('(^|[^\p{N}])(\d{1,2})' || $re-space || '*h' || $re-space || '*' || $re-range-dash
                   || $re-space || '*(\d{1,2})' || $re-space || '*h([^\p{L}\p{N}]|$)', '$1$2&#xA0;h–$3&#xA0;h$4')
        (: 10h30 → 10 h 30, 10h → 10 h :)
        => replace('(^|[^\p{N}])(\d{1,2})' || $re-space || '*h' || $re-space || '*(\d{2})([^\p{L}\p{N}]|$)',
                   '$1$2&#xA0;h&#xA0;$3$4')
        => replace('(^|[^\p{N},.])(\d{1,2})' || $re-space || '*h([^\p{L}\p{N}]|$)', '$1$2&#xA0;h$3')
      else $grouped
        (: French notation left by the translation: 10 h 30 → 10:30 :)
        => replace('(^|[^\p{N}])(\d{1,2})' || $re-space || '*h' || $re-space || '*(\d{2})([^\p{L}\p{N}]|$)',
                   '$1$2:$3$4')
        (: 10 am, 10 AM, 10 a.m. → 10 a.m. :)
        => replace('(\d)' || $re-space || '*[Aa]\.? ?[Mm]\.?([^\p{L}\p{N}]|$)', '$1&#xA0;a.m.$2')
        => replace('(\d)' || $re-space || '*[Pp]\.? ?[Mm]\.?([^\p{L}\p{N}]|$)', '$1&#xA0;p.m.$2')"/>
    <xsl:variable name="ranges-and-units" select="$times
      (: range: en dash, no space :)
      => replace($re-number-range, '$1$2–$3$4')
      (: units: no-break space, added when missing for unambiguous symbols :)
      => replace('(\d)' || $re-space || '*(' || $re-unit || ')([^\p{L}\p{N}]|$)', '$1&#xA0;$2$3')
      => replace('(\d)' || $re-space || '+(' || $re-short-unit || ')([^\p{L}\p{N}]|$)', '$1&#xA0;$2$3')"/>
    <xsl:sequence select="
      if ($lang = 'fr')
      then replace($ranges-and-units, '(\d)' || $re-space || '*([%‰€$£])', '$1&#xA0;$2')
      else $ranges-and-units
        => replace('(\d)' || $re-space || '+%', '$1%')
        (: currency symbol before the amount: 10 € → €10, 10 $ CA → CA$10 :)
        => replace('(\d(?:[\d,.–]*\d)?)' || $re-space || '*([€£$])(?:' || $re-space || '*(CA|US|AU)D?)?([^\p{L}]|$)',
                   '$3$2$1$4')"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>
      <xd:p>Joins the thousands of a number with the separator of the language.</xd:p>
      <xd:p>Every sequence of digit groups separated by spaces (or, in French, periods) is
        taken as a whole, then only treated as a number if it has one to three digits
        followed by groups of exactly three. Digits are never grouped when they are not
        already separated, so that years and page numbers are left unchanged.</xd:p>
    </xd:desc>
    <xd:param name="s">The text to process.</xd:param>
    <xd:param name="lang">The language of the text: <xd:i>fr</xd:i> or
      <xd:i>en</xd:i>.</xd:param>
    <xd:return>The text with numbers joined by U+202F in French (<xd:i>10 000</xd:i>,
      <xd:i>10.000</xd:i> → 10 000) and by a comma in English (10,000); other digit
      sequences (<xd:i>514 987 3000</xd:i>, <xd:i>3.5</xd:i>, <xd:i>2.0.1</xd:i>) are left
      unchanged.</xd:return>
  </xd:doc>
  <xsl:function name="nucma:group-digits" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:param name="lang" as="xs:string"/>
    <xsl:variable name="re-separator" select="if ($lang = 'fr') then $re-group-separator-fr else $re-space"/>
    <xsl:variable name="separator" select="if ($lang = 'fr') then '&#x202F;' else ','"/>
    <xsl:variable name="parts" as="xs:string*">
      <xsl:analyze-string select="$s" regex="{'(^|[^\p{N},.])(\d+(?:' || $re-separator || '\d+)+)'}">
        <xsl:matching-substring>
          <xsl:sequence select="regex-group(1)
            || (if (matches(regex-group(2), '^\d{1,3}(?:' || $re-separator || '\d{3})+$'))
                then replace(regex-group(2), $re-separator, $separator)
                else regex-group(2))"/>
        </xsl:matching-substring>
        <xsl:non-matching-substring>
          <xsl:sequence select="."/>
        </xsl:non-matching-substring>
      </xsl:analyze-string>
    </xsl:variable>
    <xsl:sequence select="string-join($parts)"/>
  </xsl:function>


  <xd:doc>
    <xd:desc>Ellipsis and dashes.</xd:desc>
    <xd:param name="s">The text to process (contains no URL).</xd:param>
    <xd:param name="lang">The language of the text: <xd:i>fr</xd:i> or
      <xd:i>en</xd:i>.</xd:param>
    <xd:param name="after-element">True when the text node directly follows an element: a
      leading spaced dash is then a parenthetical.</xd:param>
    <xd:return>The text with:
      <xd:ul>
        <xd:li>the ellipsis character (<xd:i>...</xd:i>, <xd:i>. . .</xd:i> → …), and
          <xd:i>etc...</xd:i> → etc.;</xd:li>
        <xd:li>in French, <xd:i>(…)</xd:i> → […] for a cut in a quotation, and a spaced
          hyphen, double hyphen or em dash turned into an en dash preceded by a no-break
          space, so that a dash never starts a line (<xd:i>mot - incise - suite</xd:i> →
          mot – incise – suite);</xd:li>
        <xd:li>in English (Chicago Manual of Style), a spaced hyphen, double hyphen or em
          dash turned into a closed em dash (<xd:i>word - word</xd:i>,
          <xd:i>word--word</xd:i> → word—word); spaced en dashes (British usage) are kept;
          <xd:i>n°</xd:i> left by the translation → no.</xd:li>
      </xd:ul>
      Ranges of numbers have already been handled by
      <xd:ref name="nucma:numbers" type="function"/>.
    </xd:return>
  </xd:doc>
  <xsl:function name="nucma:punctuation" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:param name="lang" as="xs:string"/>
    <xsl:param name="after-element" as="xs:boolean"/>
    <xsl:variable name="ellipsis" select="$s
      => replace('([Ee]tc)\.?' || $re-space || '?(?:\.{3}|…)', '$1.')
      => replace('\.\.\.|\.(?: \.){2}', '…')"/>
    <!-- a text that follows an element gets a leading letter, so that a leading dash is
         handled like any other; the letter is removed afterwards -->
    <xsl:variable name="text" select="if ($after-element) then 'x' || $ellipsis else $ellipsis"/>
    <xsl:variable name="dashes" select="
      if ($lang = 'fr')
      then $text
        => replace('\(…\)', '[…]')
        => replace('([^\s\p{Zs}])' || $re-spaced-dash, '$1&#xA0;– ')
      else $text
        (: French n° left by the translation: no. (Chicago) :)
        => replace('([Nn])[°ºᵒ](s?)\.?', '$1o$2.')
        (: guillemets inherited from the translation: no space inside, before nucma:quotes :)
        => replace('«' || $re-space || '+', '«')
        => replace($re-space || '+»', '»')
        => replace('([^\s\p{Zs}])' || $re-space || '+(?:--?|—)' || $re-space || '+', '$1—')
        => replace('(\p{L})--(\p{L})', '$1—$2')"/>
    <xsl:sequence select="if ($after-element) then substring($dashes, 2) else $dashes"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>
      <xd:p>Quotation marks, paired by nesting level.</xd:p>
      <xd:p>A straight double quote opens a quotation after a space, an opening bracket or
        quote, a dash or at the start of the text, and is followed by a non-space; it
        closes one otherwise. Existing typographic quotes are kept but counted.</xd:p>
      <xd:ul>
        <xd:li>French: « » for the first level, “ ” inside (an existing “ ” at the first
          level becomes « »);</xd:li>
        <xd:li>English: “ ” for the first level, ‘ ’ inside; guillemets inherited from the
          translation are converted the same way.</xd:li>
      </xd:ul>
    </xd:desc>
    <xd:param name="s">The text to process.</xd:param>
    <xd:param name="lang">The language of the text: <xd:i>fr</xd:i> or
      <xd:i>en</xd:i>.</xd:param>
    <xd:param name="initial-depth">The nesting level at the start of the text.</xd:param>
    <xd:param name="after-element">True when the text directly follows an element (a
      leading straight quote then closes).</xd:param>
    <xd:param name="before-element">True when the text is directly followed by an element
      (a trailing straight quote then opens).</xd:param>
    <xd:return>A map: <xd:i>text</xd:i>, the text with typographic quotes;
      <xd:i>depth</xd:i>, the nesting level at the end of the text.</xd:return>
  </xd:doc>
  <xsl:function name="nucma:quotes" as="map(xs:string, item())">
    <xsl:param name="s" as="xs:string"/>
    <xsl:param name="lang" as="xs:string"/>
    <xsl:param name="initial-depth" as="xs:integer"/>
    <xsl:param name="after-element" as="xs:boolean"/>
    <xsl:param name="before-element" as="xs:boolean"/>
    <xsl:variable name="chars" select="string-to-codepoints($s) ! codepoints-to-string(.)"/>
    <xsl:iterate select="1 to count($chars)">
      <xsl:param name="depth" as="xs:integer" select="$initial-depth"/>
      <xsl:param name="out" as="xs:string*" select="()"/>
      <xsl:on-completion>
        <xsl:sequence select="map{'text': string-join($out), 'depth': $depth}"/>
      </xsl:on-completion>
      <xsl:variable name="i" select="."/>
      <xsl:variable name="char" select="$chars[$i]"/>
      <xsl:choose>
        <xsl:when test="not($char = ('&quot;', '«', '»', '“', '”'))">
          <xsl:next-iteration>
            <xsl:with-param name="out" select="($out, $char)"/>
          </xsl:next-iteration>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="previous" select="
            if ($i gt 1) then $chars[$i - 1] else if ($after-element) then 'a' else ' '"/>
          <xsl:variable name="next" select="
            if ($i lt count($chars)) then $chars[$i + 1] else if ($before-element) then 'a' else ' '"/>
          <xsl:variable name="opening" as="xs:boolean" select="
            if ($char = ('«', '“')) then true()
            else if ($char = ('»', '”')) then false()
            else if (not(matches($previous, $re-before-opening-quote))) then false()
            else if (not(matches($next, '[\s\p{Zs}]'))) then true()
            else $depth = 0"/>
          <!-- French: « » at the first level, “ ” inside (explicitly nested « » are kept);
               English: “ ” at the first level, ‘ ’ inside -->
          <xsl:variable name="glyph" select="
            if ($lang = 'fr')
            then (if ($opening)
                  then (if ($depth = 0 or $char = '«') then '«' else '“')
                  else (if ($depth le 1 or $char = '»') then '»' else '”'))
            else (if ($opening)
                  then (if ($depth = 0) then '“' else '‘')
                  else (if ($depth le 1) then '”' else '’'))"/>
          <xsl:next-iteration>
            <xsl:with-param name="depth" select="if ($opening) then $depth + 1 else max((0, $depth - 1))"/>
            <xsl:with-param name="out" select="($out, $glyph)"/>
          </xsl:next-iteration>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:iterate>
  </xsl:function>


  <!-- ================================================================== -->
  <!-- 4b. French ligatures, spacing and ordinals                         -->
  <!-- ================================================================== -->

  <xd:doc>
    <xd:desc>French œ ligature.</xd:desc>
    <xd:param name="s">The text to process.</xd:param>
    <xd:return>The text with <xd:i>oe</xd:i> replaced by <xd:i>œ</xd:i> in the stems listed
      in <xd:ref name="re-oe-stems" type="variable"/>, keeping the case
      (<xd:i>Oeuvre</xd:i> → Œuvre, <xd:i>OEUVRE</xd:i> → ŒUVRE).</xd:return>
  </xd:doc>
  <xsl:function name="nucma:ligatures-fr" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:variable name="parts" as="xs:string*">
      <xsl:analyze-string select="$s" regex="{$re-oe-stems}" flags="i">
        <xsl:matching-substring>
          <xsl:sequence select="replace(., 'oe', 'œ') => replace('O[eE]', 'Œ')"/>
        </xsl:matching-substring>
        <xsl:non-matching-substring>
          <xsl:sequence select="."/>
        </xsl:non-matching-substring>
      </xsl:analyze-string>
    </xsl:variable>
    <xsl:sequence select="string-join($parts)"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>French spacing, following the Imprimerie nationale rules.</xd:desc>
    <xd:param name="s">The text to process (contains no URL).</xd:param>
    <xd:param name="after-element">True when the text node directly follows an element
      (e.g. <xd:i>&lt;/hi&gt;?</xd:i>): leading punctuation is then handled as if it followed
      a word.</xd:param>
    <xd:return>The text with normalised spaces:
      <xd:ul>
        <xd:li>U+202F before <xd:i>; ! ?</xd:i>, added when missing;</xd:li>
        <xd:li>U+00A0 before <xd:i>:</xd:i>, except between two digits (times, ratios) and
          before <xd:i>//</xd:i>;</xd:li>
        <xd:li>an ordinary space after punctuation, added when missing;</xd:li>
        <xd:li>U+00A0 inside guillemets « » (U+202F if
          <xd:ref name="fr-guillemets-narrow-space" type="parameter"/> is set), and no space
          inside second-level quotes “ ”;</xd:li>
        <xd:li>remaining breaking thin spaces (U+2009, U+2005) turned into ordinary
          spaces.</xd:li>
      </xd:ul>
    </xd:return>
  </xd:doc>
  <xsl:function name="nucma:spacing-fr" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:param name="after-element" as="xs:boolean"/>
    <xsl:variable name="quote-space" select="if ($fr-guillemets-narrow-space) then '&#x202F;' else '&#xA0;'"/>
    <xsl:variable name="start" select="
      if ($after-element)
      then $s => replace('^([;!?])', '&#x202F;$1') => replace('^:([^\d/]|$)', '&#xA0;:$1')
      else $s"/>
    <xsl:sequence select="
      $start
      (: ; ! ? : narrow no-break space U+202F, also when missing :)
      => replace('([^\s\p{Zs}])' || $re-space || '+([;!?])', '$1&#x202F;$2')
      => replace($re-before-punct || '([;!?])', '$1&#x202F;$2')
      => replace('^' || $re-space || '+([;!?])', '&#x202F;$1')
      (: colon: no-break space U+00A0; not between two digits (times, ratios) :)
      => replace('([^\s\p{Zs}])' || $re-space || '+:', '$1&#xA0;:')
      => replace($re-before-punct || ':([^\d/]|$)', '$1&#xA0;:$2')
      => replace('^' || $re-space || '+:', '&#xA0;:')
      (: after punctuation: ordinary space, added when missing :)
      => replace('([;:!?])&#xA0;(\w)', '$1 $2')
      => replace('([;:!?])(\p{L})', '$1 $2')
      (: guillemets: no-break space inside; second-level quotes: no space inside :)
      => replace('«' || $re-space || '*', '«' || $quote-space)
      => replace($re-space || '*»', $quote-space || '»')
      => replace('“' || $re-space || '+', '“')
      => replace($re-space || '+”', '”')
      (: remaining breaking thin or unusual spaces → ordinary space :)
      => replace('[&#x2009;&#x2005;]+', ' ')"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Canonical form of a French ordinal suffix (Imprimerie nationale).</xd:desc>
    <xd:param name="suffix">A suffix matched by
      <xd:ref name="re-suffix-fr" type="variable"/>.</xd:param>
    <xd:return>e, es, er, ers, re, res, d, de, ds or des
      (<xd:i>ème</xd:i>, <xd:i>ième</xd:i>, <xd:i>è</xd:i>, <xd:i>ᵉ</xd:i> → <xd:i>e</xd:i>;
      <xd:i>ère</xd:i> → <xd:i>re</xd:i>).</xd:return>
  </xd:doc>
  <xsl:function name="nucma:canonical-suffix-fr" as="xs:string">
    <xsl:param name="suffix" as="xs:string"/>
    <xsl:sequence select="translate($suffix, 'ᵉʳˢᵈ', 'ersd')
      => replace('^(i?èmes|emes)$', 'es')
      => replace('^(i?ème|eme|è)$', 'e')
      => replace('^ères$', 'res')
      => replace('^ère$', 're')"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>
      <xd:p>Marks up French ordinals and centuries.</xd:p>
      <xd:ul>
        <xd:li>Before <xd:i>siècle(s)</xd:i> or <xd:i>s.</xd:i>: Roman numerals, in small
          capitals (see <xd:ref name="fr-centuries-small-caps" type="parameter"/>), and a
          no-break space before <xd:i>siècle</xd:i>; Arabic numbers are converted
          (<xd:i>20e siècle</xd:i> → xxᵉ siècle). Series such as <xd:i>XIXe-XXe
          siècles</xd:i> or <xd:i>du XVIIIe au XXIe siècle</xd:i> are handled.</xd:li>
        <xd:li>Elsewhere: number unchanged, suffix in superscript (3ᵉ éd., Vᵉ
          République).</xd:li>
        <xd:li><xd:i>n°</xd:i>, <xd:i>nº</xd:i> (numéro): <xd:i>n</xd:i> followed by a
          superscript <xd:i>o</xd:i>, as recommended by the Imprimerie nationale
          (n&lt;hi rend="superscript"&gt;o&lt;/hi&gt; 16, plural
          n&lt;hi rend="superscript"&gt;os&lt;/hi&gt;).</xd:li>
      </xd:ul>
    </xd:desc>
    <xd:param name="s">The text to process, after
      <xd:ref name="nucma:spacing-fr" type="function"/>.</xd:param>
    <xd:return>A sequence of text nodes and <xd:i>hi</xd:i> elements.</xd:return>
  </xd:doc>
  <xsl:function name="nucma:ordinals-fr" as="node()*">
    <xsl:param name="s" as="xs:string"/>
    <xsl:analyze-string select="$s" regex="{$re-ordinals-fr}">
      <xsl:matching-substring>
        <xsl:variable name="series" select="regex-group(2)"/>
        <xsl:variable name="century" select="regex-group(3)"/>
        <xsl:value-of select="regex-group(1)"/>
        <xsl:choose>
          <xsl:when test="$series">
            <xsl:analyze-string select="$series" regex="({$re-century-number})({$re-suffix-fr})">
              <xsl:matching-substring>
                <xsl:sequence select="nucma:ordinal-fr(regex-group(1), regex-group(2), true())"/>
              </xsl:matching-substring>
              <xsl:non-matching-substring>
                <xsl:value-of select="."/>
              </xsl:non-matching-substring>
            </xsl:analyze-string>
            <xsl:value-of select="'&#xA0;' || $century"/>
          </xsl:when>
          <xsl:when test="regex-group(7)">
            <!-- numéro: n° → n + superscript o (Imprimerie nationale) -->
            <xsl:value-of select="regex-group(7)"/>
            <hi rend="superscript"><xsl:value-of select="'o' || regex-group(8)"/></hi>
            <xsl:value-of select="regex-group(9)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="nucma:ordinal-fr(regex-group(4), regex-group(5), false())"/>
            <xsl:value-of select="regex-group(6)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:value-of select="."/>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:function>

  <xd:doc>
    <xd:desc>Marks up one French ordinal.</xd:desc>
    <xd:param name="num">The number, Roman or Arabic.</xd:param>
    <xd:param name="suffix">The suffix, as found in the text.</xd:param>
    <xd:param name="is-century">True when the ordinal is followed by
      <xd:i>siècle</xd:i>.</xd:param>
    <xd:return>The number (converted to Roman numerals, in small capitals if required, for
      a century) followed by the canonical suffix in a
      <xd:i>hi rend="superscript"</xd:i>. When the combination is not an ordinal
      (<xd:i>er</xd:i>/<xd:i>re</xd:i> only after 1 or I, <xd:i>d</xd:i>/<xd:i>de</xd:i>
      only after 2: <xd:i>Vers</xd:i>, <xd:i>3d</xd:i>), the text is returned unchanged,
      and a superscript folded by the unwrap-ordinals step is restored.</xd:return>
  </xd:doc>
  <xsl:function name="nucma:ordinal-fr" as="node()+">
    <xsl:param name="num" as="xs:string"/>
    <xsl:param name="suffix" as="xs:string"/>
    <xsl:param name="is-century" as="xs:boolean"/>
    <xsl:variable name="canonical" select="nucma:canonical-suffix-fr($suffix)"/>
    <xsl:choose>
      <xsl:when test="($canonical = ('er', 'ers', 're', 'res') and not($num = ('1', 'I')))
                      or ($canonical = ('d', 'de', 'ds', 'des') and $num ne '2')">
        <xsl:value-of select="$num"/>
        <xsl:choose>
          <xsl:when test="matches($suffix, '[ᵉʳˢᵈ]')">
            <hi rend="superscript"><xsl:value-of select="translate($suffix, 'ᵉʳˢᵈ', 'ersd')"/></hi>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$suffix"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="numeral" select="
          if ($is-century and $num castable as xs:integer)
          then format-integer(xs:integer($num), 'I') else $num"/>
        <xsl:choose>
          <xsl:when test="$is-century and $fr-centuries-small-caps">
            <hi rend="smallcaps"><xsl:value-of select="lower-case($numeral)"/></hi>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$numeral"/>
          </xsl:otherwise>
        </xsl:choose>
        <hi rend="superscript"><xsl:value-of select="$canonical"/></hi>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>


  <!-- ================================================================== -->
  <!-- 4c. English spacing and ordinals                                   -->
  <!-- ================================================================== -->

  <xd:doc>
    <xd:desc>English spacing.</xd:desc>
    <xd:param name="s">The text to process (contains no URL).</xd:param>
    <xd:return>The text with no space before <xd:i>; : ! ?</xd:i>, an ordinary space
      after them (added when missing, except between two digits), no space inside “ ” and
      after ‘, commas and periods moved inside closing quotes if
      <xd:ref name="en-punctuation-inside-quotes" type="parameter"/> is set, and thin or
      no-break thin spaces turned into ordinary spaces.</xd:return>
  </xd:doc>
  <xsl:function name="nucma:spacing-en" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:sequence select="
      $s
      (: ; : ! ? : no space before (also at the start of a node, after an element) :)
      => replace($re-space || '+([;:!?])', '$1')
      (: after punctuation: ordinary space, added when missing;
         not between two digits (times, ratios) :)
      => replace('([;:!?])&#xA0;(\w)', '$1 $2')
      => replace('([;!?])(\p{L})', '$1 $2')
      => replace('([^\d]):(\p{L})', '$1: $2')
      (: no space inside quotes :)
      => replace('([“‘])' || $re-space || '+', '$1')
      => replace($re-space || '+([”])', '$1')
      => (function($t) {
            if ($en-punctuation-inside-quotes)
            then $t
              (: “hello”, → “hello,” :)
              => replace('”([.,])', '$1”')
              (: ‘word’, → ‘word,’ only when the opening quote is found, not after an apostrophe :)
              => replace('(‘[^‘’]*)’([.,])', '$1$2’')
            else $t })()
      (: remaining thin or unusual spaces → ordinary space :)
      => replace('[&#x2009;&#x2005;&#x202F;]+', ' ')"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Value of a Roman numeral.</xd:desc>
    <xd:param name="roman">A Roman numeral from I to XXXIX.</xd:param>
    <xd:return>Its integer value.</xd:return>
  </xd:doc>
  <xsl:function name="nucma:roman-to-integer" as="xs:integer">
    <xsl:param name="roman" as="xs:string"/>
    <xsl:variable name="values" select="
      for $c in string-to-codepoints($roman)
      return map{'I': 1, 'V': 5, 'X': 10}(codepoints-to-string($c))"/>
    <xsl:sequence select="sum(
      for $i in 1 to count($values)
      return if ($i lt count($values) and $values[$i] lt $values[$i + 1])
             then -$values[$i] else $values[$i])"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>English ordinal suffix of an integer.</xd:desc>
    <xd:param name="n">A positive integer.</xd:param>
    <xd:return><xd:i>st</xd:i>, <xd:i>nd</xd:i>, <xd:i>rd</xd:i> or <xd:i>th</xd:i>
      (1st, 2nd, 3rd, 4th, 11th–13th, 21st, 101st, 111th…).</xd:return>
  </xd:doc>
  <xsl:function name="nucma:english-suffix" as="xs:string">
    <xsl:param name="n" as="xs:integer"/>
    <xsl:sequence select="
      if ($n mod 100 = (11, 12, 13)) then 'th'
      else (map{1: 'st', 2: 'nd', 3: 'rd'}($n mod 10), 'th')[1]"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>
      <xd:p>Normalises English ordinals and centuries.</xd:p>
      <xd:ul>
        <xd:li>Suffixes are recomputed from the number (<xd:i>21th</xd:i> → 21st,
          <xd:i>3d</xd:i> → 3rd, <xd:i>3e edition</xd:i> → 3rd edition).</xd:li>
        <xd:li>Before <xd:i>century</xd:i>, Roman numerals are converted
          (<xd:i>XVIIIth century</xd:i>, <xd:i>XVIIIe century</xd:i> → 18th century);
          elsewhere they are left unchanged (<xd:i>Louis XIV</xd:i>).</xd:li>
      </xd:ul>
    </xd:desc>
    <xd:param name="s">The text to process, after
      <xd:ref name="nucma:spacing-en" type="function"/>.</xd:param>
    <xd:return>A sequence of text nodes and, if required, <xd:i>hi</xd:i> elements.</xd:return>
  </xd:doc>
  <xsl:function name="nucma:ordinals-en" as="node()*">
    <xsl:param name="s" as="xs:string"/>
    <xsl:analyze-string select="$s" regex="{$re-ordinals-en}">
      <xsl:matching-substring>
        <xsl:variable name="series" select="regex-group(2)"/>
        <xsl:variable name="separator" select="regex-group(3)"/>
        <xsl:variable name="century" select="regex-group(4)"/>
        <xsl:value-of select="regex-group(1)"/>
        <xsl:choose>
          <xsl:when test="$series">
            <xsl:analyze-string select="$series" regex="({$re-century-number})({$re-suffix-en})">
              <xsl:matching-substring>
                <xsl:sequence select="nucma:ordinal-en(regex-group(1), true())"/>
              </xsl:matching-substring>
              <xsl:non-matching-substring>
                <xsl:value-of select="."/>
              </xsl:non-matching-substring>
            </xsl:analyze-string>
            <xsl:value-of select="$separator || $century"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="nucma:ordinal-en(regex-group(5), false())"/>
            <xsl:value-of select="regex-group(7)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:value-of select="."/>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:function>

  <xd:doc>
    <xd:desc>Writes one English ordinal.</xd:desc>
    <xd:param name="num">The number, Roman or Arabic.</xd:param>
    <xd:param name="is-century">True when the ordinal is followed by
      <xd:i>century</xd:i>.</xd:param>
    <xd:return>The ordinal in Arabic numerals with its computed suffix, in superscript if
      <xd:ref name="en-ordinals-superscript" type="parameter"/> is set, or spelled out for a
      century if <xd:ref name="en-centuries-in-words" type="parameter"/> is set.</xd:return>
  </xd:doc>
  <xsl:function name="nucma:ordinal-en" as="node()+">
    <xsl:param name="num" as="xs:string"/>
    <xsl:param name="is-century" as="xs:boolean"/>
    <xsl:variable name="n" select="
      if ($num castable as xs:integer) then xs:integer($num)
      else nucma:roman-to-integer($num)"/>
    <xsl:choose>
      <xsl:when test="$is-century and $en-centuries-in-words">
        <xsl:value-of select="format-integer($n, 'w;o', 'en')"/>
      </xsl:when>
      <xsl:when test="$en-ordinals-superscript">
        <xsl:value-of select="$n"/>
        <hi rend="superscript"><xsl:value-of select="nucma:english-suffix($n)"/></hi>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$n || nucma:english-suffix($n)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
</xsl:stylesheet>
