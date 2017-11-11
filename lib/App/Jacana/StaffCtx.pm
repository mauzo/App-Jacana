package App::Jacana::StaffCtx;

use App::Jacana::Moose;
use MooseX::Copiable;

use Scalar::Util                qw/blessed/;
use namespace::autoclean;

has item => (
    is          => "rw", 
    isa         => My "Music",
    weak_ref    => 1,
    clearer     => 1,
    predicate   => 1,
    traits      => [qw/Copiable/],
);

sub clone {
    my ($self, @args) = @_;
    my $class = blessed $self;
    $class->new(copy_from => $self, @args);
}

sub next {
    my ($self) = @_;

    my $note = $self->item  or return;
    $note->is_music_end     and return $self->at_end;
    $self->item($note->next);
    return 1;
}

sub at_end {
    return;
}

1;
