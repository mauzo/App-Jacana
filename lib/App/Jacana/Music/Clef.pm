package App::Jacana::Music::Clef;

use Moo;

use Carp ();

extends "App::Jacana::Music";

has type        => is => "ro";
has _staff_line => is => "ro", init_arg => "staff_line";

my %Preset = (
    treble  => {qw/type G staff_line -2/},
    soprano => {qw/type C staff_line -4/},
    alto    => {qw/type C staff_line 0/},
    tenor   => {qw/type C staff_line 2/},
    bass    => {qw/type F staff_line 2/},
);

sub BUILDARGS {
    my ($self, @args) = @_;
    my $args = (@args == 1 && ref $args[0]) ? $args[0] : {@args};
    if (my $preset = delete $$args{preset}) {
        my $def = $Preset{$preset}
            or Carp::croak "No such clef preset '$preset'";
        $$args{$_} = $$def{$_} for keys %$def;
    }
    $args;
}

# Hmm, I can't find a way to make the reader ignore arguments
sub staff_line { $_[0]->_staff_line }

my %Centre = qw/C 7 F 3 G 11/;

sub centre_line {
    my ($self) = @_;
    $Centre{$self->type} - $self->staff_line;
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

    my $gly = $self->_glyph($font, "clefs." . $self->type);
    $c->show_glyphs($gly);

    return $self->_glyph_width($c, $gly);
}

1;
