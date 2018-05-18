package App::Jacana::StaffCtx::MIDI;

use App::Jacana::Moose;
use App::Jacana::Log;
use namespace::autoclean;

extends "App::Jacana::StaffCtx";
with    map "App::Jacana::StaffCtx::Has::$_", 
        qw/ Tie When /;

has midi => (
    is          => "ro", 
    required    => 1,
    isa         => My "MIDI",
    weak_ref    => 1,
);
has player => (
    is          => "ro", 
    required    => 1, 
    isa         => My "MIDI::Player",
    weak_ref    => 1,
);
has chan => (
    is          => "lazy", 
    isa         => Int,
);

has pitch           => is => "rw", isa => Maybe[Int];
has transposition   => is => "rw", isa => Has "MidiTranspose";

has on_start    => is => "ro", isa => CodeRef;
has on_stop     => is => "ro", isa => CodeRef;

sub _build_chan { 
    my ($self) = @_;

    my $midi    = $self->midi;
    my $c       = $midi->alloc_chan;

    my $prg     = $self->item->ambient->find_role("MidiInstrument");
    $midi->set_program($c, $prg->program);

    $c;
}

sub BUILD {
    my ($self) = @_;

    my $amb     = $self->item->ambient;

    my $trans   = $amb->find_role("MidiTranspose");
    $trans and $self->transposition($trans);

    if (my $tempo = $amb->find_role("Tempo")) {
        msg DEBUG => "STAFFCTX FOUND TEMPO [$tempo]: " . $tempo->to_lily;
        $self->player->set_tempo($tempo);
    }
}

sub DEMOLISH {
    my ($self) = @_;
    my $midi = $self->midi or return;
    $midi->free_chan($self->chan);
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

        if (Has("MidiInstrument")->check($note)) {
            $midi->set_program($chan, $note->program);
        }
        elsif (Has("MidiTranspose")->check($note)) {
            $self->transposition($note);
        }
        elsif (Has("Tempo")->check($note)) {
            $self->player->set_tempo($note);
        }
        elsif (Has("Pitch")->check($note)) {
            my $trans = $self->transposition;
            my $sound = $trans ? $trans->transpose($note) : $note;
            my $pitch = $sound->pitch;

            my $written     = $note->pitch_to_lily;
            my $sounding    = $sound->pitch_to_lily;
            my $by = $trans ? $trans->into->pitch_to_lily : "";
            msg DEBUG => "*$chan NOTE [$written][$by] -> [$sounding]";

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
