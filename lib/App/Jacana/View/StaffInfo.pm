package App::Jacana::View::StaffInfo;

use App::Jacana::Moose;
use POSIX       qw/ceil floor/;
use namespace::autoclean;

has start => (
    is          => "ro",
    required    => 1,
    #isa         => Music,
    weak_ref    => 1,
);
has end => (
    is          => "rw",
    #isa         => Maybe[Music],
    weak_ref    => 1,
);

has ctxinfo => is => "rw";#, isa => ArrayRef;

# device coordinates
has offset  => is => "ro", required => 1;#, isa => Int;
has top     => is => "ro", required => 1;#, isa => Int;
has bottom  => is => "rw";#, isa => Int;
has left    => is => "ro", required => 1;#, isa => Int;
has right   => is => "rw";#, isa => Int;

sub create {
    my ($class, $s, $c, $x, $y) = @_;

    $class->new({
        start   => $s->item,
        offset  => $y,
        top     => floor($c->u2d($s->top) + $y),
        bottom  => ceil($c->u2d($s->bottom) + $y),
        left    => floor($c->u2d($x)),
    });
}

my @CtxAtts = qw/when y bar pos/;

sub update {
    my ($self, $s, $c, $x) = @_;
    $self->end($s->item);
    $self->right(ceil($c->u2d($x)));
    $self->ctxinfo([map +($_, $s->$_), @CtxAtts]);
}

sub continue {
    my ($self) = @_;
    
    my $item = $self->end or return;
    My("StaffCtx::Draw")->new({
        item    => $item,
        @{$self->ctxinfo},
    });
}

1;
