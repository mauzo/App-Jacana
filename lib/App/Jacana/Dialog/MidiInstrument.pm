package App::Jacana::Dialog::MidiInstrument;

use utf8;
use App::Jacana::Moose;
use MooseX::Gtk2;

use App::Jacana::Gtk2::RadioGroup;
use App::Jacana::Gtk2::RadioMember;

extends "App::Jacana::Dialog";
with    qw/ 
    App::Jacana::Has::MidiInstrument
/;

has _current        => is => "lazy";
has _menu           => is => "lazy";
has _menu_group     => is => "lazy";

has "+program" => (
    traits      => ["Gtk2"],
    #isa         => Any,
    default     => 68,
    gtk_prop    => "_menu_group.current-value",
);

sub title { "MIDI instrument" }

sub _build__current {
    my ($self) = @_;
    
    my $grp     = $self->_menu_group;
    my $lab     = Gtk2::Label->new($grp->get_current->get_label);

    $lab->set_alignment(0, 0.5);
    $grp->signal_connect("notify::current", sub {
        $lab->set_text($grp->get_current->get_label);
    });

    $lab;
}

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
    $menu[0]->show_all;
    $menu[0];
}
                
sub _build_content_area {
    my ($self, $vb) = @_;

    my $menu = $self->_menu;

    my $button  = Gtk2::Button->new;
    my $arrow   = Gtk2::Arrow->new("down", "out");
    $button->add($arrow);
    $button->signal_connect("button-press-event", sub {
        $menu->popup(undef, undef, undef, undef, 0,
            Gtk2->get_current_event_time);
    });

    my $hb      = Gtk2::HBox->new;
    $hb->pack_start($self->_current, 1, 1, 5);
    $hb->pack_end($button, 0, 0, 5);

    $vb->pack_start($hb, 1, 1, 5);
}
    
1;
