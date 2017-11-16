package App::Jacana::Has::Tick;

use App::Jacana::Moose -role;
use MooseX::Copiable;

has tick => (
    is          => "rw",
    default     => 0,
    isa         => Tick,
    traits      => [qw/Copiable/],
);

sub add_to_tick {
    my ($self, $t) = @_;
    $self->tick($self->tick + $t);
}

1;

