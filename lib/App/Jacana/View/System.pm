package App::Jacana::View::System;

use App::Jacana::Moose;
use App::Jacana::Types;

use List::Util      qw/first/;

use namespace::autoclean;

with qw/App::Jacana::Has::Tick/;

has surface => (
    is      => "lazy",
    isa     => InstanceOf["Cairo::ImageSurface"],
);

# device coordinates
has top     => is => "ro", required => 1, isa => Int;
has height  => is => "ro", required => 1, isa => Int;
has width   => is => "ro", required => 1, isa => Int;

has staffs => (
    is      => "rw",
    isa     => ArrayRef[My "View::StaffInfo"],
);

sub _build_surface {
    my ($self) = @_;
    Cairo::ImageSurface->create("argb32", $self->width, $self->height);
}

sub bottom { $_[0]->top + $_[0]->height }

sub find_item_at {
    my ($self, $x, $y) = @_;

    my $staff = first {
        my $bot = $_->bottom;
        $_->bottom >= $y 
    } @{$self->staffs};
    my ($i, $e) = ($staff->start, $staff->end);
    while (1) {
        no warnings "uninitialized";
        $i->bbox->[2] > $x  and return $i;
        $i = $i->next   or return;
        $i == $e        and return;
    }
    $i;
}

1;
