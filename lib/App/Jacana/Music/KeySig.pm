package App::Jacana::Music::KeySig;

use Moo;

use YAML::XS ();

extends "App::Jacana::Music";

my @Fifths = qw/
    fes ces ges des aes ees bes
    f   c   g   d   a   e   b
    fis cis gis dis ais eis bis
/;
my %Fifths = map +($Fifths[$_], $_), 0..$#Fifths;
my %Mode = qw/ major 8 minor 11 /;

has key     => (
    is      => "rw",
    isa     => sub {
        $_[0] =~ /^0|-?[1-7]$/
            or die "Bad key signature [$_[0]]";
    },
    copiable => 1,
);
has mode    => (
    is      => "rw",
    isa     => sub {
        exists $Mode{$_[0]}
            or die "Bad key signature mode [$_[0]]";
    },
    copiable => 1,
);

sub staff_line { 0 }

sub to_lily {
    my ($self) = @_;
    sprintf "\\key %s \\%s", 
        $Fifths[$self->key + $Mode{$self->mode}],
        $self->mode;
}

sub from_lily {
    my ($self, %c) = @_;
    $self->new(
        mode    => $c{mode},
        key     => $Fifths{$c{note}} - $Mode{$c{mode}},
    );
}

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

sub draw {
    my ($self, $c, $pos) = @_;

    my $key     = $self->key;
    my $clef    = $c->clef->clef;
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
