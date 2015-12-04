package MooseX::Copiable::Meta::Attribute::Role;

use Moose::Role;

my $Att = "MooseX::Copiable::Meta::Attribute";

with $Att;

around attribute_for_class => sub {
    my ($super, $self) = @_;

    my $role    = $self->original_role;
    my $meta    = $role->applied_attribute_metaclass;

    $meta->does("$Att\::Class") or return $self->$super;

    $meta->interpolate_class_and_new($self->name,
        %{ $self->original_options },
        _copiable_role => $role,
    );
};

1;
