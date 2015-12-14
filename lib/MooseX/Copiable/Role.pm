package MooseX::Copiable::Role;

use Moose::Role;

use Moose::Util     qw/find_meta/;

use namespace::autoclean;

sub copy_from {
    my ($self, $from) = @_;

    my @atts = find_meta($self)->find_copiable_atts_for($from);

    for (@atts) {
        my ($f, $t) = @$_;

        $f->has_value($from)    or next;
        $t->set_value($self, $f->get_value($from));
    }
}

1;
