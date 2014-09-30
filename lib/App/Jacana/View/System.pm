package App::Jacana::View::System;

use Moo;

use App::Jacana::Util::Types;

use List::Util      qw/first/;

use namespace::clean;

has surface => (
    is      => "lazy",
    isa     => InstanceOf["Cairo::ImageSurface"],
);

# device coordinates
has top     => is => "ro", isa => Int, required => 1;
has height  => is => "ro", isa => Int, required => 1;
has width   => is => "ro", isa => Int, required => 1;

has staffs => (
    is      => "rw",
    isa     => ArrayRef[InstanceOf[My "View::StaffInfo"]],
);

sub _build_surface {
    my ($self) = @_;
    Cairo::ImageSurface->create("a8", $self->width, $self->height);
}

sub bottom { $_[0]->top + $_[0]->height }

sub find_item_at {
    my ($self, $x, $y) = @_;

    my $staff = first {
        my $bot = $_->bottom;
        warn "FIND STAFF [$_] [$y] [$bot]";
        $_->bottom >= $y 
    } @{$self->staffs};
    my ($i, $e) = ($staff->start, $staff->end);
    while (1) {
        $i->bbox->[2] > $x  and return $i;
        $i = $i->next   or return;
        $i == $e        and return;
    }
    $i;
}

1;
