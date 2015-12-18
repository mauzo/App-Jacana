package MooseX::Copiable::Meta::Class;

use Moose::Role;

use Moose::Util     qw/does_role find_meta/;
use Scalar::Util    qw/blessed/;

use MooseX::Copiable::DeepCopy;

use namespace::autoclean;

has copiable_roles => (
    is      => "ro",
    default => sub { {} },
);

sub find_all_copiable_roles {
    my ($self) = @_;

    my @classes = map find_meta($_), $self->linearized_isa;

    my %roles;
    for (reverse @classes) {
        does_role $_, __PACKAGE__ or next;
        my $r = $_->copiable_roles;

        $roles{$_} = $$r{$_} for keys %$r;
    }

    return \%roles;
}

# $self is the metaclass we are copying to
# $for is the object we are copying from
# $want is a hashref of roles to include, or undef
sub find_copiable_atts_for {
    my ($self, $for, $want) = @_;

    my $meta    = find_meta $for;
    does_role $meta, __PACKAGE__ or return;

    my $to      = $self->find_all_copiable_roles;
    my $from    = $meta->find_all_copiable_roles;

    my @out;
    for my $r (keys %$from) {
        $want && !exists $$want{$r} and next;
        my $rt = $$to{$r}           or next;;
        my $rf = $$from{$r};
        for my $m (keys %$rf) {
            my $mt = $$rt{$m}       or next;
            my $mf = $$rf{$m};
            push @out, [$mf, $mt];
        }
    }
    @out;
}

sub _copiable_process_params {
    my ($self, $params) = @_;

    my $from    = delete $$params{copy_from}            or return;
    my @atts    = $self->find_copiable_atts_for($from)  or return;

    for (@atts) {
        my ($f, $t) = @$_;
        
        my $n = $t->name;
        my $i = $t->init_arg;

        exists $$params{$i}     and next;
        $f->has_value($from)    or next;

        my $v = $f->get_value($from);

        $$params{$i} =
            MooseX::Copiable::DeepCopy->new($t, $v);
    }
}

around new_object => sub {
    my ($super, $self, @params) = @_;
    my $params = @params == 1 ? $params[0] : { @params };

    $self->_copiable_process_params($params);
    $self->$super($params);
};

around _inline_params => sub {
    my ($super, $self, $params, $class) = @_;

    return (
        $self->$super($params, $class),
        qq{Moose::Util::find_meta($class)} .
            qq{->_copiable_process_params($params);},
    );
};

around _inline_init_attr_from_constructor => sub {
    my ($super, $self, $attr, $idx) = @_;

    my @code = $self->$super($attr, $idx);

    $attr->deep_copy            or return @code;
    my $init = $attr->init_arg  or return @code;

    my $param = qq{\$params->{"\Q$init\E"}};
    my $bless = "Scalar::Util::blessed";
    
    return split(/\n/, <<PERL), @code;
    {
        my \$v = $param;
        $bless(\$v) && $bless(\$v) eq "MooseX::Copiable::DeepCopy"
            and $param = \$v->evaluate(\$instance);
    }
PERL
};

1;
