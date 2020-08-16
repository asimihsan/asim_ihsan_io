MathJax = {
    // See: https://github.com/mathjax/MathJax/issues/2402
    startup: {
        ready() {
            if (MathJax.version === '3.0.5') {
                const SVGWrapper = MathJax._.output.svg.Wrapper.SVGWrapper;
                const CommonWrapper = SVGWrapper.prototype.__proto__;
                SVGWrapper.prototype.unicodeChars = function (text, variant) {
                    if (!variant) variant = this.variant || 'normal';
                    return CommonWrapper.unicodeChars.call(this, text, variant);
                }
            }
            MathJax.startup.defaultReady();
        }
    },
    tex: {
        inlineMath: [['$', '$'], ['\\(', '\\)']],
        displayMath: [['$$', '$$'], ['\\[', '\\]']],

        // See: https://github.com/mathjax/MathJax/issues/2327
        processEscapes: false,

        processEnvironments: true
    },
    options: {
        skipHtmlTags: ['script', 'noscript', 'style', 'textarea', 'pre']
    }
};