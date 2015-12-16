package App::Jacana::Music::Barline;

use App::Jacana::Moose;

use Carp ();

extends "App::Jacana::Music";
with    qw/ 
    App::Jacana::Has::Barline 
    App::Jacana::Has::Dialog
    App::Jacana::Music::FindAmbient
/;

sub dialog { "Barline" }

sub lily_rx {
    qr( \\bar \s+ " (?<barline>[:.|]+) " )x;
}

sub draw {
    my ($self, $c, $pos) = @_;

    $self->_draw_barline($c, $self->barline);
}

Moose::Util::find_meta(__PACKAGE__)->make_immutable;
