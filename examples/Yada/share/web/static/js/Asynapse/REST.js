if ( typeof Asynapse == 'undefined' ) {
    Asynapse = {}
}

if ( typeof Asynapse.REST == 'undefined' ) {
    Asynapse.REST = {}
}

Asynapse.REST.VERSION = "0.10"

Asynapse.REST.Model = function(model) {
    this._model = model
    return this;
}

Asynapse.REST.Model.prototype = {
    /* Corresponds Jifty's REST Pluing API */
    show_item_field: function(column, key, field) {
        var url = "/=/model/*/*/*/*.js"
            .replace("*", this._model)
            .replace("*", column)
            .replace("*", key)
            .replace("*", field)

        return this.eval_ajax_get(url);        
    },
    
    show_item: function(column, key) {
        var url = "/=/model/*/*/*.js"
            .replace("*", this._model)
            .replace("*", column)
            .replace("*", key)

        return this.eval_ajax_get(url);
    },

    list_model_items: function(column) {
        var url = "/=/model/*/*.js"
            .replace("*", this._model)
            .replace("*", column)

        return this.eval_ajax_get(url);
    },

    list_model_columns: function() {
        var url = "/=/model/*.js"
            .replace("*", this._model)

        return this.eval_ajax_get(url);
    },

    list_models: function() {
        var url = "/=/model.js"

        return this.eval_ajax_get(url);
    },

    create_item: function(item) {
        var url ="/=/model/*.js"
            .replace("*", this._model)

        var req = new Ajax.Request(url, {
            method: 'post',
            asynchronous: false,
            postBody: $H(item).toQueryString()
        });
        if ( req.responseIsSuccess() ) {
            eval(req.transport.responseText);
            return $H($_)
        } else {
            return null;
        }
    },
    
    replace_item: function(item) {
        var url = "/=/action/update" + this._model + ".js"
        new Ajax.Request(url, {
            method: 'post',
            contentType: 'application/x-www-form-urlencoded',
            postBody: $H(item).toQueryString()            
        });
    },

    delete_item: function(column, key) {
        var url = "/=/model/*/*/*"
            .replace("*", this._model)
            .replace("*", column)
            .replace("*", key)
        
        new Ajax.Request(url, {
            method: 'DELETE',
            contentType: 'application/x-www-form-urlencoded'
        });
        return null;
    },
    
    /* Internal Helpers */
    eval_ajax_get: function(url) {
        eval(this.ajax_get(url));
        return $_ ? Object.extend({},$_) : null;
    },
    ajax_get: function(url) {
        var req = new Ajax.Request(url, {
            method: 'GET',
            asynchronous: false
        })
        if ( req.responseIsSuccess() ) {
            return req.transport.responseText;
        }
        else {
            return "var $_ = null";
        }
    }
}

Asynapse.REST.Model.ActiveRecord = function(model) {
    Object.extend(this, new Asynapse.REST.Model(model));
    this._attributes = {}
    return this;
}

Asynapse.REST.Model.ActiveRecord.prototype = {
    new: function() {
        return this;
    },
    
    find: function(param) {
        if ( typeof param == 'number' ) {
            return this.show_item("id", param)
        }
    },

    find_by_id: function(id) {
        return this.show_item("id", id)
    },

    create: function(attributes) {
        var r = this.create_item(attributes);

        if (r.success) {
            return this.show_item("id", Number(r.content.id) )
        }
        return null;
    },

    delete: function(id) {
        this.delete_item("id", id)
        return null
    },

    update: function(id, attributes) {
        var obj = this.find(id)
        obj = Object.extend(obj, attributes)
        return this.replace_item( obj )
    },

    write_attribute: function(attr, value) {
    }
}

/* Great Aliases */
Asynapse.Model = Asynapse.REST.Model
Asynapse.ActiveRecord = Asynapse.REST.Model.ActiveRecord
AsynapseRecord = Asynapse.REST.Model.ActiveRecord

/**
=head1 NAME

Asynapse.REST - Asynapse REST Client

=head1 VERSION

This document describes Asynapse.REST version 0.10

=head1 SYNOPSIS

    # Define Your own AsynapseRecord Class.
    Person = new AsynapseRecord('person')

    # Use it
    var p = Person.find(1)

=head1 DESCRIPTION

Asynapse.REST is the namespace for being a general REST client in
Asynapse framework. Under this namespace, so far we arrange
C<Asynapse.REST.Model> for Asynapse Model Classes. It means to
provide an abstration layer for data existing at given REST server(s).

With many flavours of data abstration layer in the world, we choose
to emulate ActiveRecord as our first target, which has a plain
simple object semantics, and very compatible to javascript.
The implementation of it called C<AsynapseRecord>.

To use it, you must first create your own record classes, like this:

    Person = new AsynapseRecord('person')

After this, Person becomes your Person model class, and then you
can do:

    var p = Person.find(1)

To find a person by its id. Besides C<find>, C<create>, C<update>,
and C<delete> are also implemented.

Here's more detail about how to use these interfaces. They are all
"class methods".

=over

=item find( id )

Retrieve a record from this model with given id.

=item create( attr )

Create a new with attributes specified in attr hash.

=item update( id, attr )

Update the record with primary key id with new sets of
attributes specified in attr hash.

=item delete( id )

Remove the record with given id.

=back

=head1 CONFIGURATION AND ENVIRONMENT

AsynapseRecord requires no configuration files or environment
variables.  However, you need a Jifty instance with REST plugin
(which is given by default now.)

Since JavaScript cannot do XSS, it assumed the your Jifty instance's
URL resides at C</>, and entry points of REST servces starts from
C</=/>. It should be made possible to change this assumption in the
future to match more presets in different frameworks.

=head1 BUGS AND LIMITATIONS

The asynapse project is hosted at L<http://code.google.com/p/asynapse/>.
You may contact the authors or submit issues using the web interface.

=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Kang-min Liu C<< <gugod@gugod.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

*/ 

