package App::Jacana::Has::Clef;

use Moose::Role;
use MooseX::Copiable;

use App::Jacana::Util::Pitch;

use POSIX ();

use namespace::autoclean;

my %Clef = (
    treble      => [qw/G -2/],
    alto        => [qw/C 0/],
    tenor       => [qw/C 2/],
    bass        => [qw/F 2/],
    soprano     => [qw/C -4/],
);

has clef => (
    is          => "rw",
    traits      => [qw/Copiable/],
    #isa         => Enum[keys %Clef],
    required    => 1,
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
