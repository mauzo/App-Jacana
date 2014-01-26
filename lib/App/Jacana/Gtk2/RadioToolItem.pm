package App::Jacana::Gtk2::RadioToolItem;

use App::Jacana::Gtk2::Activatable;

use Glib::Object::Subclass
    "Gtk2::ToggleToolButton",
    interfaces => ["Gtk2::Activatable"];

sub UPDATE {
    my ($self, $action, $prop) = @_;

    $self->Gtk2::ToolButton::UPDATE($action, $prop);
    
    if ($prop eq "active") {
        $action->block_activate;
        $self->set_active($action->get_property("active"));
        $action->unblock_activate;
    }
}

sub SYNC_ACTION_PROPERTIES {
    my ($self, $action) = @_;

    $action or return;

    $self->Gtk2::ToolButton::SYNC_ACTION_PROPERTIES($action);

    $action->block_activate;
    $self->set_active($action->get_property("active"));
    $action->unblock_activate;
}

1;
