package App::Jacana::MIDI::Timer;

use 5.012;
use App::Jacana::Moose;

with qw/MooseX::Role::WeakClosure/;

# This holds a self-reference. This is the only strong ref to this
# object that should exist after it has been created.
has _self => (
    is          => "ro",
    init_arg    => undef,
    builder     => 1,
    clearer     => 1,
);

has _id => (
    is          => "rw",
    predicate   => 1,
    clearer     => 1,
);

has callback => (
    is          => "ro",
    required    => 1,
);

has speed => (
    is          => "rw",
    required    => 1,
    trigger     => 1,
);

sub _build__self { $_[0] }

sub DEMOLISH {
    my ($self) = @_;
    $self->_stop_timer;
}

sub destroy {
    my ($self) = @_;
    warn "TIMER DESTROY [$self]";
    $self->_clear_self;
}

sub _trigger_speed {
    my ($self) = @_;
    $self->_stop_timer;
    $self->_start_timer;
}

sub _start_timer {
    my ($self) = @_;

    if ($self->_has_id) {
        my $id = $self->_id;
        die "TIMER [$self] ALREADY RUNNING [$id]";
    }

    my $speed   = $self->speed;
    my $id      = Glib::Timeout->add($speed, $self->callback);
    warn "TIMER [$self] STARTING [$id] @[$speed]";
    $self->_id($id);
}

sub _stop_timer {
    my ($self) = @_;

    $self->_has_id or return;
    my $id = $self->_id;
    warn "TIMER [$self] STOPPING [$id]";
    Glib::Source->remove($self->_id);
    $self->_clear_id;
}

1;

