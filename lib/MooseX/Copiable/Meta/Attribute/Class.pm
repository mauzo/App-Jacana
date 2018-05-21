package MooseX::Copiable::Meta::Attribute::Class;

use Moose::Role;
use Moose::Util     qw/does_role/;

BEGIN { *debug = \&MooseX::Copiable::debug }

use namespace::autoclean;

Moose::Util::meta_attribute_alias "Copiable";

has _copiable_role => (
    is  => "rw",
    isa => "RoleName",
);

my $Meta = "MooseX::Copiable::Meta";

with "$Meta\::Attribute";

after attach_to_class => sub {
    my ($self, $class) = @_;

    # Can't use ensure_all_roles, it gets confused and tries to do a
    # class apply on the class rather than an instance apply on the
    # metaclass.
    does_role $class, "$Meta\::Class"
        or Moose::Meta::Class->create_anon_class(
            superclasses    => [ref $class],
            roles           => ["$Meta\::Class"],
            cache           => 1,
        )->rebless_instance($class);

    my $ns      = $self->_copiable_role // $class->name;
    my $name    = $self->name;

    $class->copiable_roles->{$ns}{$name} = $name;
};

after detach_from_class => sub {
    my ($self) = @_;

    my $class = $self->associated_class;
    $class && does_role $class, "$Meta\::Class"
        or return;

    my $ns = $self->_copiable_role // $class->name;
    delete $class->copiable_roles->{$ns}{$self->name};
};

1;
