package App::Jacana::Has::Tie;

use Moo::Role;
use App::Jacana::Util::Types;
use namespace::clean;

with qw/MooX::Role::Copiable/;

has tie => (
    is          => "rw", 
    isa         => Bool, 
    default     => 0, 
    copiable    => 1,
);

1;
