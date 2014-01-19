package App::Jacana::Music::Note;

use 5.012;
use warnings;

use Moo;

extends "App::Jacana::Music";
with    qw/ App::Jacana::HasPitch /;

has accid   => (is => "rw", default => "");
has length  => is => "rw";
has dots    => is => "rw", default => 0;

my %Pitch = qw/c 0 d 2 e 4 f 5 g 7 a 9 b 11/;
my %Accid = ("", 0, qw/is 1 es -1 isis 2 eses -2/);

sub to_lily {
    my ($self) = @_;
    my ($note, $acc, $oct, $len, $dots) = 
        map $self->$_, qw/note accid octave length dots/;
    $oct = (
        $oct > 0 ? "'" x $oct   :
        $oct < 0 ? "," x -$oct  :
        "");
    $dots = "." x $dots;
    "$note$acc$oct$len$dots";
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

sub _draw_stem {
    my ($self, $c, $up, $wd) = @_;

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
    $c->move_to($x, $y1);
    $c->line_to($x, $y2);
    $c->stroke;

    return ($x + ($up ? 0.1 : 0), $y2);
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
    my ($self, $c, $font) = @_;

    my $head    = $self->_notehead($font);
    my $ext     = $c->glyph_extents($head);
    my $wd      = $ext->{x_advance} + 1;

    $c->save;
        $c->translate(0.5, 0);
        $c->show_glyphs($head);
    $c->restore;

    return $wd;
}

sub _draw_dots {
    my ($self, $c, $wd, $pos) = @_;

    my $dots    = $self->dots   or return 0;
    my $yoff    = ($pos % 2) ? 0 : -1;

    $c->save;
        $c->set_line_width(0.8);
        $c->set_line_cap("round");
        for (1..$dots) {
            $c->move_to($wd + $_ * 1.6 - 0.8, $yoff);
            $c->close_path;
            $c->stroke;
        }
    $c->restore;

    return $dots * 1.6;
}

sub draw {
    my ($self, $c, $font, $pos) = @_;

    $c->set_line_width(0.4);
    $c->set_line_cap("round");

    my $wd  = $self->_draw_head($c, $font);
    my $len = $self->length;
    my $up  = $pos < 0;

    if ($len >= 2) {
        my ($ex, $ey) = $self->_draw_stem($c, $up, $wd);
        if (my ($tail, $tlen) = $self->_tail($font, $up)) {
            $ey += ($up ? -1 : 1) * $tlen;
            $self->_draw_tail($c, $tail, $ex, $ey);
        }
    }

    abs($pos) > 5   and $self->_draw_ledgers($c, $pos, $wd);

    $wd += $self->_draw_dots($c, $wd, $pos);

    return $wd;
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

sub duration { 
    my ($self) = @_;
    my $base = my $bit = 128;
    $base += $bit >>= 1 for 1..$self->dots;

    my $dur = $base / $self->length;
    my $lily = $self->to_lily;
    warn "DURATION [$dur] FOR [$lily]";
    return $dur;
}

1;
