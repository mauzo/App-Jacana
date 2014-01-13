package App::Jacana::Music::Note;

use 5.012;
use warnings;

use Moo;

extends "App::Jacana::Music";

has note    => is => "rw";
has octave  => is => "rw";
has length  => is => "rw";

my %Note = qw/c 0 d 1 e 2 f 4 g 5 a 6 b 7/;

sub position {
    my ($self, $centre) = @_;

    my $oct = $self->octave - 1;
    my $not = $self->note;
    my $off = $Note{$not};
    my $pos = $oct * 8 + $off - $centre;
    warn sprintf "NOTE [%d%s] AT [%d]", $oct + 1, $not, $pos;
    return $pos;
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

1;
