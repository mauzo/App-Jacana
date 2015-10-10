package App::Jacana::Has::MidiInstrument;

use Moo::Role;
use App::Jacana::Util::Types;

use Readonly::Tiny;

use namespace::clean;

with qw/ MooX::Role::Copiable /;

has program => (
    is          => "rw",
    default     => 68,
    isa         => Int,
    copiable    => 1,
);

my (@Name, %Prg, @Groups);
{
    my $grp;
    while (<DATA>) {
        chomp;
        if (s/^@//) {
            $grp = [];
            push @Groups, $_, $grp;
            next;
        }
        push @Name, $_;
        push @$grp, $#Name;
        $Prg{$_} = $#Name;
    }
}
readonly \@Groups;
require Data::Dump;
warn "MIDI INSTRUMENTS: " . Data::Dump::pp(
    { Name => \@Name, Prg => \%Prg, Groups => \@Groups });

sub instrument { $Name[$_[0]->program] }

sub from_instrument { $Prg{$_[1]} }

sub groups { \@Groups }

__DATA__
@piano
acoustic grand
bright acoustic
electric grand
honky-tonk
electric piano 1
electric piano 2
harpsichord
clav
@tuned percussion
celesta
glockenspiel
music box
vibraphone
marimba
xylophone
tubular bells
dulcimer
@organ
drawbar organ
percussive organ
rock organ
church organ
reed organ
accordion
harmonica
concertina
@guitar
acoustic guitar (nylon)
acoustic guitar (steel)
electric guitar (jazz)
electric guitar (clean)
electric guitar (muted)
overdriven guitar
distorted guitar
guitar harmonics
@bass
acoustic bass
electric bass (finger)
electric bass (pick)
fretless bass
slap bass 1
slap bass 2
synth bass 1
synth bass 2
@strings
violin
viola
cello
contrabass
tremolo strings
pizzicato strings
orchestral harp
timpani
@ensemble
string ensemble 1
string ensemble 2
synthstrings 1
synthstrings 2
choir aahs
voice oohs
synth voice
orchestra hit
@brass
trumpet
trombone
tuba
muted trumpet
french horn
brass section
synthbrass 1
synthbrass 2
@reed
soprano sax
alto sax
tenor sax
baritone sax
oboe
english horn
bassoon
clarinet
@pipe
piccolo
flute
recorder
pan flute
blown bottle
shakuhachi
whistle
ocarina
@synth lead
lead 1 (square)
lead 2 (sawtooth)
lead 3 (calliope)
lead 4 (chiff)
lead 5 (charang)
lead 6 (voice)
lead 7 (fifths)
lead 8 (bass+lead)
@synth pad
pad 1 (new age)
pad 2 (warm)
pad 3 (polysynth)
pad 4 (choir)
pad 5 (bowed)
pad 6 (metallic)
pad 7 (halo)
pad 8 (sweep)
@synth fx
fx 1 (rain)
fx 2 (soundtrack)
fx 3 (crystal)
fx 4 (atmosphere)
fx 5 (brightness)
fx 6 (goblins)
fx 7 (echoes)
fx 8 (sci-fi)
@ethnic
sitar
banjo
shamisen
koto
kalimba
bagpipe
fiddle
shanai
@percussion
tinkle bell
agogo
steel drums
woodblock
taiko drum
melodic tom
synth drum
reverse cymbal
@sound fx
guitar fret noise
breath noise
seashore
bird tweet
telephone ring
helicopter
applause
gunshot
