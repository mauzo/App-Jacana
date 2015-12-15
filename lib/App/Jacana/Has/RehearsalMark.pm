package App::Jacana::Has::RehearsalMark;

use Moose::Role;
use MooseX::AttributeShortcuts;
use MooseX::Copiable;

has number  => (
    is          => "rw",
    predicate   => 1,
    clearer     => 1,
    #isa         => Int,
    copiable    => 1,
);

1;
