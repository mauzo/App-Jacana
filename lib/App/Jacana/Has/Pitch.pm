package App::Jacana::Has::Pitch;

use App::Jacana::Moose -role;
use MooseX::Copiable;

use App::Jacana::Util::Pitch;
use App::Jacana::Tables qw/
    %Chr2Ly %Ly2Chr %Staff %Nearest %Pitch
/;

has note    => (
    is          => "rw", 
    traits      => [qw/Copiable/],
    isa         => Pitch,
);
has octave  => (
    is      => "rw", 
    traits  => [qw/Copiable/],
);
has chroma  => (
    is      => "rw",
    traits  => [qw/Copiable/],
    isa     => Chroma,
    default => 0,
);

sub pitch_rx { qr{ (?<note>[a-g]) (?<chroma>[eis]*) (?<octave>,+|'*) }x }

sub pitch_from_lily {
    my ($self, %n) = @_;

    my $oct = $n{octave};

    return (
        note    => $n{note},
        chroma  => $Ly2Chr{$n{chroma}},
        octave  => ($oct =~ /,/ ? -length($oct) : length($oct)),
    );
}

sub pitch_to_lily { 
    my ($self, $nooct)  = @_;

    my $oct = "";
    unless ($nooct) {
        $oct = $self->octave;
        $oct = ($oct < 0 ? "," x -$oct : "'" x $oct);
    }

    $self->note . $Chr2Ly{$self->chroma} . $oct;
}

sub staff_line {
    my ($self) = @_;

    my $cen = $self->ambient->find_role("Clef")->centre_line;
    my $oct = $self->octave;
    my $off = $Staff{$self->note};
    $oct * 7 + $off - $cen;
}

sub octave_up       { $_[0]->octave($_[0]->octave + 1) }
sub octave_down     { $_[0]->octave($_[0]->octave - 1) }

sub nearest {
    my ($self, $note, $chrm) = @_;
    App::Jacana::Util::Pitch->new(
        octave  => $self->octave + $Nearest{$self->note . $note},
        note    => $note,
        chroma  => $chrm || 0,
    );
}

sub _clamp {
    $_[0] < $_[1]   ? $_[1]
    : $_[0] > $_[2] ? $_[2]
    : $_[0]
}

sub pitch {
    my ($self) = @_;

    my $oct = $self->octave + 4;
    my $off = $Pitch{$self->note} + $self->chroma;
    _clamp $oct * 12 + $off, 0, 127;
}

1;
