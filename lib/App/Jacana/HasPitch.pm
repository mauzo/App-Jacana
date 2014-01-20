package App::Jacana::HasPitch;

use Moo::Role;

has note    => (
    is => "rw", 
    isa => sub { 
        $_[0] =~ /^[a-g]$/
            or Carp::confess("Bad note value [$_[0]]");
    },
);
has octave  => is => "rw";
has chroma  => is => "rw", default => "";

my %Staff = qw/c 1 d 2 e 3 f 4 g 5 a 6 b 7/;

sub staff_line {
    my ($self, $centre) = @_;

    my $oct = $self->octave - 1;
    my $off = $Staff{$self->note};
    $oct * 7 + $off - $centre;
}

sub octave_up       { $_[0]->octave($_[0]->octave + 1) }
sub octave_down     { $_[0]->octave($_[0]->octave - 1) }

sub copy_pitch_from {
    my ($self, $from) = @_;
    $from->DOES(__PACKAGE__) or return;
    $self->octave($from->octave);
    $self->note($from->note);
    $self->chroma($from->chroma);
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
