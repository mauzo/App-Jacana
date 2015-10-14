package MooseX::Gtk2::Meta::Class;

use Moose::Role;

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

around new_object => sub {
    my ($super, $self, @args) = @_;

    my $obj     = $self->$super(@args);

    $self->_gtk_process_attribute($obj, "Signal", "widget");
    $self->_gtk_process_attribute($obj, "Action", "actions", sub {
        my ($att, $name) = @_;
        my $act = $att->get_action($name)
            or Carp::croak("Can't find action '$name' on '$att'");
        ($act, "activate");
    });

#    my %props;
#    $self->_gtk2_build_props_list(\%props);
#    $self->_gtk2_setup_props($_, @{$props{$_}}) for keys %props;

    $obj;
};

sub _gtk2_setup_props {
    my ($self, $name, $reader, $writer, $path, $prop, $objs) = @_;

    my $class = Scalar::Util::blessed $self;
    debug "GTK2: PROP BUILD CALLED FOR [$class][$name] -> [$path][$prop]";

    my $obj = $$objs{$self} = $self->_resolve_object_path($path);
    Scalar::Util::weaken $$objs{$self};

    my $id;
    $id = $obj->signal_connect("notify::$prop", 
        $self->weak_closure(sub {
            my ($self) = @_;
            debug "GTK2 GET PROP [$prop] FOR [$name]";
            my $value = $obj->get_property($prop);
            $value eq $self->$reader and return;
            $self->$writer($value);
        }, sub {
           $obj->signal_handler_disconnect($id);
        }));
    debug "GTK2 SET PROP [$prop] FOR [$name]";
    $obj->set_property($prop, $self->$reader);
}

1;
