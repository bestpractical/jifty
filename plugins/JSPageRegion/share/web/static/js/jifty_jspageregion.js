
var CACHE = {};

Jifty.Web.new_action = function() {
    var args = _get_named_args(arguments);
    var a;
    jQuery(Jifty.Web.current_actions).each(function(i, v) {
        if (v.moniker == args.moniker) a = v;
    });
    if (!a) throw "hate";
    return a;
};

Jifty.web = function() { return Jifty.Web };

function _get_named_args(args) {
    var result = {};
    for (var i = 0; i < args.length; i+=2) {
        result[args[i]] = args[i+1];
    }
    return result;

}

function _get_onclick(action_hash, name, args, path) {
    var onclick = 'if(event.ctrlKey||event.metaKey||event.altKey||event.shiftKey) return true; return Jifty.update('
    + JSON.stringify({'continuation': {},
                      'actions': action_hash,
                      'fragments': [{'mode': 'Replace', 'args': args, 'region': name, 'path': path}]})
    +', this)';
    onclick = onclick.replace(/"/g, "'"); //"' )# grr emacs!
        return onclick;
}
// XXX
var hyperlink  = function() {
    var args = _get_named_args(arguments);
    var current_region = Jifty.Web.current_region;
    var onclick = _get_onclick({}, current_region.name, current_region.args, args.onclick[0].replace_with);
    outs( a(function() { attr(function()
                              {return ['onclick', onclick, 'href', '#']});
            return args.label
                }));
}

var render_param = function(a, field) { outs(a.render_param(field)) };
var form_return  = function() {
    var args = _get_named_args(arguments);
    var action_hash = {};
    action_hash[args.submit.moniker] = 1;
    // XXX: fix the fabricated refresh-self
    // XXX: implicit onclick only for now

    // $self->_push_onclick($args, { refresh_self => 1, submit => $args->{submit} });
    // @args{qw/mode path region/} = ('Replace', Jifty->web->current_region->path, Jifty->web->current_region);

    var current_region = Jifty.Web.current_region;
    var onclick = _get_onclick(action_hash, current_region.name, current_region.args, current_region.path);
    outs(
         div(function() {
                 attr(function() { return ['class', 'submit_button'] });
                 return input(function() { attr(function()
                                                {return ['type', 'submit',
                                                         'onclick', onclick,
                                                         'class', 'widget button',
                                                         'id', 'S' + (++SERIAL + SERIAL_postfix),
                                                         'value', args.label,
                                                         'name', 'J:V-region-__page-signup_widget=_signup|J:ACTIONS=signupnow'] })});
                     }));

};


function apply_cached_for_action(code, actions) {
    Jifty.Web.current_actions = actions;
    this['out_buf'] = '';
    this['outs'] = function(text) { this.out_buf += text };
    actions.each(register_action);
    var foo = code();
    return foo;
    alert(foo);
    throw 'not yet';
}



Jifty.JSPageRegion = function() {

};

Jifty.JSPageRegion.init = function() {
        return new Jifty.JSPageRegion();
};

Jifty.JSPageRegion.response_hook = function(response_fragment, f) {
        walk_node(fragment,
                  { cacheable: function(fragment_bit) {
                      var c_type = fragment_bit.getAttribute("type");
                      var textContent = '';
                      if (fragment_bit.textContent) {
                          textContent = fragment_bit.textContent;
                      } else if (fragment_bit.firstChild) {
                          textContent = fragment_bit.firstChild.nodeValue;
                      }
                      try {
                          var cache_func = eval(textContent);
                          CACHE[f['path']] = { 'type': c_type, 'content': cache_func };
                      }
                      catch(e) {
                          alert(e);
                          alert(textContent);
                      }
                  }
                  });
};

Jifty.JSPageRegion.prototype = {
    update_from_cache: [],
    process_fragment: function(f) {
        // CST Load the fragment from cache if it has been saved there
        var cached = CACHE[f['path']];

        // CST XXX XXX XXX
        if (cached && cached['type'] == 'static') {
            var my_fragment = document.createElement('fragment');
            var content_node = document.createElement('content');
            var cached_result;

            Jifty.Web.current_region = fragments[ f['region'] ];
            try { 
                cached_result = apply_cached_for_action(cached['content'], []) 
            }
            catch (e) { alert(e) }

            content_node.textContent = cached_result;
            my_fragment.appendChild(content_node);
            my_fragment.setAttribute('id', f['region']);

            this.update_from_cache.push(function(){ 
                apply_fragment_updates(my_fragment, f);
            } );

            return 1;
        }

        // CST XXX XXX XXX
        else if (cached && cached['type'] == 'action') {
            var my_fragment = document.createElement('fragment');
            var content_node = document.createElement('content');

            my_fragment.appendChild(content_node);
            my_fragment.setAttribute('id', f['region']);
            this.update_from_cache.push(function() {
                var cached_result;
                Jifty.Web.current_region = fragments[ f['region'] ];
                try {
                    cached_result = apply_cached_for_action(
                        cached['content'], Jifty.Form.getActions(form)
                    );
                }
                catch (e) { alert(e); throw e }
                content_node.textContent = cached_result;
                apply_fragment_updates(my_fragment, f);
            } );

            return 1;
        }
        
        // CST XXX XXX XXX
        else if (cached && cached['type'] == 'crudview') {
            try { 
                // XXX: get model class etc as metadata in cache
                // XXX: kill dup code
                var Todo = new AsynapseRecord('todo');
                var record = Todo.find(f['args']['id']);
                var my_fragment = document.createElement('fragment');
                var content_node = document.createElement('content');
                content_node.textContent = cached['content'](record);
                my_fragment.appendChild(content_node);
                my_fragment.setAttribute('id', f['region']);
                this.update_from_cache.push(function(){ apply_fragment_updates(my_fragment, f); } );
            }
            catch (e) { alert(e) };

            return 1;
        }
        return 0;
    },
    process_update: function() {
        jQuery.each(this.update_from_cache, function() { this() });
    }
};

Jifty.Update.response_hooks.push(Jifty.JSPageRegion.response_hook);
Jifty.Update.handler_hooks.push(Jifty.JSPageRegion);
