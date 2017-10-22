package App::Jacana::View::StaffInfo;

use App::Jacana::Moose;
use App::Jacana::Types;

use POSIX       qw/ceil floor/;
use namespace::autoclean;

has start => (
    is          => "ro",
    required    => 1,
    isa         => Music,
    weak_ref    => 1,
);
has end => (
    is          => "rw",
    isa         => Maybe[Music],
    weak_ref    => 1,
);

has continue => is => "rw", isa => My "StaffCtx::Draw";

# user coordinates
has offset  => is => "ro", required => 1, isa => Int;
# device coordinates
has top     => is => "ro", required => 1, isa => Int;
has bottom  => is => "rw", isa => Int;
has left    => is => "ro", required => 1, isa => Int;
has right   => is => "rw", isa => Int;

sub BUILDARGS {
    my ($class, $s, $c, $x, $y) = @_;

    my $hi = $s->has_item;
    my $i = $s->item;
    warn "BUILD STAFFINFO s [$s] hi [$hi] item [$i]";

    return {
        start   => $s->item,
        offset  => $y,
        top     => floor($c->u2d($s->top) + $y),
        bottom  => ceil($c->u2d($s->bottom) + $y),
        left    => floor($c->u2d($x)),
    };
}

my @CtxAtts = qw/when y bar pos/;

sub update {
    my ($self, $s, $c, $x) = @_;
    $self->end($s->item);
    $self->right(ceil($c->u2d($x)));
    $self->continue($s->clone);
}

1;
