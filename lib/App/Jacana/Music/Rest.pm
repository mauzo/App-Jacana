package App::Jacana::Music::Rest;

use Moo;

extends "App::Jacana::Music";
with    qw/
    App::Jacana::Has::Length
/;

my @Glyph   = qw/ M1 0 1 2 3 4 5 6 7 /;

sub staff_line { 0 }

sub lily_rx {
    my $length = $_[0]->length_rx;
    qr( r $length )x;
}

sub from_lily {
    my ($self, %n) = @_;
    $self->new({ $self->_length_from_lily(%n) });
}

sub to_lily {
    my ($self) = @_;
    "r" . $self->_length_to_lily;
}

sub draw {
    my ($self, $c, $pos) = @_;

    my $gly = $c->glyph("rests.$Glyph[$self->length]");
    $c->save;
        $c->translate(0.5, ($self->length == 1) ? -2 : 0);
        $c->show_glyphs($gly);
    $c->restore;

    my $wd = $c->glyph_width($gly) + 1;
    # rests always show dots in the first space
    return $wd + $self->_draw_dots($c, $wd, $pos);
}

1;
