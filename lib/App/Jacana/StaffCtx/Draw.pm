package App::Jacana::StaffCtx::Draw;

use App::Jacana::Moose;
use Carp;
use namespace::autoclean;

extends "App::Jacana::StaffCtx";

has y => (
    is          => "ro", 
    required    => 1,
    #isa         => Num,
    traits      => [qw/Copiable/],
);

has bar => (
    is          => "rw",
    default     => 0,
    traits      => [qw/Copiable/],
);
has pos => (
    is          => "rw", 
    default     => 0,
    traits      => [qw/Copiable/],
);

has tie_x => (
    is          => "rw",
    #isa         => Num,
    traits      => [qw/Copiable/],
);

sub top     { $_[0]->y - 12 }
sub bottom  { $_[0]->y + 12 }

before next => sub {
    my ($self) = @_;

    my $note = $self->item or return;

    if ($note->DOES("App::Jacana::Has::Time")) {
        my $len = $note->length;
        my $par = $note->partial;

        $self->bar($len);
        $self->pos($par ? $len - $par->duration : 0);
    }
    if ($note->DOES("App::Jacana::Has::Length")) {
        $self->pos($self->pos + $note->duration);
    }
};

sub barline {
    my ($self) = @_;

    my $bar = $self->bar    or return;
    my $pos = $self->pos    or return;

    $pos < $bar             and return;
    $self->pos($pos % $bar);

    my $note = $self->item  or return;
    $note->DOES("App::Jacana::Has::Barline")
        && $pos == $bar
        and return;

    return 1;
}

sub start_tie {
    my ($self, $x) = @_;

    $self->has_tie and croak "I already have an open tie";
    $self->tie_x($x);
    $self->tie_from($self->item);
}

1;
