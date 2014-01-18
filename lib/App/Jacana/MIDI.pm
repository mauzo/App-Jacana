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
has active      => is => "ro", default => sub { [] };

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
    my ($s, $id) = @_;
    push @{$s->active}, $id;
}

sub remove_active {
    my ($s, $id) = @_;
    my $ac = $s->active;
    @$ac = grep $_ != $id, @$ac;
}

sub BUILD {
    my ($self) = @_;

    $self->synth->program_select(0, $self->sfont, 0, 68);
    $self->driver;
}

sub DESTROY {
    my ($self) = @_;
    Glib::Source->remove($_) for @{$self->active};
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

    eval { $syn->noteon(0, $notes[0][0], 85) };
    $start_note->($notes[0][2]);

    my $id;
    $id = Glib::Timeout->add(32, $self->weak_closure(sub {
        my ($self) = @_;

        $notes[0][1]-- > 1 and return 1;

        eval { $syn->noteoff(0, $notes[0][0]) };
        $stop_note->($notes[0][2]);

        shift @notes;
        unless (@notes) {
            $finish->();
            $self and $self->remove_active($id);
            return 0;
        }

        eval { $syn->noteon(0, $notes[0][0], 85) };
        $start_note->($notes[0][2]);
        return 1;
    }));
    $self->add_active($id);
}

1;
