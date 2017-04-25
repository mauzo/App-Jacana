package App::Jacana::Has::Pitch;

use App::Jacana::Moose -role;
use MooseX::Copiable;

use App::Jacana::Util::Pitch;

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

my %Chr2Ly  = (0, "", qw/1 is -1 es 2 isis -2 eses/);
my %Ly2Chr  = reverse %Chr2Ly;

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
    my ($self)  = @_;

    my $oct = $self->octave;
    $oct = ($oct < 0 ? "," x -$oct : "'" x $oct);

    $self->note . $Chr2Ly{$self->chroma} . $oct;
}

my %Staff = qw/c 0 d 1 e 2 f 3 g 4 a 5 b 6/;

sub staff_line {
    my ($self) = @_;

    my $cen = $self->ambient->find_role("Clef")->centre_line;
    my $oct = $self->octave;
    my $off = $Staff{$self->note};
    $oct * 7 + $off - $cen;
}

sub octave_up       { $_[0]->octave($_[0]->octave + 1) }
sub octave_down     { $_[0]->octave($_[0]->octave - 1) }

my %Nearest = (
    cg => -1, ca => -1, cb => -1, cc =>  0, cd =>  0, ce =>  0, cf =>  0,
    da => -1, db => -1, dc =>  0, dd =>  0, de =>  0, df =>  0, dg =>  0,
    eb => -1, ec =>  0, ed =>  0, ee =>  0, ef =>  0, eg =>  0, ea =>  0,
    fc =>  0, fd =>  0, fe =>  0, ff =>  0, fg =>  0, fa =>  0, fb =>  0,
    gd =>  0, ge =>  0, gf =>  0, gg =>  0, ga =>  0, gb =>  0, gc =>  1,
    ae =>  0, af =>  0, ag =>  0, aa =>  0, ab =>  0, ac =>  1, ad =>  1,
    bf =>  0, bg =>  0, ba =>  0, bb =>  0, bc =>  1, bd =>  1, be =>  1,
);

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

my %Pitch = qw/c 0 d 2 e 4 f 5 g 7 a 9 b 11/;

sub pitch {
    my ($self) = @_;

    my $oct = $self->octave + 4;
    my $off = $Pitch{$self->note} + $self->chroma;
    _clamp $oct * 12 + $off, 0, 127;
}

1;
