package App::Jacana::Has::Tempo;

use App::Jacana::Moose -role;
use MooseX::Copiable;

use POSIX qw/round/;

use App::Jacana::Util::Length;

use namespace::autoclean;

has beat => (
    is          => "rw",
    traits      => [qw/Copiable/],
    isa         => Has "Length",
    deep_copy   => 1,
    required    => 1,
);
has bpm => (
    is          => "rw",
    traits      => [qw/Copiable/],
    isa         => Int,
    required    => 1,
);

sub ms_per_tick {
    my ($self) = @_;

    my $beat    = $self->beat->duration;
    my $bpm     = $self->bpm;

    return round(60_000 / ($beat * $bpm));
}

1;
