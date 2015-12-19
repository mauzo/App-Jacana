package MooseX::Copiable::Role;

use Moose::Role;

use Moose::Util     qw/find_meta/;

use namespace::autoclean;

sub copy_from {
    my ($self, $from) = @_;

    my @atts = find_meta($self)->find_copiable_atts_for($from);

    for (@atts) {
        my ($f, $t) = @$_;

        my $n = $t->name;
        unless ($f->has_value($from)) {
            warn "COPY CLEAR FOR [$n]";
            $t->clear_value($self);
            next;
        }

        my $v = $f->get_value($from);
        if (!$t->deep_copy) {
            warn "SHALLOW COPY FOR [$n]";
            $t->set_value($self, $v);
        }
        elsif ($t->has_value($self)) {
            warn "COPY TO EXISTING FOR [$n]";
            $t->get_value($self)->copy_from($v);
        }
        else {
            warn "DEEP COPY FOR [$n]";
            $t->set_value($self, { copy_from => $v });
        }
    }
}

1;
