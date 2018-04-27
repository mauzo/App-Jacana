package App::Jacana::Music::Clef;

use App::Jacana::Moose;
use Carp ();
use namespace::autoclean;

extends "App::Jacana::Music";

with qw/
    App::Jacana::Has::Clef
    App::Jacana::Music::HasAmbient
/;

sub lily_rx {
    qr( \\clef \s+ (?: "(?<clef>[a-z]+)" | (?<clef>[a-z]+) ) )x
}
sub to_lily {
    "\\clef " . $_[0]->clef;
}

sub draw {
    my ($self, $c, $pos) = @_;

    my $gly = $c->glyph("clefs." . $self->clef_type);
    $c->show_glyphs($gly);

    return $c->glyph_width($gly);
}

1;
