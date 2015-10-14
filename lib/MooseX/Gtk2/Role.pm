package MooseX::Gtk2::Role;

use Moose::Role;
use MooseX::MethodAttributes::Role;

with qw/ 
    MooseX::Role::ObjectPath
    MooseX::Role::WeakClosure 
    MooseX::Role::NoGlobalDestruction 
/;

1;

=pod

BEGIN { *debug = \&MooseX::Gtk2::debug }

my $map_attr = sub {
    my ($self, $attr, $default, $map) = @_;

    my $methods = MooX::MethodAttributes
        ->methods_with_attr($self, $attr);

    for my $method (keys %$methods) {
        for (@{$$methods{$method}}) {
            $_ //= "";
            my ($att, $name) = /^(?:(.*)\.)?([\w:]*)$/ or next;
            $att //= $default;
            my $obj = $self->_resolve_object_path($att)
                or Carp::croak("Can't resolve '$att'");
            unless ($name) {
                $name = $method;
                $name =~ s/^_//;
                $name =~ s/_/-/g;
            }
            $map and ($obj, $name) = $map->($obj, $name);
            my $id;
            $id = $obj->signal_connect($name,
                $self->weak_method($method, sub {
                    $obj->signal_handler_disconnect($id);
                }),
            );
        }
    }
};

my $sig_connect = sub {
    my ($obj, $sig, $self, $method) = @_;
    Scalar::Util::weaken $obj;
    my $id;
    $id = $obj->signal_connect($sig,
        $self->weak_method($method, sub { 
            $obj->signal_handler_disconnect($id);
        }));
};

after BUILD => sub {
    my ($self)  = @_;

    my $class = Moose::Util::find_meta $self;
    debug "GTK2: BUILD CALLED FOR [$self]";

    my @methods = $class->get_nearest_methods_with_attributes;
    debug "GTK2: METHODS WITH ATTS: " . Data::Dump::pp [
        map { meth => $_->name, atts => [ $_->attributes ] },
        @methods,
    ];
    die;

    $self->$map_attr("Signal", "widget");
    $self->$map_attr("Action", "actions", sub {
        my ($att, $name) = @_;
        my $act = $att->get_action($name)
            or Carp::croak("Can't find action '$name' on '$att'");
        ($act, "activate");
    });

    my %props;
    $self->_gtk2_build_props_list(\%props);
    $self->_gtk2_setup_props($_, @{$props{$_}}) for keys %props;
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
