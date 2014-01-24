package App::Jacana::Music::Clef;

use Moo;

use App::Jacana::Util::Types;

use Carp ();

extends "App::Jacana::Music";
with    qw/ App::Jacana::HasCentre /;

my %Type = (
    treble      => [qw/G -2/],
    alto        => [qw/C 0/],
    tenor       => [qw/C 2/],
    bass        => [qw/F 2/],
    soprano     => [qw/C -4/],
);
my %Centre = qw/C 7 F 3 G 11/;

has type => (
    is  => "rw",
    isa => Enum[keys %Type],
);

sub staff_line {
    my ($self, $centre) = @_;
    $Type{$self->type}[1];
}

sub centre_line {
    my ($self) = @_;
    $Centre{$Type{$self->type}[0]} - $self->staff_line;
}

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

sub draw {
    my ($self, $c, $font, $pos) = @_;

    my $gly = $self->_glyph($font, "clefs." . 
        $Type{$self->type}[0]);
    $c->show_glyphs($gly);

    return $self->_glyph_width($c, $gly);
}

1;
