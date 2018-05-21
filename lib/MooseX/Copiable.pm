package MooseX::Copiable;

use Moose::Exporter;
use Moose::Util;
use Carp;

use MooseX::Copiable::Meta::Attribute::Class;

my $My = "MooseX::Copiable";

BEGIN { 
    *debug = $ENV{MOOSEX_COPIABLE_DEBUG} ?
        sub { carp "COPIABLE: ", @_ } : sub {};
}

Moose::Exporter->setup_import_methods(
    role_metaroles => {
        attribute           => ["$My\::Meta::Attribute::Role"],
    },
);

sub init_meta {
    my (undef, %args) = @_;

    Moose::Util::ensure_all_roles $args{for_class}, "$My\::Role";
}

1;
