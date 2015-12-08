package MooseX::Copiable::Meta::Attribute::Class;

use Moose::Role;

has _copiable_role => (
    is      => "ro",
    #isa    => Str,
);

my $Meta = "MooseX::Copiable::Meta";

with "$Meta\::Attribute";

after attach_to_class => sub {
    my ($self, $class) = @_;

    # Can't use ensure_all_roles, it gets confused and tries to do a
    # class apply on the class rather than an instance apply on the
    # metaclass.

    Moose::Util::does_role($class, "$Meta\::Class") and return;

    Moose::Meta::Class->create_anon_class(
        superclasses    => [ref $class],
        roles           => ["$Meta\::Class"],
        cache           => 1,
    )->rebless_instance($class);
};

1;
