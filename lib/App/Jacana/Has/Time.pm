package App::Jacana::Has::Time;

use Moose::Role;
use MooseX::AttributeShortcuts;
use MooseX::Copiable;

use App::Jacana::Util::Length;

has beats => (
    is      => "rw",
    traits      => [qw/Copiable/],
    #isa     => Int,
);
has divisor => (
    is      => "rw",
    traits      => [qw/Copiable/],
    #isa     => Enum[qw/1 2 4 8 16 32/],
);
has partial => (
    is          => "rw",
    traits      => [qw/Copiable/],
    #isa         => Maybe[ConsumerOf["App::Jacana::Has::Length"]],
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
