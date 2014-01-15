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
    $w->set_default_size(800, 600);

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

sub _quit :Action(Quit) { 
    my ($self) = @_;
    $self->frame->destroy;
}

sub _destroy :Signal(frame::destroy) {
    my ($self) = @_;
    Gtk2->main_quit;
}

# actions

my @NoteLengths = qw/
    semibreve minim crotchet quaver semiquaver
/;

sub _build_actions {
    my ($self) = @_;
    my $actions = YAML::XS::Load <<'YAML';
        FileMenu:
            label:          File
        Quit:
            label:          Quit
            accelerator:    "<Ctrl>Q"

        NoteMenu:
            label:          Note
        Backspace:
            label:          Backspace
            accelerator:    BackSpace

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
    $grp->add_actions([
        map +{
            name        => "Insert$_",
            label       => "Insert $_",
            accelerator => $_,
            callback    => $self->weak_method(
                "_insert_note", [], [$_]),
        },
        "A".."G"
    ]);
    $grp->add_radio_actions([   
        map +{
            name        => "Note\u$NoteLengths[$_]",
            label       => "\u$NoteLengths[$_]",
            accelerator => $_ + 1,
            value       => (1<<$_),
        },
        0..$#NoteLengths
    ], 4, undef);

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
            <menu action="NoteMenu"/>
            <menu action="MidiMenu">
                <menuitem action="MidiPlay"/>
            </menu>
        </menubar>
        <toolbar>
            <toolitem action="MidiPlay"/>
        </toolbar>
        <accelerator action="Backspace"/>
XML
    my $notemenu = join "",
        map qq!<menuitem action="Insert$_"/>!,
        "A".."G";
    $notemenu .= "<separator/>";
    $notemenu .= join "",
        map qq!<menuitem action="Note\u$NoteLengths[$_]"/>!,
        0..$#NoteLengths;
    my $notetools = join "",
        map qq!<toolitem action="Note\u$NoteLengths[$_]"/>!,
        0..$#NoteLengths;
    $ui->add_ui_from_string(<<XML);
        <menubar>
            <menu action="NoteMenu">
                $notemenu
            </menu>
        </menubar>
        <toolbar>
            <separator/>
            $notetools
        </toolbar>
XML
    $ui->insert_action_group($self->actions, 0);
    $ui;
}

sub _insert_note {
    my ($self, $note) = @_;
    my $length = $self->actions->get_action("NoteCrotchet")
        ->get_current_value;
    $self->app->document->push_music(
        App::Jacana::Music::Note->new(
            note    => lc($note),
            octave  => 1,
            length  => $length,
        ));
    $self->view->refresh;
}

sub _backspace :Action(Backspace) {
    my ($self) = @_;
    $self->app->document->pop_music;
    $self->view->refresh;
}

sub _play_music :Action(MidiPlay) {
    my ($self, $action) = @_;
    my $app     = $self->app;
    my $view    = $self->view;

    $self->set_status("playing");
    $action->set_sensitive(0);

    $app->midi->play_music(
        $app->document->music,
        $view->weak_method("playing_on"),
        $view->weak_method("playing_off"),
        $self->weak_closure(sub {
            $_[0] and $_[0]->set_status("");
            $action->set_sensitive(1);
        }),
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
