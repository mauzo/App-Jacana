package App::Jacana::Music::KeySig;

use App::Jacana::Moose;

use YAML::XS ();

extends "App::Jacana::Music";
with    qw/ 
    App::Jacana::Has::Dialog
    App::Jacana::Has::Key 
    App::Jacana::Music::HasAmbient
/;

sub dialog { "KeySig" }

my %Staff = %{YAML::XS::Load <<YAML};
    treble:
        sharp:  [x, 4, 1, 5, 2, -1, 3, 0]
        flat:   [x, 0, 3, -1, 2, -2, 1, -3]
    alto:
        sharp:  [x, 3, 0, 4, 1, -2, 2, -1]
        flat:   [x, -1, 2, -2, 1, -3, 0, -4]
    tenor:
        sharp:  [x, -2, 2, -1, 3, 0, 4, 1]
        flat:   [x, 1, 4, 0, 3, -1, 2, -2]
    bass:
        sharp:  [x, 2, -1, 3, 0, -3, 1, -2]
        flat:   [x, -2, 1, -3, 0, -4, -1, -5]
YAML

sub lily_rx {
    qr( \\key \s+ (?<note>[a-g] (?:[ei]s)?)
        \s* \\(?<mode>major|minor)
    )x;
}

sub draw {
    my ($self, $c, $pos) = @_;

    my $key     = $self->key;
    my $clef    = $self->ambient->find_role("Clef")->clef;
    my $staff   = $Staff{$clef};
    my $count   = abs $key;
    my $chroma  = $key > 0 ? "sharp" : $key < 0 ? "flat" : "natural";
    my $glyph   = $c->glyph("accidentals.$chroma");
    my $gwd     = $c->glyph_width($glyph) + 0.2;

    my $wd = 0;
    my $show = sub {
        my ($y) = @_;
        $c->save;
            $c->translate($wd, -$y);
            $c->show_glyphs($glyph);
        $c->restore;
        $wd += $gwd;
    };

    if ($count) {
        $show->($$staff{$chroma}[$_])
            for 1..$count;
    }
    else {
        $c->save;
            $c->push_group;
                $show->($$staff{sharp}[1]);
            $c->pop_group_to_source;
            $c->paint_with_alpha(0.3);
        $c->restore;
    }

    return $wd + 0.5;
}

1;
