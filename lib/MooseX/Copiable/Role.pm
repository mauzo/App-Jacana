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

        my $v = $f->get_value($from);
        if (!$t->deep_copy) {
            $t->set_value($self, $v);
        }
        elsif ($t->has_value($self)) {
            $t->get_value($self)->copy_from($v);
        }
        else {
            $t->set_value($self,
                MooseX::Copiable::DeepCopy
                    ->new($t, $v)
                    ->evaluate($self)
            );
        }
    }
}

1;
