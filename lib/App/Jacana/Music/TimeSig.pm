package App::Jacana::Music::TimeSig;

use Moo;
use MooX::AccessorMaker
    apply => [qw/ MooX::MakerRole::Coercer /];

use App::Jacana::Util::Length;

use Data::Dump      qw/pp/;
use List::Util      qw/sum max/;
use Scalar::Util    qw/blessed/;

use namespace::clean;

extends "App::Jacana::Music";
with qw/
    App::Jacana::Has::Time
    App::Jacana::Has::Dialog
    App::Jacana::Music::HasAmbient
/;

has "+partial" => coerce_to => "App::Jacana::Util::Length";

sub dialog { "TimeSig" }

sub lily_rx {
    qr( \\time \s+ (?<beats>[0-9]+) / (?<divisor>[0-9]+)
        (?: \s* \\partial \s+ (?<plen>[0-9]+) (?<pdots>\.*) )?
    )x;
}

sub from_lily {
    my ($self, %c) = @_;
    if ($c{plen}) {
        $c{partial} = {
            App::Jacana::Has::Length->_length_from_lily(
                length  => delete $c{plen},
                dots    => delete $c{pdots},
            ),
        };
    }
    $self->new(\%c);
}

sub to_lily {
    my ($self) = @_;
    my $par = $self->partial;
    sprintf("\\time %u/%u", $self->beats, $self->divisor)
        . ($par && " \\partial " . $par->_length_to_lily);
}

sub staff_line { 0 }

# use glyph names for consistency, even though numbers would be easier
my %Num = qw/
    0 zero 1 one 2 two 3 three 4 four 
    5 five 6 six 7 seven 8 eight 9 nine
/;

sub draw {
    my ($self, $c, $pos) = @_;
    
    my ($nwd, @num) = $c->layout_glyphs(\%Num, $self->beats);
    my ($dwd, @den) = $c->layout_glyphs(\%Num, $self->divisor);

    my $doff = ($nwd - $dwd) / 2;

    $c->save;
        $doff < 0 and $c->translate(-$doff, 0);
        $c->show_glyphs(@num);
        $c->translate($doff, 4);
        $c->show_glyphs(@den);
    $c->restore;

    return max $nwd, $dwd;
}

1;
