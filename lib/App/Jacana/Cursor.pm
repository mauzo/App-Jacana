package App::Jacana::Cursor;

use utf8;

use Moo;
use MooX::MethodAttributes use => ["MooX::Gtk2"];
use Class::Method::Modifiers qw/:all/;

use App::Jacana::Util::Types;

use Try::Tiny;

use namespace::clean;

with qw/ 
    MooX::Gtk2 
    App::Jacana::Has::Length
/;

my @Mutable = qw/is rw lazy 1 builder 1 clearer 1 trigger 1/;

has view        => is => "ro", weak_ref => 1;
has movement    => @Mutable, isa => InstanceOf[My "Document::Movement"];
has voice       => @Mutable, isa => Music "Voice";
has position    => @Mutable, isa => Music;

has mode        => (
    is          => "rw",
    isa         => Enum[qw/insert edit/],
    default     => "insert",
    gtk_prop    => "view.status_mode.label",
    trigger     => 1,
);

has midi_chan   => is => "lazy";

has "+length"   => (
    # default doesn't fire the trigger, set it in BUILD instead
    #default     => 3,
    gtk_prop    => "view.get_action(NoteLength).current-value",
    trigger     => 1,
);

sub _build_movement     { $_[0]->view->doc->next_movement }
sub _build_voice        { $_[0]->movement->next_voice }
sub _build_position     { $_[0]->voice }

sub _trigger_movement   { $_[0]->clear_voice; $_[0]->clear_position }

sub _trigger_voice      { 
    my ($self, $new) = @_;

    my $time = $self->position->get_time;
    $self->position($new->find_time($time));
    $self->set_midi_program;
}

sub _trigger_position {
    my ($self, $note) = @_;

    my $view = $self->view or return;

    $self->mode eq "edit" and $note->is_music_start
        and return $self->position($note->next);

    my %isa     = map +($_, $note->isa("App::Jacana::Music::$_")),
        qw/ Note Note::Grace /;
    my %does    = map +($_, $note->DOES("App::Jacana::Has::$_")),
        qw/Pitch Length Key Dialog/;
    my %act     = map +($_, $view->get_action($_)), qw/
        AddDot NoteChroma Sharpen Flatten OctaveUp OctaveDown
        Tie Grace Properties
    /;

    $act{AddDot}->set_sensitive($does{Length});
    if ($isa{Note}) {
        $act{$_}->set_sensitive(1) for qw/Tie Grace/;
        $act{Tie}->set_active($note->tie);
        $act{Grace}->set_active($isa{"Note::Grace"});
    }
    else {
        for (qw/Tie Grace/) {
            $act{$_}->set_sensitive(0);
            $act{$_}->set_active(0);
        }
    }
    if ($does{Pitch}) {
        $act{NoteChroma}->set_current_value($note->chroma);
        $act{NoteChroma}->set_sensitive(1);
    }
    else {
        $act{NoteChroma}->set_sensitive(0);
    }
    $_->set_sensitive($does{Pitch} || $does{Key}) 
        for @act{qw/Sharpen Flatten/};
    $_->set_sensitive($does{Pitch})
        for @act{qw/OctaveUp OctaveDown/};
    $act{Properties}->set_sensitive($does{Dialog});

    $self->copy_from($note, "App::Jacana::Has::Length");

    $view->scroll_to_cursor;
    $view->redraw;
}

sub _build_midi_chan {
    my ($self) = @_;
    $self->view->midi->alloc_chan;
}

sub set_midi_program {
    my ($self) = @_;

    my $view    = $self->view;
    my $midi    = $view->midi;
    my $prg     = $self->voice->midi_prg;

    $midi->set_program($self->midi_chan, $prg);
    $view->get_action("StaffMidiVoice")->set_current_value($prg);
}

sub BUILD {
    my ($self) = @_;
    $self->length(3);
    $self->position($self->position);
    $self->set_midi_program;
    $self->view->refresh;
}

sub DEMOLISH {
    my ($self) = @_;
    $self->view->midi->free_chan($self->midi_chan);
}

sub _trigger_mode { 
    my ($self, $mode) = @_;
    for (qw/ Rest KeySig TimeSig Barline /) {
        $self->view->get_action($_)
            ->set_sensitive($mode eq "insert");
    }
    my $pos = $self->position;
    $self->position($pos);
}
sub insert_mode :Action(view.InsertMode)   { $_[0]->mode("insert") }
sub edit_mode :Action(view.EditMode)       { $_[0]->mode("edit") }

sub _trigger_length {
    my ($self, $new) = @_;
    my $view = $self->view;
    $self->view->get_action("Rest")->set_icon_name("icon-rest-$new");
}

sub _reset_length :Action(view.NoteLength) {
    my ($self) = @_;
    $self->dots(0);
    $self->position->copy_from($self, "App::Jacana::Has::Length");
    $self->view->refresh;
}

sub _reset_chroma :Action(view.NoteChroma) {
    my ($self, $action) = @_;
    $self->position->chroma($action->get_current_value);
    $self->_play_note;
    $self->view->refresh;
}

sub _change_octave {
    my ($self, $by) = @_;
    my $pos = $self->position;
    $pos->DOES("App::Jacana::Has::Pitch") or return;
    $pos->octave($pos->octave + $by);
    $self->_play_note;
    $self->view->refresh;
}

sub _octave_up   :Action(view.OctaveUp)   { $_[0]->_change_octave(+1) }
sub _octave_down :Action(view.OctaveDown) { $_[0]->_change_octave(-1) }

sub move_left :Action(view.Left) {
    my ($self) = @_;
    my $pos = $self->position->prev or return;
    $self->position($pos);
}

sub move_right :Action(view.Right)  {
    my ($self) = @_;
    my $pos = $self->position->next or return;
    $self->position($pos);
}

sub move_to_end :Action(view.End) {
    my ($self) = @_;
    $self->position($self->voice->prev_music);
}

sub move_to_start :Action(view.Home) {
    my ($self) = @_;
    $self->position($self->voice);
}

sub goto_position :Action(view.GotoPosition) {
    my ($self) = @_;

    my $dlg = $self->view->run_dialog(
        "Simple", undef,
        title   => "Goto…",
        label   => "Goto position (qhdsq):",
        value   => $self->position->get_time,
    );
    my ($pos) = $self->voice->find_time($dlg->value);
    warn "GOTO POSITION [$pos]";
    $self->position($pos);
}

sub np_mvmt {
    my ($self, $dir) = @_;
    my $m = $self->movement->$dir;
    $m->is_movement_start and $m = $m->$dir;
    $self->movement($m);
    my $vw = $self->view;
    $vw->refresh;
    $vw->scroll_to_cursor;
    $vw->reset_title;
}

sub prev_mvmt :Action(view.PreviousMovement) 
    { $_[0]->np_mvmt("prev_movement") }
sub next_mvmt :Action(view.NextMovement) 
    { $_[0]->np_mvmt("next_movement") }

sub name_mvmt :Action(view.NameMovement) {
    my ($self) = @_;
    my $m   = $self->movement;
    my $dlg = $self->view->run_dialog(
        "Simple", undef,
        title   => "Name movement",
        label   => "Name",
        value   => $m->name,
    ) or return;
    $m->name($dlg->value);
    $self->view->reset_title;
}

sub insert_mvmt :Action(view.InsertMovement) {
    my ($self) = @_;
    
    my $m = App::Jacana::Document::Movement->new(name => "");
    my $v = $self->movement->next_voice;
    while (1) {
        warn "OLD VOICE [$v]";
        my $n = App::Jacana::Music::Voice->new(name => $v->name);
        my $c = $v->find_next_with("Clef");
        $n->insert(App::Jacana::Music::Clef->new(clef => $c->clef));
        $m->prev_voice->insert_voice($n);
        $v->is_voice_end and last;
        $v = $v->next_voice;
    }

    $self->movement->insert_movement($m);
    $self->movement($m);
    $self->name_mvmt;

    $self->view->refresh;
}

sub delete_movement :Action(view.DeleteMovement) {
    my ($self) = @_;

    my $m = $self->movement->remove_movement;
    $m->is_movement_start and $m = $m->next_movement;
    $m->is_movement_start and $m = $m->insert_movement(
        App::Jacana::Music::Movement->new(name => ""));
    
    $self->movement($m);
    my $v = $self->view;
    $v->stop_playing;
    $v->refresh;
    $v->scroll_to_cursor;
    $v->reset_title;
}

sub up_down_staff {
    my ($self, $dir) = @_;
    my $v = $self->voice->$dir;
    $v->is_voice_start and $v = $v->$dir;
    $self->voice($v);
    $self->view->scroll_to_cursor;
}

sub up_staff :Action(view.Up) { $_[0]->up_down_staff("prev_voice") }
sub down_staff :Action(view.Down) { $_[0]->up_down_staff("next_voice") }

sub insert_staff :Action(view.InsertStaff) {
    my ($self) = @_;
    
    my $v = App::Jacana::Music::Voice->new(name => "voice");
    $self->voice($self->voice->insert_voice($v));
    $self->view->scroll_to_cursor;
    $self->view->refresh;
}

sub delete_staff :Action(view.DeleteStaff) {
    my ($self) = @_;

    my $v = $self->voice->remove_voice;
    $v->is_voice_start and $v = $v->next_voice;
    $v->is_voice_start and $v = $v->insert_voice(
        App::Jacana::Music::Voice->new(name => "voice"));
    
    $self->voice($v);
    $self->view->stop_playing;
    $self->view->refresh;
    $self->view->scroll_to_cursor;
}

sub move_staff :Action(view.MoveStaff) {
    my ($self) = @_;
    my $v = $self->voice;

    $self->view->refresh;
}

sub mute_staff :Action(view.MuteStaff) {
    my ($self) = @_;
    my $v = $self->voice;
    $v->muted(!$v->muted);
}

sub staff_midi :Action(view.StaffMidiVoice) {
    my ($self, $action) = @_;

    $self->voice->midi_prg($action->get_current_value);
    $self->set_midi_program;
}

sub name_staff :Action(view.NameStaff) {
    my ($self) = @_;

    my $voice   = $self->voice;
    my $dlg     = $self->view->run_dialog(
        "Simple", undef,
        title   => "Name staff",
        label   => "Name:",
        value   => $voice->name,
    ) or return;
    $voice->name($dlg->value);
}

sub _play_note {
    my ($self) = @_;
    my $pos = $self->position;
    $pos->DOES("App::Jacana::Has::Pitch") or return;
    $self->view->midi->play_note($self->midi_chan, $pos->pitch, 8);
}

sub _adjust_chroma {
    my ($self, $by) = @_;

    my $pos     = $self->position;
    my $view    = $self->view;

    if ($pos->isa("App::Jacana::Music::KeySig")) {
        try     { $pos->key($pos->key + $by) }
        catch   { $view->silly };
        $view->refresh;
        return;
    }

    $pos->DOES("App::Jacana::Has::Pitch") or return;
    my $new = $pos->chroma + $by;
    abs($new) > 2 and return $view->silly;
    $pos->chroma($new);
    $self->_play_note;
    $self->position($pos);
    $self->view->refresh;
}

sub sharpen :Action(view.Sharpen) { $_[0]->_adjust_chroma(+1) }
sub flatten :Action(view.Flatten) { $_[0]->_adjust_chroma(-1) }

method_attrs change_pitch => map "Action(view.Pitch$_)", "A".."G";

sub change_pitch {
    my ($self, $action) = @_;

    my $pos = $self->position;
    my $Dp  = $pos->DOES("App::Jacana::Has::Pitch");
    my $Ik  = $pos->isa("App::Jacana::Music::KeySig");

    $Dp || $Ik || $self->mode eq "insert" or return;

    my ($note) = $action->get_name =~ /^Pitch([A-Z])$/ or return;
    $note = lc $note;

    if ($Ik && $self->mode eq "edit") {
        $pos->set_from_note($note);
        $self->view->refresh;
        return;
    }

    # find the pitch we want
    my $ref     = $Dp ? $pos 
        : $pos->ambient->find_role("Clef")->centre_pitch;
    my $pitch   = $ref->nearest($note);

    # changing note always resets chroma
    my $key     = $pos->ambient->find_role("Key");
    $pitch->chroma($key->chroma($note));

    if ($self->mode eq "insert") {
        my $new = App::Jacana::Music::Note->new(copy_from => $self);
        $pos->insert($new);
        $pos = $new;
    }
    $pos->copy_from($pitch);
    $self->position($pos);
    $self->_play_note;
    $self->view->refresh;
}

sub _add_dot :Action(view.AddDot) {
    my ($self) = @_;

    my $note = $self->position;
    $note->DOES("App::Jacana::Has::Length") or return;

    my $view = $self->view;

    my $dots = $note->dots + 1;
    $dots > 6 and return $view->silly;
    $note->dots($dots);

    $note->duration != int($note->duration) and
        $view->status_flash("Divisions this small will not play correctly.");
    $view->refresh;
}

sub _toggle_tie :Action(view.Tie) {
    my ($self, $act) = @_;

    my $note = $self->position;
    $note->isa("App::Jacana::Music::Note") or return;
    $note->tie($act->get_active);
    $self->view->refresh;
}

sub _toggle_grace :Action(view.Grace) {
    my ($self, $act) = @_;
    
    my $note = $self->position;

    if ($act->get_active) {
        $note->isa("App::Jacana::Music::Note") or return;
        bless $note, "App::Jacana::Music::Note::Grace"; # XXX
    }
    else {
        $note->isa("App::Jacana::Music::Note::Grace") or return;
        bless $note, "App::Jacana::Music::Note"; # XXX
    }

    $self->view->refresh;
}

sub _insert_rest :Action(view.Rest) {
    my ($self) = @_;
    $self->mode eq "insert" or return;
    $self->position($self->position->insert(
        App::Jacana::Music::Rest->new(copy_from => $self)));
    $self->view->refresh;
}

sub _insert_multirest :Action(view.MultiRest) {
    my ($self) = @_;
    $self->mode eq "insert" or return;
    my $pos = $self->position;
    if ($pos->isa("App::Jacana::Music::MultiRest")) {
        $pos->bars($pos->bars + 1);
    }
    else {
        $self->position($pos->insert(
            App::Jacana::Music::MultiRest->new(bars => 1)));
    }
    $self->view->refresh;
}

sub _do_marks {
    my ($self, $type, @args) = @_;
    my $pos = $self->position;
    $pos->DOES("App::Jacana::Has::Marks") or return;
    $pos->delete_marks($type);
    @args and $pos->add_mark($type, @args);
    $self->view->refresh;
}

sub _clear_artic :Action(view.ClearArticulation) {
    $_[0]->_do_marks("Articulation");
}

for my $t (qw/
    staccato accent tenuto marcato staccatissimo
    trill turn prall mordent
    fermata segno coda
/) {
    my $m = "_add_$t";
    fresh $m, sub { 
        $_[0]->_do_marks(Articulation => articulation => $t);
    };
    method_attrs $m, "Action(view.\u$t)";
}

sub _slur_start :Action(view.SlurStart) {
    $_[0]->_do_marks(Slur => is_start => 1);
}

sub _slur_end :Action(view.SlurEnd) {
    $_[0]->_do_marks(Slur => is_start => 0);
}

sub _slur_clear :Action(view.ClearSlur) {
    $_[0]->_do_marks("Slur");
}

sub _dynamic_clear :Action(view.ClearDynamic) {
    $_[0]->_do_marks("Dynamic");
}

for my $d (qw/ pp p mp mf f ff fp sf sfz /) {
    my $m = "_dynamic_$d";
    fresh $m, sub {
        $_[0]->_do_marks(Dynamic => dynamic => $d);
    };
    method_attrs $m, "Action(view.Dynamic\U$d)";
}

sub _backspace :Action(view.Backspace) {
    my ($self) = @_;
    $self->position($self->position->remove);
    $self->view->refresh;
}

sub _do_clef {
    my ($self, $type) = @_;
    my $pos = $self->position;
    if ($self->mode eq "insert") {
        $self->position($pos->insert(
            App::Jacana::Music::Clef->new(clef => $type)));
        $pos->ambient->owner->clear_ambient;
    }
    else {
        $pos->isa("App::Jacana::Music::Clef") or return;
        $pos->clef($type);
    }
    $self->view->refresh;
}

for my $c (qw/Treble Alto Tenor Bass Soprano/) {
    my $m = "_clef_\L$c";
    fresh $m, sub { $_[0]->_do_clef(lc $c) };
    method_attrs $m, "Action(view.Clef$c)";
}

sub _insert_with_dialog {
    my ($self, $type, @args) = @_;
    $self->mode eq "insert" or return;

    my $class = "App::Jacana::Music::$type";
    $class->DOES("App::Jacana::Has::Dialog") or die "$class has no dialog";
    my $dlg = $self->view->run_dialog($class->dialog, $class, @args)
        or return;

    my $pos = $self->position;
    $class->DOES("App::Jacana::Music::HasAmbient")
        and $pos->ambient->owner->clear_ambient;
    $self->position($pos->insert($class->new(copy_from => $dlg)));
    $self->view->refresh;
}

for my $t (qw/ Barline KeySig RehearsalMark Text::Mark TimeSig /) {
    my $a = $t =~ s/:://gr;
    my $m = "_insert_\L$a";
    fresh $m, sub { $_[0]->_insert_with_dialog($t) };
    method_attrs $m, "Action(view.$a)";
}

sub _properties :Action(view.Properties) {
    my ($self) = @_;

    my $pos = $self->position;
    $pos->DOES("App::Jacana::Has::Dialog") or return;

    $pos->run_dialog($self->view);
    $self->view->refresh;
}

1;
