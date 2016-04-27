package App::Jacana::Music::Text;

use App::Jacana::Moose;

extends "App::Jacana::Music";
with    qw/ 
    App::Jacana::Has::Dialog 
    App::Jacana::Has::Markup
    App::Jacana::Music::FindAmbient
/;

sub dialog { "Text" }
sub dialog_title {...}

1;
