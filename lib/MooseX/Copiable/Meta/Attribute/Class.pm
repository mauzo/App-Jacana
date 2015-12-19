package MooseX::Copiable::Meta::Attribute::Class;

use Moose::Role;
use Moose::Util     qw/does_role/;
use Scalar::Util    qw/blessed/;

use namespace::autoclean;

has _copiable_role => (
    is      => "ro",
    #isa    => Str,
);

my $Meta = "MooseX::Copiable::Meta";

with "$Meta\::Attribute";

after attach_to_class => sub {
    my ($self, $class) = @_;

    $self->has_read_method              or return;

    # Can't use ensure_all_roles, it gets confused and tries to do a
    # class apply on the class rather than an instance apply on the
    # metaclass.
    does_role $class, "$Meta\::Class"
        or Moose::Meta::Class->create_anon_class(
            superclasses    => [ref $class],
            roles           => ["$Meta\::Class"],
            cache           => 1,
        )->rebless_instance($class);

    my $pred = $self->has_predicate ? $self->predicate : undef;
    ref $pred and ($pred) = keys %$pred;

    $class->copiable_roles
        ->{$self->_copiable_role->name}{$self->name} = $self;
};

after detach_from_class => sub {
    my ($self) = @_;

    my $class = $self->associated_class;
    $class && does_role $class, "$Meta\::Class"
        or return;

    delete $self->associated_class->copiable_roles
        ->{$self->_copiable_role->name}{$self->name};
};

1;
