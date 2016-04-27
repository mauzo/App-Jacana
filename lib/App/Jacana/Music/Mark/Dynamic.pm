package App::Jacana::Music::Mark::Dynamic;

use App::Jacana::Moose;

extends "App::Jacana::Music::Mark";

my @Dynamics = qw/
    pp p mp mf f ff fp sf sfz rf
/;

has dynamic => (
    is          => "rw",
    required    => 1,
    #isa         => Enum[@Dynamics],
);

sub lily_rx { 
    my $dyn = join "|", @Dynamics;
    qr/ \\ (?<dynamic> $dyn ) /x 
}

sub from_lily {
    my ($self, %n) = @_;
    $n{dynamic} or return;
    $self->new(\%n);
}

sub to_lily { "\\" . $_[0]->dynamic }

sub draw {
    my ($self, $c, $pos) = @_;

    my ($wd, @gly) = $c->layout_glyphs(undef, $self->dynamic);

    $c->save;
        $c->translate(0, 10 + $pos);
        $c->show_glyphs(@gly);
    $c->restore;

    return 1;
}

1;
