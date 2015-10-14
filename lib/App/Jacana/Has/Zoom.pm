package App::Jacana::Has::Zoom;

use Moose::Role;
use MooseX::Copiable;

has zoom => is => "rw", copiable => 1;

1;
