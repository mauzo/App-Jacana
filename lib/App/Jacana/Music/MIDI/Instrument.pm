package App::Jacana::Music::MIDI::Instrument;

use App::Jacana::Moose;
use App::Jacana::Log;

extends "App::Jacana::Music";
with qw/
    App::Jacana::Music::HasAmbient
    App::Jacana::Has::Dialog
    App::Jacana::Has::MidiInstrument
    App::Jacana::Has::OwnLine
/;

sub lily_rx { qr{ 
    \\set \s+ Staff.midiInstrument \s+ = \s+
    \#" (?<instrument>[a-z0-9() -]+) "
}x }

sub from_lily {
    my ($class, %n) = @_;
    my $prg = $class->from_instrument($n{instrument});
    msg DEBUG => "MIDI INSTRUMENT [$n{instrument}] = [$prg]";
    $class->new(program => $prg);
}

sub to_lily {
    my ($self) = @_;
    my $ins = $self->instrument;
    qq/\\set Staff.midiInstrument = #"$ins"/;
}

sub dialog { "MIDI::Instrument" }

sub draw {
    my ($self, $c) = @_;

    $c->save;
        $c->text_font("normal", 4);
        $c->move_to(0, -0.5);
        my $wd = $c->show_text("MI");
        $c->move_to(0.3, 3.5);
        $c->show_text("DI");
    $c->restore;

    return $wd;
}

1;
