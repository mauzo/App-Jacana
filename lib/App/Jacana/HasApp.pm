package App::Jacana::HasApp;

use Moo::Role;

has app => (
    is          => "ro",
    weak_ref    => 1,
);

sub _resource {
    my ($self, $res) = @_;
    $self->app->resource->$res;
}

1;
