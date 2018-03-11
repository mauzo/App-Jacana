package App::Jacana::Event::Change;

use App::Jacana::Moose;

has type => (
    is          => "ro",
    isa         => ChangeType,
    required    => 1,
);

has item => (
    is          => "ro",
    isa         => Music,
    weak_ref    => 1,
    predicate   => 1,
);

has tick => (
    is          => "ro",
    isa         => Tick,
    predicate   => 1,
);

has duration => (
    is          => "ro",
    isa         => Int,
    predicate   => 1,
);

push @Data::Dump::FILTERS, sub {
    my ($ctx, $obj) = @_;
    $ctx->container_isa(__PACKAGE__)
        && $ctx->object_isa("App::Jacana::Music")
        and return { dump => "$obj" };
    return;
};

1;
