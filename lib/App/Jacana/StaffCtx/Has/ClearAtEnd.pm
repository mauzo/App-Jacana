package App::Jacana::StaffCtx::Has::ClearAtEnd;

use App::Jacana::Moose -role;

after at_end => sub {
    my ($self) = @_;
    $self->clear_item;
};

1;
