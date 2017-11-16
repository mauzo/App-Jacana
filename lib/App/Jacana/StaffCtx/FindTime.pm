package App::Jacana::StaffCtx::FindTime;

use App::Jacana::Moose;

extends "App::Jacana::StaffCtx";
with    qw/App::Jacana::StaffCtx::Has::When/;

sub skip_time {
    my ($self, $time) = @_;

    while ($time > 0) {
        $self->next or return;
        $time -= $self->when;
    }
    $self->when(-$time);

    return $self;
}

sub get_time_for {
    my ($self, $end) = @_;

    my $time = 0;
    while ($end != $self->item) {
        $time += $self->when;
        $self->next or Carp::croak("FindTime ran off the end!");
    }
    $time += $self->when;

    return $time;
}

1;
