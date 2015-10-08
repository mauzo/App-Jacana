package App::Jacana::Music::FindAmbient;

use Moo::Role;
use MooX::AccessorMaker
    apply => [qw/ MooX::MakerRole::IgnoreUndef /];

use App::Jacana::Util::Types;

requires    qw/prev is_music_start/;

has ambient     => (
    is          => "rw",
    lazy        => 1,
    builder     => 1,
    isa         => InstanceOf["App::Jacana::Music::Ambient"],
    weak_ref    => 1,
    ignore_undef    => 1,
    clearer     => 1,
);

sub _build_ambient {
    my ($self) = @_;

    $self->is_music_start and die "Start of list must be HasAmbient";
    my $prev = $self->prev;
    my $amb = $self->prev->ambient;
    warn "FOUND AMBIENT [$amb] FROM [$prev] FOR [$self]";
    $amb;
}

1;
