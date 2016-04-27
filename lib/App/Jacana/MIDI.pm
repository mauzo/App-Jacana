package App::Jacana::MIDI;

use 5.012;
use App::Jacana::Moose;

use App::Jacana::StaffCtx::MIDI;

use Audio::FluidSynth;
use Glib;
use Time::HiRes     qw/usleep/;
use List::Util      qw/min first/;
use Scalar::Util    qw/refaddr/;

use namespace::autoclean;

with qw/ MooseX::Role::WeakClosure /;

has settings    => is => "lazy";
has synth       => is => "lazy";
has driver      => is => "lazy";
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
    my ($s, $id, @chan) = @_;
    $s->active->{$id} = \@chan;
}

sub remove_active {
    my ($s, $id) = @_;
    my $ch = delete $s->active->{$id};
    Glib::Source->remove($id);
    $s->free_chan($_) for @$ch;
}

sub alloc_chan {
    my ($s) = @_;
    my $used = $s->in_use;
    my $c = first { !$$used[$_] } 0..16;
    $$used[$c] = 1;
    $c;
}

sub free_chan {
    my ($s, $c) = @_;
    $s->_all_notes_off($c);
    $s->in_use->[$c] = 0;
}

sub set_program {
    my ($s, $c, $v) = @_;
    $s->synth->program_select($c, $s->sfont, 0, $v);
}

sub BUILD {
    my ($self) = @_;

    $self->settings;
    $self->synth;
    $self->driver;
}

sub DEMOLISH {
    my ($self) = @_;
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
    my ($self, $chan, $note) = @_;

    $note->DOES("App::Jacana::Has::MidiInstrument")
        and $self->set_program($chan, $note->program);

    my $pitch;
    if ($note->DOES("App::Jacana::Has::Pitch")) {
        $pitch = $note->pitch;
        eval { $self->synth->noteon($chan, $pitch, 85) };
    }
    return $pitch;
}

sub note_off {
    my ($self, $chan, $pitch) = @_;
    defined $pitch 
        and eval { $self->synth->noteoff($chan, $pitch) };
}

sub _all_notes_off {
    my ($self, $chan) = @_;
    eval { $self->synth->cc($chan, 123, 0) };
}

sub play_music {
    my ($self, %arg) = @_;

    my $m = $arg{music}; my @music;
    while (1) {
        $m->is_voice_end and last;
        $m = $m->next_voice;
        $m->muted and next;
        
        my ($note, $when) = $m->find_time($arg{time});
        my $c   = $self->alloc_chan;
        my $prg = $note->ambient->find_role("MidiInstrument");

        $self->set_program($c, $prg->program);

        push @music, App::Jacana::StaffCtx::MIDI->new(
            midi => $self, chan => $c,
            on_start => $arg{start}, on_stop => $arg{stop},
            item => $note, when => $when,
        );
    }
    $_->start_note for @music;

    my $finish = $arg{finish};
    my $id;
    $id = Glib::Timeout->add($arg{speed}, $self->weak_closure(sub {
        my ($self) = @_;
        
        for (grep !$_->when, @music) {
            while (!$_->when) {
                $_->stop_note;
                $_->next and $_->start_note;
            }
        }

        @music = grep $_->has_item, @music;
        unless (@music) {
            $finish->();
            $self and $self->remove_active($id);
            return 0;
        }

        $_->skip(1) for @music;
        return 1;
    }, sub { Glib::Source->remove($id) }));
    $self->add_active($id, map $_->chan, @music);
    $id;
}

1;
