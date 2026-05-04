<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  exclude-result-prefixes="xd"
  version="3.0">

  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Serialization only of NUCMA TEI texts.</xd:b></xd:p>
      <xd:p>Copies the document unchanged, with exactly the same serialization as
        <xd:i>normalization.xsl</xd:i>: start tags split over several lines are written on
        one line, everything else is kept. The canonical form of the document (c14n) is
        unchanged.</xd:p>
      <xd:p>Running it before <xd:i>normalization.xsl</xd:i>, in a separate commit, isolates
        the reformatting, so that the diff of the normalization only shows the actual
        corrections.</xd:p>
      <xd:p>Usage (Saxon 12; write to a temporary file, not to the source):</xd:p>
      <xd:pre>saxon -s:fr/acquisition/variabilite.xml -xsl:xsl/serialization.xsl -o:variabilite.tmp</xd:pre>
      <xd:p><xd:b>Author:</xd:b> Emmanuel Château-Dutier</xd:p>
    </xd:desc>
  </xd:doc>

  <xd:doc>
    <xd:desc>Same output settings as <xd:i>normalization.xsl</xd:i>: no indentation, so that
      the source layout is kept.</xd:desc>
  </xd:doc>
  <xsl:output method="xml" indent="no" encoding="UTF-8"/>

  <xsl:mode on-no-match="shallow-copy"/>

  <xd:doc>
    <xd:desc>Copies the top-level nodes (comments, processing instructions, root element),
      writing back the line breaks between them, which are not part of the tree. Same
      behavior as <xd:i>normalization.xsl</xd:i>.</xd:desc>
  </xd:doc>
  <xsl:template match="/">
    <xsl:for-each select="node()">
      <xsl:text>&#10;</xsl:text>
      <xsl:apply-templates select="."/>
    </xsl:for-each>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>
</xsl:stylesheet>
