package App::Jacana::Document;

use 5.012;
use warnings;

use Moo;

use App::Jacana::Music::Note;

has music => (
    is      => "ro",
    lazy    => 1,
    default => sub { +[] },
);

sub push_music {
    my ($self, @music) = @_;
    push @{$self->music}, @music;
}

sub parse_music {
    my ($self, $text) = @_;

    while ($text =~ s/^([a-g])([',]*)([0-9.]+)\s*//) {
        my ($note, $octave, $length) = ($1, $2, $3);
        $octave = $octave
            ? length($octave) * ($octave =~ /'/ ? 1 : -1)
            : 0;
        $self->push_music(App::Jacana::Music::Note->new(
            note    => $note,
            octave  => $octave,
            length  => $length,
        ));
    }
}

1;
