<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" exclude-result-prefixes="xlink mml"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:mml="http://www.w3.org/1998/Math/MathML"
                xmlns:xlink="http://www.w3.org/1999/xlink">

    <xsl:output method="xml" encoding="utf-8" omit-xml-declaration="yes" indent="yes"/>

    <xsl:strip-space elements="contrib collab"/>

    <xsl:param name="public-reviews" select="false()"/>
    <xsl:param name="static-root" select="''"/>
    <xsl:param name="search-root" select="''"/>
    <xsl:param name="download-prefix" select="'file'"/>
    <xsl:param name="publication-type" select="'publication'"/>
    <xsl:param name="self-uri" select="/article/front/article-meta/self-uri/@xlink:href"/>

    <xsl:variable name="meta" select="/article/front/article-meta"/>
    <xsl:variable name="id" select="$meta/article-id[@pub-id-type='publisher-id']"/>
    <xsl:variable name="doi" select="$meta/article-id[@pub-id-type='doi']"/>
    <xsl:variable name="title" select="$meta/title-group/article-title"/>
    <xsl:variable name="pub-date" select="$meta/pub-date[@date-type='pub'][@pub-type='epub']|$meta/pub-date[@date-type='preprint'][@pub-type='epreprint']"/>
    <xsl:variable name="authors" select="$meta/contrib-group[@content-type='authors']/contrib[@contrib-type='author']"/>
    <xsl:variable name="editors" select="$meta/contrib-group[@content-type='editors']/contrib[@contrib-type='editor']"/>

    <xsl:variable name="journal-meta" select="/article/front/journal-meta"/>
    <xsl:variable name="journal-title" select="$journal-meta/journal-title-group/journal-title"/>

    <xsl:variable name="end-punctuation">
        <xsl:text>.?!"')]}</xsl:text>
    </xsl:variable>

    <xsl:key name="ref" match="ref" use="@id"/>
    <xsl:key name="aff" match="aff" use="@id"/>
    <xsl:key name="corresp" match="corresp" use="@id"/> <!-- remove when converted -->

    <xsl:include href="jats-to-html/util.xsl"/>
    <xsl:include href="jats-to-html/meta.xsl"/>
    <xsl:include href="jats-to-html/front.xsl"/>
    <xsl:include href="jats-to-html/self-citation.xsl"/>
    <xsl:include href="jats-to-html/citation.xsl"/>

    <!-- article -->
    <xsl:template match="/article">
        <html>
            <!-- article head -->
            <head>
                <meta charset="utf-8"/>
                <meta name="robots" content="noindex"/>
                <title>
                    <xsl:value-of select="$title"/>
                </title>
                <link rel="canonical" href="{$id}"/>
                <xsl:apply-templates select="front/article-meta" mode="head"/>
                <xsl:apply-templates select="front/journal-meta" mode="head"/>
            </head>

            <!-- article body -->
            <body>
                <article itemscope="itemscope" itemtype="http://schema.org/ScholarlyArticle">
                    <xsl:apply-templates select="front/article-meta"/>
                    <xsl:apply-templates select="body"/>
                    <xsl:apply-templates select="back"/>
                    <xsl:apply-templates select="floats-group"/>
                </article>
            </body>
        </html>
    </xsl:template>

    <!-- footnote and affiliation labels -->
    <xsl:template match="fn/label | aff/label">
        <a class="article-label">
            <xsl:apply-templates/>
        </a>
    </xsl:template>

    <!-- funding-statement -->
    <xsl:template match="funding-statement" mode="back">
        <h3 class="heading">Funding</h3>
        <div>
            <xsl:apply-templates select="node()"/>
        </div>
    </xsl:template>

    <xsl:template match="body">
        <main>
            <div class="{local-name()}" lang="en">
                <xsl:apply-templates select="node()|@*"/>
            </div>

            <xsl:call-template name="footnotes">
                <xsl:with-param name="footnotes" select="descendant::fn[preceding-sibling::xref[@ref-type='fn']]"/>
            </xsl:call-template>
        </main>
    </xsl:template>

    <!-- don't display footnotes inline -->
    <xsl:template match="body//fn[preceding-sibling::xref[@ref-type='fn']]"/>

    <xsl:template name="footnotes">
        <xsl:param name="footnotes"/>

        <xsl:if test="$footnotes">
            <div id="article-footnotes">
                <xsl:for-each select="$footnotes">
                    <div class="fn article-footnote">
                        <xsl:apply-templates select="node()[not(local-name() = 'label')]|@*"/>
                    </div>
                </xsl:for-each>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template match="back">
        <footer class="{local-name()}">
            <xsl:apply-templates select="node()|@*"/>
        </footer>
    </xsl:template>

    <xsl:template match="sec[@sec-type='additional-information']">
        <div class="{local-name()}">
            <xsl:apply-templates select="node()|@*"/>
            <xsl:apply-templates select="$meta/funding-group/funding-statement" mode="back"/>
        </div>
    </xsl:template>

    <!-- any label -->
    <xsl:template match="label">
        <span class="article-label">
            <xsl:apply-templates select="node()|@*"/>
        </span>
    </xsl:template>

    <xsl:template match="label" mode="caption">
        <span class="caption-label">
            <xsl:apply-templates select="node()|@*"/>
            <xsl:text>:&#32;</xsl:text>
        </span>
    </xsl:template>

    <!-- ordered list -->
    <xsl:template match="list[@list-type='order']">
        <ol class="{local-name()}">
            <xsl:apply-templates select="node()|@*"/>
        </ol>
    </xsl:template>

    <!-- unordered list -->
    <xsl:template match="list">
        <ul class="{local-name()}">
            <xsl:apply-templates select="node()|@*"/>
        </ul>
    </xsl:template>

    <!-- list item -->
    <xsl:template match="list-item">
        <li class="{local-name()}">
            <xsl:apply-templates select="node()|@*"/>
        </li>
    </xsl:template>

    <!-- paragraph -->
    <xsl:template match="p">
        <p>
            <xsl:apply-templates select="node()|@*"/>
        </p>
    </xsl:template>

    <!-- paragraph in the body -->
    <xsl:template match="body//p">
        <p>
            <!-- a sequential id for each paragraph -->
            <xsl:attribute name="id">
                <xsl:text>p-</xsl:text>
                <xsl:number count="body//p" level="any"/>
            </xsl:attribute>
            <xsl:apply-templates select="node()|@*"/>
        </p>
    </xsl:template>

    <!-- the article title -->
    <xsl:template match="article-title">
        <h1 class="{local-name()}" itemprop="name">
            <xsl:apply-templates select="node()|@*"/>
        </h1>
    </xsl:template>

    <!-- people -->
    <xsl:template match="person-group">
        <div class="{local-name()}">
            <xsl:apply-templates select="node()|@*"/>
        </div>
    </xsl:template>

    <!-- name -->
    <xsl:template name="name">
        <xsl:apply-templates select="given-names"/>
        <xsl:if test="surname">
            <xsl:text>&#32;</xsl:text>
            <xsl:apply-templates select="surname"/>
        </xsl:if>
        <xsl:if test="suffix">
            <xsl:text>&#32;</xsl:text>
            <xsl:apply-templates select="suffix"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="given-names">
        <span class="{local-name()}" itemprop="givenName">
            <xsl:apply-templates select="node()|@*"/>
        </span>
    </xsl:template>

    <xsl:template match="surname">
        <span class="{local-name()}" itemprop="familyName">
            <xsl:apply-templates select="node()|@*"/>
        </span>
    </xsl:template>

    <!-- name -->
    <xsl:template match="name">
        <span class="{local-name()}" itemprop="name">
            <xsl:call-template name="name"/>
        </span>
        <xsl:call-template name="comma-separator"/>
    </xsl:template>

    <xsl:template match="collab">
        <span class="{local-name()} name" itemprop="name">
            <xsl:apply-templates select="node()|@*"/>
        </span>
    </xsl:template>

    <!-- text formatting -->
    <!--
    <xsl:template match="italic">
        <span class="{local-name()}">
            <xsl:call-template name="add-style">
                <xsl:with-param name="style">font-style:italic</xsl:with-param>
            </xsl:call-template>
            <xsl:apply-templates select="node()|@*"/>
        </span>
    </xsl:template>

    <xsl:template match="bold">
        <span class="{local-name()}">
            <xsl:call-template name="add-style">
                <xsl:with-param name="style">font-weight:bold</xsl:with-param>
            </xsl:call-template>
            <xsl:apply-templates select="node()|@*"/>
        </span>
    </xsl:template>
    -->

    <xsl:template match="italic">
        <i>
            <xsl:apply-templates select="node()|@*"/>
        </i>
    </xsl:template>

    <xsl:template match="bold">
        <b>
            <xsl:apply-templates select="node()|@*"/>
        </b>
    </xsl:template>

    <xsl:template match="sub">
        <sub>
            <xsl:apply-templates select="node()|@*"/>
        </sub>
    </xsl:template>

    <xsl:template match="sup">
        <sup>
            <xsl:apply-templates select="node()|@*"/>
        </sup>
    </xsl:template>

    <xsl:template match="underline">
        <u>
            <xsl:apply-templates select="node()|@*"/>
        </u>
    </xsl:template>

    <xsl:template match="break">
        <br/>
    </xsl:template>

    <!-- preformatted code block -->
    <!-- contains zero-width spaces to ensure white-space is preserved in HTML -->
    <xsl:template match="preformat">
        <pre><code><xsl:apply-templates select="node()|@*"/>&#8203;</code>&#8203;</pre>
    </xsl:template>

    <!-- style elements -->
    <xsl:template match="sc | strike | roman | sans-serif | monospace | overline">
        <span class="{local-name()}">
            <xsl:apply-templates select="node()|@*"/>
        </span>
    </xsl:template>

    <!-- inline elements -->
    <xsl:template
        match="abbrev | suffix | email | year | month | day
        | xref | contrib | source | volume | fpage | lpage | etal | pub-id
        | named-content | styled-content | funding-source | award-id | institution | country | addr-line
        | chem-struct">
        <span class="{local-name()}">
            <xsl:apply-templates select="node()|@*"/>
        </span>
    </xsl:template>

    <!-- links -->
    <xsl:template match="uri">
        <a class="{local-name()}">
            <xsl:attribute name="href">
                <xsl:choose>
                    <xsl:when test="@xlink:href">
                        <xsl:value-of select="@xlink:href"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:apply-templates select="node()|@*"/>
        </a>
    </xsl:template>

    <!-- table elements -->
    <xsl:template match="table | tbody | thead | tfoot | column | tr | th | td | colgroup | col">
        <xsl:element name="{local-name()}">
            <xsl:if test="@content-type = 'text'">
                <xsl:attribute name="class">table-text</xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="table-wrap">
        <div class="{local-name()}">
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="caption" mode="table"/>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="table-wrap/alternatives">
        <div class="table-container">
            <xsl:apply-templates select="table"/>
        </div>

        <xsl:apply-templates select="../object-id[@pub-id-type='doi']" mode="caption"/>
    </xsl:template>

    <!-- table caption and label are handled elsewhere -->
    <xsl:template match="table-wrap/caption | table-wrap/label"/>

    <xsl:template match="caption" mode="table">
        <div class="{local-name()}">
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="preceding-sibling::label" mode="caption"/>
            <xsl:apply-templates select="node()"/>
        </div>
    </xsl:template>

    <xsl:template match="table-wrap-foot/fn/p[normalize-space(.) = 'Notes.']">
        <p class="table-wrap-foot-notes">
            <b>Notes:</b>
        </p>
    </xsl:template>

    <!--<xsl:template match="table/label"></xsl:template>-->

    <!-- label with a paragraph straight afterwards -->
    <!--<xsl:template match="label[following-sibling::p]"></xsl:template>-->

    <!--
    <xsl:template match="label" mode="included-label">
        <span class="article-label">
            <xsl:apply-templates select="node()|@*"/>
        </span>
    </xsl:template>
    -->

    <xsl:template match="p[ancestor::caption]">
        <span class="{local-name()}">
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="node()"/>
        </span>
    </xsl:template>

    <xsl:template match="fn/p[preceding-sibling::label]">
        <span class="{local-name()}">
            <xsl:apply-templates select="@*"/>
            <!--<xsl:apply-templates select="preceding-sibling::label" mode="included-label"/>-->
            <xsl:apply-templates select="node()"/>
        </span>
    </xsl:template>


    <!-- object DOI -->
    <xsl:template match="object-id[@pub-id-type=doi]">
        <a class="{local-name()}" href="http://dx.doi.org/{.}">
            <xsl:apply-templates select="node()|@*"/>
        </a>
    </xsl:template>

    <!-- other object ID -->
    <xsl:template match="object-id"/>

    <!-- sections -->
    <xsl:template match="sec">
        <section class="{local-name()}">
            <xsl:apply-templates select="node()|@*"/>
        </section>
    </xsl:template>

    <!-- section headings -->
    <xsl:template match="title">
        <xsl:variable name="heading-level"
                      select="count(ancestor::sec | ancestor::back | ancestor::fig | ancestor::g) + 1"/>

        <xsl:if test="$heading-level > 6">
            <xsl:variable name="heading-level">6</xsl:variable>
        </xsl:if>

        <xsl:variable name="heading">h<xsl:value-of select="$heading-level"/></xsl:variable>

        <xsl:element name="{$heading}">
            <xsl:attribute name="class">heading</xsl:attribute>
            <xsl:if test="parent::caption and ancestor::fig">
                <xsl:apply-templates select="../../label" mode="caption"/>
            </xsl:if>
            <xsl:if test="preceding-sibling::label">
                <xsl:apply-templates select="preceding-sibling::label" mode="caption"/>
            </xsl:if>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:element>
    </xsl:template>

    <!-- additional material -->
    <xsl:template match="sec[@sec-type='additional-information']/title">
        <h2 class="heading">
            <xsl:apply-templates select="node()|@*"/>
        </h2>
    </xsl:template>

    <!-- links -->
    <xsl:template match="ext-link">
        <a class="{local-name()}" href="{@xlink:href}">
            <xsl:apply-templates select="node()|@*"/>
        </a>
    </xsl:template>

    <xsl:template match="ext-link[@ext-link-type='doi']">
        <xsl:variable name="encoded-doi">
            <xsl:call-template name="urlencode">
                <xsl:with-param name="value" select="@xlink:href"/>
            </xsl:call-template>
        </xsl:variable>

        <a class="{local-name()}" href="http://dx.doi.org/{$encoded-doi}">
            <xsl:apply-templates select="node()|@*"/>
        </a>
    </xsl:template>

    <xsl:template match="ext-link[@ext-link-type='DDBJ/EMBL/GenBank']">
        <a class="{local-name()}" href="https://www.ncbi.nlm.nih.gov/nucleotide?term={@xlink:href}">
            <xsl:apply-templates select="node()|@*"/>
        </a>
    </xsl:template>

    <xsl:template match="license-p/ext-link">
        <a class="{local-name()}" href="{@xlink:href}" rel="license">
            <xsl:apply-templates select="node()|@*"/>
        </a>
    </xsl:template>

    <!-- quotes -->
    <xsl:template match="disp-quote">
        <blockquote class="{local-name()}">
            <xsl:apply-templates select="node()|@*"/>
        </blockquote>
    </xsl:template>

    <!-- formulae -->
    <xsl:template match="inline-formula">
        <span class="{local-name()}">
            <xsl:apply-templates select="node()|@*"/>
        </span>
    </xsl:template>

    <!-- displ-formula has to be span, as it can appear inside a p -->
    <xsl:template match="disp-formula">
        <span class="{local-name()}">
            <xsl:apply-templates select="node()|@*"/>
        </span>
    </xsl:template>

    <xsl:template match="inline-formula/alternatives">
        <xsl:call-template name="formula-alternatives"/>
    </xsl:template>

    <xsl:template match="disp-formula/alternatives">
        <xsl:call-template name="formula-alternatives"/>
    </xsl:template>

    <!-- choose an appropriate formula representation -->
    <xsl:template name="formula-alternatives">
        <xsl:choose>
            <xsl:when test="mml:math">
                <xsl:apply-templates select="mml:math"/>
            </xsl:when>
            <xsl:when test="inline-graphic">
                <xsl:apply-templates select="inline-graphic"/>
            </xsl:when>
            <xsl:when test="tex-math">
                <xsl:apply-templates select="tex-math"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <!-- math expressed in TeX -->
    <xsl:template match="tex-math">
        <span class="{local-name()}">
            <xsl:value-of select="."/>
        </span>
    </xsl:template>

    <!-- cross-reference -->
    <xsl:template match="xref">
        <a class="{local-name()} xref-{@ref-type}" href="#{@rid}">
            <xsl:apply-templates select="node()|@*"/>
        </a>
    </xsl:template>

    <!-- bibliographic reference -->
    <xsl:template match="xref[@ref-type='bibr']">
        <xsl:variable name="ref" select="key('ref', @rid)"/>
        <xsl:variable name="citation" select="$ref/element-citation"/>

        <xsl:variable name="title">
            <xsl:choose>
                <xsl:when test="$citation/article-title">
                    <xsl:value-of select="$citation/article-title"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$citation/source"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="ref-doi" select="$ref/*/pub-id[@pub-id-type='doi']"/>
        <xsl:variable name="ref-uri" select="$ref/*/comment/uri"/>
        <xsl:variable name="url">
            <xsl:call-template name="citation-url">
                <xsl:with-param name="citation" select="$citation"/>
            </xsl:call-template>
        </xsl:variable>

        <a class="{local-name()} xref-{@ref-type}" href="{$url}" title="{$title}">
            <xsl:apply-templates select="node()|@*"/>
        </a>
    </xsl:template>

    <!-- figure -->
    <xsl:template match="fig">
        <figure class="{local-name()}">
            <xsl:apply-templates select="@*"/>

            <div class="image-container">
                <xsl:apply-templates select="graphic" mode="fig"/>
            </div>

            <xsl:apply-templates select="caption" mode="fig"/>

            <xsl:apply-templates select="p"/>
        </figure>
    </xsl:template>

    <!-- figure caption -->
    <xsl:template match="caption" mode="fig">
        <figcaption>
            <xsl:if test="not(title)">
                <xsl:apply-templates select="preceding-sibling::label" mode="caption"/>
            </xsl:if>

            <xsl:apply-templates select="node()|@*"/>

            <div class="article-image-download">
                <xsl:variable name="fig-id" select="../@id"/>
                <a href="{$static-root}{$fig-id}-full.png" class="btn btn-mini" download="{$download-prefix}-{$id}-{$fig-id}.png">
                    <i class="icon-large icon-picture">&#160;</i>
                    <xsl:text>&#32;Download full-size image</xsl:text>
                </a>
            </div>

            <xsl:apply-templates select="../object-id[@pub-id-type='doi']" mode="caption"/>
        </figcaption>
    </xsl:template>

    <!-- DOI in a caption -->
    <xsl:template match="object-id[@pub-id-type='doi']" mode="caption">
        <div class="{local-name()} article-component-doi">
            <xsl:text>DOI:&#32;</xsl:text>
            <a href="{concat('http://dx.doi.org/', .)}" rel="tooltip" title="Cite this object using this DOI">
                <xsl:value-of select="."/>
            </a>
        </div>
    </xsl:template>

    <!-- figure title -->
    <xsl:template match="title[ancestor::table-wrap]">
        <div class="{local-name()}">
            <xsl:apply-templates select="node()|@*"/>
        </div>
    </xsl:template>

    <!-- figure title -->
    <xsl:template match="title" mode="fig">
        <div class="{local-name()}">
            <xsl:apply-templates select="node()|@*"/>
        </div>
    </xsl:template>

    <!-- graphic -->
    <xsl:template match="graphic | inline-graphic">
        <img class="{local-name()}" src="{$static-root}{@xlink:href}" data-filename="{@xlink:href}">
            <xsl:apply-templates select="@*"/>
        </img>
    </xsl:template>

    <!-- figure graphic -->
    <!-- TODO: image width and height -->
    <xsl:template match="graphic" mode="fig">
        <xsl:variable name="fig" select=".."/>
        <xsl:variable name="fig-id" select="$fig/@id"/>
        <a href="{$static-root}{$fig-id}-2x.jpg"
           title="View the full image"
           class="fresco"
           data-fresco-caption="{$fig/label}: {$fig/caption/title}"
           data-fresco-group="figure"
           data-fresco-options="fit: 'width', ui: 'outside', thumbnails: false, loop: true, position: true, preload: false">
            <img class="{local-name()}"
                 src="{$static-root}{$fig-id}-1x.jpg"
                 data-image-id="{$fig-id}"
                 alt="{$fig/caption/title}"
                 data-full="{$static-root}{$fig-id}-full.png"
                 data-thumb="{$static-root}{$fig-id}-thumb.jpg"
                 data-original="{$static-root}{@xlink:href}"
                 data-image-type="figure">
                <xsl:apply-templates select="@*"/>
            </img>
        </a>
    </xsl:template>

    <!-- list -->
    <xsl:template match="list[@list-type='order']">
        <ol>
            <xsl:apply-templates select="node()|@*"/>
        </ol>
    </xsl:template>

    <xsl:template match="list[@list-type='bullet']">
        <ul>
            <xsl:apply-templates select="node()|@*"/>
        </ul>
    </xsl:template>

    <!-- list item -->
    <xsl:template match="list-item">
        <li>
            <xsl:apply-templates select="node()|@*"/>
        </li>
    </xsl:template>

    <!-- definition list -->
    <xsl:template match="def-list">
        <dl>
            <xsl:apply-templates select="node()|@*"/>
        </dl>
    </xsl:template>

    <xsl:template match="def-item">
        <xsl:apply-templates select="term" mode="def-item"/>
        <xsl:apply-templates select="def" mode="def-item"/>
    </xsl:template>

    <xsl:template match="term" mode="def-item">
        <dt>
            <xsl:apply-templates select="node()|@*"/>
        </dt>
    </xsl:template>

    <xsl:template match="def" mode="def-item">
        <dd>
            <xsl:apply-templates select="node()|@*"/>
        </dd>
    </xsl:template>

    <!-- TODO -->
    <xsl:template match="list-item/label"/>

    <!-- supplementary material -->
    <xsl:template match="supplementary-material">
        <div class="{local-name()} well well-small">
            <xsl:apply-templates select="@*"/>
            <h3 class="heading">
                <!--<xsl:apply-templates select="label/text()"/>-->
                <xsl:choose>
                    <xsl:when test="normalize-space(caption/title) != ''">
                        <xsl:apply-templates select="caption/title" mode="supp-title"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="label"/>
                    </xsl:otherwise>
                </xsl:choose>
            </h3>

            <xsl:apply-templates select="caption"/>
        </div>
    </xsl:template>

    <xsl:template match="supplementary-material/caption">
        <xsl:apply-templates select="node()|@*"/>
        <xsl:apply-templates select="../object-id[@pub-id-type='doi']" mode="caption"/>

        <xsl:variable name="filename" select="../@xlink:href"/>

        <xsl:variable name="encoded-filename">
            <xsl:call-template name="urlencode">
                <xsl:with-param name="value" select="$filename"/>
            </xsl:call-template>
        </xsl:variable>

        <div>
            <a href="{$static-root}{$encoded-filename}" class="btn article-supporting-download"
               download="{$filename}" data-filename="{$filename}">
                <i class="icon-large icon-download-alt">&#160;</i>
                <!--<xsl:value-of select="concat(' Download .', ../@mime-subtype)"/>-->
                <xsl:value-of select="' Download'"/>
            </a>
        </div>
    </xsl:template>

    <xsl:template match="supplementary-material/caption/title"/>

    <xsl:template match="supplementary-material/caption/title" mode="supp-title">
        <!--<xsl:text>:&#32;</xsl:text>-->
        <xsl:apply-templates select="node()"/>
    </xsl:template>

    <!-- acknowledgments -->
    <xsl:template match="ack">
        <section class="{local-name()}" id="acknowledgements">
            <xsl:apply-templates select="@*"/>
            <h2 class="heading">Acknowledgements</h2>
            <xsl:apply-templates select="node()"/>
        </section>
    </xsl:template>

    <!-- appendices -->
    <xsl:template match="app-group">
        <xsl:apply-templates select="app"/>
    </xsl:template>

    <!-- appendix -->
    <xsl:template match="app">
        <section class="{local-name()}">
            <xsl:apply-templates select="node()|@*"/>
        </section>
    </xsl:template>

    <!-- appendix label -->
    <xsl:template match="app/label">
        <h2 class="heading">
            <xsl:apply-templates/>
        </h2>
    </xsl:template>

    <!-- appendix title -->
    <xsl:template match="app/title"/>

    <!-- reference list -->
    <xsl:template match="ref-list">
        <section class="ref-list-container" id="references">
            <xsl:apply-templates select="title"/>
            <ul class="{local-name()}">
                <xsl:apply-templates select="ref|@*"/>
            </ul>
        </section>
    </xsl:template>

    <!-- reference list item -->
    <xsl:template match="ref-list/ref">
        <li class="{local-name()}">
            <div class="citation" itemprop="citation" itemscope="itemscope">
                <xsl:choose>
                    <xsl:when test="element-citation/@publication-type = 'journal'">
                        <xsl:attribute name="itemtype">http://schema.org/ScholarlyArticle</xsl:attribute>
                    </xsl:when>
                    <xsl:when test="element-citation/@publication-type = 'book'">
                        <xsl:attribute name="itemtype">http://schema.org/Book</xsl:attribute>
                    </xsl:when>
                </xsl:choose>

                <xsl:apply-templates select="element-citation|@*"/>
            </div>
        </li>
    </xsl:template>

    <!-- "et al" -->
    <xsl:template match="person-group/etal">
        <span class="{local-name()}">et al.</span>
    </xsl:template>

    <!-- block elements -->
    <xsl:template match="*">
        <div class="{local-name()}">
            <xsl:apply-templates select="node()|@*"/>
        </div>
    </xsl:template>

    <!-- attributes to copy directly -->
    <xsl:template match="@id | @colspan | @rowspan | @style">
        <xsl:copy-of select="."/>
    </xsl:template>

    <!-- attributes that should be styles -->
    <xsl:template match="@valign">
        <xsl:call-template name="add-style">
            <xsl:with-param name="style" select="concat('vertical-align:', .)"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="@align">
        <xsl:call-template name="add-style">
            <xsl:with-param name="style" select="concat('text-align:', .)"/>
        </xsl:call-template>
    </xsl:template>

    <!-- even though it's deprecated, need these -->
    <xsl:template match="colgroup/@valign | colgroup/@align | col/@valign | col/@align">
        <xsl:copy-of select="."/>
    </xsl:template>

    <!-- add to the style attribute -->
    <xsl:template name="add-style">
        <xsl:param name="style"/>
        <xsl:attribute name="style">
            <xsl:value-of select="normalize-space(concat(@style, ' ', $style, ';'))"/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="@sec-type">
        <xsl:attribute name="id">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>

    <!-- other attributes (ignore) -->
    <xsl:template match="@*">
        <xsl:attribute name="data-jats-{local-name()}">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>

    <!-- ignore namespaced attributes -->
    <xsl:template match="@*[namespace-uri()]"/>

    <!-- mathml root element -->
    <xsl:template match="mml:math">
        <math xmlns="http://www.w3.org/1998/Math/MathML">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="mathml"/>
        </math>
    </xsl:template>

    <!-- mathml (direct copy) -->
    <xsl:template match="*" mode="mathml">
        <xsl:element name="{local-name()}" xmlns="http://www.w3.org/1998/Math/MathML">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="mathml"/>
        </xsl:element>
        <!--<xsl:copy-of select="."/>-->
    </xsl:template>
</xsl:stylesheet>
