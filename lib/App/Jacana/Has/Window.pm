package App::Jacana::Has::Window;

use Moose::Role;
use MooseX::AttributeShortcuts;
use MooseX::Copiable;

has _window => (
    is          => "ro",
    init_arg    => "window",
    weak_ref    => 1,
    required    => 1,
    copiable    => 1,
    handles     => [qw/ 
        silly set_status status_flash status_mode set_busy reset_title
    /],
);

1;
