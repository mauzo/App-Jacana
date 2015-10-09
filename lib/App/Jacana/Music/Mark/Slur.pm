package App::Jacana::Music::Mark::Slur;

use Moo;
use App::Jacana::Util::Types;

extends "App::Jacana::Music::Mark";

has is_start => (
    is          => "ro",
    required    => 1,
    isa         => Bool,
);

sub lily_rx { qr/ (?<slur> \( | \) ) /x }

sub from_lily {
    my ($self, %n) = @_;
    $n{slur} or return;
    $self->new({ is_start => ($n{slur} eq "(") });
}

sub to_lily { $_[0]->is_start ? "(" : ")" }

sub draw {
    my ($self, $c, $pos, $up) = @_;

    my @y = $self->is_start 
        ? $up ? (3, 4, 4, 4) : (-3, -4, -4, -4)
        : $up ? (4, 4, 4, 3) : (-4, -4, -4, -3);
    $c->save;
        $c->set_line_width(0.7);
        $c->move_to(0, $y[0]);
        $c->curve_to(1, $y[1], 2, $y[2], 3, $y[3]);
        $c->stroke;
    $c->restore;

    return 0;
}

1;
