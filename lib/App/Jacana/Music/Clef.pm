package App::Jacana::Music::Clef;

use Moo;

use App::Jacana::Util::Types;

use Carp ();

extends "App::Jacana::Music";

my %Clef = (
    treble      => [qw/G -2/],
    alto        => [qw/C 0/],
    tenor       => [qw/C 2/],
    bass        => [qw/F 2/],
    soprano     => [qw/C -4/],
);
my %Centre = qw/C 7 F 3 G 11/;

has clef => (
    is          => "rw",
    isa         => Enum[keys %Clef],
    required    => 1,
);

# This must be applied after 'has clef', because that is a requirement.
with    qw/
    App::Jacana::HasClef
    App::Jacana::Music::HasAmbient
/;

sub to_lily {
    "\\clef " . $_[0]->clef;
}

sub staff_line {
    my ($self, $centre) = @_;
    $Clef{$self->clef}[1];
}

sub centre_line {
    my ($self) = @_;
    $Centre{$Clef{$self->clef}[0]} - $self->staff_line;
}

sub draw {
    my ($self, $c, $pos) = @_;

    my $gly = $c->glyph("clefs.$Clef{$self->clef}[0]");
    $c->show_glyphs($gly);

    return $c->glyph_width($gly);
}

1;
