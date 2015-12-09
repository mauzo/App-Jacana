package MooseX::Copiable::Meta::Attribute::Role;

use Moose::Role;

my $Att = "MooseX::Copiable::Meta::Attribute";

with $Att;

has copiable => (
    is      => "ro",
#   isa     => Bool,
    default => 0,
);

around attribute_for_class => sub {
    my ($super, $self) = @_;

    $self->copiable or return $self->$super;

    my $role    = $self->original_role;
    my $meta    = $role->applied_attribute_metaclass;
    my %opts    = %{ $self->original_options };

    delete $opts{copiable};
    $opts{_copiable_role} = $role;
    push @{$opts{traits}}, "$Att\::Class";

    $meta->interpolate_class_and_new($self->name, %opts);
};

1;
