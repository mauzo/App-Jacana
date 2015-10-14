package MooseX::Gtk2;

use Moose::Exporter;
use MooseX::MethodAttributes        ();
use MooseX::MethodAttributes::Role  ();

use Moose::Util     qw/ensure_all_roles is_role/;

BEGIN { *debug = $ENV{MOOSEX_GTK2_DEBUG} ? sub { warn @_ } : sub {} }

Moose::Exporter->setup_import_methods(
    class_metaroles => {
        class       => ["MooseX::Gtk2::Meta::Class"],
    },
);

sub init_meta {
    my (undef, %args) = @_;

    ensure_all_roles $args{for_class}, "MooseX::Gtk2::Role";
    if (is_role $args{for_class}) {
        MooseX::MethodAttributes::Role->init_meta(%args);
    }
    else {
        MooseX::MethodAttributes->init_meta(%args);
    }
}

=pod

package MooX::Gtk2::AccessorMaker;

use Moo::Role;

BEGIN { *debug = \&MooseX::Gtk2::debug }

around generate_method => sub {
    my ($orig, $self, @args) = @_;
    my ($into, $name, $spec) = @args;

    my $pspec = $$spec{gtk_prop} or return $self->$orig(@args);
    debug "GTK2: PSPEC [$pspec] FOR [$name]";
    my ($path, $prop) = $pspec =~ /^(.*)\.([\w-]+)$/
        or Carp::croak("Bad property spec '$pspec'");

    $$spec{trigger} = 1;

    # this call will update $spec
    my $methods = $self->$orig(@args);

    my $reader  = $$spec{reader} // $$spec{accessor};
    my $writer  = $$spec{writer} // $$spec{accessor};

    $reader && $writer or Carp::croak("Attribute '$name' is not rw");

    my $oname = $name;
    s/^\+// for $name;

    my $trigger = "_trigger_$name";
    my $mod     = \&Class::Method::Modifiers::install_modifier;

    Hash::Util::FieldHash::fieldhash my %obj;

    $mod->($into, "after", "_gtk2_build_props_list", sub {
        ${$_[1]}{$name} = [$reader, $writer, $path, $prop, \%obj];
    });

    $into->can($trigger)
        or $mod->($into, "fresh", $trigger, sub {});

    $mod->($into, "after", $trigger, sub {
        my ($self, $value) = @_;
        my $obj = $obj{$self} or return;

        debug "GTK2 TRIGGER [$self][$name] -> [$obj][$prop]";
        $value eq $obj->get_property($prop) and return;
        $obj->set_property($prop, $value);
    });

    return $methods;
};

=cut

1;
