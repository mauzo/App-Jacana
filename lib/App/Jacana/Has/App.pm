package App::Jacana::Has::App;

use Moose::Role;
use MooseX::Copiable;

has app => (
    is          => "ro",
    traits      => [qw/Copiable/],
    required    => 1,
#    isa         => InstanceOf["App::Jacana"],
    weak_ref    => 1,
);

sub _resource {
    my ($self, $res) = @_;
    $self->app->resource->$res;
}

1;
