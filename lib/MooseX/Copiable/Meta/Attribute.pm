package MooseX::Copiable::Meta::Attribute;

use Moose::Role;

has deep_copy => (
    is      => "ro",
    #isa    => Bool,
    default => 0,
);

1;
