package App::Jacana::Window;

use utf8;
use 5.012;
use warnings;

use Moo;
use MooX::MethodAttributes;

use YAML::XS ();

with qw/ App::Jacana::HasApp MooX::Gtk2 /;

has frame       => is => "lazy";
has status_bar  => is => "lazy";
has view        => is => "ro";

has actions     => is => "lazy";
has uimgr       => is => "lazy";

# frame

sub _build_frame {
    my ($self) = @_;

    my $w = Gtk2::Window->new("toplevel");

    $w->set_title("Jacana");
    $w->set_default_size(400, 300);

    my $ui = $self->uimgr;
    $ui->ensure_update;
    $w->add_accel_group($ui->get_accel_group);

    my $vb = Gtk2::VBox->new;
    $vb->pack_start($_, 0, 0, 0) for $ui->get_toplevels("menubar");
    for ($ui->get_toplevels("toolbar")) {
        $_->set_style("icons");
        $_->set_icon_size("small-toolbar");
        $vb->pack_start($_, 0, 0, 0);
    }

    $vb->pack_start($self->view->widget, 1, 1, 0);
    $vb->pack_start($self->status_bar, 0, 0, 0);

    $w->add($vb);
    $w;
}

sub _quit : Signal(frame::destroy) Action(Quit) { 
    Gtk2->main_quit;
}

# actions

sub _build_actions {
    my ($self) = @_;
    my $actions = YAML::XS::Load <<YAML;
        FileMenu:
            label:          File
        Quit:
            label:          Quit
            accelerator:    "<Ctrl>Q"

        MidiMenu:
            label:          MIDI
        MidiPlay:
            stock_id:       gtk-media-play
            label:          Play
            accelerator:    F5
YAML
    my $grp = Gtk2::ActionGroup->new("edit");
    $grp->add_actions([
        map +{ name => $_, %{$$actions{$_}} },
        keys %$actions
    ]);
    $grp;
}

sub _build_uimgr {
    my ($self) = @_;
    my $ui = Gtk2::UIManager->new;
    $ui->add_ui_from_string(<<XML);
        <menubar>
            <menu action="FileMenu">
                <menuitem action="Quit"/>
            </menu>
            <menu action="MidiMenu">
                <menuitem action="MidiPlay"/>
            </menu>
        </menubar>
        <toolbar>
            <toolitem action="MidiPlay"/>
        </toolbar>
XML
    $ui->insert_action_group($self->actions, 0);
    $ui;
}

sub _play_music :Action(MidiPlay) {
    my ($self, $action) = @_;
    my $app     = $self->app;
    my $view    = $self->view;

    $self->set_status("playing");
    $action->set_sensitive(0);

    $app->midi->play_music(
        $app->document->music,
        sub { $view->playing_on($_[0]) },
        sub { $view->playing_off($_[0]) },
        sub { 
            $self->set_status("");
            $action->set_sensitive(1);
        },
    );
}

# status bar

sub _build_status_bar { 
    my ($self) = @_;
    my $b = Gtk2::Statusbar->new;
    $b->push(0, "loading…");
    $b;
}

sub set_status {
    my ($self, $msg) = @_;
    my $b = $self->status_bar;
    $b->pop(0);
    $b->push(0, $msg);
}

# show

sub show {
    my ($self) = @_;
    $self->frame->show_all;
}

1;
