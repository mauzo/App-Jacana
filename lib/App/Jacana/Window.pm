package App::Jacana::Window;

use utf8;
use 5.012;
use warnings;

use Moo;
use MooX::MethodAttributes
    use     => [qw/MooX::Gtk2/];

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
    for my $tb ($ui->get_toplevels("toolbar")) {
        $tb->set_style("icons");
        $tb->set_icon_size("small-toolbar");
        $vb->pack_start($tb, 0, 0, 0);
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
    breve semibreve minim crotchet quaver semiquaver d.s.quaver
    h.d.s.quaver q.h.d.s.quaver
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

        Left:
            accelerator:    h
        Right:
            accelerator:    l
        Home:
            accelerator:    asciicircum
        End:
            accelerator:    dollar

        OctaveUp:
            label:          Octave up
            accelerator:    apostrophe
        OctaveDown:
            label:          Octave down
            accelerator:    comma
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

    # Build the RadioActions by hand, because the GtkPerl implementation
    # of ActionGroup->add_radio_actions doesn't set icon_name properly.
    my $radio;
    for (0..8) {
        my $l = $NoteLengths[$_];
        my $act = Gtk2::RadioAction->new(
            name    => "Note\u$l",
            label   => "\u$l",
            value   => ($_ ? (1<<($_-1)) : 0),
        );
        $act->set_icon_name("icon-note-$_");
        if ($radio) { $act->set_group($radio) }
        else        { $radio = $act }
        $grp->add_action_with_accel($act, 
            $_ > 0 && $_ < 6 ? $_ : "");
    }
    $radio->set_current_value(4);

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
            <menu action="NoteMenu">
                <menuitem action="OctaveUp"/>
                <menuitem action="OctaveDown"/>
            </menu>
            <menu action="MidiMenu">
                <menuitem action="MidiPlay"/>
            </menu>
        </menubar>
        <toolbar>
            <toolitem action="MidiPlay"/>
        </toolbar>

        <accelerator action="Backspace"/>
        <accelerator action="Left"/>
        <accelerator action="Right"/>
        <accelerator action="Home"/>
        <accelerator action="End"/>
XML
    my $notemenu = join "",
        map qq!<menuitem action="Insert$_"/>!,
        "A".."G";
    $notemenu .= "<separator/>";
    $notemenu .= join "",
        map qq!<menuitem action="Note\u$NoteLengths[$_]"/>!,
        0..8;
    my $notetools = join "",
        map qq!<toolitem action="Note\u$NoteLengths[$_]"/>!,
        1..5;
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

sub _move_left :Action(Left)    { $_[0]->view->cursor->move_left  }
sub _move_right :Action(Right)  { $_[0]->view->cursor->move_right }

sub _move_to_end :Action(End) {
    my ($self) = @_;
    my $view = $self->view;
    $view->cursor->position($view->doc->music->prev);
}

sub _move_to_start :Action(Home) {
    my ($self) = @_;
    my $view = $self->view;
    $view->cursor->position($view->doc->music);
}

sub _octave_up :Action(OctaveUp) {
    my ($self) = @_;
    $self->view->cursor->octave_up;
}

sub _octave_down :Action(OctaveDown) {
    my ($self) = @_;
    $self->view->cursor->octave_down;
}

sub _insert_note {
    my ($self, $note) = @_;

    my $cursor = $self->view->cursor;
    $note = lc $note;
    my $octave = $cursor->nearest($note);
    my $length = $self->actions->get_action("NoteCrotchet")
        ->get_current_value;

    my $new = App::Jacana::Music::Note->new(
        note    => $note,
        octave  => $octave,
        length  => $length,
    );
    $cursor->position($cursor->position->insert($new));
    $self->app->midi->play_note($new->pitch, 8);
}

sub _backspace :Action(Backspace) {
    my ($self) = @_;
    no warnings "uninitialized";
    my $cursor  = $self->view->cursor;
    $cursor->position($cursor->position->remove);
}

sub _play_music :Action(MidiPlay) {
    my ($self, $action) = @_;
    my $app     = $self->app;
    my $view    = $self->view;

    $self->set_status("Initialising MIDI…");
    $action->set_sensitive(0);
    $app->yield;
    my $midi = $app->midi;

    $self->set_status("Playing");
    $midi->play_music(
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
