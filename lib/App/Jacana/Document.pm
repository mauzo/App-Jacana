package App::Jacana::Document;

use 5.012;
use warnings;

use Moo;

use File::Slurp     qw/read_file write_file/;
use Module::Runtime qw/use_module/;
use Regexp::Common;

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
    isa     => ArrayRef[Music],
    default => sub { 
        [ App::Jacana::Music::Voice->new(name => "voice") ];
    },
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
    write_file $self->filename, 
        join "\n",
        map $_->to_lily,
        @{$self->music};
}

sub parse_music {
    my ($self, $text) = @_;

    my $voices = $self->music();
    @$voices = ();

    while ($text) {
        $text =~ s/^\s+//;
        if ($text =~ s(
            ^ ([-a-zA-Z]+) \s* = \s*
              $RE{balanced}{-parens => "{}"}
        )()x) {
            my $v = App::Jacana::Music::Voice->new(name => $1);
            s/^\{//, s/\}$// for my $l = $2;
            $self->parse_voice($v, $l);
            push @$voices, $v;
        }
        else { last }
    }
    $text and die "Unparsable music [$text]";
}

my @MTypes = map "App::Jacana::Music::$_",
    qw/ Barline Clef KeySig Note Rest TimeSig /;
use_module $_ for @MTypes;
require App::Jacana::Music::Lily;

sub parse_voice {
    my ($self, $music, $text) = @_;

    my $unknown = "";
    ITEM: while ($text) {
        $text =~ s/^\s+//;
        for my $M (@MTypes) {
            my $rx = $M->lily_rx;
            if ($text =~ s/^$rx//) {
                if ($unknown) {
                    $music = $music->insert(
                        App::Jacana::Music::Lily->new(
                            lily => $unknown));
                    $unknown = "";
                }
                $music = $music->insert($M->from_lily(%+));
                next ITEM;
            }
        }
        $text =~ s/^(\S+\s*)// and $unknown .= $1;
    }

    $unknown and $music->insert(
        App::Jacana::Music::Lily->new(lily => $unknown));

    $text and die "Unparsable music [$text]";
}

1;
