package App::Jacana::Has::MidiInstrument;

use Moo::Role;
use App::Jacana::Util::Types;

use Data::Dump      qw/pp/;
use Readonly::Tiny;

use namespace::clean;

with qw/ MooX::Role::Copiable /;

has program => (
    is          => "rw",
    default     => 68,
    isa         => Int,
    copiable    => 1,
);

my (@Name, %Prg, @Menu);
{
    while (<DATA>) {
        chomp;
        if (s/^(-|\[|\])//) {
            if ($1 eq "-") {
                push @Menu, { typ => "separator" };
            }
            elsif ($1 eq "[") {
                push @Menu, { typ => "push", label => $_ };
            }
            else {
                push @Menu, { typ => "pop" };
            }
            next;
        }
        
        my ($ix, $lily, $name) = split /:/;
        $name ||= ucfirst $lily;

        $Name[$ix] = $lily;
        $Prg{$lily} = $ix;
        push @Menu, { typ => "entry", label => $name, prg => $ix };
    }
    close DATA;
}
readonly \@Menu;

sub instrument { $Name[$_[0]->program] }

sub from_instrument { $Prg{$_[1]} }

sub menu { \@Menu }

__DATA__
[Woodwind
73:flute
68:oboe
71:clarinet
70:bassoon
-
72:piccolo
69:english horn:Cor anglais
74:recorder
-
64:soprano sax
65:alto sax
66:tenor sax
67:baritone sax
]
[Brass
56:trumpet
57:trombone
58:tuba
60:french horn
-
59:muted trumpet
61:brass section
]
[Strings
40:violin
41:viola
42:cello
43:contrabass:Double bass
46:orchestral harp:Harp
[Guitar
24:acoustic guitar (nylon)
25:acoustic guitar (steel)
26:electric guitar (jazz)
27:electric guitar (clean)
28:electric guitar (muted)
29:overdriven guitar
30:distorted guitar
31:guitar harmonics
]
[Bass
32:acoustic bass
33:electric bass (finger)
34:electric bass (pick)
35:fretless bass
36:slap bass 1
37:slap bass 2
38:synth bass 1
39:synth bass 2
]
[Ensemble
44:tremolo strings
45:pizzicato strings
48:string ensemble 1
49:string ensemble 2
]
]
[Folk
21:accordion
109:bagpipe
105:banjo
23:concertina
110:fiddle
22:harmonica
78:whistle
-
108:kalimba
107:koto
75:pan flute
77:shakuhachi
106:shamisen
111:shanai
104:sitar
-
76:blown bottle
79:ocarina
]
[Keyboard
[Piano
0:acoustic grand
1:bright acoustic
2:electric grand
3:honky-tonk
4:electric piano 1
5:electric piano 2
]
[Organ
16:drawbar organ
17:percussive organ
18:rock organ
19:church organ
20:reed organ
]
8:celesta
7:clav:Clavinet
15:dulcimer
6:harpsichord
]
[Percussion
9:glockenspiel
12:marimba
10:music box
114:steel drums
47:timpani
14:tubular bells
11:vibraphone
13:xylophone
-
113:agogo
117:melodic tom
119:reverse cymbal
118:synth drum
116:taiko drum
112:tinkle bell
115:woodblock
]
[Synth
50:synthstrings 1
51:synthstrings 2
62:synthbrass 1
63:synthbrass 2
55:orchestra hit
52:choir aahs
53:voice oohs
54:synth voice
[Lead
80:lead 1 (square):Square
81:lead 2 (sawtooth):Sawtooth
82:lead 3 (calliope):Calliope
83:lead 4 (chiff):Chiff
84:lead 5 (charang):Charan
85:lead 6 (voice):Voice
86:lead 7 (fifths):Fifths
87:lead 8 (bass+lead):Bass + lead
]
[Pad
88:pad 1 (new age):New Age
89:pad 2 (warm):Warm
90:pad 3 (polysynth):Polysynth
91:pad 4 (choir):Choir
92:pad 5 (bowed):Bowed
93:pad 6 (metallic):Metallic
94:pad 7 (halo):Halo
95:pad 8 (sweep):Sweep
]
[FX
96:fx 1 (rain):Rain
97:fx 2 (soundtrack):Soundtrack
98:fx 3 (crystal):Crystal
99:fx 4 (atmosphere):Atmosphere
100:fx 5 (brightness):Brightness
101:fx 6 (goblins):Goblins
102:fx 7 (echoes):Echoes
103:fx 8 (sci-fi):Sci-fi
-
120:guitar fret noise
121:breath noise
122:seashore
123:bird tweet
124:telephone ring
125:helicopter
126:applause
127:gunshot
]
]
