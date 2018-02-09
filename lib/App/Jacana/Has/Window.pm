package App::Jacana::Has::Window;

use App::Jacana::Moose  -role;
use MooseX::Copiable;

has _window => (
    is          => "ro",
    traits      => [qw/Copiable/],
    init_arg    => "window",
    weak_ref    => 1,
    required    => 1,
    handles     => [qw/ 
        silly set_status status_flash set_busy
    /],
);

1;
