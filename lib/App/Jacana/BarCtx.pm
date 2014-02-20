package App::Jacana::BarCtx;

use Moo;

use App::Jacana::Util::Types;

use Carp;

use namespace::clean;

has y   => is => "ro", isa => Num, required => 1;

has item => (
    is          => "rw", 
    isa         => InstanceOf["App::Jacana::Music"],
    required    => 1,
    clearer     => 1,
    predicate   => 1,
);
has when => is => "rw", default => 0;

has bar => is => "rw", default => 0;
has pos => is => "rw", default => 0;

has tie_from => (
    is          => "rw",
    isa         => ConsumerOf["App::Jacana::HasPitch"],
    weak_ref    => 1,
    clearer     => "clear_tie",
    predicate   => "has_tie",
);
has tie_x => (
    is          => "rw",
    isa         => Num,
);

sub skip {
    my ($self, $by) = @_;

    $self->has_item or return;
    my $when = $self->when;
    $when < $by and warn sprintf "SKIPPED OVER A NOTE [%s]!",
        $self->item->to_lily;
    $self->when($when - $by);
}

sub next {
    my ($self) = @_;

    my $note = $self->item;
    if ($note->is_list_end) {
        $self->clear_item;
        $self->when(-1);
        return;
    }

    if ($note->DOES("App::Jacana::HasTime")) {
        my $len = $note->length;
        my $par = $note->partial;

        $self->bar($len);
        $self->pos($par ? $len - $par->duration : 0);
    }
    if ($note->DOES("App::Jacana::HasLength")) {
        my $dur = $note->duration;
        $self->when($dur);
        $self->pos($self->pos + $dur);
    }
    $self->item($note->next);
}

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
