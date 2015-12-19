package MooseX::Copiable::Meta::Attribute;

use Moose::Role;

has deep_copy => (
    is      => "ro",
    default => 0,
    isa    => "Bool",
);

1;
