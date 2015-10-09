package App::Jacana::Music::Ambient;

use Moo;
use MooX::AccessorMaker
    apply => [qw/ MooX::MakerRole::IgnoreUndef /];

use App::Jacana::Util::Types;

use Carp;

use namespace::clean;

my $Amb     = "App::Jacana::Music::Ambient";
my $HasAmb  = "App::Jacana::Music::HasAmbient";

has prev    => (
    is          => "lazy",
    isa         => Maybe[InstanceOf[$Amb]],
    weak_ref    => 1,
    ignore_undef    => 1,
);
has owner   => (
    is          => "ro",
    required    => 1,
    isa         => ConsumerOf[$HasAmb],
    weak_ref    => 1,
);

sub _build_prev {
    my ($self) = @_;

    my $own     = $self->owner;
    my $item    = $own;

    for (;;) {
        $item->is_music_start and return;
        $item = $item->prev;
        $item->DOES($HasAmb) and last;
    }

    $item->ambient;
}

sub find_role {
    my ($self, $role) = @_;

    my $owner = $self->owner;
    $owner->DOES("App::Jacana::Has::$role") and return $owner;

    my $prev = $self->prev or croak "No intial value for $role";
    $prev->find_role($role);
}

sub find_voice {
    my ($self) = @_;

    my $owner = $self->owner;
    $owner->isa("App::Jacana::Music::Voice") and return $owner;
    $self->prev->find_voice;
}

1;
