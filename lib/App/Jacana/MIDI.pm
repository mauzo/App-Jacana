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

    $self->synth->program_select($_, $self->sfont, 0, 68+$_)
        for 0..10;
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
    my ($self, $chan, $note) = @_;
    my $pitch;
    if ($note->DOES("App::Jacana::HasPitch")) {
        $pitch = $note->pitch;
        eval { $self->synth->noteon($chan, $pitch, 85) };
    }
    my $duration = $note->DOES("App::Jacana::HasLength")
        ? $note->duration : undef;
    return ($pitch, $duration);
}

sub _note_off {
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

    my (@note, @pitch, @when);

    for (0..$#$music) {
        ($note[$_], $when[$_])  = $$music[$_]->find_time($time);
        ($pitch[$_], undef)     = $self->_note_on($_ + 1, $note[$_]);
        $start_note->($note[$_]);
    }

    my $next_note = sub {
        my ($n) = @_;

        $when[$n]-- > 1 and return;
        
        $self->_note_off($n + 1, $pitch[$n]);
        $stop_note->($note[$n]);

        if ($note[$n]->is_list_end) {
            splice @$_, $n, 1 for \(@note, @pitch, @when);
            return;
        }

        $note[$n] = $note[$n]->next;
        ($pitch[$n], $when[$n]) = $self->_note_on($n + 1, $note[$n]);
        $start_note->($note[$n]);
    };

    my $id;
    $id = Glib::Timeout->add(32, $self->weak_closure(sub {
        my ($self) = @_;
    
        $next_note->($_) for 0..$#note;
    
        unless (@note) {
            $finish->();
            $self and $self->remove_active($id);
            return 0;
        }
        return 1;
    }));
    $self->add_active($id, 1..@note);
    $id;
}

1;
