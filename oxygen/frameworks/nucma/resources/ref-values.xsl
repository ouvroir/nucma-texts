<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xi="http://www.w3.org/2001/XInclude"
    xmlns:nucma="https://www.nucma.ca/ns/oxygen"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    exclude-result-prefixes="#all"
    version="3.0">

    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>Content completion proposals for NUCMA references, called by oXygen through
                cc_config.xml each time proposals are requested.</xd:p>
            <xd:p>The proposals depend on the element that carries the attribute:</xd:p>
            <xd:ul>
                <xd:li>persName/@ref, author/@ref: person in a listPerson (meta/authors.xml,
                    meta/names.xml);</xd:li>
                <xd:li>orgName/@ref: org in a listOrg (meta/names.xml);</xd:li>
                <xd:li>placeName/@ref: place (meta/places.xml);</xd:li>
                <xd:li>objectName/@ref: object (meta/artworks.xml);</xd:li>
                <xd:li>title/@ref: event (meta/exhibitions.xml);</xd:li>
                <xd:li>bibl/@ref: biblStruct (meta/bibliography.xml);</xd:li>
                <xd:li>ref/@target, ptr/@target: with type="figure", figure (meta/medias.xml);
                    with type="internal" or "crossref", the identifier (sourceDesc/@xml:id) of the
                    entries in the language of the document; without type, both.</xd:li>
            </xd:ul>
            <xd:p>The records are read from the files declared in the corpus of the folder of the
                document, fr/_corpus.xml or en/_corpus.xml, whose xi:include are followed
                recursively. The repository is found from the location of this stylesheet
                (oxygen/frameworks/nucma/resources/). For a document outside fr/ and en/ (meta/
                for instance), or when the corpus gives no record of the requested kind
                (includes that cannot be resolved), the records are read from the meta/ folder of
                the repository.</xd:p>
        </xd:desc>
    </xd:doc>

    <xd:doc>
        <xd:desc>URI of the edited document (set by oXygen).</xd:desc>
    </xd:doc>
    <xsl:param name="documentSystemID" as="xs:string"/>

    <xd:doc>
        <xd:desc>XPath of the element carrying the attribute being completed (set by
            oXygen).</xd:desc>
    </xd:doc>
    <xsl:param name="contextElementXPathExpression" as="xs:string"/>

    <xd:doc>
        <xd:desc>Root of the repository: four levels above this stylesheet
            (oxygen/frameworks/nucma/resources/); if no meta/ folder is found there (the
            stylesheet may be loaded from elsewhere by oXygen), the part of the document URI
            before /fr/, /en/ or /meta/.</xd:desc>
    </xd:doc>
    <xsl:variable name="repository" as="xs:string" select="
            (string(resolve-uri('../../../../', static-base-uri()))[doc-available(. || 'meta/authors.xml')],
            replace($documentSystemID, '^(.*/)(fr|en|meta)/.*$', '$1')[. ne $documentSystemID])[1]"/>

    <xd:doc>
        <xd:desc>Entry point.</xd:desc>
    </xd:doc>
    <xsl:template name="start">
        <xsl:if test="doc-available($documentSystemID)">
            <xsl:apply-templates select="doc($documentSystemID)"/>
        </xsl:if>
    </xsl:template>

    <xd:doc>
        <xd:desc>Selects the records matching the context element and writes the
            proposals.</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:variable name="context" as="element()?">
            <xsl:variable name="found" as="node()*">
                <xsl:evaluate xpath="$contextElementXPathExpression" context-item="."
                    namespace-context="/*"/>
            </xsl:variable>
            <xsl:sequence select="$found[self::element()][1]"/>
        </xsl:variable>
        <!-- folder of the document in the repository: fr or en -->
        <xsl:variable name="folder" as="xs:string?" select="
                tokenize(substring-after(nucma:path($documentSystemID), nucma:path($repository)), '/')[1]
                [. = ('fr', 'en')]"/>
        <xsl:variable name="label-lang" as="xs:string?"
            select="($context/ancestor-or-self::*[@xml:lang][1]/@xml:lang, $folder)[1]"/>
        <xsl:variable name="corpus" as="document-node()*"
            select="$folder ! nucma:included($repository || . || '/_corpus.xml', ())"/>
        <xsl:variable name="from-corpus" as="element()*"
            select="nucma:records($corpus, $context, $folder)"/>
        <xsl:variable name="records" as="element()*" select="
                if (exists($from-corpus)) then $from-corpus
                else nucma:records(collection($repository || 'meta/?select=*.xml;on-error=ignore'), $context, $folder)"/>

        <items>
            <!-- one proposal per identifier, even when a file is reached twice -->
            <xsl:for-each-group select="$records" group-by="@xml:id">
                <xsl:sort select="current-grouping-key()" lang="fr"/>
                <item value="#{current-grouping-key()}"
                    annotation="{nucma:label(., $label-lang)} ({tokenize(base-uri(.), '/')[last()]})"/>
            </xsl:for-each-group>
        </items>
    </xsl:template>

    <xd:doc>
        <xd:desc>Records that the context element may point to, found in the given
            documents.</xd:desc>
        <xd:param name="docs">Documents to search.</xd:param>
        <xd:param name="context">Element carrying the attribute being completed.</xd:param>
        <xd:param name="lang">Language of the document, for the entries.</xd:param>
    </xd:doc>
    <xsl:function name="nucma:records" as="element()*">
        <xsl:param name="docs" as="document-node()*"/>
        <xsl:param name="context" as="element()?"/>
        <xsl:param name="lang" as="xs:string?"/>
        <xsl:variable name="type" as="xs:string?" select="$context/@type"/>
            <xsl:choose>
                <xsl:when test="$context/(self::tei:persName | self::tei:author)">
                    <xsl:sequence select="$docs//tei:listPerson/tei:person[@xml:id]"/>
                </xsl:when>
                <xsl:when test="$context/self::tei:orgName">
                    <xsl:sequence select="$docs//tei:listOrg/tei:org[@xml:id]"/>
                </xsl:when>
                <xsl:when test="$context/self::tei:placeName">
                    <xsl:sequence select="$docs//tei:place[@xml:id]"/>
                </xsl:when>
                <xsl:when test="$context/self::tei:objectName">
                    <xsl:sequence select="$docs//tei:object[@xml:id]"/>
                </xsl:when>
                <xsl:when test="$context/self::tei:title">
                    <xsl:sequence select="$docs//tei:event[@xml:id]"/>
                </xsl:when>
                <xsl:when test="$context/self::tei:bibl">
                    <xsl:sequence select="$docs//tei:biblStruct[@xml:id]"/>
                </xsl:when>
                <xsl:when test="$context/(self::tei:ref | self::tei:ptr)">
                    <xsl:if test="empty($type) or $type = 'figure'">
                        <xsl:sequence select="$docs//tei:figure[@xml:id]"/>
                    </xsl:if>
                    <xsl:if test="empty($type) or $type = ('internal', 'crossref')">
                        <!-- entries: file identifiers nucma.{lang}.{chapter}.{slug} -->
                        <xsl:sequence select="
                                $docs//tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc
                                [starts-with(@xml:id, 'nucma.' || $lang || '.')]"/>
                    </xsl:if>
                </xsl:when>
            </xsl:choose>
    </xsl:function>

    <xd:doc>
        <xd:desc>Readable label of a record, shown next to the proposal.</xd:desc>
        <xd:param name="record">The record (person, org, place…).</xd:param>
        <xd:param name="lang">Preferred language of the label.</xd:param>
    </xd:doc>
    <xsl:function name="nucma:label" as="xs:string">
        <xsl:param name="record" as="element()"/>
        <xsl:param name="lang" as="xs:string?"/>
        <xsl:variable name="label" as="item()*">
            <xsl:choose>
                <xsl:when test="$record/self::tei:person">
                    <xsl:sequence select="nucma:text($record/tei:persName[1])"/>
                </xsl:when>
                <xsl:when test="$record/self::tei:org">
                    <xsl:sequence
                        select="nucma:text(($record/tei:orgName[@xml:lang = $lang], $record/tei:orgName)[1])"/>
                </xsl:when>
                <xsl:when test="$record/self::tei:place">
                    <xsl:sequence select="nucma:text($record/tei:placeName[1])"/>
                </xsl:when>
                <xsl:when test="$record/self::tei:object">
                    <xsl:sequence select="string-join((nucma:text($record/tei:objectName[1]),
                            nucma:text($record/tei:author[1])[.]), ', ')"/>
                </xsl:when>
                <xsl:when test="$record/self::tei:event">
                    <xsl:sequence select="string-join((nucma:text($record/tei:eventName[1]),
                            nucma:text($record/tei:date[1])[.]), ', ')"/>
                </xsl:when>
                <xsl:when test="$record/self::tei:biblStruct">
                    <xsl:variable name="part" select="($record/tei:analytic, $record/tei:monogr)[1]"/>
                    <xsl:sequence select="string-join((
                            string-join($part/(tei:author | tei:editor)/tei:surname ! nucma:text(.), ', ')[.],
                            nucma:text(($record//tei:imprint/tei:date)[1])[.],
                            nucma:text(($part/tei:title[@type = 'short'], $part/tei:title)[1])), ', ')"/>
                </xsl:when>
                <xsl:when test="$record/self::tei:figure">
                    <xsl:variable name="head"
                        select="nucma:text(($record/tei:head[@xml:lang = $lang], $record/tei:head)[1])"/>
                    <xsl:sequence
                        select="if (string-length($head) gt 100) then substring($head, 1, 99) || '…' else $head"/>
                </xsl:when>
                <xsl:when test="$record/self::tei:sourceDesc">
                    <xsl:variable name="titles" select="$record/../tei:titleStmt/tei:title"/>
                    <xsl:sequence
                        select="nucma:text(($titles[@type = 'main'], $titles[not(@type)], $titles)[1])"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:sequence select="(string-join($label)[.], '?')[1]"/>
    </xsl:function>

    <xd:doc>
        <xd:desc>Text of an element, its words separated by single spaces (forename and
            surname elements included).</xd:desc>
        <xd:param name="element">The element, possibly absent.</xd:param>
    </xd:doc>
    <xsl:function name="nucma:text" as="xs:string">
        <xsl:param name="element" as="element()?"/>
        <xsl:sequence select="string-join($element//text()[normalize-space()] ! normalize-space(), ' ')"/>
    </xsl:function>

    <xd:doc>
        <xd:desc>Path of a file URI, whatever its form (file:/…, file:///…).</xd:desc>
        <xd:param name="uri">The URI.</xd:param>
    </xd:doc>
    <xsl:function name="nucma:path" as="xs:string">
        <xsl:param name="uri" as="xs:string"/>
        <xsl:sequence select="replace($uri, '^file:/*', '/')"/>
    </xsl:function>

    <xd:doc>
        <xd:desc>Documents reached from the given ones through xi:include, followed
            recursively; documents that are missing or not well-formed are skipped. If the
            parser already resolved the inclusions, their content is in the first document.</xd:desc>
        <xd:param name="todo">URIs still to read.</xd:param>
        <xd:param name="seen">URIs already read.</xd:param>
    </xd:doc>
    <xsl:function name="nucma:included" as="document-node()*">
        <xsl:param name="todo" as="xs:string*"/>
        <xsl:param name="seen" as="xs:string*"/>
        <xsl:variable name="uri" select="head($todo)"/>
        <xsl:choose>
            <xsl:when test="empty($todo)"/>
            <xsl:when test="$uri = $seen or not(doc-available($uri))">
                <xsl:sequence select="nucma:included(tail($todo), $seen)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="doc" select="doc($uri)"/>
                <xsl:variable name="hrefs" as="xs:string*" select="
                        $doc//xi:include[@href][not(@parse = 'text')] ! string(resolve-uri(@href, base-uri(.)))"/>
                <xsl:sequence select="$doc, nucma:included((tail($todo), $hrefs), ($seen, $uri))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

</xsl:stylesheet>
