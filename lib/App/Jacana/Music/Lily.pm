package App::Jacana::Music::Lily;

use App::Jacana::Moose;

extends "App::Jacana::Music";
with    qw/
    App::Jacana::Has::Dialog
    App::Jacana::Has::Lily
    App::Jacana::Has::OwnLine
    App::Jacana::Music::FindAmbient
/;

sub dialog { "Lily" }

sub to_lily { 
    my ($self) = @_;
    $self->lily;
}

sub staff_line { -3 }

sub draw {
    my ($self, $c) = @_;

    $c->save;
        $c->text_font("bold", 8);
        my $wd = $c->show_text("?");
    $c->restore;

    return $wd;
}

1;
