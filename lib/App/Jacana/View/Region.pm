package App::Jacana::View::Region;

use App::Jacana::Moose -role;
use MooseX::Gtk2;

use App::Jacana::Log;

requires qw/ cursor redraw doc /;

has mark => (
    is          => "rw", 
    predicate   => 1, 
    clearer     => 1, 
    isa         => StaffCtx("Cursor"),
    coerce      => 1,
);

sub set_mark :Action(SetMark) { 
    my ($self) = @_;
    $self->clear_mark;
    $self->mark({copy_from => $self->cursor->_iter});
    warn "MARK TICK: " . $self->mark->tick;
    $self->redraw;
}
sub _act_clear_mark :Action(ClearMark) {
    my ($self) = @_;
    $self->clear_mark;
    $self->redraw;
}
sub goto_mark :Action(GotoMark) {
    my ($self) = @_;
    $self->has_mark or return;
    $self->cursor->_iter->copy_from($self->mark);
}

sub find_region {
    my ($self) = @_;

    $self->mark or return;

    my $mt = $self->mark->tick;
    my $ct = $self->cursor->_iter->tick;
    warn "MARK TICK [$mt] CURSOR TICK [$ct]";

    my $mark    = $self->mark->item;
    my $curs    = $self->cursor->position;
    my $cv      = $curs->ambient->find_voice;

    for ($mark, $curs) {
        if ($_ && $_->is_music_start) {
            $_->is_music_end and return;
            $_ = $_->next_music;
        }
    }

    if ($mark) {
        my $mv = $mark->ambient->find_voice;
        $mv == $cv or $mark = $cv->find_time($mark->get_time);
        return $mark->order_music($curs);
    }

    $cv->is_music_end and return;
    return ($cv, $cv->prev_music);
}

sub _rgn_change_octave {
    my ($self, $by) = @_;

    # XXX this wants to be a StaffCtx::Region
    my ($start, $end) = $self->find_region or return;

    $self->doc->signal_emit(changed => Event("Change")->new(
        type    => "other",
        item    => $start,
    ));

    my $pos = $start;
    while (1) {
        Has("Pitch")->check($pos)
            and $pos->octave($pos->octave + $by);
        $pos == $end and last;
        $pos = $pos->next;
    }
}

sub rgn_octave_up :Action(RegionOctaveUp) { 
    $_[0]->_rgn_change_octave(+1);
}
sub rgn_octave_down :Action(RegionOctaveDown) { 
    $_[0]->_rgn_change_octave(-1);
}

sub rgn_transpose :Action(RegionTranspose) {
    my ($self) = @_;

    # XXX this wants to be a StaffCtx::Region
    my ($start, $end) = $self->find_region or return;
    Music("Voice")->check($start)
        and ($start = $start->next or return);
    $start = $start->find_next_with(qw/Key Pitch/) or do {
        $self->status_flash("Nothing to transpose!");
        return;
    };

    my $old     = $start->ambient->find_role("Key");
    my $reset   = My("Music::KeySig")->new(copy_from => $old);
    my $new     = My("Music::KeySig")->new(copy_from => $old);
    $new->run_dialog($self);

    my $diff = $new->subtract($old);

    $self->doc->signal_emit(changed => Event("Change")->new(
        type    => "other",
        item    => $start,
    ));

    $start == $old or $start->prev->insert($new);
    $start->break_ambient;

    my $pos = $start;
    while (1) {
        $pos = $new->transpose($diff, $pos, $end) or last;
        $reset = My("Music::KeySig")->new(copy_from => $pos);
        $pos->add($diff);
        $pos == $end and last;
        $pos = $pos->next
            or die "Transpose ran off the end of the voice!";
    }
    $end->find_next_with("Pitch") and $end->insert($reset);
    $end->break_ambient;
}

sub _rgn_length {
    my ($self, $by) = @_;

    # XXX this wants to be a StaffCtx::Region
    my ($start, $end) = $self->find_region or return;

    $self->doc->signal_emit(changed => Event("Change")->new(
        type    => "other",
        item    => $start,
    ));

    my $pos = $start;
    while (1) {
        $pos ~~ Has "Length"    or next;
        my $len = $pos->length;
        $len == 0 && $by == -1
            || $len == 8 && $by == 1
            and next;
        $pos->length($len + $by);
    }
    continue {
        $pos == $end and last;
        $pos = $pos->next
            or die "Length change ran off the end of the list!";
    }
}

sub rgn_halve :Action(RegionHalve) { $_[0]->_rgn_length(+1) }
sub rgn_double :Action(RegionDouble) { $_[0]->_rgn_length(-1) }

1;
