package App::Jacana::StaffCtx::Cursor;

use App::Jacana::Moose;
use App::Jacana::Log;
use MooseX::Gtk2;

use App::Jacana::Log;

use namespace::autoclean;

extends "App::Jacana::StaffCtx";
with    qw/App::Jacana::Has::Tick/;

has doc => (
    is          => "ro",
    isa         => My("Document"),
    required    => 1,
    weak_ref    => 1,
    traits      => [qw/Copiable/],
);

has voice => (
    is          => "rwp",
    isa         => Music "Voice",
    required    => 1,
    weak_ref    => 1,
    traits      => [qw/Copiable/],
);

gtk_default_target signal => "doc";

has on_change => (
    is          => "ro",
    isa         => CodeRef,
    default     => sub { sub { } },
);

has "+item" => trigger => 1;

sub _trigger_item {
    my ($self, $new) = @_;
    $self->on_change->($new);
}

sub _changed :Signal {
    my ($self, $e) = @_;

    $e->has_tick or return;
    my $type    = $e->type;
    my $tick    = $e->tick;
    my $dur     = $e->duration;

    msgf TICK => "caught time change [%s] [%s] @[%u] +[%u]",
        $self, $type, $tick, $dur;

    if ($tick >= $self->tick) {
        msgf TICK => "...ignoring (%u >= %u)", $tick, $self->tick;
        return;
    }
    if ($type eq "remove") {
        if ($tick + $dur >= $self->tick) {
            msg TICK => "removal, step to", $e->item;
            $self->step_to(prev => $e->item);
            msg TICK => "now at", $self->item;
            return;
        }
        $dur = -$dur;
    }
    $self->add_to_tick($dur);
}

around next => sub {
    my ($super, $self) = @_;

    my $note = $self->$super or return;

    Has("Length")->check($note)
        and $self->add_to_tick($note->duration);
    
    return $note;
};

sub prev {
    my ($self) = @_;

    my $note = $self->item  or return;
    $note->is_music_start   and return $self->at_start;

    if (Has("Length")->check($note)) {
        my $d = $note->duration;
        my $t = $self->tick;
        if ($d > $t) {
            msg DEBUG => "NEGATIVE TICK [$d] > [$t]";
            $self->tick(0);
        }
        else {
            $self->add_to_tick(-$note->duration);
        }
    }

    return $self->item($note->prev_music);
}

sub step_to {
    my ($self, $dir, $to) = @_;

    my $on = $self->item    or Carp::confess("No item!");

    #msg DEBUG => "STEP_TO to [$to] on: " . $on->dump_music;

    while ($on != $to) {
        msg DEBUG => "STEP_TO on [$on] to [$to]";
        $on = $self->$dir   or Carp::confess("No $dir!");
    }
}

sub at_start {
    my ($self) = @_;
    if ($self->tick != 0) {
        msg DEBUG => "RESET TICK";
        $self->tick(0);
    }
    return;
}

sub change_voice {
    my ($self, $dir) = @_;

    $dir =~ /^(?:prev|next)$/m or Carp::confess("bad direction");
    $dir = "$dir\_voice";

    my $v = $self->voice->$dir;
    $v->is_voice_start and $v = $v->$dir;

    $self->_set_voice($v);

    my $time = $self->item->get_time;
    my $pos = StaffCtx("FindTime")->new(item => $v);
    $pos->skip_time($time);
    $self->copy_from($pos);
}

sub insert {
    my ($self, $new) = @_;
    
#    my $dur = $new->duration_to;
#    $dur and msg DEBUG =>("INSERT [$self] DURATION [$dur]"),
#        $self->add_to_tick($dur);

    $self->step_to(next => $self->item->insert($new));
    return $new;
}

sub remove {
    my ($self, $mark) = @_;

    my ($start, $end) = $mark
        ? $self->tick > $mark->tick
            ? ($mark, $self) : ($self, $mark)
        : ($self, $self);

    my $tick    = $start->tick;
    my $dur     = $end->tick - $tick;
    $_ = $_->item for $start, $end;

    Music("Voice")->check($start)   and $start = $start->next_music;
    Music("Voice")->check($start)   and return;
    $start->is_music_start          and Carp::confess("list start");

    my $first   = $start->duration;

    msg TICK => "before remove", $self->item;
    $self->doc->signal_emit(changed => Event("Change")->new(
        type        => "remove",
        item        => $start->prev_music,
        tick        => $tick - $first,
        duration    => $dur + $first,
    ));
    msg TICK => "after remove", $self->item;

    $_->break_ambient for $start, $end;
    $start->remove($end);
    return $start;
}

1;
