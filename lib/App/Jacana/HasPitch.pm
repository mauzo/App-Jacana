package App::Jacana::HasPitch;

use Moo::Role;

with qw/MooX::Role::Copiable/;

has note    => (
    is          => "rw", 
    isa         => sub { 
        $_[0] =~ /^[a-g]$/
            or Carp::confess("Bad note value [$_[0]]");
    },
    copiable    => 1,
);
has octave  => is => "rw", copiable => 1;
has chroma  => is => "rw", default => "", copiable => 1;

my %Staff = qw/c 0 d 1 e 2 f 3 g 4 a 5 b 6/;

sub staff_line {
    my ($self, $centre) = @_;

    my $oct = $self->octave;
    my $off = $Staff{$self->note};
    $oct * 7 + $off - $centre;
}

sub octave_up       { $_[0]->octave($_[0]->octave + 1) }
sub octave_down     { $_[0]->octave($_[0]->octave - 1) }

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
