package App::Jacana::Music::FindAmbient;

use Moose::Role;
use MooseX::AttributeShortcuts;

use Carp;

use namespace::autoclean;

requires    qw/prev is_music_start/;

has ambient     => (
    traits      => ["IgnoreUndef"],
    is          => "rw",
    lazy        => 1,
    builder     => 1,
    #isa         => InstanceOf["App::Jacana::Music::Ambient"],
    weak_ref    => 1,
    clearer     => 1,
);

sub _build_ambient {
    my ($self) = @_;

    $self->is_music_start and confess "Start of list must be HasAmbient";
    my $prev = $self->prev;
    my $amb = $self->prev->ambient;
    $amb;
}

1;
