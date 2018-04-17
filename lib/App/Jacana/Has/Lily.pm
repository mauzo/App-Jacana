package App::Jacana::Has::Lily;

use App::Jacana::Moose -role;
use MooseX::Copiable;

has lily => (
    is      => "rw", 
    isa     => Str,
    traits  => [qw/Copiable/],
);

1;
