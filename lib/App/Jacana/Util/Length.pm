package App::Jacana::Util::Length;

use App::Jacana::Moose;

with "App::Jacana::Has::Length";

sub BUILD { }

Moose::Util::find_meta(__PACKAGE__)->make_immutable;
