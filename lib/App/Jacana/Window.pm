package App::Jacana::Window;

use utf8;
use 5.012;
use warnings;

use Moo;
use MooX::MethodAttributes
    use     => [qw/MooX::Gtk2/];

use App::Jacana::Gtk2::RadioGroup;
use App::Jacana::View;

use Encode ();
use YAML::XS ();

with qw/
    MooX::Gtk2
    App::Jacana::HasApp
    App::Jacana::HasActions
/;

has doc         => is => "ro";
has view        => is => "lazy";

# we own the canonical copy of the actions
has "+actions"  => is => "lazy", required => 0;

has frame       => is => "lazy";
has status_bar  => is => "lazy";
has status_mode => is => "lazy";

has uimgr       => is => "lazy";

# view

sub _build_view {
    my ($self) = @_;
    App::Jacana::View->new(
        copy_from   => $self,
        window      => $self,
        doc         => $self->doc,
    );
}

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

    my $scr = Gtk2::ScrolledWindow->new;
    $scr->set_policy("automatic", "automatic");
    $scr->add_with_viewport($self->view->widget);
    $vb->pack_start($scr, 1, 1, 0);

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

sub _build_actions {
    my ($self) = @_;
    my $actions = YAML::XS::Load Encode::encode "utf8", <<'YAML';
        FileMenu:
            label:      File
        ToLily:
            label:      Show Lilypond source
            icon_name:  icon-lily
        Quit:
            label:      Quit

        EditMenu:
            label:      Edit
        InsertMode:
            label:      Insert mode
        EditMode:
            label:      Edit mode

        StaffMenu:
            label:      Staff
        ClefMenu:
            label:      Clef
        ClefTreble:
            label:      Treble clef
            icon_name:  icon-treble
        ClefSoprano:
            label:      Soprano clef
            icon_name:  icon-soprano
        ClefAlto:
            label:      Alto clef
            icon_name:  icon-alto
        ClefTenor:
            label:      Tenor clef
            icon_name:  icon-tenor
        ClefBass:
            label:      Bass clef
            icon_name:  icon-bass
        KeySig:
            label:      Key signature…

        NoteMenu:
            label:      Note
        NotePitchMenu:
            label:      Pitch
        PitchA:
            label:      A
        PitchB:
            label:      B
        PitchC:
            label:      C
        PitchD:
            label:      D
        PitchE:
            label:      E
        PitchF:
            label:      F
        PitchG:
            label:      G
        Rest:
            label:      Rest
            icon_name:  icon-rest-1
        
        NoteLengthMenu:
            label:      Length
        AddDot:
            label:      Add dot
            icon_name:  icon-dot
        NoteAccidentalMenu:
            label:      Accidental
        Sharpen:
            label:      Sharpen
        Flatten:
            label:      Flatten

        Left:
        Right:
        Home:
        End:

        Backspace:
            label:      Backspace

        OctaveUp:
            label:      Octave up
        OctaveDown:
            label:      Octave down

        MidiMenu:
            label:      MIDI
        MidiPlay:
            label:      Play
            icon_name:  icon-play
        MidiPlayHere:
            label:      Play from cursor
            icon_name:  icon-play-here
        MidiStop:
            label:      Stop
            icon_name:  icon-stop

        ViewMenu:
            label:      View
        ZoomIn:
            label:      Zoom in
        ZoomOut:
            label:      Zoom out
        ZoomOff:
            label:      Reset zoom
YAML
    
    my $grp = Gtk2::ActionGroup->new("edit");
    for my $nm (keys %$actions) {
        my $def = $$actions{$nm};
        my $act = Gtk2::Action->new(
            name        => $nm,
            label       => $$def{label},
        );
        $$def{icon_name} and $act->set_icon_name($$def{icon_name});
        $$def{stock_id} and $act->set_stock_id($$def{stock_id});
        $grp->add_action_with_accel($act, "");
    }

    my $radios = YAML::XS::Load <<'YAML';
    NoteLength:
        Breve:
            label:      Breve
            value:      0
        Semibreve:
            label:      Semibreve
            icon_name:  icon-note-1
            value:      1
        Minim:
            label:      Minim
            icon_name:  icon-note-2
            value:      2
        Crotchet:
            label:      Crotchet
            icon_name:  icon-note-3
            value:      3
        Quaver:
            label:      Quaver
            icon_name:  icon-note-4
            value:      4
        Semiquaver:
            label:      Semiquaver
            icon_name:  icon-note-5
            value:      5
        DSquaver:
            label:      D.s.quaver
            value:      6
        HDSquaver:
           label:       H.d.s.quaver
           value:       7
        QHDSquaver:
            label:      Q.h.d.s.quaver
            value:      8

    NoteChroma:
        Natural:
            label:      Natural
            icon_name:  icon-natural
            value:      0
        Sharp:
            label:      Sharp
            icon_name:  icon-sharp
            value:      1
        Flat:
            label:      Flat
            icon_name:  icon-flat
            value:      -1
        DoubleSharp:
            label:      Double sharp
            icon_name:  icon-dsharp
            value:      2
        DoubleFlat:
            label:      Double flat
            icon_name:  icon-dflat
            value:      -2
YAML

    for my $gnm (keys %$radios) {
        my $gact = App::Jacana::Gtk2::RadioGroup->new(
            name => $gnm,
        );
        $grp->add_action_with_accel($gact, "");
        for my $nm (keys %{$$radios{$gnm}}) {
            my $def = $$radios{$gnm}{$nm};
            my $act = App::Jacana::Gtk2::RadioMember->new(
                name        => $nm,
                label       => $$def{label},
                value       => $$def{value},
            );
            $gact->add_member($act);
            $$def{icon_name} and $act->set_icon_name($$def{icon_name});
            $grp->add_action_with_accel($act, "");
        }
    }

    $grp;
}

sub _build_uimgr {
    my ($self) = @_;
    my $ui = Gtk2::UIManager->new;

    $ui->add_ui_from_string(<<XML);
        <menubar>
            <menu action="FileMenu">
                <menuitem action="ToLily"/>
                <menuitem action="Quit"/>
            </menu>
            <menu action="EditMenu">
                <menuitem action="InsertMode"/>
                <menuitem action="EditMode"/>
            </menu>
            <menu action="StaffMenu">
                <menu action="ClefMenu">
                    <menuitem action="ClefTreble"/>
                    <menuitem action="ClefBass"/>
                    <menuitem action="ClefTenor"/>
                    <menuitem action="ClefAlto"/>
                    <separator/>
                    <menuitem action="ClefSoprano"/>
                </menu>
                <menuitem action="KeySig"/>
            </menu>
            <menu action="NoteMenu">
                <menu action="NotePitchMenu">
                    <menuitem action="PitchC"/>
                    <menuitem action="PitchD"/>
                    <menuitem action="PitchE"/>
                    <menuitem action="PitchF"/>
                    <menuitem action="PitchG"/>
                    <menuitem action="PitchA"/>
                    <menuitem action="PitchB"/>
                    <separator/>
                    <menuitem action="OctaveUp"/>
                    <menuitem action="OctaveDown"/>
                    <separator/>
                    <menuitem action="Natural"/>
                    <menuitem action="Sharp"/>
                    <menuitem action="Flat"/>
                    <menuitem action="DoubleSharp"/>
                    <menuitem action="DoubleFlat"/>
                    <separator/>
                    <menuitem action="Sharpen"/>
                    <menuitem action="Flatten"/>
                </menu>
                <menu action="NoteLengthMenu">
                    <menuitem action="Breve"/>
                    <menuitem action="Semibreve"/>
                    <menuitem action="Minim"/>
                    <menuitem action="Crotchet"/>
                    <menuitem action="Quaver"/>
                    <menuitem action="Semiquaver"/>
                    <menuitem action="DSquaver"/>
                    <menuitem action="HDSquaver"/>
                    <menuitem action="QHDSquaver"/>
                    <separator/>
                    <menuitem action="AddDot"/>
                </menu>
                <menuitem action="Rest"/>
            </menu>
            <menu action="MidiMenu">
                <menuitem action="MidiPlay"/>
                <menuitem action="MidiPlayHere"/>
                <menuitem action="MidiStop"/>
            </menu>
            <menu action="ViewMenu">
                <menuitem action="ZoomIn"/>
                <menuitem action="ZoomOut"/>
                <menuitem action="ZoomOff"/>
            </menu>
        </menubar>
        <toolbar>
            <toolitem action="Semibreve"/>
            <toolitem action="Minim"/>
            <toolitem action="Crotchet"/>
            <toolitem action="Quaver"/>
            <toolitem action="Semiquaver"/>
            <toolitem action="Rest"/>
            <toolitem action="AddDot"/>
            <separator/>
            <toolitem action="Sharp"/>
            <toolitem action="Flat"/>
            <toolitem action="Natural"/>
            <separator/>
            <toolitem action="ClefTreble"/>
            <toolitem action="ClefAlto"/>
            <toolitem action="ClefTenor"/>
            <toolitem action="ClefBass"/>
            <separator/>
            <toolitem action="MidiPlay"/>
            <toolitem action="MidiPlayHere"/>
            <toolitem action="MidiStop"/>
            <toolitem action="ToLily"/>
        </toolbar>

        <accelerator action="Backspace"/>
        <accelerator action="Left"/>
        <accelerator action="Right"/>
        <accelerator action="Home"/>
        <accelerator action="End"/>
XML

    $ui->insert_action_group($self->actions, 0);
    $ui;
}

# status bar

sub _build_status_mode { Gtk2::Label->new("insert") }

sub _build_status_bar { 
    my ($self) = @_;
    my $b = Gtk2::Statusbar->new;

    my $l = $self->status_mode;
    my $r = $l->size_request;
    $l->set_size_request($r->width + 4, -1);
    my $f = Gtk2::Frame->new;
    $f->add($l);
    $f->set_shadow_type("in");
    my $m = $b->get_message_area;
    $m->pack_start($f, 0, 0, 0);
    $m->reorder_child($f, 0);

    my $id = $b->push(0, "loading…");
    Glib::Idle->add(sub { $b->remove(0, $id) });
    $b;
}

sub set_status {
    my ($self, $msg) = @_;
    my $b = $self->status_bar;
    $b->pop(0);
    $b->push(0, $msg);
}

sub status_flash {
    my ($self, $msg) = @_;
    my $b = $self->status_bar;
    my $id = $b->push(1, $msg);
    Glib::Timeout->add(5000, sub { $b->remove(1, $id) });
}

sub silly {
    my ($self) = @_;
    $self->status_flash("Don't be *silly*.");
    return;
}

sub set_busy {
    my ($self, $msg) = @_;
    my $a = $self->app;
    my $b = $self->status_bar;
    my $id = $b->push(2, $msg);
    Glib::Idle->add(sub { $b->remove(2, $id) }, undef,
        # This is what ->busy uses
        Glib::G_PRIORITY_DEFAULT_IDLE - 10);
    $a->busy;
    $a->yield;
}

# show

sub show {
    my ($self) = @_;
    $self->frame->show_all;
}

1;
