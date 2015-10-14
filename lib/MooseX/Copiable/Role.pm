package MooseX::Copiable::Role;

use Moose::Role;
use Moose::Util     qw/find_meta/;

use List::MoreUtils qw/uniq/;

require Data::Dump;

my $Me  = __PACKAGE__;
my $Att = "MooseX::Copiable::Meta::Attribute";

# $for is the object we are copying to ($self in copy_from)
sub _find_copiable_atts_for {
    my ($self, $for, @roles) = @_;

    my $Mself   = find_meta $self   or return;
    my $Mfor    = find_meta $for    or return;
    @roles or @roles = $Mself->calculate_all_roles_with_inheritance;

    grep $_->copiable || $_->deep_copy,
    grep $_->does($Att),
    map $Mself->find_attribute_by_name($_),
    uniq
    map $_->get_attribute_list,
    grep $Mfor->does_role($_),
    map $_->calculate_all_roles,
    grep $Mself->does_role($_),
    @roles;
}

#around BUILDARGS => sub {
#    my ($orig, $self, @args) = @_;
#
#    my $args = $self->$orig(@args);
#    my $from = delete $$args{copy_from} or return $args;
#
#    my @atts = $from->_find_copiable_atts_for($self);
#    warn "COPIABLE BUILDARGS [$self]<-[$from]: " .
#        join "|", map $_->name, @atts;
#
#    for my $att (@atts) {
#        my $arg = $att->init_arg;
#        exists $$args{$arg}     and next;
#        $att->has_value($from)  or next;
#
#        my $val = $att->get_value($from);
#        $$args{$arg} = $att->deep_copy ? { copy_from => $val } : $val;
#    }
#    warn "COPIABLE BUILDARGS RETURNING: " . Data::Dump::pp($args);
#    return $args;
#};

sub copy_from {
    my ($self, $from) = @_;

    warn "MOOSE COPY FROM [$self] [$from]";
}

1;
