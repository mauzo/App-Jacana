package App::Jacana::StaffCtx;

use App::Jacana::Moose;
use Scalar::Util                qw/blessed/;
use namespace::autoclean;

has item => (
    is          => "rw", 
    #isa         => InstanceOf["App::Jacana::Music"],
    weak_ref    => 1,
    required    => 1,
    clearer     => 1,
    predicate   => 1,
);
has when => is => "rw", default => 0;

has tie_from => (
    is          => "rw",
    #isa         => ConsumerOf["App::Jacana::Has::Pitch"],
    weak_ref    => 1,
    clearer     => "clear_tie",
    predicate   => "has_tie",
);

sub clone {
    my ($self, @args) = @_;
    my $class = blessed $self;
    $class->new(
        map(+($_, $self->$_), qw/item when/),
        ($self->has_tie ? $self->tie_from : ()),
        @args,
    );
}

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
    if ($note->is_music_end) {
        $self->clear_item;
        $self->when(-1);
        return;
    }
    $note = $self->item($note->next);
    $note->DOES("App::Jacana::Has::Length")
        and $self->when($note->duration);
    return 1;
}

1;
