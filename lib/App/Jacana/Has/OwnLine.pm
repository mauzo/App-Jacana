package App::Jacana::Has::OwnLine;

use App::Jacana::Moose -role;
use MooseX::Copiable;

has indent => (
    is          => "rw",
    isa         => Str,
    default     => "  ",
    predicate   => 1,
    clearer     => 1,
    traits      => [qw/Copiable/],
);


1;
