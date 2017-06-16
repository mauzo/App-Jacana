package App::Jacana::StaffCtx::MIDI;

use App::Jacana::Moose;
use namespace::autoclean;

extends "App::Jacana::StaffCtx";

has midi => is => "ro", required => 1, weak_ref => 1;
has chan => is => "ro", required => 1;

has pitch           => is => "rw";
has transposition   => is => "rw";

has on_start    => is => "ro";#, isa => CodeRef;
has on_stop     => is => "ro";#, isa => CodeRef;

sub DEMOLISH {
    my ($self) = @_;
    $self->midi->free_chan($self->chan);
}

sub start_note {
    my ($self) = @_;

    my $note = $self->item;

    if ($self->has_tie) { 
        $self->clear_tie;
    }
    else {
        my $midi = $self->midi;
        my $chan = $self->chan;

        if ($note->DOES("App::Jacana::Has::MidiInstrument")) {
            $midi->set_program($chan, $note->program);
        }
        elsif ($note->DOES("App::Jacana::Has::MidiTranspose")) {
            $self->transposition($note);
        }
        elsif ($note->DOES("App::Jacana::Has::Pitch")) {
            my $trans = $self->transposition;
            my $sound = $trans ? $trans->transpose($note) : $note;
            my $pitch = $sound->pitch;

            my $written     = $note->pitch_to_lily;
            my $sounding    = $sound->pitch_to_lily;
            my $by = $trans ? $trans->into->pitch_to_lily : "";
            warn "*$chan NOTE [$written][$by] -> [$sounding]";

            $midi->note_on($chan, $pitch);
            $self->pitch($pitch);
        }
    }
    $note->isa("App::Jacana::Music::Note") && $note->tie
        and $self->tie_from($note);
    $self->on_start->($note);
}

sub stop_note {
    my ($self) = @_;

    if (my $p = $self->pitch) {
        unless ($self->has_tie) {
            $self->midi->note_off($self->chan, $p);
            $self->pitch(undef);
        }
    }
    $self->on_stop->($self->item);
}

1;
