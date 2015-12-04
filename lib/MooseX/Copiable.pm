package MooseX::Copiable;

use Moose::Exporter;
use Moose::Util     qw/ensure_all_roles find_meta is_role with_traits/;

my $Role    = "MooseX::Copiable::Role";
my $Att     = "MooseX::Copiable::Meta::Attribute";

Moose::Exporter->setup_import_methods(
    role_metaroles => {
        attribute           => ["$Att\::Role"],
        applied_attribute   => ["$Att\::Class"],
    },
    class_metaroles => {
        attribute           => ["$Att\::Class"],
    },
);

sub init_meta {
    my (undef, %args) = @_;

    Moose::Util::apply_all_roles $args{for_class}, $Role;
}

1;
