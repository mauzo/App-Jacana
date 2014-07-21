package App::Jacana::Has::Lily;

use Moo::Role;

with qw/ MooX::Role::Copiable /;

has lily => is => "rw", copiable => 1;

1;
