package App::Jacana::Music::MultiRest;

use Moo;

extends "App::Jacana::Music";
with    qw/
    App::Jacana::Has::Length
    App::Jacana::Has::Marks
    App::Jacana::Music::FindAmbient
/;

has bars    => (
    is      => "rw",
    isa     => sub {
        ref $_[0] || $_[0] !~ /^\d+$/
            and Carp::confess "Bad multi-rest length [$_[0]]";
    },
    default => 1,
);

sub staff_line { 0 }

sub lily_rx {
    my $marks   = $_[0]->marks_rx;
    qr( R1 \* \d+/\d+ \* (?<bars>\d+)  $marks )x;
}

sub from_lily {
    my ($self, %n) = @_;
    $self->new({ bars => $n{bars} });
}

sub to_lily {
    my ($self) = @_;
    my $time = $self->ambient->find_role("Time");
    sprintf "R1*%d/%d*%d",
        $time->beats, $time->divisor, $self->bars;
}

sub duration {
    my ($self) = @_;
    my $time = $self->ambient->find_role("Time");
    $time->length * $self->bars;
}

sub draw {
    my ($self, $c, $pos) = @_;

    my ($nwd, @num) = $c->layout_num($self->bars);
    my $rhs = $nwd + 9;

    $c->save;
        $c->set_line_width(0.4);
        $c->set_line_cap("round");
        $c->move_to(1, -2);
        $c->line_to(1, 2);
        $c->stroke;
        $c->move_to($rhs, -2);
        $c->line_to($rhs, 2);
        $c->stroke;
        $c->set_line_width(1.5);
        $c->set_line_cap("butt");
        $c->move_to(1, 0);
        $c->line_to($rhs, 0);
        $c->stroke;
        $c->translate(5, -6);
        $c->show_glyphs(@num);
    $c->restore;

    $rhs + 1;
}

1;
