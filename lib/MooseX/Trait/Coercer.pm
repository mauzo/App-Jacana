package MooseX::Trait::Coercer;

use Moose::Role;

use Moose::Util;
use Moose::Util::TypeConstraints;

Moose::Util::meta_attribute_alias "Coercer";

# I would like to allow subrefs, too, but that makes the inline code
# more complicated. The subref would have to be passed via
# _eval_environment, but in the constructor case the metaclass
# environment is used, so we would have to apply a trait to the class.

subtype "MooseX::Trait::Coercer::SubName",
    as "Str", where { /^\w+\z/a };

has coercer => (
    is          => "rw",
    isa         => "MooseX::Trait::Coercer::SubName",
    predicate   => "has_coercer",
);

around _coerce_and_verify => sub {
    my ($super, $self, $value, $instance) = @_;

    my $c = $self->has_coercer ? $self->coercer 
        : "_coerce_" . $self->name;

    $value = $instance->$c($value);
    $self->$super($value, $instance);
};

around _inline_set_value => sub {
    my ($super, $self, $instance, $value, @args) = @_;
    my $ctor = $args[3];

    my $c = $self->has_coercer ? $self->coercer 
        : "_coerce_" . $self->name;

    my $rv = '$mxt_coercer_rv';

    return (
        qq{ my $rv = $instance\->$c($value); },
        $self->$super($instance, $rv, @args),
    );
};

1;
