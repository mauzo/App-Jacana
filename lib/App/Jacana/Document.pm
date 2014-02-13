package App::Jacana::Document;

use 5.012;
use warnings;

use Moo;

use File::Slurp     qw/read_file write_file/;

use App::Jacana::Music::Clef;
use App::Jacana::Music::KeySig;
use App::Jacana::Music::Note;
use App::Jacana::Music::Rest;
use App::Jacana::Music::TimeSig;
use App::Jacana::Music::Voice;
use App::Jacana::Util::Types;

use namespace::clean;

has filename => (
    is          => "rw",
    isa         => Maybe[Str],
    predicate   => 1,
    clearer     => 1,
);
has dirty => (
    is      => "rw",
    isa     => Bool,
    default => 0,
);

# We always have a Music::Start item at the head of the list. This is
# invisible and inaudible, but it makes the list traversal easier.
has music => (
    is      => "ro",
    isa     => Music,
    default => sub { App::Jacana::Music::Voice->new },
);

sub open {
    my ($self, $file) = @_;

    my $lily    = read_file $file;
    my $new     = $self->new(filename => $file);

    $new->parse_music($lily);
    $new;
}

sub save {
    my ($self) = @_;

    $self->has_filename or die "No filename";
    write_file $self->filename, $self->music->to_lily;
}

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
        elsif ($text =~ s(
            ^ \\time \s+ (?<beats>[0-9]+) / (?<divisor>[0-9]+)
            (?: \s* \\partial \s+ (?<plen>[0-9]+) (?<pdots>\.*) )?
        )()x) {
            $music = $music->insert(
                App::Jacana::Music::TimeSig->from_lily(%+));
        }
        else {
            last;
        }
    }
    $text and die "Can't parse music '$text'";
}

1;
