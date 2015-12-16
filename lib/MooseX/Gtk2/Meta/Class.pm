package MooseX::Gtk2::Meta::Class;

use Moose::Role;

Moose::Util::meta_class_alias "Gtk2";

BEGIN { *debug = \&MooseX::Gtk2::debug }

sub _gtk_signal_connect {
    my ($self, $on, $sig, $obj, $method) = @_;

    debug "CONNECTING [$sig] ON [$on] TO [$obj]->[$method]";
    Scalar::Util::weaken $on;

    my $id;
    $id = $on->signal_connect($sig,
        $obj->weak_method($method, sub { 
            $on->signal_handler_disconnect($id);
        }));
}

sub _gtk_process_attribute {
    my ($self, $obj, $key, $default, $map) = @_;

    for ($self->_gtk_methods_by_attribute($key)) {
        my ($method, $val) = @$_;
        $method = $method->name;

        $val //= "";
        my ($att, $name) = $val =~ /^(?:(.*)\.)?([\w:]*)$/ or next;
        $att //= $default;

        my $on = $obj->_resolve_object_path($att)
            or Carp::croak("Can't resolve '$att'");

        unless ($name) {
            $name = $method;
            $name =~ s/^_//;
            $name =~ s/_/-/g;
        }
        $map and ($on, $name) = $map->($on, $name);
        $self->_gtk_signal_connect($on, $name, $obj, $method);
    }
}

sub _gtk_methods_by_attribute {
    my ($self, $att) = @_;
    
    my @meth;
    for my $m ($self->get_nearest_methods_with_attributes) {
        for (@{$m->attributes}) {
            my ($n, $v) = /^(\w+)(?:\((.*)\))?$/x
                or next;
            $n eq $att or next;
            push @meth, [$m, $v];
        }
    }
    @meth;
}

# XXX
push @Data::Dump::FILTERS, sub {
    my ($ctx, $obj) = @_;

    Scalar::Util::blessed $obj && $obj->isa("Moose::Meta::Method") 
        or return;

    return {
        dump => sprintf "METAMETHOD[%s]", $obj->fully_qualified_name,
    };
};

sub _gtk_extra_init {
    my ($self, $obj) = @_;

    $self->_gtk_process_attribute($obj, "Signal", "widget");
    $self->_gtk_process_attribute($obj, "Action", "actions", sub {
        my ($att, $name) = @_;
        my $act = $att->get_action($name)
            or Carp::croak("Can't find action '$name' on '$att'");
        ($act, "activate");
    });

    my @props =
        grep $_->gtk_prop,
        grep $_->does("MooseX::Gtk2::Meta::Attribute"),
        $self->get_all_attributes;
    warn "GTK PROPS FOR [$obj]: " . join "; ", map $_->name, @props;
    $self->_gtk_setup_prop($obj, $_) for @props;
}

around new_object => sub {
    my ($super, $self, @args) = @_;

    my $obj = $self->$super(@args);
    $self->_gtk_extra_init($obj);
    
    $obj;
};

around _inline_extra_init => sub {
    my ($super, $self) = @_;

    return (
        $self->$super,
        q{Moose::Util::find_meta($instance)->_gtk_extra_init($instance);},
    );
};

sub _gtk_setup_prop {
    my ($self, $obj, $att) = @_;

    my $name    = $att->name;
    my ($reader, $writer)       = map $att->$_, 
        qw/get_read_method get_write_method/;
    my ($targs, $path, $prop)   = $att->_gtk_prop_args;

    my $class = Scalar::Util::blessed $obj;
    debug "GTK2: PROP BUILD CALLED FOR [$class][$name] -> [$path][$prop]";

    my $targ = $$targs{$obj} = $obj->_resolve_object_path($path);
    Scalar::Util::weaken $$targs{$obj};

    my $id;
    $id = $targ->signal_connect("notify::$prop", 
        $obj->weak_closure(sub {
            my ($self) = @_;
            debug "GTK2 GET PROP [$prop] FOR [$name]";
            my $value = $targ->get_property($prop);
            $value eq $self->$reader and return;
            $self->$writer($value);
        }, sub {
           $targ->signal_handler_disconnect($id);
        }));
    debug "GTK2 SET PROP [$prop] FOR [$name]";
    $targ->set_property($prop, $obj->$reader);
}

1;
