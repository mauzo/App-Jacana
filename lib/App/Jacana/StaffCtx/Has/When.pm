package App::Jacana::StaffCtx::Has::When;

use App::Jacana::Moose -role;
use MooseX::Copiable;

with qw/App::Jacana::Has::Tick/;

has when => (
    is          => "rw", 
    default     => 0, 
    isa         => Tick,
    traits      => [qw/Copiable/],
);

sub skip {
    my ($self, $by) = @_;

    $self->has_item or return;
    my $when = $self->when;
    $when < $by and warn "SKIPPED OVER A NOTE [%s]!",
        $self->item->to_lily;
    $self->when($when - $by);
    $self->add_to_tick($by);
}

after next => sub {
    my ($self) = @_;
    $self->has_item or return;
    $self->add_to_tick($self->when);
    my $note = $self->item;
    my $when = Has("Length")->check($note) ? $note->duration : 0;
    $self->when($when);
};

after at_end => sub {
    my ($self) = @_;
    $self->when(0);
};

1;
