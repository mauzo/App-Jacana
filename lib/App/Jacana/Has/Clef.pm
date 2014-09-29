package App::Jacana::Has::Clef;

use Moo::Role;

use App::Jacana::Util::Pitch;
use App::Jacana::Util::Types;

use POSIX ();

use namespace::clean;

with qw/MooX::Role::Copiable/;

my %Clef = (
    treble      => [qw/G -2/],
    alto        => [qw/C 0/],
    tenor       => [qw/C 2/],
    bass        => [qw/F 2/],
    soprano     => [qw/C -4/],
);

has clef => (
    is          => "rw",
    isa         => Enum[keys %Clef],
    required    => 1,
    copiable    => 1,
);

sub clef_type { $Clef{$_[0]->clef}[0] }

sub staff_line {
    my ($self) = @_;
    $Clef{$self->clef}[1];
}

my %Centre = qw/C 7 F 3 G 11/;
sub centre_line {
    my ($self) = @_;
    $Centre{$Clef{$self->clef}[0]} - $self->staff_line;
}

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
