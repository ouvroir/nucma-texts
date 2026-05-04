<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
  version="3.0">

  <!--
    Met en forme un rapport Schematron (SVRL) en texte lisible : une ligne par erreur ou
    avertissement, précédée du nombre de chaque niveau.
    Utilisation : voir xsl/README.md (« Contrôle de l’encodage »).
  -->

  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:param name="document" select="'document'"/>

  <xsl:template match="/">
    <xsl:variable name="messages" select="//(svrl:failed-assert | svrl:successful-report)"/>
    <xsl:variable name="errors" select="$messages[not(@role) or @role = ('error', 'fatal')]"/>
    <xsl:value-of select="'== ' || $document || ' : ' || count($errors) || ' erreur(s), '
      || count($messages) - count($errors) || ' avertissement(s)&#10;'"/>
    <xsl:for-each select="$messages">
      <xsl:value-of select="(if (. intersect $errors) then '   ERREUR  ' else '   avert.  ')
        || normalize-space(svrl:text) || '&#10;'"/>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
