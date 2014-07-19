package App::Jacana::Music::Barline;

use Moo;

use App::Jacana::Util::Types;

use Carp ();

extends "App::Jacana::Music";
with    qw/ 
    App::Jacana::Has::Barline 
    App::Jacana::Has::Dialog
/;

sub dialog { "Barline" }

sub lily_rx {
    qr( \\bar \s+ " (?<barline>[:.|]+) " )x;
}

sub draw {
    my ($self, $c, $pos) = @_;

    $self->_draw_barline($c, $self->barline);
}

1;
