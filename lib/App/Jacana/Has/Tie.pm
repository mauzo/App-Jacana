package App::Jacana::Has::Tie;

use Moose::Role;
use MooseX::Copiable;

has tie => (
    is          => "rw", 
    traits      => [qw/Copiable/],
    #isa         => Bool, 
    default     => 0, 
);

1;
