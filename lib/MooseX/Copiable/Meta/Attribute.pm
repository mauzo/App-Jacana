package MooseX::Copiable::Meta::Attribute;

use Moose::Role;

has deep_copy => (
    is      => "ro",
    default => undef,
    #isa    => Bool,
);

1;
