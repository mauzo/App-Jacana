package App::Jacana::Music::Voice;

use Moo;

extends "App::Jacana::Music";
with    qw/ App::Jacana::HasClef /;

sub to_lily {
    my ($self) = @_;
    my $lily;

    until ($self->is_list_end) {
        $self = $self->next;
        $lily .= $self->to_lily . " ";
    }

    $lily;
}

# We default to treble clef, because Lily does.
sub clef { "treble" }
sub centre_line { 13 }

1;
