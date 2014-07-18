package App::Jacana::Music::Barline;

use Moo;

use App::Jacana::Util::Types;

use Carp ();

extends "App::Jacana::Music";
with    qw/ 
    App::Jacana::HasBarline 
    App::Jacana::HasDialog
/;

sub dialog { "Barline" }

sub draw {
    my ($self, $c, $pos) = @_;

    $self->_draw_barline($c, $self->barline);
}

1;
