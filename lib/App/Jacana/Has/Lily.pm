package App::Jacana::Has::Lily;

use App::Jacana::Moose -role;
use MooseX::Copiable;

has lily => (
    is      => "rw", 
    isa     => Str,
    traits  => [qw/Copiable/],
);

has indent => (
    is          => "rw",
    isa         => Str,
    predicate   => 1,
    clearer     => 1,
    traits      => [qw/Copiable/],
);

1;
