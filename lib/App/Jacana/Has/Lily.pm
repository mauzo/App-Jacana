package App::Jacana::Has::Lily;

use Moose::Role;
use MooseX::Copiable;

has lily => is => "rw", copiable => 1;

1;
