package App::Jacana::Gtk2::RadioMember;

=head1 NAME

App::Jacana::Gtk2::RadioMember - a member of a group of radio actions

=cut

use XSLoader;

BEGIN { XSLoader::load }

use App::Jacana::Gtk2::RadioGroup;

# This derives from Action, rather than ToggleAction, because TA insists
# on activating every time it changes state. Since I want an action that
# can distinguish between a passive state change and an active user
# action I need to redo all the toggle-state stuff.
use Glib::Object::Subclass
    "Gtk2::Action",
    properties  => [
        Glib::ParamSpec->boolean(
            "active", "", "",
            0,
            [qw"readable writable"],
        ),
        Glib::ParamSpec->string(
            "value", "", "",
            undef,
            [qw"readable writable"],
        ),
    ],
    signals     => {
        activate    => \&_do_activate,
    };

sub SET_PROPERTY {
    my ($self, $prop, $value) = @_;
    my $name = $prop->get_name;
    $self->{$name} = $value;
}

sub get_value {
    my ($self) = @_;
    $self->{value};
}

sub _do_activate {
    my ($self) = @_;
    my $grp = $self->{radio_group} or return;
    $grp->set_current($self);
    $grp->activate;
}

sub set_group {
    my ($self, $group) = @_;
    $self->{radio_group}
        and Carp::croak "$self is already in a group";
    $group->isa("App::Jacana::Gtk2::RadioGroup")
        or Carp::croak "'$group' is not a RadioGroup";
    $self->{radio_group} = $group;
}

sub create_menu_item {
    my ($self) = @_;
    require App::Jacana::Gtk2::RadioMenuItem;
    my $i = App::Jacana::Gtk2::RadioMenuItem->new;
    $i->set_draw_as_radio(1);
    $i;
}

sub create_tool_item {
    my ($self) = @_;
    require App::Jacana::Gtk2::RadioToolItem;
    App::Jacana::Gtk2::RadioToolItem->new;
}

1;
