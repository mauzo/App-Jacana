package App::Jacana::Util::Pitch;

use App::Jacana::Moose;

with "App::Jacana::Has::Pitch";

sub BUILD {}

Moose::Util::find_meta(__PACKAGE__)->make_immutable;
