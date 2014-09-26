package App::Jacana::Has::Voices;

use Moo::Role;

use App::Jacana::Util::LinkList;
use App::Jacana::Util::Types;

use namespace::clean;

linklist "voice";
warn "CAN WITH: " . __PACKAGE__->can("with");

1;
