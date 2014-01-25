package App::Jacana::Music::Rest;

use Moo;

extends "App::Jacana::Music";
with    qw/
    App::Jacana::HasGlyphs
    App::Jacana::HasLength
/;

my @Glyph   = qw/ M1 0 1 2 3 4 5 6 7 /;

sub staff_line { 0 }

sub to_lily {
    my ($self) = @_;
    "r" . $self->_length_to_lily;
}

sub draw {
    my ($self, $c, $font, $pos) = @_;

    my $gly = $self->_glyph($font, "rests.$Glyph[$self->length]");
    $c->save;
        $c->translate(0.5, ($self->length == 1) ? -2 : 0);
        $c->show_glyphs($gly);
    $c->restore;

    my $wd = $self->_glyph_width($c, $gly) + 1;
    # rests always show dots in the first space
    return $wd + $self->_draw_dots($c, $wd, $pos);
}

1;
