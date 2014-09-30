package App::Jacana::View::Render;

use Moo;

use App::Jacana::DrawCtx;
use App::Jacana::StaffCtx::Draw;
use App::Jacana::Util::Types;
use App::Jacana::View::StaffInfo;
use App::Jacana::View::System;

use List::BinarySearch      qw/binsearch_pos binsearch_range/;
use List::Util              qw/first max min/;
use POSIX                   qw/ceil/;

use namespace::clean;

has view => (
    is          => "ro",
    required    => 1,
    isa         => InstanceOf[My "View"],
    weak_ref    => 1,
);

has lines => (
    is      => "ro",
    lazy    => 1,
    clearer => 1,
    isa     => ArrayRef[InstanceOf[My "View::System"]],
    default => sub { +[] },
);

has width   => is => "rw", isa => Int, required => 1, trigger => 1;
has height  => is => "rw", isa => Int, default => 0;

sub _trigger_width {
    my ($self) = @_;
    @{$self->lines} = ();
}

sub find_line_at {
    my ($self, $y) = @_;

    my $lines = $self->lines;
    my $l = binsearch_pos { $a <=> $b->bottom } $y, @$lines;
    $$lines[$l];
}

sub show_lines {
    my ($self, $c, $from, $to) = @_;

    my $bottom = $self->render_upto(sub { 
        $_[0] && $_[0]->bottom > $to;
    });
    $to = min $to, $bottom;
    warn "SHOWING LINES FROM [$from] TO [$to]";

    my $lines   = $self->lines;
    @$lines or return;
    warn "CURRENT LINES: [" . join(", ", map $_->top, @$lines) . "]";

    my ($s, $e) = binsearch_range 
        { $a <=> (ref $b ? $b->top : $b) } 
        $from, $to, @$lines;
    $s and $s -= 1;
    warn "SHOWING LINES [$s]-[$e]";

    for my $l (@$lines[$s..$e]) {
        $c->set_source_surface($l->surface, 0, $l->top);
        $c->paint;
    }

    return $bottom;
}

sub render_upto {
    my ($self, $upto) = @_;

    warn "RENDERING UP TO [$upto]";
    my $lines   = $self->lines;
    my $scale   = $self->view->zoom;

    my ($start, $top);
    if (@$lines) {
        my $l   = $$lines[-1];
        $start  = [ map $_->continue, @{$l->staffs} ];
        $top    = $l->bottom;
    }
    else {
        $top    = 0;
        my $v   = $self->view->cursor->movement;
        my @vs;
        while (1) {
            $v->is_voice_end and last;
            $v = $v->next_voice;
            push @vs, $v;
        }
        $start  = [
            map My("StaffCtx::Draw")->new(
                item    => $vs[$_],
                y       => 24*($_ + 1),
            ),
            0..$#vs,
        ];
    }

    until (!@$start || @$lines && $upto->($$lines[-1])) {
        warn "RENDERING LINE AT [$top]:\n" .
            join "\n", map "  $_",
            map $_->item, @$start;
        my $l = My("View::System")->new(
            top     => $top,
            width   => $self->width,
            height  => ceil((@$start + 1)*24*$scale),
        );
        my $c = My("DrawCtx")->new(
            copy_from   => $self->view,
            surface     => $l->surface,
        );
        my @staffs = map My("View::StaffInfo")->create(
            $_, $c, 0, $top
        ), @$start;
        $l->staffs(\@staffs);

        my ($wd, $more) = $self->_show_music($c, $start, $top);
        $top += $l->height;
        $staffs[$_]->update($$start[$_], $c, $wd) for 0..$#staffs;
        push @$lines, $l;
        $more or last;
    }

    return @$start ? $top + 24*$scale : $top;
}

sub _show_scale {
    my ($self, $c, $wd, $ht) = @_;

    my $nx = $c->u2d($wd);

    $ht += 6;
    $c->set_line_width(0.2); $c->set_source_rgb(0, 0.7, 0);
    $c->move_to(0, $ht); $c->line_to($wd, $ht);
    for (0..($nx / 10)) {
        my $x = $c->d2u($_*10);
        $c->move_to($x, $ht);
        $c->line_to($x, $ht + (
            $_ % 10 ?
                $_ % 5 ? 3 : 5
            : 7));
        unless ($_ % 10) {
            $c->move_to($x, $ht + 12);
            $c->c->show_text($_/10);
        }
    }
    $c->stroke;
    $ht + 18;
}

#        $c->save;
#            $c->set_line_width(0.1);
#            $c->set_source_rgb(0.8, 0, 0);
#            $c->move_to($x, 0);
#            $c->line_to($x, 24*@voices);
#            $c->stroke;
#        $c->restore;
#            $c->save;
#                $c->set_line_width(0.1);
#                if (my $lsb = $item->lsb($c)) {
#                    $c->set_source_rgb(0.8, 0, 0.8);
#                    $c->move_to($x - $lsb, $y - 6);
#                    $c->line_to($x - $lsb, $y + 6);
#                    $c->stroke;
#                }
#                $c->set_source_rgb(0, 0.8, 0);
#                $c->move_to($x + $mywd, $y - 10);
#                $c->line_to($x + $mywd, $y + 10);
#                $c->stroke;
#            $c->restore;

sub _show_music {
    my ($self, $c, $start, $top) = @_;

    my $width   = $c->width;
    my @voices  = @$start;
    my $voices  = @voices;

    $c->set_source_rgb(0, 0, 0);
    $self->_show_stave($c, $_) for map $_->y, @voices;

    my $x = 4 + max map $self->_show_item($c, 4, $_), @voices;
    for (@voices) {
        @{$_->item->bbox}[0,1] = 
            ($c->u2d(4), $c->u2d($_->y - 12) + $top);
    }

    my $lastx;
    while ($x < $width - 6) {
        my $skip = min map $_->when, @voices;
        $_->skip($skip) for @voices;

        my @draw = grep !$_->when, @voices;
        @{$_->item->bbox}[2,3] = 
            ($c->u2d($x), $c->u2d($_->y + 12) + $top)
            for @draw;

        @draw = grep $_->next, @draw;
        @{$_->item->bbox}[0,1] = 
            ($c->u2d($x), $c->u2d($_->y - 12) + $top)
            for @draw;

        $x += max 0, 
            map $self->_show_barline($c, $x, $_),
            grep $_->barline,
            @draw;
        $lastx = $x; warn "LASTX [$lastx]";
        $x += max 0, map $_->lsb($c), map $_->item, @draw;
        $x += max 0, map $self->_show_item($c, $x, $_), @draw;

        @voices = grep $_->has_item, @voices or last;
    }

    my $ht = ($voices + 1) * 24;
    $c->save;
        $c->set_operator("clear");
        $c->set_source_rgb(0, 0, 0);
        $c->move_to($lastx, 0);
        $c->line_to($width, 0);
        $c->line_to($width, $ht);
        $c->line_to($lastx, $ht);
        $c->close_path;
        $c->fill;
    $c->restore;

    return ($x, !!@voices);
}

sub _show_stave {
    my ($self, $c, $y) = @_;

    $c->save;
        for (-2..2) {
            $c->move_to(0, 2*$_ + $y);
            $c->line_to($c->width, 2*$_ + $y);
        }
        $c->set_line_width(0.1);
        $c->stroke;
    $c->restore;
}

sub _show_item {
    my ($self, $c, $x, $v) = @_;
    my $y       = $v->y;
    my $item    = $v->item;

    $v->has_tie and $self->_show_tie($c, $x, $v);

    $c->save;
        $c->translate($x, $y);
        my $wd = $self->_draw_item($c, $item);
    $c->restore;

    $item->DOES(My "Has::Tie") && $item->tie
        and $v->start_tie($x + $wd);

    $wd = ($wd // 0) + $item->rsb;
    $item->bbox->[4] = $c->u2d($x + $wd);
    $wd;
}

sub _draw_item {
    my ($self, $c, $item) = @_;
    no warnings "uninitialized";

    my $pos = $item->staff_line;
    $c->save;
        $c->translate(0, -$pos);
        $c->move_to(0, 0);
        my $wd = $item->draw($c, $pos);
    $c->restore;

    return $wd;
}

sub _show_tie {
    my ($self, $c, $x, $v) = @_;
    my $item    = $v->item;
    my $from    = $v->tie_from;

    $c->save;
        if ($item->isa("App::Jacana::Music::Note")
            && $from->pitch == $item->pitch
        )       { $c->set_source_rgb(0, 0, 0) }
        else    { $c->set_source_rgb(1, 0, 0) }
        $c->set_line_width(0.5);

        my $x1  = $v->tie_x;
        my $x2  = $x - $item->lsb($c);
        my $xc  = ($x2 - $x1) / 4;
        my $y   = $v->y - $from->staff_line - 1;
        $c->move_to($x1, $y);
        $c->curve_to(
            $x1 + $xc,  $y - 2,
            $x2 - $xc,  $y - 2,
            $x2,        $y,
        );
        $c->stroke;
    $c->restore;

    $v->clear_tie;
}

sub _show_barline {
    my ($self, $c, $x, $bar) = @_;

    my $y = $bar->y;
    $c->save;
        my $p = $bar->pos 
            and $c->set_source_rgb(0.9, 0, 0);
        $c->set_line_width(0.5);
        $c->set_line_cap("butt");
        $c->move_to($x + 1, $y - 4);
        $c->line_to($x + 1, $y + 4);
        $c->stroke;
        if ($p) {
            $c->translate($x, $y - 4.5);
            $c->scale(0.5, 0.5);
            my (undef, @gly) = $c->layout_num($p);
            $c->show_glyphs(@gly);
        }
    $c->restore;
    return 3;
}

1;
