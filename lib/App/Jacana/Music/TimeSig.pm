package App::Jacana::Music::TimeSig;

use App::Jacana::Moose;

use App::Jacana::Util::Length;

use Data::Dump      qw/pp/;
use List::Util      qw/sum max/;
use Scalar::Util    qw/blessed/;

use namespace::autoclean;

extends "App::Jacana::Music";
with qw/
    App::Jacana::Has::Time
    App::Jacana::Has::Dialog
    App::Jacana::Music::HasAmbient
/;

has "+partial" => (
    isa         => "App::Jacana::Util::Length",
    coerce      => 1,
);

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

sub draw {
    my ($self, $c, $pos) = @_;
    
    my ($nwd, @num) = $c->layout_num($self->beats);
    my ($dwd, @den) = $c->layout_num($self->divisor);

    my $doff = ($nwd - $dwd) / 2;

    $c->save;
        $doff < 0 and $c->translate(-$doff, 0);
        $c->show_glyphs(@num);
        $c->translate($doff, 4);
        $c->show_glyphs(@den);
    $c->restore;

    return max $nwd, $dwd;
}

Moose::Util::find_meta(__PACKAGE__)->make_immutable;
