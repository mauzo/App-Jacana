package App::Jacana::Has::Voices;

use Moose::Role;

use App::Jacana::MUtil::LinkList;

use namespace::autoclean;

linklist "voice";
warn "CAN WITH: " . __PACKAGE__->can("with");

1;
