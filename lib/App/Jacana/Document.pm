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

my %Chroma = ("", 0, qw/is 1 es -1 isis 2 eses -2/);

sub parse_music {
    my ($self, $text) = @_;

    my $music = $self->music->prev;

    $text =~ s/^\s+//;
    while ($text =~ s(
        ^ (?<note>[a-g]) (?<chroma>[eis]*) (?<octave>[',]*)
          (?<length>[0-9]+) (?<dots>\.*)
        \s*
    )()x) {
        my %n = %+;
        my $octave = $n{octave}
            ? length($n{octave}) * ($n{octave} =~ /'/ ? 1 : -1)
            : 0;
        $music = $music->insert(App::Jacana::Music::Note->new(
            note    => $n{note},
            chroma  => $Chroma{$n{chroma}},
            octave  => $octave,
            length  => $n{length},
            dots    => length $n{dots},
        ));
    }
    $text and die "UNPARSED MUSIC [$text]";
}

1;
