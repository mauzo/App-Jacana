package MooseX::Copiable;

use Moose::Exporter;
use Moose::Util;

my $My = "MooseX::Copiable";

Moose::Exporter->setup_import_methods(
    role_metaroles => {
        attribute           => ["$My\::Meta::Attribute::Role"],
        applied_attribute   => ["$My\::Meta::Attribute::Class"],
    },
    class_metaroles => {
        class               => ["$My\::Meta::Class"],
        attribute           => ["$My\::Meta::Attribute::Class"],
    },
);

sub init_meta {
    my (undef, %args) = @_;

    Moose::Util::apply_all_roles $args{for_class}, "$My\::Role";
}

1;
