package App::Jacana::Has::App;

use Moose::Role;
use MooseX::Copiable;

#with qw/App::Jacana::Role::Copiable/;
#Moose::Util::ensure_all_roles __PACKAGE__, "App::Jacana::Role::Copiable";

has app => (
    is          => "ro",
    required    => 1,
#    isa         => InstanceOf["App::Jacana"],
    weak_ref    => 1,
    copiable    => 1,
);

sub _resource {
    my ($self, $res) = @_;
    $self->app->resource->$res;
}

1;
