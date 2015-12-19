package App::Jacana::Has::Lily;

use Moose::Role;
use MooseX::Copiable;

has lily => is => "rw", traits => [qw/Copiable/];

1;
