package App::Jacana::HasGlyphs;

use Moo::Role;

sub _glyph {
    my ($self, $font, $gly) = @_;
    +{
        index   => $font->get_name_index($gly),
        x       => 0,
        y       => 0,
    };
}

sub _glyph_width {
    my ($self, $c, $gly) = @_;
    $c->glyph_extents($gly)->{x_advance};
}

1;
