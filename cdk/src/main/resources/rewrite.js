'use strict';

var regexps = [
    [new RegExp("\.html(\.br|\.gz)?$"), "text/html; charset=UTF-8"],
    [new RegExp("\.js(\.br|\.gz)?$"), "application/javascript"],
    [new RegExp("\.css(\.br|\.gz)?$"), "text/css"],
    [new RegExp("\.woff2(\.br|\.gz)?$"), "font/woff2"],
    [new RegExp("\.mjs(\.br|\.gz)?$"), "text/javascript"],
    [new RegExp("\.txt(\.br|\.gz)?$"), "text/plain"],
    [new RegExp("\.xml(\.br|\.gz)?$"), "application/xml"],
    [new RegExp("\.eot(\.br|\.gz)?$"), "application/vnd.ms-fontobject"],
    [new RegExp("\.ttf(\.br|\.gz)?$"), "font/ttf"],
    [new RegExp("\.otf(\.br|\.gz)?$"), "font/otf"],
    [new RegExp("\.woff(\.br|\.gz)?$"), "font/woff"],
    [new RegExp("\.jpg(\.br|\.gz)?$"), "image/jpg"],
    [new RegExp("\.png(\.br|\.gz)?$"), "image/png"],
    [new RegExp("\.gif(\.br|\.gz)?$"), "image/gif"],
    [new RegExp("\.svg(\.br|\.gz)?$"), "image/svg+xml"],
    [new RegExp("\.ico(\.br|\.gz)?$"), "image/x-icon"],
    [new RegExp("\.md(\.br|\.gz)?$"), "text/markdown; charset=UTF-8"],
]
var regexps_length = regexps.length;

// See: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/example-function-add-index.html
function handler(event) {
    console.log("EVENT");
    console.log(JSON.stringify(event));
    var request = event.request;
    if (event.context.eventType === "viewer-request") {
        console.log("REQUEST");
        var request_headers = request.headers;
        var uri = request.uri;
        var acceptEncodingHeader = request_headers['accept-encoding'];

        if (uri.endsWith("/")) {
            // If requesting a directory redirect to index.html
            request.uri += "index.html";
        }
        if (!acceptEncodingHeader) {
            // No Accept-Encoding header, just pass-through request.
            return request;
        }
        if (request.uri.endsWith(".woff2") ||
            request.uri.endsWith(".png") ||
            request.uri.endsWith(".jpg") ||
            request.uri.endsWith(".gif") ||
            request.uri.endsWith(".woff")) {
            // Already compressed so don't serve a compressed version of it.
            return request;
        }

        var value = acceptEncodingHeader.value;
        var elems = value.split(',').map(x => x.trim());
        console.log(elems);
        if (elems.indexOf('br') !== -1) {
            request.uri += '.br';
        }
        else if (elems.indexOf('gzip') !== -1) {
            request.uri += '.gz';
        }

        return request;
    } else {
        console.log("RESPONSE");
        var response = event.response;
        var response_headers = response.headers;
        for (var i = 0; i < regexps_length; i++) {
            var elem = regexps[i];
            var re = elem[0];
            var mime = elem[1];
            if (re.test(request.uri)) {
                response_headers["content-type"] = {value: mime};
                break;
            }
        }

        response_headers['strict-transport-security'] = {value: 'max-age=63072000; includeSubdomains; preload'};
        response_headers['x-content-type-options'] = { value: 'nosniff'};
        response_headers['x-frame-options'] = {value: 'DENY'};
        response_headers['x-xss-protection'] = {value: '1; mode=block'};

        /*
        work in progress! I use inline CSS for syntax highlighting. JS is a mess too, need inline and eval.
        https://observatory.mozilla.org/analyze/preprod-asim.ihsan.io
        https://infosec.mozilla.org/guidelines/web_security#content-security-policy
        https://www.html5rocks.com/en/tutorials/security/content-security-policy/
        */
//        headers['content-security-policy'] = [
//            {
//                key: 'Content-Security-Policy',
//                value: "default-src 'none'; img-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; font-src 'self'"
//            }
//        ];

        return response;
    }
}
