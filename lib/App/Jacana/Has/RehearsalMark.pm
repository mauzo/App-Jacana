package App::Jacana::Has::RehearsalMark;

use Moo::Role;

use App::Jacana::Util::Types;

with qw/ MooX::Role::Copiable /;

has number  => (
    is          => "rw",
    predicate   => 1,
    clearer     => 1,
    isa         => Int,
    copiable    => 1,
);

1;
