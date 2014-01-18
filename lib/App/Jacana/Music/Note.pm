package App::Jacana::Music::Note;

use 5.012;
use warnings;

use Moo;

extends "App::Jacana::Music";

has note    => is => "rw";
has accid   => (is => "rw", default => "");
has octave  => is => "rw";
has length  => is => "rw";

my %Staff = qw/c 1 d 2 e 3 f 4 g 5 a 6 b 7/;
my %Pitch = qw/c 0 d 2 e 4 f 5 g 7 a 9 b 11/;
my %Accid = ("", 0, qw/is 1 es -1 isis 2 eses -2/);

sub to_lily {
    my ($self) = @_;
    my ($note, $acc, $oct, $len) = 
        map $self->$_, qw/note accid octave length/;
    $oct = (
        $oct > 0 ? "'" x $oct   :
        $oct < 0 ? "," x -$oct  :
        "");
    "$note$acc$oct$len";
}

# staff position
sub position {
    my ($self, $centre) = @_;

    my $oct = $self->octave - 1;
    my $off = $Staff{$self->note};
    $oct * 7 + $off - $centre;
}

sub _glyph {
    my ($self, $font, $gly) = @_;
    +{
        index   => $font->get_name_index($gly),
        x       => 0,
        y       => 0,
    };
}

my %Heads = qw/1 s0 2 s1/;
my %Tails = qw/8 3 16 4 32 5 64 6 128 7/;

sub _notehead {
    my ($self, $font) = @_;
    my $len = $Heads{$self->length} || "s2";
    $self->_glyph($font, "noteheads.$len");
}

sub _tail {
    my ($self, $font, $up) = @_;
    my $len = $Tails{$self->length} or return;
    my $dir = $up ? "u" : "d";
    my $gly = $self->_glyph($font, "flags.$dir$len");
    my $off = ($len - 2) * 1.5;
    return ($gly, $off);
}

sub width {
    my ($self, $cr, $font) = @_;

    my $ext = $cr->glyph_extents($self->_notehead($font));
    $ext->{x_advance} + 1;
}

sub _draw_stem {
    my ($self, $cr, $up, $wd) = @_;

    my ($x, $y1, $y2);
    if ($up) {
        $x  = $wd - 0.6;
        $y1 = -0.5;
        $y2 = -6.5;
    }
    else {
        $x  = 0.6;
        $y1 = 0.5;
        $y2 = 5.5;
    }
    $cr->move_to($x, $y1);
    $cr->line_to($x, $y2);
    $cr->stroke;

    return ($x + ($up ? 0.1 : 0), $y2);
}

sub _draw_tail {
    my ($self, $cr, $tail, $x, $y) = @_;

    $cr->save;
    $cr->translate($x, $y);
    $cr->show_glyphs($tail);
    $cr->restore;
}

sub _draw_ledgers {
    my ($self, $cr, $pos, $wd) = @_;

    my $sgn = $pos > 0 ? 1 : -1;
    my $n   = int(abs($pos)/2) - 2;
    my $off = $pos % 2 ? -1 : -2;

    for (1..$n) {
        my $y = $sgn * (2 * $_ + $off);
        $cr->move_to(0, $y);
        $cr->line_to($wd, $y);
        $cr->stroke;
    }
}

sub draw {
    my ($self, $cr, $font, $pos) = @_;

    $cr->set_line_width(0.4);
    $cr->set_line_cap("round");

    $cr->save;
    $cr->translate(0.5, 0);
    $cr->show_glyphs($self->_notehead($font));
    $cr->restore;

    my $len = $self->length;
    my $up  = $pos < 0;
    my $wd  = $self->width($cr, $font);

    abs($pos) > 5   and $self->_draw_ledgers($cr, $pos, $wd);
    if ($len >= 2) {
        my ($ex, $ey) = $self->_draw_stem($cr, $up, $wd);
        if (my ($tail, $tlen) = $self->_tail($font, $up)) {
            $ey += ($up ? -1 : 1) * $tlen;
            $self->_draw_tail($cr, $tail, $ex, $ey);
        }
    }
}

sub _clamp {
    $_[0] < $_[1]   ? $_[1]
    : $_[0] > $_[2] ? $_[2]
    : $_[0]
}

sub pitch {
    my ($self) = @_;

    my $oct = $self->octave + 4;
    my $off = $Pitch{$self->note} + $Accid{$self->accid};
    _clamp $oct * 12 + $off, 0, 127;
}

sub duration { $_[0]->length }

1;
