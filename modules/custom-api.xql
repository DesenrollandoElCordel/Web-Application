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
