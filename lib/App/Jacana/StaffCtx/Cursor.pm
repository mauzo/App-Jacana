package App::Jacana::StaffCtx::Cursor;

use App::Jacana::Moose;
use namespace::autoclean;

extends "App::Jacana::StaffCtx";
with    qw/App::Jacana::Has::Tick/;

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

around next => sub {
    my ($super, $self) = @_;

    my $note = $self->$super or return;

    Has("Length")->check($note)
        and $self->add_to_tick($note->duration);
};

sub prev {
    my ($self) = @_;

    my $note = $self->item  or return;
    $note->is_music_start   and return $self->at_start;

    if (Has("Length")->check($note)) {
        my $d = $note->duration;
        my $t = $self->tick;
        if ($d > $t) {
            warn "NEGATIVE TICK [$d] > [$t]";
            $self->tick(0);
        }
        else {
            $self->add_to_tick(-$note->duration);
        }
    }

    $self->item($note->prev_music);
}

sub at_start {
    my ($self) = @_;
    if ($self->tick != 0) {
        warn "RESET TICK";
        $self->tick(0);
    }
    return;
}

sub insert {
    my ($self, $new) = @_;
    
    my $dur = $new->duration_to;
    $dur and $self->add_to_tick($dur);

    $self->item($self->item->insert($new));
    return $new;
}

sub remove {
    my ($self, $mark) = @_;

    my ($start, $end) = map $_->item, 
        $mark
            ? $self->tick > $mark->tick
                ? ($mark, $self) : ($self, $mark)
            : ($self, $self);

    Music("Voice")->check($start) and $start = $start->next_music;
    Music("Voice")->check($start) and return;

    my $dur = $start->duration_to($self->item);
    $dur and $self->add_to_tick(-$dur);

    $_->break_ambient for $start, $end;
    $self->item($start->remove($end));
    return $start;
}

1;
