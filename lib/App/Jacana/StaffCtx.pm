package App::Jacana::StaffCtx;

use App::Jacana::Moose;
use App::Jacana::Types;
use MooseX::Copiable;

use Scalar::Util                qw/blessed/;
use namespace::autoclean;

has item => (
    is          => "rw", 
    isa         => My "Music",
    weak_ref    => 1,
    clearer     => 1,
    predicate   => 1,
    traits      => [qw/Copiable/],
);
# This is a float; see Has::Length
has when => (
    is          => "rw", 
    default     => 0, 
    isa         => StrictNum,
    traits      => [qw/Copiable/],
);
has tie_from => (
    is          => "rw",
    isa         => Has "Pitch",
    weak_ref    => 1,
    clearer     => "clear_tie",
    predicate   => "has_tie",
    traits      => [qw/Copiable/],
);

sub clone {
    my ($self, @args) = @_;
    my $class = blessed $self;
    $class->new(copy_from => $self, @args);
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

    my $note = $self->item or return;
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
