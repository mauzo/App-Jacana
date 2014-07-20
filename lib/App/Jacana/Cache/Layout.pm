package App::Jacana::Cache::Layout;

use Moo;

use App::Jacana::Util::Types;
use namespace::clean;

has start_x => is => "rw", isa => Num, default => 0;

# the heights of the staffs
has height => is => "rw", isa => ArrayRef[Num];

has columns => (
    is      => "rw",
    isa     => ArrayRef[InstanceOf["App::Jacana::Cache::Position"]],
);

sub end_x {
    my ($self) = @_;
    $self->columns->[-1]->x;
}

sub find_x {
    my ($self, $x) = @_;
    $x < $self->start_x || $x >= $self->end_x and return;
    for (@{$self->columns}) {
        $_->x > $x and return $_;
    }
    die "Panic: Layout->find_x";
}



1;
