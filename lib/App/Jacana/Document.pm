package App::Jacana::Document;

use 5.012;
use warnings;

use Moo;

use App::Jacana::Music::Clef;
use App::Jacana::Music::Note;
use App::Jacana::Music::Start;
use App::Jacana::Util::Types;

# We always have a Music::Start item at the head of the list. This is
# invisible and inaudible, but it makes the list traversal easier.
has music => (
    is      => "ro",
    isa     => Music,
    default => sub { App::Jacana::Music::Start->new },
);

my %Chroma = ("", 0, qw/is 1 es -1 isis 2 eses -2/);

sub parse_music {
    my ($self, $text) = @_;

    my $music = $self->music->prev;

    while ($text) {
        $text =~ s/^\s+//;
        if ($text =~ s(
            ^ (?<note>[a-g]) (?<chroma>[eis]*) (?<octave>[',]*)
              (?<length>[0-9]+) (?<dots>\.*)
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
        elsif ($text =~ s(
            ^ \\clef \s+ (?: "(?<type>[a-z]+)" | (?<type>[a-z]+) )
        )()x) {
            $music = $music->insert(
                App::Jacana::Music::Clef->new(type => $+{type}));
        }
        else {
            last;
        }
    }
    $text and die "Can't parse music '$text'";
}

1;
