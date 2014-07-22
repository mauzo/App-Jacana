package App::Jacana::Has::Time;

use Moo::Role;

use App::Jacana::Util::Types;
use App::Jacana::Util::Length;

with qw/MooX::Role::Copiable/;

has beats => (
    is      => "rw",
    isa     => Int,
    copiable => 1,
);
has divisor => (
    is      => "rw",
    isa     => Enum[qw/1 2 4 8 16 32/],
    copiable => 1,
);
has partial => (
    is          => "rw",
    isa         => Maybe[ConsumerOf["App::Jacana::Has::Length"]],
    deep_copy   => 1,
    predicate   => 1,
    clearer     => 1,
);

# in qhdsqs
sub length {
    my ($self) = @_;
    (128/$self->divisor)*$self->beats;
}

1;
