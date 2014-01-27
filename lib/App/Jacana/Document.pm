package App::Jacana::Document;

use 5.012;
use warnings;

use Moo;

use App::Jacana::Music::Clef;
use App::Jacana::Music::KeySig;
use App::Jacana::Music::Note;
use App::Jacana::Music::Rest;
use App::Jacana::Music::Voice;
use App::Jacana::Util::Types;

# We always have a Music::Start item at the head of the list. This is
# invisible and inaudible, but it makes the list traversal easier.
has music => (
    is      => "ro",
    isa     => Music,
    default => sub { App::Jacana::Music::Voice->new },
);

my %Chroma = ("", 0, qw/is 1 es -1 isis 2 eses -2/);
my %Length = qw/ \breve 0 1 1 2 2 4 3 8 4 16 5 32 6 64 7 128 8 /;

sub parse_music {
    my ($self, $text) = @_;

    my $music = $self->music->prev;

    while ($text) {
        $text =~ s/^\s+//;
        if ($text =~ s(
            ^ (?<note>[a-g]) (?<chroma>[eis]*) (?<octave>[',]*)
              (?<length>\\breve|[0-9]+) (?<dots>\.*)
        )()x) {
            my %n = %+;
            my $octave = $n{octave}
                ? length($n{octave}) * ($n{octave} =~ /'/ ? 1 : -1)
                : 0;
            $music = $music->insert(App::Jacana::Music::Note->new(
                note    => $n{note},
                chroma  => $Chroma{$n{chroma}},
                octave  => $octave,
                length  => $Length{$n{length}},
                dots    => length $n{dots},
            ));
        }
        elsif ($text =~ s(
            ^ r (?<length>\\breve|[0-9]+) (?<dots>\.*)
        )()x) {
            $music = $music->insert(App::Jacana::Music::Rest->new(
                length  => $Length{$+{length}},
                dots    => length $+{dots},
            ));
        }
        elsif ($text =~ s(
            ^ \\clef \s+ (?: "(?<clef>[a-z]+)" | (?<clef>[a-z]+) )
        )()x) {
            $music = $music->insert(
                App::Jacana::Music::Clef->new(clef => $+{clef}));
        }
        elsif ($text =~ s(
            ^ \\key \s+ (?<note>[a-g] (?:[ei]s)?)
                \s* \\(?<mode>major|minor)
        )()x) {
            $music = $music->insert(
                App::Jacana::Music::KeySig->from_lily(%+));
        }
        else {
            last;
        }
    }
    $text and die "Can't parse music '$text'";
}

1;
