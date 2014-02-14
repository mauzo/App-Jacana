package App::Jacana::HasClef;

use Moo::Role;

use App::Jacana::Util::Pitch;

use POSIX ();

# A named clef type. This must be provided so key signatures know where
# to draw their sharps and flats.
requires "clef";

# The note on the centre line, counting in staff lines above 4' C = 0.
requires "centre_line";

sub centre_pitch {
    my ($self) = @_;
    my $line = $self->centre_line;
    App::Jacana::Util::Pitch->new(
        octave  => POSIX::floor($line / 7),
        note    => (qw/c d e f g a b/)[$line % 7],
        chroma  => 0,
    );
}

1;
