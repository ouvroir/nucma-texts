<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
  xmlns:fn="http://www.w3.org/2005/xpath-functions"
  xmlns:nucma="https://nucma.ca/ns"
  exclude-result-prefixes="xs svrl fn nucma"
  version="3.0">

  <!--
    Met en forme un rapport Schematron (SVRL) en texte lisible : une ligne par erreur ou
    avertissement, précédée du nombre de chaque niveau. Chaque message est précédé de
    fichier:ligne:colonne, lien cliquable dans les terminaux qui le reconnaissent (VS Code…),
    omis quand le fichier contrôlé ne peut être lu.
    Utilisation : voir README.md (« Contrôle de l’encodage »).
  -->

  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:param name="document" select="'document'"/>

  <xsl:template match="/">
    <xsl:variable name="messages" select="//(svrl:failed-assert | svrl:successful-report)"/>
    <xsl:variable name="errors" select="$messages[not(@role) or @role = ('error', 'fatal')]"/>
    <!-- fichier contrôlé, donné par SchXslt2 sur chaque règle déclenchée -->
    <xsl:variable name="uri" select="string((//svrl:fired-rule/@document)[1])"/>
    <xsl:variable name="source" select="if ($uri and doc-available($uri)) then doc($uri) else ()"/>
    <xsl:variable name="tags" select="if ($source) then nucma:tags(unparsed-text($uri)) else ()"/>
    <xsl:value-of select="'== ' || $document || ' : ' || count($errors) || ' erreur(s), '
      || count($messages) - count($errors) || ' avertissement(s)&#10;'"/>
    <xsl:for-each select="$messages">
      <xsl:value-of select="(if (. intersect $errors) then '   ERREUR  ' else '   avert.  ')
        || nucma:line(@location, $source, $tags) || normalize-space(svrl:text) || '&#10;'"/>
    </xsl:for-each>
  </xsl:template>

  <!-- « fichier:ligne:colonne  » de l’élément désigné par $location, ou « » si le fichier
       est inconnu. Saxon HE ne donne pas les numéros de ligne : l’élément est le n-ième dans
       l’ordre du document, sa ligne est celle de la n-ième balise ouvrante du texte source.
       Même calcul que typo:line dans schematron/svrl-report.xsl de typesetter. -->
  <xsl:function name="nucma:line" as="xs:string">
    <xsl:param name="location" as="xs:string?"/>
    <xsl:param name="source" as="document-node()?"/>
    <xsl:param name="tags" as="xs:string*"/>
    <xsl:variable name="node" as="node()*">
      <xsl:if test="$source and $location">
        <xsl:evaluate xpath="$location" context-item="$source"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="element" select="($node[1]/ancestor-or-self::*)[last()]"/>
    <xsl:variable name="n" select="count($element/ancestor-or-self::*) + count($element/preceding::*)"/>
    <xsl:sequence select="if ($element and $tags[$n]) then $document || ':' || $tags[$n] || '  ' else ''"/>
  </xsl:function>

  <!-- « ligne:colonne » de chaque balise ouvrante d’un texte XML, dans l’ordre du document ;
       commentaires, sections CDATA, instructions de traitement, déclarations et balises
       fermantes sont ignorés -->
  <xsl:function name="nucma:tags" as="xs:string*">
    <xsl:param name="text" as="xs:string"/>
    <xsl:iterate select="analyze-string($text, '&lt;!--.*?--&gt;|&lt;!\[CDATA\[.*?\]\]&gt;|&lt;\?.*?\?&gt;|&lt;[!/][^&gt;]*&gt;|&lt;', 's')/*">
      <xsl:param name="line" as="xs:integer" select="1"/>
      <xsl:param name="column" as="xs:integer" select="1"/>
      <xsl:if test="self::fn:match and . = '&lt;'">
        <xsl:sequence select="$line || ':' || $column"/>
      </xsl:if>
      <xsl:variable name="breaks" select="string-length(.) - string-length(translate(., '&#10;', ''))"/>
      <xsl:next-iteration>
        <xsl:with-param name="line" select="$line + $breaks"/>
        <xsl:with-param name="column" select="if ($breaks) then string-length(replace(., '^.*&#10;', '', 's')) + 1
          else $column + string-length(.)"/>
      </xsl:next-iteration>
    </xsl:iterate>
  </xsl:function>
</xsl:stylesheet>
