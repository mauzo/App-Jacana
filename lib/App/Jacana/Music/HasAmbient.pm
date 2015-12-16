package App::Jacana::Music::HasAmbient;

use Moose::Role;
use MooseX::AttributeShortcuts;

use App::Jacana::Music::Ambient;

use namespace::autoclean;

has ambient     => (
    traits      => [qw/IgnoreUndef/],
    is          => "ro",
    lazy        => 1,
    builder     => 1,
    #isa         => InstanceOf["App::Jacana::Music::Ambient"],
    clearer     => 1,
);

sub _build_ambient {
    my ($self) = @_;

    my $amb = App::Jacana::Music::Ambient->new(owner => $self);
    warn "BUILD AMBIENT FOR [$self] [$amb]";
    $amb;
}

1;
