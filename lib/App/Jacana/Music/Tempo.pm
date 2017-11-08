package App::Jacana::Music::Tempo;

use App::Jacana::Moose;

use App::Jacana::Util::Length;

use namespace::autoclean;

extends "App::Jacana::Music";
with qw/
    App::Jacana::Has::Tempo
    App::Jacana::Has::Dialog
    App::Jacana::Music::HasAmbient
/;

has "+beat" => (
    isa         => My "Util::Length",
    coerce      => 1,
);

sub dialog { "Tempo" }

sub lily_rx {
    qr( \\tempo \s+ (?<length>[0-9]+) (?<dots>\.*)
        \s+ = \s+ (?<bpm>[0-9]+)
    )x;
}

sub from_lily {
    my ($self, %c) = @_;
    $c{beat} = { App::Jacana::Util::Length->_length_from_lily(%c) };
    $self->new(\%c);
}

sub to_lily {
    my ($self) = @_;

    my $beat = $self->beat;
    sprintf "\\tempo %s = %u", $beat->_length_to_lily, $self->bpm;
}

sub staff_line { 6 }

sub draw {
    my ($self, $c, $pos) = @_;
    
    my $beat    = $self->beat;
    my $txt     = sprintf "%u%s = %u",
        $beat->length, ("." x $beat->dots), $self->bpm;

    $c->save;
        $c->text_font("bold", 4);
       my $wd = $c->show_text($txt);
    $c->restore;

    $wd;
}

1;
