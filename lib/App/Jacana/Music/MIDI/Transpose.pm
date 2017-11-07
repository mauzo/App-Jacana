package App::Jacana::Music::MIDI::Transpose;

use App::Jacana::Moose;

use App::Jacana::Tables qw/%Acci/;

extends "App::Jacana::Music";
with qw/
    App::Jacana::Music::HasAmbient
    App::Jacana::Has::Dialog
    App::Jacana::Has::MidiTranspose
/;

has "+into" => (
    isa     => My "Util::Pitch",
    coerce  => 1,
);

my $Pitch = "App::Jacana::Util::Pitch";

sub lily_rx { 
    my $pitch = $Pitch->pitch_rx;
    qr{ \\transposition \s+ $pitch }x;
}

sub from_lily {
    my ($class, @args) = @_;
    $class->new({
        into => { $Pitch->pitch_from_lily(@args) },
    });
}

sub to_lily {
    my ($self) = @_;
    my $trans = $self->into->pitch_to_lily;
    qq/\\transposition $trans/;
}

sub dialog { "MIDI::Transpose" }

sub draw {
    my ($self, $c) = @_;

    $c->save;
        $c->text_font("normal", 4);
        $c->move_to(0, -0.5);
        my $wd = $c->show_text("in");
        $c->move_to(0.3, 3.5);
        my $x = $c->show_text(uc $self->into->note);
    $c->restore;

    if (my $chroma = $self->into->chroma) {
        my $glyph   = $c->glyph("accidentals.$Acci{$chroma}");

        $c->save;
            if ($chroma > 0) {
                $c->translate(0.4 + $x, 2.9);
                $c->scale(0.65, 0.65);
            }
            else {
                $c->translate(0.5 + $x, 3.3);
                $c->scale(0.7, 0.7);
            }
            $c->show_glyphs($glyph);
        $c->restore;
    }

    return $wd + 0.2;
}

1;
