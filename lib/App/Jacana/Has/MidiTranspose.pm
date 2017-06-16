package App::Jacana::Has::MidiTranspose;

use Moose::Role;
use MooseX::Copiable;

use App::Jacana::Types -all;
use App::Jacana::Util::Pitch;
use App::Jacana::Tables qw/@Trans %Trans %Chroma %Nearest/;

use namespace::autoclean;

has into => (
    is          => "rw",
    isa         => Has "Pitch",
    traits      => [qw/Copiable/],
    deep_copy   => 1,
    required    => 1,
);

sub transpose {
    my ($self, $pos) = @_;
    
    if (Has("Pitch")->check($pos)) {
        my $into    = $self->into->pitch_to_lily(1);
        my $by      = $Trans{$into} - $Trans{c};
        my $old     = $pos->pitch_to_lily(1);
        my $new     = $Trans{$old} + $by;
        $new < 0        and $new += 12;
        $new > $#Trans  and $new -= 12;

        my ($note, $chrm) = $Trans[$new] =~ /(.)(.*)/;

        return App::Jacana::Util::Pitch->new(
            note    => $note,
            chroma  => $Chroma{$chrm},
            octave  => $pos->octave + $self->into->octave +
                $Nearest{$pos->note . $note},
        );
    }

    return $pos;
}

1;
