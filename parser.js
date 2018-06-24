var parser = require('./cblparser.js').parser;

parser.yy.extend = function(a,b){
    if(typeof a == 'undefined') a = {};
    for(key in b) {
        if(b.hasOwnProperty(key)) {
            a[key] = b[key]
        }
    }
    return a;
}

module.exports = parser;
