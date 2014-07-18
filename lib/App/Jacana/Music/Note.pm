package App::Jacana::Music::Note;

use 5.012;
use warnings;

use Moo;
use App::Jacana::Util::Types;
use namespace::clean;

extends "App::Jacana::Music";
with    qw/
    App::Jacana::Has::Pitch 
    App::Jacana::Has::Length 
/;

has tie => is => "rw", isa => Bool, default => 0;

my %Chroma = (0, "", qw/1 is -1 es 2 isis -2 eses/);

sub to_lily {
    my ($self) = @_;
    my ($note, $chrm, $oct, $len) = 
        map $self->$_, qw/note chroma octave _length_to_lily/;
    $oct = (
        $oct > 0 ? "'" x $oct   :
        $oct < 0 ? "," x -$oct  :
        "");
    my $tie = $self->tie ? "~" : "";
    "$note$Chroma{$chrm}$oct$len$tie";
}

my %Heads   = qw/0 sM1 1 s0 2 s1/;
my %Tails   = qw/4 3 5 4 6 5 7 6 8 7/;
my %Acci    = qw/0 natural 1 sharp -1 flat 2 doublesharp -2 flatflat/;

sub _notehead {
    my ($self, $c) = @_;
    my $len = $Heads{$self->length} || "s2";
    $c->glyph("noteheads.$len");
}

sub _tail {
    my ($self, $c, $up) = @_;
    my $len = $Tails{$self->length} or return;
    my $dir = $up ? "u" : "d";
    my $gly = $c->glyph("flags.$dir$len");
    my $off = ($len - 2) * 1.5;
    return ($gly, $off);
}

sub _accidental {
    my ($self, $c) = @_;
    my $chroma  = $self->chroma;
    my $note    = $self->note;
    my $ambient = $self->ambient
        or die "Can't find ambient for: " . Data::Dump::pp($self);
    my $key     = $self->ambient->find_role("Key")
        or return;

    $chroma == $key->chroma($note) and return;
    $c->glyph("accidentals.$Acci{$chroma}");
}

sub lsb {
    my ($self, $c) = @_;

    my $gly = $self->_accidental($c) or return 0;
    $c->glyph_width($gly) + 1;
}


sub _draw_accidental {
    my ($self, $c) = @_;

    my $gly = $self->_accidental($c) or return 0;
    my $wd  = $c->glyph_width($gly);

    $c->save;
        $c->translate(-$wd/2 - 1, 0);
        $c->show_glyphs($gly);
    $c->restore;
}

sub _draw_stem {
    my ($self, $c, $up, $wd) = @_;

    my ($x, $y1, $y2);
    if ($up) {
        $x  = $wd - 0.7;
        $y1 = -0.5;
        $y2 = -6.5;
    }
    else {
        $x  = 0.7;
        $y1 = 0.5;
        $y2 = 5.5;
    }
    $c->move_to($x, $y1);
    $c->line_to($x, $y2);
    $c->stroke;

    return ($x + -0.1, $y2);
}

sub _draw_tail {
    my ($self, $c, $tail, $x, $y) = @_;

    $c->save;
    $c->translate($x, $y);
    $c->show_glyphs($tail);
    $c->restore;
}

sub _draw_ledgers {
    my ($self, $c, $pos, $wd) = @_;

    my $sgn = $pos > 0 ? 1 : -1;
    my $n   = int(abs($pos)/2) - 2;
    my $off = $pos % 2 ? -1 : -2;

    for (1..$n) {
        my $y = $sgn * (2 * $_ + $off);
        $c->move_to(0, $y);
        $c->line_to($wd, $y);
        $c->stroke;
    }
}

sub _draw_head {
    my ($self, $c) = @_;

    my $head    = $self->_notehead($c);
    my $wd      = $c->glyph_width($head) + 1;

    $c->save;
        $c->translate(0.5, 0);
        $c->show_glyphs($head);
    $c->restore;

    return $wd;
}

sub draw {
    my ($self, $c, $pos) = @_;

    $c->set_line_width(0.4);
    $c->set_line_cap("round");

    $self->_draw_accidental($c);

    my $wd  = $self->_draw_head($c);

    my $len = $self->length;
    my $up  = $pos < 0;

    if ($len >= 2) {
        my ($ex, $ey) = $self->_draw_stem($c, $up, $wd);
        if (my ($tail, $tlen) = $self->_tail($c, $up)) {
            $ey += ($up ? -1 : 1) * $tlen;
            $self->_draw_tail($c, $tail, $ex, $ey);
        }
    }

    abs($pos) > 5   and $self->_draw_ledgers($c, $pos, $wd);

    $wd += $self->_draw_dots($c, $wd, $pos);

    return $wd;
}

1;
