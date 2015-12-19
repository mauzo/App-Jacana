package App::Jacana::Has::RehearsalMark;

use Moose::Role;
use MooseX::AttributeShortcuts;
use MooseX::Copiable;

has number  => (
    is          => "rw",
    traits      => [qw/Copiable/],
    predicate   => 1,
    clearer     => 1,
    #isa         => Int,
);

1;
