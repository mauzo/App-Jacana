package App::Jacana::Has::MidiTranspose;

use Moose::Role;
use MooseX::Copiable;

use App::Jacana::Types -all;
use App::Jacana::Util::Pitch;

use namespace::autoclean;

has into => (
    is          => "rw",
    isa         => Has "Pitch",
    traits      => [qw/Copiable/],
    deep_copy   => 1,
    required    => 1,
);

1;
