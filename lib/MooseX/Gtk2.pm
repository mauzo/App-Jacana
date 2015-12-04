package MooseX::Gtk2;

use Moose::Exporter;
use MooseX::MethodAttributes        ();
use MooseX::MethodAttributes::Role  ();

use Moose::Util     qw/ensure_all_roles is_role/;

BEGIN { *debug = $ENV{MOOSEX_GTK2_DEBUG} ? sub { warn @_ } : sub {} }

my $Meta = "MooseX::Gtk2::Meta";

Moose::Exporter->setup_import_methods(
    class_metaroles => {
        attribute       => ["$Meta\::Attribute"],
        class           => ["$Meta\::Class"],
    },
#    role_metaroles => {
#        attribute           => ["$Meta\::Attribute"],
#        applied_attribute   => ["$Meta\::Attribute"],
#    },
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


=cut

1;
