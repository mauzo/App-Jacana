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
    App::Jacana::Has::App
    App::Jacana::Has::Actions
/;

has doc         => is => "ro";
has view        => is => "lazy";

# we own the canonical copy of the actions
has "+actions"  => lazy => 1, builder => 1, required => 0;

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

    $vb->pack_start($self->view->scrolled, 1, 1, 0);

    $vb->pack_start($self->status_bar, 0, 0, 0);

    $w->add($vb);
    $w;
}

sub _quit :Action(Quit) { 
    my ($self) = @_;
    $self->frame->destroy;
}

sub _destroy :Signal(frame.destroy) {
    my ($self) = @_;
    Gtk2->main_quit;
}

# actions

sub _build_actions {
    my ($self) = @_;
    my $actions = YAML::XS::Load Encode::encode "utf8", <<'YAML';
        FileMenu:
            label:      File
        Open:
            label:      Open…
            stock_id:   gtk-open
        Save:
            stock_id:   gtk-save
        SaveAs:
            label:      Save As…
            stock_id:   gtk-save-as
        ToLily:
            label:      Show Lilypond source
            icon_name:  icon-lily
        Quit:

        EditMenu:
            label:      Edit
        InsertMode:
        EditMode:
        GotoPosition:
            label:      Goto position…
        RegionMenu:
            label:      Region
        SetMark:
        ClearMark:
        GotoMark:
        RegionOctaveUp:
            label:      Octave up
        RegionOctaveDown:
            label:      Octave down
        RegionTranspose:
            label:      Transpose…
        Properties:
            label:      Properties…
            stock_id:   gtk-properties

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
            icon_name:  icon-keysig
        TimeSig:
            label:      Time signature…
            icon_name:  icon-timesig
        Barline:
            label:      Barline…
            icon_name:  icon-barline
        InsertStaff:
        NameStaff:
            label:      Name staff…
        RehearsalMark:
            label:  Rehearsal mark…
        TextMark:
            label:  Text mark…


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
            icon_name:  icon-rest-1
        
        NoteLengthMenu:
            label:      Length
        AddDot:
            icon_name:  icon-dot
        Tie:
            icon_name:  icon-tie
            toggle:     1

        NoteAccidentalMenu:
            label:      Accidental
        Sharpen:
        Flatten:

        MarksMenu:
            label:  Marks

        MarksArticMenu:
            label:      Articulation
        ClearArticulation:
        Staccato:
        Accent:
        Tenuto:
        Marcato:
        Staccatissimo:
        Trill:
        Turn:
        Prall:
        Mordent:
        Fermata:
        Segno:
        Coda:

        MarksSlurMenu:
            label: Slurs
        SlurStart:
        SlurEnd:
        ClearSlur:

        MarksDynamicMenu:
            label:  Dynamics
        ClearDynamic:
        DynamicPP:
            label:  Pianissimo
        DynamicP:
            label:  Piano
        DynamicMP:
            label:  Mezzo-piano
        DynamicMF:
            label:  Mezzo-forte
        DynamicF:
            label:  Forte
        DynamicFF:
            label:  Fortissimo
        DynamicFP:
            label:  Forte-piano
        DynamicSF:
            label:  Sforzato
        DynamicSFZ:
            label:  Sforzando

        Left:
        Right:
        Home:
        End:
        Up:
        Down:

        Backspace:

        OctaveUp:
        OctaveDown:

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
        MidiSpeed:
            label:      Playback speed

        ViewMenu:
            label:      View
        ZoomIn:
            stock_id:   gtk-zoom-in
        ZoomOut:
            stock_id:   gtk-zoom-out
        ZoomOff:
            label:      Reset zoom
            stock_id:   gtk-zoom-100
YAML
    
    my $grp = Gtk2::ActionGroup->new("edit");
    for my $nm (keys %$actions) {
        my $def     = $$actions{$nm};
        my $class   = delete $$def{toggle} 
            ? "Gtk2::ToggleAction" : "Gtk2::Action";
        my $label = $$def{label} // 
            $nm =~ s/([a-z])([A-Z])/$1 \L$2/gr;
        my $act     = $class->new(
            name        => $nm,
            label       => $label,
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
                <menuitem action="Open"/>
                <menuitem action="Save"/>
                <menuitem action="SaveAs"/>
                <menuitem action="ToLily"/>
                <menuitem action="Quit"/>
            </menu>
            <menu action="EditMenu">
                <menuitem action="InsertMode"/>
                <menuitem action="EditMode"/>
                <menuitem action="GotoPosition"/>
                <menu action="RegionMenu">
                    <menuitem action="SetMark"/>
                    <menuitem action="ClearMark"/>
                    <menuitem action="GotoMark"/>
                    <separator/>
                    <menuitem action="RegionOctaveUp"/>
                    <menuitem action="RegionOctaveDown"/>
                    <menuitem action="RegionTranspose"/>
                </menu>
                <separator/>
                <menuitem action="Properties"/>
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
                <menuitem action="TimeSig"/>
                <menuitem action="Barline"/>
                <separator/>
                <menuitem action="Barline"/>
                <menuitem action="RehearsalMark"/>
                <menuitem action="TextMark"/>
                <separator/>
                <menuitem action="InsertStaff"/>
                <menuitem action="NameStaff"/>
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
                    <menuitem action="Tie"/>
                </menu>
                <menuitem action="Rest"/>
            </menu>
            <menu action="MarksMenu">
                <menu action="MarksArticMenu">
                    <menuitem action="ClearArticulation"/>
                    <separator/>
                    <menuitem action="Staccato"/>
                    <menuitem action="Accent"/>
                    <menuitem action="Tenuto"/>
                    <menuitem action="Marcato"/>
                    <menuitem action="Staccatissimo"/>
                    <separator/>
                    <menuitem action="Trill"/>
                    <menuitem action="Turn"/>
                    <menuitem action="Prall"/>
                    <menuitem action="Mordent"/>
                    <separator/>
                    <menuitem action="Fermata"/>
                    <menuitem action="Segno"/>
                    <menuitem action="Coda"/>
                </menu>
                <menu action="MarksSlurMenu">
                    <menuitem action="ClearSlur"/>
                    <menuitem action="SlurStart"/>
                    <menuitem action="SlurEnd"/>
                </menu>
                <menu action="MarksDynamicMenu">
                    <menuitem action="ClearDynamic"/>
                    <separator/>
                    <menuitem action="DynamicPP"/>
                    <menuitem action="DynamicP"/>
                    <menuitem action="DynamicMP"/>
                    <menuitem action="DynamicMF"/>
                    <menuitem action="DynamicF"/>
                    <menuitem action="DynamicFF"/>
                    <separator/>
                    <menuitem action="DynamicFP"/>
                    <menuitem action="DynamicSF"/>
                    <menuitem action="DynamicSFZ"/>
                </menu>
            </menu>
            <menu action="MidiMenu">
                <menuitem action="MidiPlay"/>
                <menuitem action="MidiPlayHere"/>
                <menuitem action="MidiStop"/>
                <menuitem action="MidiSpeed"/>
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
            <toolitem action="Tie"/>
            <separator/>
            <toolitem action="Sharp"/>
            <toolitem action="Flat"/>
            <toolitem action="Natural"/>
            <separator/>
            <toolitem action="KeySig"/>
            <toolitem action="TimeSig"/>
            <toolitem action="Barline"/>
            <toolitem action="Properties"/>
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
        <accelerator action="Up"/>
        <accelerator action="Down"/>
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
    Glib::Timeout->add(4000, sub { $b->remove(1, $id) });
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
