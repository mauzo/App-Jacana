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
my @Num = qw/zero one two three four five six seven eight nine/;

sub _num_glyphs {
    my ($self, $c, $nums) = @_;

    my @gly =
        map [$_, $c->glyph_width($_)],
        map $c->glyph($Num[$_]), 
        split //, $nums;
    my $wd = sum map $$_[1], @gly;
    return $wd, @gly;
}

sub draw {
    my ($self, $c, $pos) = @_;
    
    my ($nwd, @num) = $self->_num_glyphs($c, $self->beats);
    my ($dwd, @den) = $self->_num_glyphs($c, $self->divisor);

    my $doff = ($nwd - $dwd) / 2;

    my $show = sub {
        $c->save;
        for (@_) {
            $c->show_glyphs($$_[0]);
            $c->translate($$_[1], 0);
        }
        $c->restore;
    };

    $c->save;
        $doff < 0 and $c->translate(-$doff, 0);
        $show->(@num);
        $c->translate($doff, 4);
        $show->(@den);
    $c->restore;

    return max $nwd, $dwd;
}

1;
