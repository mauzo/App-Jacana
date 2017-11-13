package App::Jacana::StaffCtx::Cursor;

use App::Jacana::Moose;
use namespace::autoclean;

extends "App::Jacana::StaffCtx";

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

sub prev {
    my ($self) = @_;
    my $note = $self->item  or return;
    $note->is_music_start   and return $self->at_start;
    $self->item($note->prev);
    return 1;
}

sub at_start { return }

sub insert {
    my ($self, $new) = @_;
    $self->item($self->item->insert($new));
}

sub remove {
    my ($self, $upto) = @_;
    $self->item($self->item->remove($upto));
}

1;
