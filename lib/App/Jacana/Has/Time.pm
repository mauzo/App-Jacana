package App::Jacana::Has::Time;

use Moose::Role;
use MooseX::AttributeShortcuts;
use MooseX::Copiable;

use App::Jacana::Util::Length;

has beats => (
    is      => "rw",
    #isa     => Int,
    copiable => 1,
);
has divisor => (
    is      => "rw",
    #isa     => Enum[qw/1 2 4 8 16 32/],
    copiable => 1,
);
has partial => (
    is          => "rw",
    #isa         => Maybe[ConsumerOf["App::Jacana::Has::Length"]],
    copiable    => 1,
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
