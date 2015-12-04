package MooseX::Copiable::Meta::Attribute::Class;

use Moose::Role;

has _copiable_role => (
    is      => "ro",
    #isa    => Str,
);

my $Att = "MooseX::Copiable::Meta::Attribute";

with $Att;

before initialize_instance_slot => sub {
    my ($attr, $meta, $inst, $params) = @_;

    my $deep = $attr->deep_copy;
    $deep || $attr->copiable        or return;

    my $init = $attr->init_arg;
    defined $init                   or return;
    exists $$params{$init}          and return;

    my $from = $$params{copy_from}  or return;
    my $name = $attr->name;
    my $role = $attr->_copiable_role;

    warn "INITIALIZE COPIABLE SLOT [$name] FOR [$inst] FROM [$from]";
    
    my $Mfrom = Moose::Util::find_meta $from
                                    or return;
    my $f_att = $Mfrom->find_attribute_by_name($attr->name)
                                    or return;
    $f_att->does("$Att\::Class")    or return;
    $f_att->_copiable_role == $role or return;
    $f_att->has_value($from)        or return;

    my $val = $f_att->get_value($from);
    $$params{$init} = $deep ? { copy_from => $val } : $val;
};

1;
