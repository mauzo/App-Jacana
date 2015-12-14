package MooseX::Copiable::Meta::Class;

use Moose::Role;

use Moose::Util     qw/does_role find_meta/;

use namespace::autoclean;

has copiable_roles => (
    is      => "ro",
    default => sub { {} },
);

# $self is the metaclass we are copying to
# $for is the object we are copying from
# $want is a hashref of roles to include, or undef
sub find_copiable_atts_for {
    my ($self, $for, $want) = @_;

    my $meta    = find_meta $for;
    does_role $meta, __PACKAGE__ or return;

    my $to      = $self->copiable_roles;
    my $from    = $meta->copiable_roles;

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

around new_object => sub {
    my ($super, $self, @params) = @_;
    my $params = @params == 1 ? $params[0] : { @params };

    my $from    = delete $$params{copy_from} 
        or return $self->$super($params);
    my @atts    = $self->find_copiable_atts_for($from)
        or return $self->$super($params);

    for (@atts) {
        my ($f, $t) = @$_;
        
        my $i = $t->init_arg;

        exists $$params{$i}     and next;
        $f->has_value($from)    or next;

        $$params{$i} = $f->get_value($from);
    }
    
    $self->$super($params);
};

=for later

around _inline_params => sub {
    my ($super, $self, $params, $class) = @_;

    require Data::Dump;
    my $name  = $self->name;
    my $roles = Data::Dump::pp($self->find_copiable_roles);

    warn "INLINE PARAMS FOR [$name]";

    return (
        $self->$super($params, $class),
        qq{warn "COPIABLE ROLES FOR [\Q$name\E]: \Q$roles\E";},
    );
};

=cut

1;
