package App::Jacana::Music::Slur;

use Moo;

extends "App::Jacana::Music";
with    qw/ App::Jacana::Has::Span /;

sub span_types { "slur" }

sub lily_rx { qr/ (?<slur> \( | \) ) /x }

sub from_lily {
    my ($self, %n) = @_;
    $self->new({ span_start => ($n{slur} eq "(") });
}

sub to_lily { $_[0]->span_start ? "(" : ")" }

sub draw {
    my ($self, $c) = @_;

    my @y = $self->span_start ? (-5, -6, -6, -6) : (-6, -6, -6, -5);
    $c->save;
        $c->set_line_width(0.7);
        $c->move_to(-4, $y[0]);
        $c->curve_to(-3, $y[1], -2, $y[2], -1, $y[3]);
        $c->stroke;
    $c->restore;

    return 0;
}

1;
