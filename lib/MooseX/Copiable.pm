package MooseX::Copiable;

use Moose::Exporter;
use Moose::Util;

my $My = "MooseX::Copiable";

Moose::Exporter->setup_import_methods(
    role_metaroles => {
        attribute           => ["$My\::Meta::Attribute::Role"],
    },
);

sub init_meta {
    my (undef, %args) = @_;

    Moose::Util::apply_all_roles $args{for_class}, "$My\::Role";
}

1;
