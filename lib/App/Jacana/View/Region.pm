package App::Jacana::View::Region;

use Moo::Role;
use MooX::MethodAttributes
    use     => [qw/ MooX::Gtk2 /];

use App::Jacana::Util::Types;

requires qw/ cursor redraw refresh /;

has mark => (
    is          => "rw", 
    predicate   => 1, 
    clearer     => 1, 
    isa         => Music,
);

sub set_mark :Action(SetMark) { 
    my ($self) = @_;
    $self->mark($self->cursor->position);
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
    $self->cursor->position($self->mark);
}

sub find_region {
    my ($self) = @_;

    my $mark    = $self->mark;
    my $curs    = $self->cursor->position;
    my $cv      = $curs->ambient->find_voice;

    if ($mark) {
        my $mv = $mark->ambient->find_voice;
        $mv == $cv or $mark = $cv->find_time($mark->get_time);
        return $mark->order_music($curs);
    }

    return ($cv, $cv->prev_music);
}

sub _rgn_change_octave {
    my ($self, $by) = @_;

    my ($pos, $end) = $self->find_region or return;
    while (1) {
        $pos->DOES("App::Jacana::Has::Pitch") 
            and $pos->octave($pos->octave + $by);
        $pos == $end and last;
        $pos = $pos->next;
    }

    $self->refresh;
}

sub rgn_octave_up :Action(RegionOctaveUp) { 
    $_[0]->_rgn_change_octave(+1);
}
sub rgn_octave_down :Action(RegionOctaveDown) { 
    $_[0]->_rgn_change_octave(-1);
}

sub rgn_transpose :Action(RegionTranspose) {
    my ($self) = @_;

    my ($pos, $end) = $self->find_region or return;
    $pos = $pos->find_next_with(qw/Key Pitch/) or do {
        $self->status_flash("Nothing to transpose!");
        return;
    };

    my $old     = $pos->ambient->find_role("Key");
    my $reset   = My("Music::KeySig")->new(copy_from => $old);
    my $new     = My("Music::KeySig")->new(copy_from => $old);
    $new->run_dialog($self);

    my $diff = $new->subtract($old);

    $pos == $old or $pos->prev->insert($new);
    $pos->break_ambient;
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

    $self->refresh;
}

sub _rgn_length {
    my ($self, $by) = @_;
    my ($pos, $end) = $self->find_region;

    while (1) {
        $pos->DOES(My "Has::Length") or next;
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
    $self->refresh;
}

sub rgn_halve :Action(RegionHalve) { $_[0]->_rgn_length(+1) }
sub rgn_double :Action(RegionDouble) { $_[0]->_rgn_length(-1) }

1;
