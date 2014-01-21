package App::Jacana::HasActions;

use Moo::Role;
use App::Jacana::Util::Types;

has actions     => (
    is          => "ro",
    required    => 1,
    isa         => InstanceOf["Gtk2::ActionGroup"],
    handles     => ["get_action"],
);

1;
