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
        $item->is_list_start and return;
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

sub find_span_start {
    my ($self, $span) = @_;

    my $owner = $self->owner;
    $owner->DOES("App::Jacana::Has::Span")
        && $owner->span_start
        && grep $_ eq $span, $owner->span_types
        and return $owner;

    my $prev = $self->prev or return;
    $prev->find_span_start($span);
}

1;
