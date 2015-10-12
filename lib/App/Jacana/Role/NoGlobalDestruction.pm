package App::Jacana::Role::NoGlobalDestruction;

use Moose::Role;

sub DESTROY {}

before DESTROY => sub {
    ${^GLOBAL_PHASE} eq "DESTRUCT"
        and warn "$_[0] destroyed in global destruction";
};

1;
