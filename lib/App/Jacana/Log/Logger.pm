package App::Jacana::Log::Logger;

use App::Jacana::Moose;

has active => (
    is      => "ro",
    isa     => HashRef,
    default => sub { +{ ERR => 1, WARN => 1 } },
);

has verbose => (
    is      => "ro",
    isa     => Bool,
    default => 0,
);

has logfh => (
    is          => "ro",
    isa         => FileHandle,
    required    => 1,
);

sub msg {
    my ($self, $fac, $msg) = @_;

    $self->active->{$fac} || $self->verbose or return;
    say { $self->logfh } $msg;
}

1;
