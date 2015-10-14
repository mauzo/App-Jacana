package MooseX::Copiable::Meta::Attribute;

use Moose::Role;

has copiable => (
    is      => "ro",
#   isa     => Bool,
    default => 0,
);

has deep_copy => (
    is      => "ro",
    #isa    => Bool,
    default => 0,
);

1;
