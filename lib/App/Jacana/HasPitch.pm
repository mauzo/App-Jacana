package App::Jacana::HasPitch;

use Moo::Role;

has note    => is => "rw";
has octave  => is => "rw";

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
}

1;
