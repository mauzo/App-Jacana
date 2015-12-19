package MooseX::Copiable::Meta::Attribute::Role;

use Moose::Role;

my $Att = "MooseX::Copiable::Meta::Attribute";

with $Att;

around attribute_for_class => sub {
    my ($super, $self) = @_;

    my $att = $self->$super;

    $att->does("$Att\::Class") 
        and $att->_copiable_role($self->original_role->name);

    $att;
};

1;
