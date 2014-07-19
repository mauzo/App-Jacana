package App::Jacana::Has::Span;

use Moo::Role;

use App::Jacana::Util::Types;

with "App::Jacana::Music::HasAmbient";

requires qw/ span_types /;

has span_start => (
    is          => "rw",
    required    => 1,
    isa         => Bool,
    default     => 0,
);

1;
