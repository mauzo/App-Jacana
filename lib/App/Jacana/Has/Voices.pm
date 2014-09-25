package App::Jacana::Has::Voices;

use Moo::Role;

use App::Jacana::Util::LinkList;
use App::Jacana::Util::Types;

use namespace::clean;

linklist "voice";
warn "CAN WITH: " . __PACKAGE__->can("with");

has name => (
    is          => "rw", 
    required    => 1,
    isa         => Match("[a-zA-Z]+", "voice name"),
);

1;
