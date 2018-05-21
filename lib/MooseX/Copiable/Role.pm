package MooseX::Copiable::Role;

use Moose::Role;

use Carp;
use Moose::Util     qw/find_meta/;

BEGIN { *debug = \&MooseX::Copiable::debug }

use namespace::autoclean;

sub copy_from {
    my ($self, $from, @roles) = @_;

    my $want;
    @roles and $want = +{ map +($_, 1), @roles };
    my @atts = find_meta($self)->find_copiable_atts_for($from, $want);

    for (@atts) {
        my ($f, $t) = @$_;

        my $n = $t->name;

        debug "copy_from processing [$n] using [$f]->[$t]";

        unless ($f->has_value($from)) {
            debug "COPY CLEAR FOR [$n]";
            $t->clear_value($self);
            next;
        }

        my $v = $f->get_value($from);
        if (!$t->deep_copy) {
            debug "SHALLOW COPY FOR [$n]";
            $t->set_value($self, $v);
        }
        elsif ($t->has_value($self)) {
            debug "COPY TO EXISTING FOR [$n]";
            $t->get_value($self)->copy_from($v);
        }
        else {
            debug "DEEP COPY FOR [$n]";
            $t->set_value($self, { copy_from => $v });
        }
    }
}

1;
