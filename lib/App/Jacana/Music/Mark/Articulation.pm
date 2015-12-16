package App::Jacana::Music::Mark::Articulation;

use App::Jacana::Moose;

extends "App::Jacana::Music::Mark";
with    qw/ App::Jacana::Has::Articulation /;

my $Artic = __PACKAGE__->articulation_types;

sub lily_rx {
    my $artic = join "|", keys %$Artic;
    qr( \s* \\ (?<articulation>$artic) )x;
}

sub to_lily { "\\" . $_[0]->articulation }

sub from_lily {
    my ($self, %n) = @_;
    $n{articulation} or return;
    $self->new(\%n);
}

sub draw {
    my ($self, $c, $pos, $up) = @_;

    my $artic   = $self->articulation       or return;
    my $meta    = $$Artic{$artic};

    my $glyph   = "scripts." 
        . ($$meta{glyph} ? $up ? "d" : "u" : "")
        . ($$meta{name} || $artic);

    my $y = $$meta{pos}
        ? ($up ? 2.5 : -2.5)
        : ($pos > 4) ? -3.5 : $pos - 8.5;

    $c->save;
        $c->translate(2, $y);
        $c->show_glyphs($c->glyph($glyph));
    $c->restore;
}

Moose::Util::find_meta(__PACKAGE__)->make_immutable;
