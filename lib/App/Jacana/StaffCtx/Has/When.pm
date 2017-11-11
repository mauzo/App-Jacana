package App::Jacana::StaffCtx::Has::When;

use App::Jacana::Moose -role;
use MooseX::Copiable;

# This is a float; see Has::Length
has when => (
    is          => "rw", 
    default     => 0, 
    isa         => StrictNum,
    traits      => [qw/Copiable/],
);

sub skip {
    my ($self, $by) = @_;

    $self->has_item or return;
    my $when = $self->when;
    $when < $by and warn sprintf "SKIPPED OVER A NOTE [%s]!",
        $self->item->to_lily;
    $self->when($when - $by);
}

after next => sub {
    my ($self) = @_;
    $self->has_item or return;
    my $note = $self->item;
    $note->DOES("App::Jacana::Has::Length")
        and $self->when($note->duration);
};

sub at_end {
    my ($self) = @_;

    $self->clear_item;
    $self->when(-1);
    return;
}

1;
