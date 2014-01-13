package App::Jacana::HasApp;

use Moo::Role;

has app => is => "ro";

sub _resource {
    my ($self, $res) = @_;
    $self->app->resource->$res;
}

1;
