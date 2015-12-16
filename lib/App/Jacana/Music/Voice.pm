package App::Jacana::Music::Voice;

use App::Jacana::Moose;

use Data::Dump      qw/pp/;
use Module::Runtime     qw/use_module/;
use Text::Wrap          qw/wrap/;

use namespace::autoclean;

extends "App::Jacana::Music";
with    qw/ 
    App::Jacana::Has::Clef 
    App::Jacana::Has::Key
    App::Jacana::Has::MidiInstrument
    App::Jacana::Has::Time
    App::Jacana::Has::Voices
    App::Jacana::Music::HasAmbient
/;

has name => (
    is          => "rw", 
    required    => 1,
    #isa         => Match("[a-zA-Z]+", "voice name"),
);

has muted => (
    is          => "rw",
    default     => 0,
    #isa         => Bool,
);

# We default to treble clef, because Lily does.
has "+clef" => default => "treble";
has "+key" => default => 0;
has "+mode" => default => "major";

has "+beats" => default => 4;
has "+divisor" => default => 4;

# oboe
has "+program" => default => 68;

my @MTypes = map "App::Jacana::Music::$_",
    qw/ Barline Clef KeySig MidiInstrument MultiRest Note Note::Grace
        RehearsalMark Rest Text::Mark TimeSig 
    /;
for (@MTypes) {
    warn "LOADING [$_]";
    use_module $_;
}
my $Unkn = "App::Jacana::Music::Lily";
use_module $Unkn;

sub from_lily {
    my ($class, %n) = @_;

    my $music = my $self = $class->new(
        name        => $n{voice},
    );

    my $unknown = "";
    (my $text   = $n{music}) =~ s/^\{|\}$//g;

    warn "MTYPES: " . pp {map +($_ => $_->lily_rx), @MTypes};

    ITEM: while ($text) {
        $text =~ s/^\s+//;
        for my $M (@MTypes) {
            my $rx = $M->lily_rx;
            if ($text =~ s/^$rx//) {
                if ($unknown) {
                    $music = $music->insert(
                        $Unkn->new(lily => $unknown));
                    $unknown = "";
                }
                $music = $music->insert($M->from_lily(%+));
                next ITEM;
            }
        }
        $text =~ s/^(\S+\s*)// and $unknown .= $1;
    }

    $unknown and $music->insert($Unkn->new(lily => $unknown));
    return $self;
}

sub to_lily {
    my ($self) = @_;
    
    my $name = $self->name;

    my $lily;
    until ($self->is_music_end) {
        $self = $self->next;
        $lily .= $self->to_lily . " ";
    }

    local $Text::Wrap::huge     = "overflow";
    local $Text::Wrap::unexpand = 0;
    $lily = wrap "  ", "  ", $lily;

    "$name = {\n$lily\n}\n";
}


sub draw { 0 }

# Returns a Music item and the length of time left in that item
sub find_time {
    my ($self, $dur) = @_;

    while ($dur > 0 && !$self->is_music_end) {
        $self = $self->next;
        $self->DOES("App::Jacana::Has::Length")
            and $dur -= $self->duration;
    }

    ($self, -$dur);
}

Moose::Util::find_meta(__PACKAGE__)->make_immutable;
