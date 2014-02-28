package App::Jacana::MIDI;

use 5.012;
use warnings;

use Moo;

use App::Jacana::StaffCtx::MIDI;

use Audio::FluidSynth;
use Glib;
use Time::HiRes     qw/usleep/;
use List::Util      qw/min first/;
use Scalar::Util    qw/refaddr/;

use namespace::clean;

with qw/ MooX::WeakClosure /;

has settings    => is => "lazy";
has synth       => is => "lazy";
has driver      => is => "lazy";
has sfont       => is => "lazy";
has active      => is => "ro", default => sub { +{} };
has in_use      => is => "ro", default => sub { +[] };

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

sub BUILD {
    my ($self) = @_;

    $self->synth->program_select($_, $self->sfont, 0, 68+$_)
        for 0..10;
    $self->driver;
}

sub DESTROY {
    my ($self) = @_;
    $self->remove_active($_) for keys %{$self->active};
}

sub play_note {
    my ($self, $chan, $pitch, $length) = @_;
    my $time = (16*128)/$length;
    my $syn = $self->synth;

    eval { $syn->noteon($chan, $pitch, 85) };
    Glib::Timeout->add($time, sub {
        eval { $syn->noteoff($chan, $pitch) };
        return 0;
    });
}

sub note_on {
    my ($self, $chan, $note) = @_;
    my $pitch;
    if ($note->DOES("App::Jacana::HasPitch")) {
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
    my ($self, $music, $time, $start_note, $stop_note, $finish) = @_;

    my @music = 
        map App::Jacana::StaffCtx::MIDI->new(
            midi => $self, chan => $self->alloc_chan,
            on_start => $start_note, on_stop => $stop_note,
            item => $$_[0], when => $$_[1]
        ), 
        map [$_->find_time($time)],
        @$music;
    $_->start_note for @music;

    my $id;
    $id = Glib::Timeout->add(32, $self->weak_closure(sub {
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
