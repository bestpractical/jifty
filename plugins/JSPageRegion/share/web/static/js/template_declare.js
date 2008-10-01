// FIXME: try not to pollute the namespace!
var tags = ['div', 'h2', 'dl', 'dt', 'dd', 'span', 'label', 'input', 'a'];
for (var i in tags) {
    this[tags[i]] = _mk_tag_wrapper(tags[i]);
}
this['form'] = _mk_tag_wrapper('form', function(attr) {
	return '<form method="post" enctype="multipart/form-data" >'; // XXX action: & friends
    }, null, 1);
var _ = function(str) { return str };
var attr = function() {};

function _mk_tag_wrapper(name, pre, post, want_outbuf) {
    return function() {
	var buf = new Array;
	var sp = this['attr'];
	var attr = {};
	this['attr'] = function(a) {
	    var foo;
	    a = a();
	    while(foo = a.splice(0, 2)) {
		if (foo.length == 0)
		    break;
		attr[foo[0]] = foo[1];
	    }
	};

	var flushed = '';
	if (this.out_buf) {
	    flushed = this.out_buf;
	    this.out_buf = '';
	}

	for (var i = 0; i < arguments.length; ++i) {
	    buf.push(typeof(arguments[i]) == 'function' ? arguments[i]() : arguments[i]);
	}
	var _mk_attr = function() {
	    var foo = ' ';
	    for (var k in attr) {
		if (k == 'extend') continue;
		foo += k + '="' + attr[k] + '"';
	    }
	    return foo;
	};
	var first = buf.splice(0, 1);
	var _pre = pre ? pre(attr) : '<'+name+_mk_attr(attr)+'>';
	var _post = post ? post(attr) : '</'+name+'>';
	if (want_outbuf && this.out_buf) {
	    first += this.out_buf;
	    this.out_buf = '';
	}
	return flushed + _pre + first + _post + buf.join('');
    }
};
