package App::Jacana::Music::Clef;

use Moo;
use App::Jacana::Util::Types;
use Carp ();
use namespace::clean;

extends "App::Jacana::Music";

with qw/
    App::Jacana::Has::Clef
    App::Jacana::Music::HasAmbient
/;

# XXX I have no idea what's going on here...
*staff_line = \&App::Jacana::Has::Clef::staff_line;

warn sprintf "STAFF_LINE: Music [%s] Music::Clef [%s] Has::Clef [%s]",
    App::Jacana::Music->can("staff_line"),
    App::Jacana::Music::Clef->can("staff_line"),
    App::Jacana::Has::Clef->can("staff_line");

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
