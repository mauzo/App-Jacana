package App::Jacana::Has::App;

use Moo::Role;
use App::Jacana::Util::Types;

with qw/MooX::Role::Copiable/;

has app => (
    is          => "ro",
    required    => 1,
    isa         => InstanceOf["App::Jacana"],
    weak_ref    => 1,
    copiable    => 1,
);

sub _resource {
    my ($self, $res) = @_;
    $self->app->resource->$res;
}

1;
