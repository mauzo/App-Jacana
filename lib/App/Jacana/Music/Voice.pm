package App::Jacana::Music::Voice;

use Moo;

extends "App::Jacana::Music";
with    qw/ App::Jacana::HasCentre /;

sub to_lily {
    my ($self) = @_;
    my $lily;

    until ($self->is_list_end) {
        $self = $self->next;
        $lily .= $self->to_lily . " ";
    }

    $lily;
}

sub centre_line { 13 }

1;
