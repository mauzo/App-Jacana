package App::Jacana::MIDI;

use 5.012;
use warnings;

use Moo;

use Audio::FluidSynth;
use Glib;
use Time::HiRes     qw/usleep/;
use List::Util      qw/min/;
use Scalar::Util    qw/refaddr/;

has settings    => is => "lazy";
has synth       => is => "lazy";
has driver      => is => "lazy";
has sfont       => is => "lazy";

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

sub BUILD {
    my ($self) = @_;

    $self->synth->program_select(0, $self->sfont, 0, 68);
    $self->driver;
}

sub play_note {
    my ($self, $pitch, $length) = @_;
    my $time = 2000000/$length;
    my $syn = $self->synth;

    warn "PLAYING [$pitch] FOR [$time]";

    $syn->noteon(0, $pitch, 85);
    usleep $time;
    $syn->noteoff(0, $pitch);
}

sub play_music {
    my ($self, $music, $start_note, $stop_note, $finish) = @_;

    my $syn     = $self->synth;
    my @notes   =
        map [$_->pitch, 64/$_->length, refaddr $_],
        @$music;

    $syn->noteon(0, $notes[0][0], 85);
    $start_note->($notes[0][2]);

    Glib::Timeout->add(32, sub {
        $notes[0][1]-- > 1 and return 1;

        $syn->noteoff(0, $notes[0][0]);
        $stop_note->($notes[0][2]);

        shift @notes;
        unless (@notes) {
            $finish->();
            return 0;
        }

        $syn->noteon(0, $notes[0][0], 85);
        $start_note->($notes[0][2]);
        return 1;
    });
}

1;
