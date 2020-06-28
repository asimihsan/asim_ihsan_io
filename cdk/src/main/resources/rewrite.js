'use strict';

const regexps = [
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
    [new RegExp("\.ico(\.br|\.gz)?$"), "image/x-icon"],
    [new RegExp("\.md(\.br|\.gz)?$"), "text/markdown; charset=UTF-8"],
]
const regexps_length = regexps.length;

// See: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-examples.html
exports.handler = (event, context, callback) => {
    console.log("EVENT", JSON.stringify(event));
    const request = event.Records[0].cf.request;
    const response = event.Records[0].cf.response;

    if (response) {
        console.log("RESPONSE");
        const headers = response.headers;
        if (request.uri.endsWith(".br")) {
            headers["content-encoding"] = [
                {
                    "key": "Content-Encoding",
                    "value": "br"
                }
            ];
        } else if (request.uri.endsWith(".gz")) {
            headers["content-encoding"] = [
                {
                    "key": "Content-Encoding",
                    "value": "gzip"
                }
            ];
        }
        for (var i = 0; i < regexps_length; i++) {
          let elem = regexps[i];
          let re = elem[0];
          let mime = elem[1];
          if (re.test(request.uri)) {
            headers["content-type"] = [
                {
                    "key": "Content-Type",
                    "value": mime
                }
            ];
            break;
          }
        }

        headers['strict-transport-security'] = [
            {
                key: 'Strict-Transport-Security',
                value: 'max-age=63072000; includeSubdomains; preload'
            }
        ];

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

        return callback(null, response);
    }

    console.log("REQUEST");
    const headers = request.headers;
    const acceptEncodingHeader = headers['accept-encoding'];

    if (request.uri.endsWith("/")) {
        // If requesting a directory redirect to index.html
        request.uri += "index.html";
    }
    if (!acceptEncodingHeader) {
        // No Accept-Encoding header, just pass-through request.
        return callback(null, request);
    }
    if (request.uri.endsWith(".woff2")) {
        // WOFF2 is already Brotli-compressed so don't serve a compressed version of it.
        return callback(null, request);
    }

    let gzip = false;
    let brotli = false;

    for (let i = 0; i < acceptEncodingHeader.length; i++) {
        const value = acceptEncodingHeader[i].value;
        const elems = value.split(',').map(x => x.split(';')[0].trim());
        if (elems.indexOf('br') !== -1) {
            brotli = true;
            break;
        }
        if (elems.indexOf('gzip') !== -1) {
            gzip = true;
            break;
        }
    }

    if (brotli) {
        request.uri += '.br';
    } else if (gzip) {
        request.uri += '.gz';
    }

    return callback(null, request);
};
