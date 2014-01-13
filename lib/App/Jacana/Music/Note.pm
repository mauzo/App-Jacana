package App::Jacana::Music::Note;

use 5.012;
use warnings;

use Moo;

extends "App::Jacana::Music";

has note    => is => "rw";
has accid   => (is => "rw", default => "");
has octave  => is => "rw";
has length  => is => "rw";

my %Staff = qw/c 0 d 1 e 2 f 4 g 5 a 6 b 7/;
my %Pitch = qw/c 0 d 2 e 4 f 5 g 7 a 9 b 11/;
my %Accid = ("", 0, qw/is 1 es -1 isis 2 eses -2/);

# staff position
sub position {
    my ($self, $centre) = @_;

    my $oct = $self->octave - 1;
    my $off = $Staff{$self->note};
    $oct * 8 + $off - $centre;
}

sub _notehead { "V" }

sub width {
    my ($self, $cr) = @_;

    my $ext = $cr->text_extents($self->_notehead);
    warn "WIDTH [$$ext{x_advance}]";
    $ext->{x_advance};
}

sub draw {
    my ($self, $cr) = @_;

    $cr->show_text($self->_notehead);
}

sub pitch {
    my ($self) = @_;

    my $oct = $self->octave + 4;
    my $off = $Pitch{$self->note} + $Accid{$self->accid};
    my $pit = $oct * 12 + $off;
    warn sprintf "PITCH [%u] FOR [%d%s%s]", $pit,
        $self->octave, $self->note, $self->accid;
    return $pit;
}

sub duration { $_[0]->length }

1;
