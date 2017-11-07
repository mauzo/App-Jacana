package App::Jacana::Tables;

use Exporter qw/import/;

our @EXPORT_OK = qw/
    _mkfifths
    %Pitch %Chroma %Mode
    %Staff %Chr2Ly %Ly2Chr
    %Heads %Tails %Acci
    @Fifths %Fifths
    @Trans %Trans
    %Nearest
/;

sub _mkfifths { map "$_$_[0]", qw/f c g d a e b/ }

our %Pitch  = qw/c 0 d 2 e 4 f 5 g 7 a 9 b 11/;
our %Chroma = (qw/eses -2 es -1 is 1 isis 2/, "", 0);
our %Mode   = qw/ major 8 minor 11 /;

our %Staff  = qw/c 0 d 1 e 2 f 3 g 4 a 5 b 6/;
our %Chr2Ly = (0, "", qw/1 is -1 es 2 isis -2 eses/);
our %Ly2Chr = reverse %Chr2Ly;

our %Heads  = qw/0 sM1 1 s0 2 s1/;
our %Tails  = qw/4 3 5 4 6 5 7 6 8 7/;
our %Acci   = qw/0 natural 1 sharp -1 flat 2 doublesharp -2 flatflat/;

our @Fifths = map _mkfifths($_), "es", "", "is";
our %Fifths = map +($Fifths[$_], $_), 0..$#Fifths;

our @Trans = map _mkfifths($_), "eses", "es", "", "is", "isis";
our %Trans = map +($Trans[$_], $_), 0..$#Trans;

our %Nearest = (
    cg => -1, ca => -1, cb => -1, cc =>  0, cd =>  0, ce =>  0, cf =>  0,
    da => -1, db => -1, dc =>  0, dd =>  0, de =>  0, df =>  0, dg =>  0,
    eb => -1, ec =>  0, ed =>  0, ee =>  0, ef =>  0, eg =>  0, ea =>  0,
    fc =>  0, fd =>  0, fe =>  0, ff =>  0, fg =>  0, fa =>  0, fb =>  0,
    gd =>  0, ge =>  0, gf =>  0, gg =>  0, ga =>  0, gb =>  0, gc =>  1,
    ae =>  0, af =>  0, ag =>  0, aa =>  0, ab =>  0, ac =>  1, ad =>  1,
    bf =>  0, bg =>  0, ba =>  0, bb =>  0, bc =>  1, bd =>  1, be =>  1,
);

1;

