package App::Jacana::Has::Voices;

use Moose::Role;

use App::Jacana::Util::LinkList;

use namespace::autoclean;

linklist "voice";
warn "CAN WITH: " . __PACKAGE__->can("with");

1;
