package App::Jacana::Has::Zoom;

use App::Jacana::Moose -role;
use MooseX::Copiable;

has zoom => is => "rw", traits => [qw/Copiable/];

1;
