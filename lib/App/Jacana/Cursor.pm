package App::Jacana::Cursor;

use utf8;

use App::Jacana::Moose;
use MooseX::Gtk2;

use App::Jacana::Event::Change;
use App::Jacana::Log;
use App::Jacana::StaffCtx::Cursor;

use Try::Tiny;

use namespace::autoclean;

with qw/ 
    App::Jacana::Has::Length
/;

my @Mutable = qw/is rw lazy 1 builder 1 clearer 1 trigger 1/;

has view        => is => "ro", weak_ref => 1;
has doc         => is => "lazy", weak_ref => 1;
has movement    => @Mutable, isa => My "Document::Movement";

has _iter => (
    is      => "lazy", 
    clearer => 1,
    isa     => My "StaffCtx::Cursor",
    handles => [qw/tick voice/],
);

gtk_default_target action => "view";

has mode        => (
    is          => "rw",
    isa         => Enum[qw/insert edit/],
    default     => "insert",
    trigger     => 1,
);

has midi_chan   => (
    is          => "lazy", 
    predicate   => 1,
    traits      => ["IgnoreUndef"],
);

has "+length"   => (
    traits      => [qw/Shortcuts Gtk2/],
    # default doesn't fire the trigger, set it in BUILD instead
    #default     => 3,
    gtk_prop    => "view.get_action(NoteLength).current-value",
    trigger     => 1,
);

sub _build_doc          { $_[0]->view->doc }
sub _build_movement     { $_[0]->view->doc->next_movement }

sub _trigger_movement   { $_[0]->_clear_iter; }

sub _build__iter {
    my ($self) = @_;

    my $doc     = $self->doc;
    my $voice   = $self->movement->next_voice;

    App::Jacana::StaffCtx::Cursor->new(
        doc         => $doc,
        voice       => $voice,
        item        => $voice,
        on_change   => $self->weak_method("_change_position"),    
    );
}

sub position {
    my ($self, $note) = @_;

    @_ > 1 or return $self->_iter->item;

    Carp::carp("SET CURSOR POSITION");
    $self->_iter->item($note);
}

sub _change_position {
    my ($self, $note) = @_;

    $note //= $self->position;

    msg CURS => "change position to", $note;

    my $view = $self->view or return;
    my $edit = ($self->mode eq "edit");

    my %isa     = map +($_, Music($_)->check($note)),
        qw/ Note Note::Grace /;
    my %does    = map +($_, Has($_)->check($note)),
        qw/Pitch Length Key Dialog/;
    my %act     = map +($_, $view->get_action($_)), qw/
        AddDot NoteChroma Sharpen Flatten OctaveUp OctaveDown
        Tie Triplet Grace Properties
    /,  "PitchA".."PitchG";

    $act{AddDot}->set_sensitive($does{Length});
    if ($isa{Note}) {
        $act{$_}->set_sensitive(1) for qw/Tie Grace Triplet/;
        $act{Tie}->set_active($note->tie);
        $act{Grace}->set_active($isa{"Note::Grace"});
        $act{Triplet}->set_active($note->tuplet != 1);
    }
    else {
        for (qw/Tie Grace Triplet/) {
            $act{$_}->set_sensitive(0);
            $act{$_}->set_active(0);
        }
    }
    $_->set_sensitive($does{Pitch} || $does{Key}) 
        for @act{qw/Sharpen Flatten/};
    $_->set_sensitive(!$edit || $does{Pitch} || $does{Key})
        for @act{"PitchA".."PitchG"};
    $does{Pitch} and $act{NoteChroma}->set_current_value($note->chroma);
    $_->set_sensitive($does{Pitch}) 
        for @act{qw/ NoteChroma OctaveUp OctaveDown /};
    $act{Properties}->set_sensitive($does{Dialog});

    $self->copy_from($note, "App::Jacana::Has::Length");

    $view->scroll_to_cursor;
    $view->redraw;
}

sub _emit_doc_changed {
    my ($self, %args) = @_;

    $args{type} //= "other";
    $args{item} //= $self->position
        unless delete $args{no_item};

    my $ev = App::Jacana::Event::Change->new(\%args);
    $self->doc->signal_emit(changed => $ev);
}

sub _trigger_length {
    my ($self, $new) = @_;
    $self->view->get_action("Rest")->set_icon_name("icon-rest-$new");
}

sub _build_midi_chan {
    my ($self) = @_;
    $self->view->midi->alloc_chan;
}

sub BUILD {
    my ($self) = @_;
    $self->length(3);
    $self->_change_position;
}

sub DEMOLISH {
    my ($self) = @_;
    $self->has_midi_chan or return;
    $self->view->midi->free_chan($self->midi_chan);
}

sub _trigger_mode { 
    my ($self, $mode) = @_;
    for (qw/ Rest KeySig TimeSig Barline MIDIInstrument /) {
        $self->view->get_action($_)
            ->set_sensitive($mode eq "insert");
    }
    $self->_change_position;
    $self->view->redraw;
}
sub insert_mode :Action   { $_[0]->mode("insert") }
sub edit_mode :Action     { $_[0]->mode("edit") }

sub _note_length :Action {
    my ($self, $action) = @_;

    $self->dots(0);

    my $pos = $self->position;
    my $dur = $pos->duration;

    $self->_emit_doc_changed(
        type        => "length",
        tick        => $self->tick - $dur,
        duration    => $self->duration - $dur,
    );

    $pos->copy_from($self, "App::Jacana::Has::Length");
}

sub _action_method {
    my ($meth, @actions) = @_;

    my $cv;
    if (ref $actions[-1]) {
        $cv = pop @actions;
        Moose::Util::find_meta(__PACKAGE__)->add_method($meth, $cv);
    }
    else {
        $cv = __PACKAGE__->can($meth);
    }

    attributes->import(__PACKAGE__, $cv, map "Action($_)", @actions);
}

sub _note_chroma :Action {
    my ($self, $action) = @_;
    my $pos = $self->position;
    $pos->chroma($action->get_current_value);
    $self->_play_note;
    $self->_emit_doc_changed;
}

sub _change_octave {
    my ($self, $by) = @_;
    my $pos = $self->position;
    Has("Pitch")->check($pos)   or return;
    $pos->octave($pos->octave + $by);
    $self->_play_note;
    $self->_emit_doc_changed;
}

sub _octave_up   :Action   { $_[0]->_change_octave(+1) }
sub _octave_down :Action { $_[0]->_change_octave(-1) }

sub move_left :Action(Left) {
    my ($self) = @_;
    $self->_iter->prev;
}

sub move_right :Action(Right)  {
    my ($self) = @_;
    $self->_iter->next;
}

sub move_to_end :Action(End) {
    my ($self) = @_;
    $self->position($self->voice->prev_music);
}

sub move_to_start :Action(Home) {
    my ($self) = @_;
    $self->position($self->voice);
}

sub goto_position :Action {
    my ($self) = @_;

    my $dlg = $self->view->run_dialog(
        "Simple", undef,
        title   => "Goto…",
        label   => "Goto position (qhdsq):",
        value   => $self->position->get_time,
    ) or return;
    
    my $pos = StaffCtx("FindTime")->new(item => $self->voice)
        ->skip_time($dlg->value)
        or return;
    $self->_iter->copy_from($pos);
}

sub np_mvmt {
    my ($self, $dir) = @_;
    my $m = $self->movement->$dir;
    $m->is_movement_start and $m = $m->$dir;
    $self->movement($m);
    my $vw = $self->view;
    $vw->refresh;
    $vw->scroll_to_cursor;
}

sub previous_movement :Action 
    { $_[0]->np_mvmt("prev_movement") }
sub next_movement :Action 
    { $_[0]->np_mvmt("next_movement") }

sub name_movement :Action {
    my ($self) = @_;
    my $m   = $self->movement;
    my $dlg = $self->view->run_dialog(
        "Simple", undef,
        title   => "Name movement",
        label   => "Name",
        value   => $m->name,
    ) or return;
    $self->_emit_doc_changed(type => "movement", no_item => 1);
    $m->name($dlg->value);
}

sub insert_movement :Action {
    my ($self) = @_;
    
    my $m = My("Document::Movement")->new(name => "");
    my $v = $self->movement->next_voice;
    while (1) {
        my $n = Music("Voice")->new(name => $v->name);
        my $c = $v->find_next_with("Clef");
        $n->insert(Music("Clef")->new(clef => $c->clef));
        $m->prev_voice->insert_voice($n);
        $v->is_voice_end and last;
        $v = $v->next_voice;
    }

    $self->movement->insert_movement($m);
    $self->movement($m);
    $self->name_movement;
}

sub delete_movement :Action {
    my ($self) = @_;

    $self->_emit_doc_changed(type => "movement", no_item => 1);

    my $m = $self->movement->remove_movement;
    $m->is_movement_start and $m = $m->next_movement;
    $m->is_movement_start and $m = $m->insert_movement(
        Music("Movement")->new(name => ""));
    
    $self->movement($m);
    my $v = $self->view;
    $v->stop_playing;
    $v->scroll_to_cursor;
}

sub up_staff :Action(Up) { $_[0]->_iter->change_voice("prev")}
sub down_staff :Action(Down) { $_[0]->_iter->change_voice("next") }

sub insert_staff :Action {
    my ($self) = @_;
    
    $self->_emit_doc_changed(type => "staff", no_item => 1);
    my $v = Music("Voice")->new(name => "voice");
    $self->voice->insert_voice($v);
    $self->down_staff;
}

sub delete_staff :Action {
    my ($self) = @_;

    my $v = $self->voice;
    my $n = $v->next_voice;

    $self->_emit_doc_changed(type => "staff", no_item => 1);

    if ($v->is_voice_end) {
        $n = $n->next_voice;
        $n == $v and $n = $n->insert_voice(
            Music("Voice")->new(name => "voice"));
    }

    $self->view->stop_playing;
    $self->voice($n);
    $v->remove_voice;

    $self->view->scroll_to_cursor;
}

sub move_staff :Action {
    my ($self) = @_;

    my $v = $self->voice;
    my $n = $v->next_voice;

    $self->_emit_doc_changed(type => "staff", no_item => 1);

    $self->view->stop_playing;
    $v->remove_voice;
    $n->insert_voice($v);

    $self->view->scroll_to_cursor;
}

sub mute_staff :Action {
    my ($self) = @_;
    my $v = $self->voice;
    $v->muted(!$v->muted);
}

sub name_staff :Action {
    my ($self) = @_;

    my $voice   = $self->voice;
    my $dlg     = $self->view->run_dialog(
        "Simple", undef,
        title   => "Name staff",
        label   => "Name:",
        value   => $voice->name,
    ) or return;
    $self->_emit_doc_changed(type => "staff", no_item => 1);
    $voice->name($dlg->value);
}

sub _play_note {
    my ($self) = @_;
    
    my $pos = $self->position;
    Has("Pitch")->check($pos)   or return;

    try {
        my $chan    = $self->midi_chan;

        my $midi    = $self->view->midi;
        my $amb     = $pos->ambient;
        my $prg     = $amb->find_role("MidiInstrument");
        my $trans   = $amb->find_role("MidiTranspose");
        my $note    = $trans ? $trans->transpose($pos) : $pos;

        $midi->set_program($chan, $prg->program);
        $midi->play_note($chan, $note->pitch, 8);
    }
    catch { $self->view->status_flash($_) };
}

sub _adjust_chroma {
    my ($self, $by) = @_;

    my $pos     = $self->position;
    my $view    = $self->view;
    
    my $meth    =
        Has("Key")->check($pos)     ? "key"     :
        Has("Pitch")->check($pos)   ? "chroma"  :
        return;

    $self->_emit_doc_changed;

    try     { $pos->$meth($pos->$meth + $by); 1 }
    catch   { $view->silly; 0 }
        or return;

    $self->_play_note;
    $self->_change_position;
}

sub sharpen :Action { $_[0]->_adjust_chroma(+1) }
sub flatten :Action { $_[0]->_adjust_chroma(-1) }

sub change_pitch {
    my ($self, $action) = @_;

    my $pos     = $self->position;
    my $mode    = $self->mode;

    my ($note)  = $action->get_name =~ /^Pitch([A-Z])$/ or return;
    $note = lc $note;

    if ($mode eq "edit" && Has("Key")->check($pos)) {
        $self->_emit_doc_changed;
        $pos->set_from_note($note);
        return;
    }

    my $ref;
    if (Has("Pitch")->check($pos)) {
        $ref    = $pos;
    }
    else {
        $mode eq "insert" or return;
        $ref    = $pos->ambient->find_role("Clef")->centre_pitch;
    }

    # find the pitch we want
    my $pitch   = $ref->nearest($note);

    # changing note always resets chroma
    my $key     = $pos->ambient->find_role("Key");
    $pitch->chroma($key->chroma($note));

    if ($self->mode eq "insert") {
        my $new = Music("Note")->new(copy_from => [$self, $pitch]);
        $self->_emit_doc_changed(type => "insert",
            tick => $self->tick, duration => $new->duration);
        $self->_iter->insert($new);
    }
    else {
        $self->_emit_doc_changed;
        $pos->copy_from($pitch);
    }
    $self->_play_note;
}

BEGIN { _action_method change_pitch => map "Pitch$_", "A".."G" }

sub _add_dot :Action {
    my ($self) = @_;

    my $note = $self->position;
    Has("Length")->check($note)     or return;

    my $dur = $note->duration;
    $self->_emit_doc_changed(
        type        => "length",
        tick        => $self->tick - $dur,
        duration    => $dur,
    );

    my $dots = $note->dots + 1;
    $dots > 6 and return $self->view->silly;
    $note->dots($dots);
}

sub _toggle_tie :Action(Tie) {
    my ($self, $act) = @_;

    my $note = $self->position;
    Music("Note")->check($note)     or return;
    $self->_emit_doc_changed;
    $note->tie($act->get_active);
}

sub _triplet :Action {
    my ($self, $act) = @_;

    my $note = $self->position;
    Music("Note")->check($note)     or return;
    # XXX this is a time change but I can't account for it properly yet
    $self->_emit_doc_changed;
    my $tuplet = $note->tuplet;
    $note->tuplet($tuplet == 1 ? (2/3) : 1);
}

sub _toggle_grace :Action(Grace) {
    my ($self, $act) = @_;
    
    my $note    = $self->position;
    my $dur     = $note->duration;

    if ($act->get_active) {
        Music("Note")->check($note)     or return;
        $self->_emit_doc_changed;
        bless $note, "App::Jacana::Music::Note::Grace"; # XXX
    }
    else {
        Music("Note::Grace")->check($note)  or return;
        $self->_emit_doc_changed;
        bless $note, "App::Jacana::Music::Note"; # XXX
    }
}

sub _insert_rest :Action(Rest) {
    my ($self) = @_;
    $self->mode eq "insert" or return;
    $self->_emit_doc_changed;
    $self->_iter->insert(Music("Rest")->new(copy_from => $self));
}

sub _multi_rest :Action {
    my ($self) = @_;
    $self->mode eq "insert" or return;

    my $pos = $self->position;
    my $dur;

    if (Music("MultiRest")->check($pos)) {
        $self->_emit_doc_changed(
            type        => "length",
            tick        => $self->tick - $pos->duration,
            duration    => $pos->bar_duration,
        );
        $pos->bars($pos->bars + 1);
    }
    else {
        $self->_emit_doc_changed(
            type        => "insert",
            tick        => $self->tick - $pos->duration,
            duration    => $pos->bar_duration,
        );
        $self->_iter->insert(Music("MultiRest")->new(bars => 1));
    }
}

sub _do_marks {
    my ($self, $type, @args) = @_;
    my $pos = $self->position;
    Has("Marks")->check($pos)       or return;
    $self->_emit_doc_changed;
    @args ? $pos->add_mark($type, @args) : $pos->delete_marks($type);
}

sub _clear_articulation :Action {
    $_[0]->_do_marks("Articulation");
}

BEGIN {
    for my $t (qw/
        staccato accent tenuto marcato staccatissimo
        trill turn prall mordent
        fermata segno coda
    /) {
        _action_method "_add_$t", ucfirst $t, sub {
            $_[0]->_do_marks(Articulation => articulation => $t);
        };
    }
}

sub _slur_start :Action {
    $_[0]->_do_marks(Slur => is_start => 1);
}

sub _slur_end :Action {
    $_[0]->_do_marks(Slur => is_start => 0);
}

sub _slur_clear :Action {
    $_[0]->_do_marks("Slur");
}

sub _dynamic_clear :Action {
    $_[0]->_do_marks("Dynamic");
}

BEGIN {
    for my $d (qw/ pp p mp mf f ff fp sf sfz /) {
        _action_method "_dynamic_$d", "Dynamic\U$d", sub {
            $_[0]->_do_marks(Dynamic => dynamic => $d);
        };
    }
}

sub _backspace :Action {
    my ($self) = @_;
    $self->_iter->remove;
}

sub _do_clef {
    my ($self, $type) = @_;
    my $pos = $self->position;
    if ($self->mode eq "insert") {
        $self->_emit_doc_changed(
            type        => "insert",
            tick        => $self->tick,
            duration    => 0,
        );
        $self->_iter->insert(Music("Clef")->new(clef => $type));
        $pos->ambient->owner->clear_ambient;
    }
    else {
        Music("Clef")->check($pos)  or return;
        $self->_emit_doc_changed;
        $pos->clef($type);
    }
}

BEGIN {
    for my $c (qw/Treble Alto Tenor Bass Soprano/) {
        _action_method "_clef_\L$c", "Clef$c",
            sub { $_[0]->_do_clef(lc $c) };
    }
}

sub _insert_with_dialog {
    my ($self, $type, @args) = @_;
    $self->mode eq "insert" or return;

    my $class = Music($type)->class;
    $class->DOES("App::Jacana::Has::Dialog") or die "$class has no dialog";
    my $dlg = $self->view->run_dialog($class->dialog, $class, @args)
        or return;

    my $pos = $self->position;
    $class->DOES("App::Jacana::Music::HasAmbient")
        and $pos->ambient->owner->clear_ambient;
    my $new = $class->new(copy_from => $dlg);
    $self->_emit_doc_changed(
        type        => "insert",
        tick        => $self->tick,
        duration    => $new->duration,
    );
    $self->_iter->insert($new);
}

BEGIN {
    for my $t (qw/ 
        Barline KeySig RehearsalMark Text::Mark Tempo TimeSig 
        Lily MIDI::Instrument MIDI::Transpose
    /) {
        my $a = $t =~ s/:://gr;
        _action_method "_insert_\L$a", $a, 
            sub { $_[0]->_insert_with_dialog($t) };
    }
}

sub _properties :Action {
    my ($self) = @_;

    my $pos = $self->position;
    Has("Dialog")->check($pos)  or return;

    $self->_emit_doc_changed;
    $pos->run_dialog($self->view);
}

1;
