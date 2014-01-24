package App::Jacana::HasWindow;

use Moo::Role;

with "MooX::Role::Copiable";

has _window => (
    is          => "ro",
    init_arg    => "window",
    weak_ref    => 1,
    required    => 1,
    copiable    => 1,
    handles     => [qw/ silly set_status status_flash /],
);

1;
