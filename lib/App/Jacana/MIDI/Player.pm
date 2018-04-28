package App::Jacana::MIDI::Player;

use 5.012;
use App::Jacana::Moose;

use App::Jacana::Log;
use App::Jacana::StaffCtx::MIDI;

use namespace::autoclean;

with qw/MooseX::Role::WeakClosure/;

has midi => (
    is          => "ro",
    required    => 1,
    isa         => My "MIDI",
);
has music => (
    is          => "ro",
    required    => 1,
    isa         => My "Document::Movement",
);
has time => (
    is          => "rw",
    required    => 1,
    isa         => Int,
);
has speed => (
    is          => "rw",
    isa         => Num,
    default     => 16,
);

for (qw/start stop finish/) {
    has "on_$_" => (
        is          => "ro",
        required    => 1,
        isa         => CodeRef,
    );
}

has _timer => (
    is          => "rw",
    predicate   => 1,
    clearer     => 1,
);
has staffs => (
    is          => "lazy",
);

sub DEMOLISH {
    my ($self) = @_;
    $self->_stop_timer;
}

sub _build_staffs {
    my ($self) = @_;

    my $midi    = $self->midi;
    my $time    = $self->time;
    my $start   = $self->on_start;
    my $stop    = $self->on_stop;

    my @music; 
    my $m = $self->music;

    while (1) {
        $m->is_voice_end and last;
        $m = $m->next_voice;
        $m->muted and next;
        
        my ($note, $when) = $m->find_time($time);
        push @music, App::Jacana::StaffCtx::MIDI->new(
            player => $self, midi => $midi,
            on_start => $start, on_stop => $stop,
            item => $note, when => $when,
        );
    }
    $_->start_note for @music;
    \@music;
}

sub start {
    my ($self) = @_;
    # Autoviv so we get errors here rather than from the callback. This
    # must be lazy since the builder relies on the other attributes
    # being set.
    $self->staffs;
    $self->_start_timer($self->speed);
}

sub _play_step {
    my ($self) = @_;

    my $music = $self->staffs;
    
    for (grep !$_->when, @$music) {
        while (!$_->when) {
            $_->stop_note;
            $_->next and $_->start_note;
        }
    }

    @$music = grep $_->has_item, @$music;
    unless (@$music) {
        $self->on_finish->();
        return 0;
    }

    $_->skip(1) for @$music;
    return 1;
}

sub _start_timer {
    my ($self, $speed) = @_;

    if ($self->_has_timer) {
        my $id = $self->_timer;
        die "TIMER [$self] ALREADY RUNNING [$id]";
    }

    my $id = Glib::Timeout->add($speed, $self->weak_method("_play_step"));
    warn "TIMER [$self] STARTING [$id] @[$speed]";
    $self->_timer($id);
}

sub _stop_timer {
    my ($self) = @_;

    $self->_has_timer or return;
    my $id = $self->_timer;
    warn "TIMER [$self] STOPPING [$id]";
    Glib::Source->remove($id);
    $self->_clear_timer;
}

sub set_tempo {
    my ($self, $tempo) = @_;

    my $speed = $tempo->ms_per_tick;
    $self->speed($speed);
    $self->_stop_timer;
    $self->_start_timer($speed);
}

1;

