xquery version "3.1";

(:~
 : This is the place to import your own XQuery modules for either:
 :
 : 1. custom API request handling functions
 : 2. custom templating functions to be called from one of the HTML templates
 :)
module namespace api = "http://teipublisher.com/api/custom";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: Add your own module imports here :)
import module namespace rutil = "http://exist-db.org/xquery/router/util";
import module namespace app = "teipublisher.com/app" at "app.xql";
import module namespace config = "http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace errors = "http://exist-db.org/xquery/router/errors";
import module namespace teis="http://www.tei-c.org/tei-simple/query/tei" at "query-tei.xql";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation/tei" at "navigation-tei.xql";
import module namespace query="http://www.tei-c.org/tei-simple/query" at "query.xql";

(:~
 : Keep this. This function does the actual lookup in the imported modules.
 :)
declare function api:lookup($name as xs:string, $arity as xs:integer) {
    try {
        function-lookup(xs:QName($name), $arity)
    } catch * {
        ()
    }
};

declare function api:get-manifest($node as node(), $model as map(*)) {
    let $id := $model?doc
    let $doc := doc($config:data-root || "/" ||$id)
    let $manifest := $doc//tei:facsimile/string(@facs)
        =>substring-after("l/")
    return
        <span>
            <a href="../mirador.html?manifest={$manifest}" target="_blank">
                <pb-i18n key="notice.comparar">Comparar</pb-i18n>
                <img src="resources/images/logos/mirador.png"
                     alt="Logo de Mirador" height="22"
                     style="display:inline-block; padding-left:10px; vertical-align:middle;"/>
            </a>
        </span>
};

(:Retrieve one manifest:)
declare function api:manifest($requests as map(*)) {
    let $id := xmldb:decode($requests?parameters?id)
    return
        if ($id) then
            let $doc := config:get-document($id)
            let $manifest := $doc//tei:facsimile/string(@facs)
            return
                map {
                "manifest": $manifest
                }
        else
            error($errors:BAD_REQUEST, "No document specified")
};

(:Retrieve a list of manifests:)
declare function api:manifests-list($requests as map(*)){
    let $doc := $requests?parameters?doc
    for $text in collection($config:data-root || "/Pliegos")
        let $manifest := $text//tei:facsimile/string(@facs)
        return $manifest      
};


declare function api:download-pdf($node as node(), $model as map(*)) {
    let $ID := $model?doc
    => substring-after('/')
    
    let $doi := doc($config:data-root || "/Pliegos/" || $ID)//tei:idno[@type = "DOI"]
    => substring-after('o.')
    
    return
        <paper-button
            class="page-pliegos__button-descargar"
            raised="">
            <a
                href="https://zenodo.org/record/{$doi}"
                target="_blank">PDF (Zenodo)</a>
        </paper-button>
};

declare function api:download-tei($node as node(), $model as map(*)) {
    let $ID := $model?doc
    => substring-after('/')
    
    let $doi := doc($config:data-root || "/Pliegos/" || $ID)//tei:idno[@type = "DOI"]
    => substring-after('o.')
    
    return
        <paper-button
            class="page-pliegos__button-descargar"
            raised="">
            <a
                href="https://zenodo.org/record/{$doi}"
                target="_blank">XML TEI (Zenodo)</a>
        </paper-button>
};

(: Display the illustrations with IIIF URI + Coordinates:)
declare function api:display-illustration($node as node(), $model as map(*)) {
    let $ID := $model?doc
    => substring-after('/')
    let $doc := doc($config:data-root || "/Illustraciones/" || $ID)
    let $URI := concat("https://iiif.unige.ch/iiif/2/", $doc//tei:figure/tei:graphic/string(@url))
    
    
    return
        <img class="page-illustration__img" src="{$URI}"/>
};



declare function api:query-options($sort, $facets) {
     map:merge((
        $query:QUERY_OPTIONS,
        map {
            "facets": $facets
        },
        map { "fields": $sort}
    ))
};


declare function api:query-document($request as map(*)) {
    let $root := if (ends-with($config:data-root, "/")) then
        $config:data-root
    else
        $config:data-root || "/"

    let $text-query := xmldb:decode($request?parameters?query)


    let $facet-query:= map:merge((
        for $dimension in map:keys($config:cross-search-facets)
            return
                (: only add the dimensions with specified criteria :)
                if ($request?parameters('facet-'||$dimension)) then
                    map {
                        (: map query parameters to local facet dimensions :)
                        $config:cross-search-facets($dimension): $request?parameters('facet-'||$dimension)
                    }
                else
                    ()
        ))

    let $fields := 
            for $f in map:keys($config:cross-search-fields)
            return 
                $config:cross-search-fields($f)


    let $constraints := 
        (
            if ($text-query) then $text-query else ()
            ,
            for $f in map:keys($config:cross-search-fields)
                let $q := 
                    for $p in $request?parameters($f) 
                        let $query := xmldb:decode($p)
                        return if ($query) then $query else ()

                return
                    if (count($q)) then 
                        $config:cross-search-fields($f) || ':(' || 
                        string-join($q, api:conjunction($request?parameters($f || '-operator'))) || ')' 
                    else 
                        ()
        )

    let $query := string-join($constraints, ' AND ')

    (: Find matches :)
    let $hits :=
        for $rootCol in $config:data-root
        return collection($rootCol)//tei:text[ft:query(., $query, api:query-options($fields, $facet-query))]
    
    let $facets:= 
        map:merge(
            for $dimension in map:keys($config:cross-search-facets)
            return
                map { $dimension: ft:facets($hits, $config:cross-search-facets($dimension), 50)}
        )

    let $data := 
        for $doc in $hits
            let $flds :=  
                for $f in map:keys($config:cross-search-fields) return
                    map:entry($f, ft:field($doc, $config:cross-search-fields($f))) 
            return
                map:merge((
                    map { "filename": substring-after(document-uri(root($doc)), $root),
                        "app": "projet-cordel"},
                    $flds         
                ))

    return 
(: ($query , $facet-query) :)
    map {
        "facets": $facets,
        "data":  if (count($data) > 1 ) then $data else [$data]
    }
};

declare function api:conjunction($operator) {
    switch ($operator) 
        case "and"
            return ' AND '
        default
            return ' OR '
};
