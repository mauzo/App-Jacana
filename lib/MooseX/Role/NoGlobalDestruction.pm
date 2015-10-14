package MooseX::Role::NoGlobalDestruction;

use Moose::Role;

sub DESTROY {}

before DESTROY => sub {
    ${^GLOBAL_PHASE} eq "DESTRUCT"
        and warn "$_[0] destroyed in global destruction:\n" .
            join "\n", map "  $_", @{mro::get_linear_isa ref $_[0]};
};

1;
