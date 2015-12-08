package MooseX::Copiable::Role;

use Moose::Role;

use Moose::Util     qw/find_meta/;

use namespace::autoclean;

sub copy_from {
    my ($self, $from) = @_;

    my @atts = find_meta($self)->find_copiable_atts_for($from);

    for (@atts) {
        my ($p, $r, $i, $w) = @$_;

        $p && !$from->$p    and next;
        $self->$w($from->$r);
    }
}

1;
