package App::Jacana::MIDI;

use 5.012;
use App::Jacana::Moose;

use Audio::FluidSynth;
use Glib;
use Time::HiRes     qw/usleep/;
use List::Util      qw/min first/;
use Scalar::Util    qw/refaddr/;

use namespace::autoclean;

has settings    => is => "lazy";
has synth       => is => "lazy";
has driver      => is => "ro", builder => 1;
has sfont       => is => "lazy";
has active      => is => "ro", default => sub { +{} };
has in_use      => is => "ro", default => sub { +[] };

sub _build_settings {
    my $s = Audio::FluidSynth::Settings->new;
    $s->set("audio.driver", "oss");
    $s->set("audio.oss.device", "/dev/dsp0");
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
    $s->active->{$id} = 1;
}

sub remove_active {
    my ($s, $id) = @_;
    my $ch = delete $s->active->{$id};
    Glib::Source->remove($id);
}

sub alloc_chan {
    my ($s) = @_;
    my $used = $s->in_use;
    my $c = first { !$$used[$_] } 0..15;
    defined $c or die "Out of MIDI channels!";
    warn "ALLOC MIDI CHANNEL [$c]";
    $$used[$c] = 1;
    $c;
}

sub free_chan {
    my ($s, $c) = @_;
    warn "FREE MIDI CHANNEL [$c]";
    $s->_all_notes_off($c);
    $s->in_use->[$c] = 0;
}

sub set_program {
    my ($s, $c, $v) = @_;
    warn "MIDI PROGRAM SELECT [$c] [$v]";
    $s->synth->program_select($c, $s->sfont, 0, $v);
}

sub DEMOLISH {
    my ($self) = @_;
    warn "DEMOLISH MIDI [$self]";
    $self->remove_active($_) for keys %{$self->active};
}

sub play_note {
    my ($self, $chan, $pitch, $length) = @_;

    my $time    = (16*128)/$length;
    my $syn     = $self->synth;

    eval { $syn->noteon($chan, $pitch, 85) };
    Glib::Timeout->add($time, sub {
        eval { $syn->noteoff($chan, $pitch) };
        return 0;
    });
}

sub note_on {
    my ($self, $chan, $pitch) = @_;
    warn "MIDI NOTE ON [$chan][$pitch]";
    defined $pitch
        and eval { $self->synth->noteon($chan, $pitch, 100) };
}

sub note_off {
    my ($self, $chan, $pitch) = @_;
    warn "MIDI NOTE OFF [$chan][$pitch]";
    defined $pitch 
        and eval { $self->synth->noteoff($chan, $pitch) };
}

sub _all_notes_off {
    my ($self, $chan) = @_;
    eval { $self->synth->cc($chan, 123, 0) };
}

1;
