package App::Jacana::Music::Voice;

use Moo;

use App::Jacana::Util::Types;

use Module::Runtime     qw/use_module/;
use Text::Wrap          qw/wrap/;

use namespace::clean;

extends "App::Jacana::Music";
with    qw/ 
    App::Jacana::Has::Clef 
    App::Jacana::Has::Key
    App::Jacana::Has::Time
    App::Jacana::Has::Voices
    App::Jacana::Music::HasAmbient
/;

has "+key" => default => 0;
has "+mode" => default => "major";

has "+beats" => default => 4;
has "+divisor" => default => 4;

my @MTypes = map "App::Jacana::Music::$_",
    qw/ Barline Clef KeySig MultiRest Note 
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

# We default to treble clef, because Lily does.
sub clef { "treble" }
sub centre_line { 13 }

sub draw { 4 }

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

1;
