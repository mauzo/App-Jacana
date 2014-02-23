package App::Jacana::StaffCtx::Draw;

use Moo;
use App::Jacana::Util::Types;
use Carp;
use namespace::clean;

extends "App::Jacana::StaffCtx";

has y   => is => "ro", isa => Num, required => 1;

has bar => is => "rw", default => 0;
has pos => is => "rw", default => 0;

has tie_x => (
    is          => "rw",
    isa         => Num,
);

before next => sub {
    my ($self) = @_;

    my $note = $self->item or return;

    if ($note->DOES("App::Jacana::HasTime")) {
        my $len = $note->length;
        my $par = $note->partial;

        $self->bar($len);
        $self->pos($par ? $len - $par->duration : 0);
    }
    if ($note->DOES("App::Jacana::HasLength")) {
        $self->pos($self->pos + $note->duration);
    }
};

sub barline {
    my ($self) = @_;

    my $bar = $self->bar    or return;
    my $pos = $self->pos    or return;

    $pos < $bar             and return;

    $self->pos($pos - $bar);
    return 1;
}

sub start_tie {
    my ($self, $x) = @_;

    $self->has_tie and croak "I already have an open tie";
    $self->tie_x($x);
    $self->tie_from($self->item);
}

1;