package App::Jacana::Music::HasAmbient;

use Moo::Role;
use MooX::AccessorMaker
    apply => [qw/ MooX::MakerRole::IgnoreUndef /];

use App::Jacana::Music::Ambient;
use App::Jacana::Util::Types;

use namespace::clean;

has ambient     => (
    is          => "ro",
    lazy        => 1,
    builder     => 1,
    isa         => InstanceOf["App::Jacana::Music::Ambient"],
    weak_ref    => 0,
    ignore_undef    => 1,
    clearer     => 1,
);

sub _build_ambient {
    my ($self) = @_;

    my $amb = App::Jacana::Music::Ambient->new(owner => $self);
    warn "BUILD AMBIENT FOR [$self] [$amb]";
    $amb;
}

1;
