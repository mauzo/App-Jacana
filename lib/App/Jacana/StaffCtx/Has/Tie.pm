package App::Jacana::StaffCtx::Has::Tie;

use App::Jacana::Moose -role;
use MooseX::Copiable;

has tie_from => (
    is          => "rw",
    isa         => Has "Pitch",
    weak_ref    => 1,
    clearer     => "clear_tie",
    predicate   => "has_tie",
    traits      => [qw/Copiable/],
);

1;
