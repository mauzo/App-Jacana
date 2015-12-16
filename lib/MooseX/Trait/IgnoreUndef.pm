package MooseX::Trait::IgnoreUndef;

use Moose::Role;
use Moose::Util;

use namespace::autoclean;

Moose::Util::meta_attribute_alias "IgnoreUndef";

around has_value => sub {
    my ($super, $self, $obj) = @_;
    
    defined $self->get_value($obj);
};

around _inline_instance_has => sub {
    my ($super, $self, $obj) = @_;

    'defined(' . $self->_inline_instance_get($obj) . ')';
};

1;
