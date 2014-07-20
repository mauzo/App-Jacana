package App::Jacana::Layout::Item;

use Moo;
use App::Jacana::Util::Types;
use namespace::clean;

has item => (
    is          => "ro",
    isa         => Music,
    required    => 1,
);

has start => (
    is          => "rw",
    isa         => InstanceOf[My "Layout::Position"],
);
has end => (
    is          => "rw",
    isa         => InstanceOf[My "Layout::Position"],
);



1;
