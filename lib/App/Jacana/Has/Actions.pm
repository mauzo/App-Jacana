package App::Jacana::Has::Actions;

use Moose::Role;
use MooseX::Copiable;

has actions     => (
    is          => "ro",
    traits      => [qw/Copiable/],
    required    => 1,
#    isa         => InstanceOf["Gtk2::ActionGroup"],
    handles     => ["get_action"],
);

1;
