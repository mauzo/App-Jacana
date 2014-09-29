package App::Jacana::View::Line;

use Moo;
use App::Jacana::Util::Types;
use namespace::clean;

has surface => (
    is      => "lazy",
    isa     => InstanceOf["Cairo::ImageSurface"],
);

has top     => is => "ro", isa => Int, required => 1;
has height  => is => "ro", isa => Int, required => 1;
has width   => is => "ro", isa => Int, required => 1;

has upto => (
    is      => "ro",
    lazy    => 1,
    isa     => ArrayRef[InstanceOf[My "StaffCtx::Draw"]],
    default => sub { +[] },
);

sub _build_surface {
    my ($self) = @_;
    Cairo::ImageSurface->create("a8", $self->width, $self->height);
}

sub bottom { $_[0]->top + $_[0]->height }

1;
