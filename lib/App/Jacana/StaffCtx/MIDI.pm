package App::Jacana::StaffCtx::MIDI;

use Moo;
use App::Jacana::Util::Types;
use namespace::clean;

extends "App::Jacana::StaffCtx";

has midi => is => "ro", required => 1;
has chan => is => "ro", required => 1;

has pitch   => is => "rw";

has on_start    => is => "ro", isa => CodeRef;
has on_stop     => is => "ro", isa => CodeRef;

sub start_note {
    my ($self) = @_;

    my $note = $self->item;
    if ($self->has_tie) { warn "TIE"; $self->clear_tie }
    else { $self->pitch($self->midi->note_on($self->chan, $note)) }
    $note->isa("App::Jacana::Music::Note") && $note->tie
        and $self->tie_from($note);
    warn sprintf "START NOTE [%s]", $self->pitch;
    #$self->on_start->($note);
}

sub stop_note {
    my ($self) = @_;

    if (my $p = $self->pitch) {
        unless ($self->has_tie) {
            warn "STOP NOTE [$p]";
            $self->midi->note_off($self->chan, $p);
            $self->pitch(undef);
        }
    }
    #$self->on_stop->($self->item);
}

1;
