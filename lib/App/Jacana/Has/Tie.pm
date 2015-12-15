package App::Jacana::Has::Tie;

use Moose::Role;
use MooseX::Copiable;

has tie => (
    is          => "rw", 
    #isa         => Bool, 
    default     => 0, 
    copiable    => 1,
);

1;
