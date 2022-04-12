xquery version "3.1";

module namespace idx="http://teipublisher.com/index";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace dbk="http://docbook.org/ns/docbook";

declare variable $idx:app-root :=
    let $rawPath := system:get-module-load-path()
    return
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    ;

(:~
 : Helper function called from collection.xconf to create index fields and facets.
 : This module needs to be loaded before collection.xconf starts indexing documents
 : and therefore should reside in the root of the app.
 :)
 
declare function idx:get-metadata($root as element(), $field as xs:string) {
    let $header := $root/tei:teiHeader
    return
        switch ($field)
            case "title" return
                string-join((
                    $header//tei:titleStmt/tei:title
                ), " - ")
                
            (:Facets for pliegos:)
            case "language" return
                head((
                    $header//tei:langUsage/tei:language
                ))
            case "date" return head((
                $header//tei:sourceDesc/tei:biblFull/tei:publicationStmt/tei:date
            ))
            case "collection" return head((
                $header//tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:collection
            ))
            case "pubplace" return head((
                $header//tei:sourceDesc//tei:pubPlace
            ))
            case "verso" return head((
                $header//tei:keywords/tei:term[@type="verso_prosa"]
            ))
            case "genre" return head((
                $header//tei:keywords/tei:term[@type="tipo_texto"]
            ))
            case "sacred" return head((
                $header//tei:keywords/tei:term[@type="sagrado_profano"]
            ))
            
            (:Facets for illusrations:)
            case "masculino" return (
                idx:get-masculino($header)
            )
            case "femenino" return (
                idx:get-femenino($header)
            )
            case "grupos" return (
                idx:get-grupos($header)
            )
            case "atuendo" return (
                idx:get-atuendo($header)
            )
            case "actitud" return (
                idx:get-actitud($header)
            )
            case "instrumento" return (
                idx:get-instrumento($header)
            )
            case "blanca" return (
                idx:get-blanca($header)
            )
            case "fuego" return (
                idx:get-fuego($header)
            )
            case "accesorios" return (
                idx:get-accesorios($header)
            )
            case "construido" return (
                idx:get-construido($header)
            )
            case "natural" return (
                idx:get-natural($header)
            )
            case "maritimo" return (
                idx:get-maritimo($header)
            )
            case "religion" return (
                idx:get-religion($header)
            )
            case "muerte" return (
                idx:get-muerte($header)
            )
            case "animales" return (
                idx:get-animales($header)
            )
            case "monstruo" return (
                idx:get-monstruo($header)
            )
            case "decorativos" return (
                idx:get-decorativos($header)
            )
            default return
                ()
};

declare function idx:get-masculino($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#personaje_masculino"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-femenino($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#personaje_femenino"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-grupos($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#grupos_personajes"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-atuendo($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#atuendo"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-actitud($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#actitud"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-instrumento($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#instrumento_musical"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-blanca($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#arma_blanca"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-fuego($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#arma_de_fuego"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-accesorios($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#accesorios_varios"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-construido($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#espacio_construido"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-natural($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#ambiente_natural"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-maritimo($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#ambiente_maritimo"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-religion($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#religion"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-muerte($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#muerte"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-animales($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#animales"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-monstruo($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#monstruo"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-decorativos($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#elementos_decorativos"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};
