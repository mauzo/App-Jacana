package App::Jacana::Has::Zoom;

use Moo::Role;

with "MooX::Role::Copiable";

has zoom => is => "rw", copiable => 1;

1;
