package App::Jacana::Music::Voice;

use Moo;

use Text::Wrap  qw/wrap/;

use namespace::clean;

extends "App::Jacana::Music";
with    qw/ 
    App::Jacana::Has::Clef 
    App::Jacana::Has::Key
    App::Jacana::Has::Time
    App::Jacana::Music::HasAmbient
/;

has name => is => "rw", required => 1;

has "+key" => default => 0;
has "+mode" => default => "major";

has "+beats" => default => 4;
has "+divisor" => default => 4;

sub to_lily {
    my ($self) = @_;
    
    my $name = $self->name;

    my $lily;
    until ($self->is_list_end) {
        $self = $self->next;
        $lily .= $self->to_lily . " ";
    }

    local $Text::Wrap::huge     = "overflow";
    local $Text::Wrap::unexpand = 0;
    $lily = wrap "  ", "  ", $lily;

    "$name = {\n$lily\n}\n";
}

# We default to treble clef, because Lily does.
sub clef { "treble" }
sub centre_line { 13 }

sub draw { 4 }

# Returns a Music item and the length of time left in that item
sub find_time {
    my ($self, $dur) = @_;

    while ($dur > 0 && !$self->is_list_end) {
        $self = $self->next;
        $self->DOES("App::Jacana::Has::Length")
            and $dur -= $self->duration;
    }

    ($self, -$dur);
}

1;
