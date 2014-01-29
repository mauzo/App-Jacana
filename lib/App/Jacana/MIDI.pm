package App::Jacana::MIDI;

use 5.012;
use warnings;

use Moo;

use Audio::FluidSynth;
use Glib;
use Time::HiRes     qw/usleep/;
use List::Util      qw/min/;
use Scalar::Util    qw/refaddr/;

with qw/ MooX::WeakClosure /;

has settings    => is => "lazy";
has synth       => is => "lazy";
has driver      => is => "lazy";
has sfont       => is => "lazy";
has active      => is => "ro", default => sub { +{} };

sub _build_settings {
    my $s = Audio::FluidSynth::Settings->new;
    $s->set("audio.driver", "oss");
    $s;
}

sub _build_synth {
    my ($s) = @_;
    Audio::FluidSynth->new($s->settings);
}

sub _build_driver {
    my ($s) = @_;
    Audio::FluidSynth::Driver->new($s->settings, $s->synth);
}

sub _build_sfont {
    my ($s) = @_;
    $s->synth->sfload("fluidr3gm.sf2", 0);
}

sub add_active {
    my ($s, $id, @chan) = @_;
    $s->active->{$id} = \@chan;
}

sub remove_active {
    my ($s, $id) = @_;
    my $ch = delete $s->active->{$id};
    Glib::Source->remove($id);
    $s->_all_notes_off($_) for @$ch;
}

sub BUILD {
    my ($self) = @_;

    $self->synth->program_select($_, $self->sfont, 0, 68)
        for 0..1;
    $self->driver;
}

sub DESTROY {
    my ($self) = @_;
    $self->remove_active($_) for keys %{$self->active};
}

sub play_note {
    my ($self, $pitch, $length) = @_;
    my $time = (16*128)/$length;
    my $syn = $self->synth;

    eval { $syn->noteon(0, $pitch, 85) };
    Glib::Timeout->add($time, sub {
        eval { $syn->noteoff(0, $pitch) };
        return 0;
    });
}

sub _note_on {
    my ($self, $note) = @_;
    my $pitch;
    if ($note->DOES("App::Jacana::HasPitch")) {
        $pitch = $note->pitch;
        eval { $self->synth->noteon(1, $pitch, 85) };
    }
    my $duration = $note->DOES("App::Jacana::HasLength")
        ? $note->duration : undef;
    return ($pitch, $duration);
}

sub _note_off {
    my ($self, $pitch) = @_;
    defined $pitch 
        and eval { $self->synth->noteoff(1, $pitch) };
}

sub _all_notes_off {
    my ($self, $chan) = @_;
    eval { $self->synth->cc($chan, 123, 0) };
}

sub play_music {
    my ($self, $note, $start_note, $stop_note, $finish) = @_;

    my ($pitch, $when) = $self->_note_on($note);
    $start_note->($note);

    my $id;
    $id = Glib::Timeout->add(16, $self->weak_closure(sub {
        my ($self) = @_;

        $when-- > 1 and return 1;

        $self->_note_off($pitch);
        $stop_note->($note);

        if ($note->is_list_end) {
            $finish->();
            $self and $self->remove_active($id);
            return 0;
        }

        $note           = $note->next;
        ($pitch, $when) = $self->_note_on($note);
        $start_note->($note);
        return 1;
    }));
    $self->add_active($id, 1);
    $id;
}

1;
