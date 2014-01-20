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

sub _build_actions {
    my ($self) = @_;
    my $actions = YAML::XS::Load <<'YAML';
        FileMenu:
            label:          File
        Quit:
            label:          Quit

        NoteMenu:
            label:          Note
        NotePitchMenu:
            label:          Pitch
        PitchA:
            label:          A
            method:         _note_pitch
        PitchB:
            label:          B
            method:         _note_pitch
        PitchC:
            label:          C
            method:         _note_pitch
        PitchD:
            label:          D
            method:         _note_pitch
        PitchE:
            label:          E
            method:         _note_pitch
        PitchF:
            label:          F
            method:         _note_pitch
        PitchG:
            label:          G
            method:         _note_pitch
        
        NoteLengthMenu:
            label:          Length
        AddDot:
            label:          Add dot

        Left:
        Right:
        Home:
        End:

        Backspace:
            label:          Backspace

        OctaveUp:
            label:          Octave up
        OctaveDown:
            label:          Octave down

        MidiMenu:
            label:          MIDI
        MidiPlay:
            stock_id:       gtk-media-play
            label:          Play
YAML
    
    my $grp = Gtk2::ActionGroup->new("edit");
    $grp->add_actions([
        map +{ name => $_, %{$$actions{$_} || {}} },
        keys %$actions
    ]);
    for (keys %$actions) {
        my $meth = $$actions{$_}{method};
        $meth and $grp->get_action($_)->signal_connect(
            "activate", $self->weak_method($meth));
    }

    my $radios = YAML::XS::Load <<'YAML';
    -   Breve:
            label:          Breve
            value:          0
        Semibreve:
            label:          Semibreve
            icon_name:      icon-note-1
            value:          1
        Minim:
            label:          Minim
            icon_name:      icon-note-2
            value:          2
        Crotchet:
            label:          Crotchet
            icon_name:      icon-note-3
            value:          4
        Quaver:
            label:          Quaver
            icon_name:      icon-note-4
            value:          8
        Semiquaver:
            label:          Semiquaver
            icon_name:      icon-note-5
            value:          16
        DSquaver:
            label:          D.s.quaver
            value:          32
        HDSquaver:
           label:          H.d.s.quaver
           value:          64
        QHDSquaver:
            label:          Q.h.d.s.quaver
            value:          128
YAML

    # Build the RadioActions by hand, because the GtkPerl implementation
    # of ActionGroup->add_radio_actions doesn't set icon_name properly.
    for my $rgrp (@$radios) {
        my $first;
        for my $nm (keys %$rgrp) {
            my $def = $$rgrp{$nm};
            my $act = Gtk2::RadioAction->new(
                name    => $nm,
                label   => $$def{label},
                value   => $$def{value},
            );
            $$def{icon_name} and $act->set_icon_name($$def{icon_name});
            if ($first) { $act->set_group($first) }
            else        { $first = $act }
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
                <menuitem action="Quit"/>
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
            </menu>
            <menu action="MidiMenu">
                <menuitem action="MidiPlay"/>
            </menu>
        </menubar>
        <toolbar>
            <toolitem action="Semibreve"/>
            <toolitem action="Minim"/>
            <toolitem action="Crotchet"/>
            <toolitem action="Quaver"/>
            <toolitem action="Semiquaver"/>
            <separator/>
            <toolitem action="MidiPlay"/>
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

sub _note_pitch {
    my ($self, $action) = @_;

    my $note    = $action->get_name =~ s/^Pitch([A-G])$/lc $1/er
        or return;
    my $cursor  = $self->view->cursor;
    my $octave  = $cursor->nearest($note);
    my $length  = $self->actions->get_action("Crotchet")
        ->get_current_value;

    my $new = App::Jacana::Music::Note->new(
        note    => $note,
        octave  => $octave,
        length  => $length,
    );
    $cursor->position($cursor->position->insert($new));
    $self->app->midi->play_note($new->pitch, 8);
}

sub _add_dot :Action(AddDot) {
    my ($self) = @_;
    my $view = $self->view;
    my $note = $view->cursor->position;
    $note->isa("App::Jacana::Music::Note") or return;
    my $dots = $note->dots + 1;
    if ($dots > 6) {
        $self->status_flash("Don't be *silly*.");
        return;
    }
    $note->dots($dots);
    $note->duration != int($note->duration) and
        $self->status_flash("Divisions this small will not play correctly.");
    $view->refresh;
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

sub status_flash {
    my ($self, $msg) = @_;
    my $b = $self->status_bar;
    my $id = $b->push(1, $msg);
    Glib::Timeout->add(5000, sub { $b->remove(1, $id) });
}

# show

sub show {
    my ($self) = @_;
    $self->frame->show_all;
}

1;
