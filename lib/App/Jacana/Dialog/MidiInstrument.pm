package App::Jacana::Dialog::MidiInstrument;

use utf8;
use Moo;
use MooX::MethodAttributes use => ["MooX::Gtk2"];

use App::Jacana::Util::Types;

use App::Jacana::Gtk2::RadioGroup;
use App::Jacana::Gtk2::RadioMember;

extends "App::Jacana::Dialog";
with    qw/ 
    MooX::Gtk2 
    App::Jacana::Has::MidiInstrument
/;

has _menu           => is => "lazy";
has _menu_group     => is => "lazy";
has _menu_button    => is => "lazy";

has "+program" => (
    isa         => Any,
    default     => 68,
    gtk_prop    => "_menu_group.current-value",
);

sub title { "MIDI instrument" }

sub _build__menu_group {
    my ($self)  = @_;
    my $grp     = App::Jacana::Gtk2::RadioGroup->new;
    my $items   = $self->menu;

    for my $it (@$items) {
        $$it{typ} eq "entry" or next;
        my $act = App::Jacana::Gtk2::RadioMember->new(
            name    => "MidiPrg$$it{prg}",
            label   => $$it{label},
            value   => $$it{prg},
        );
        $grp->add_member($act);
    }

    $grp;
}

sub _build__menu {
    my ($self) = @_;
    my $items = $self->menu;

    my $grp     = $self->_menu_group;
    my @menu    = Gtk2::Menu->new;

    for my $it (@$items) {
        if ($$it{typ} eq "entry") {
            my $act = $grp->find_member($$it{prg});
            my $ent = $act->create_menu_item;
            $ent->set_related_action($act);
            $menu[-1]->append($ent);
        }
        if ($$it{typ} eq "separator") {
            $menu[-1]->append(Gtk2::SeparatorMenuItem->new);
        }
        if ($$it{typ} eq "push") {
            my $sub = Gtk2::Menu->new;
            my $ent = Gtk2::MenuItem->new_with_label($$it{label});

            $ent->set_submenu($sub);
            $menu[-1]->append($ent);
            push @menu, $sub;
        }
        if ($$it{typ} eq "pop") {
            pop @menu;
        }
    }

    @menu == 1 or die "Badly nested MIDI instrument menu";
    $menu[0];
}
                
sub _build__menu_button {
    my ($self)  = @_;
    my $prg     = $self->program;
    my $but = Gtk2::OptionMenu->new;

    $but->set_menu($self->_menu);
    $but;
}

sub _build_content_area {
    my ($self, $vb) = @_;

    $vb->pack_start($self->_menu_button, 1, 1, 5);
}
    
1;
