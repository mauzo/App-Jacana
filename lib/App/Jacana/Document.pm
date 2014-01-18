package App::Jacana::Document;

use 5.012;
use warnings;

use Moo;

use App::Jacana::Music::Note;
use App::Jacana::Util::Types;

# We always have a plain Music item at the head of the list. This is
# invisible and inaudible, but it makes the list traversal easier.
has music => (
    is      => "ro",
    isa     => Music,
    default => sub { App::Jacana::Music->new },
);

sub parse_music {
    my ($self, $text) = @_;

    my $music = $self->music->prev;

    while ($text =~ s/^([a-g])([',]*)([0-9.]+)\s*//) {
        my ($note, $octave, $length) = ($1, $2, $3);
        $octave = $octave
            ? length($octave) * ($octave =~ /'/ ? 1 : -1)
            : 0;
        $music = $music->insert(App::Jacana::Music::Note->new(
            note    => $note,
            octave  => $octave,
            length  => $length,
        ));
    }
}

1;
