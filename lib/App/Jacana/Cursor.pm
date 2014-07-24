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

has staff       => is => "rw", isa => Num, default => 0;
has view        => is => "ro", weak_ref => 1;

has position    => (
    is      => "rw",
    isa     => Music,
    trigger => 1,
);
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

sub _build_midi_chan {
    my ($self) = @_;
    $self->view->midi->alloc_chan;
}

sub voice {
    my ($self) = @_;
    $self->view->doc->music->[$self->staff];
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

sub _trigger_position {
    my ($self, $note) = @_;

    my $view = $self->view or return;

    $self->mode eq "edit" and $note->is_list_start
        and return $self->position($note->next);

    my %isa     = map +($_, $note->isa("App::Jacana::Music::$_")),
        qw/ Note /;
    my %does    = map +($_, $note->DOES("App::Jacana::Has::$_")),
        qw/Pitch Length Key Dialog/;
    my %act     = map +($_, $view->get_action($_)), qw/
        AddDot NoteChroma Sharpen Flatten OctaveUp OctaveDown
        Tie Properties
    /;

    $act{AddDot}->set_sensitive($does{Length});
    if ($isa{Note}) {
        $act{Tie}->set_sensitive(1);
        $act{Tie}->set_active($note->tie);
        warn "TIE [" . $note->tie . "]";
    }
    else {
        $act{Tie}->set_sensitive(0);
        $act{Tie}->set_active(0);
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
    $view->refresh;
}

sub BUILD {
    my ($self) = @_;
    $self->length(3);
    $self->position($self->position);
}

sub DEMOLISH {
    my ($self) = @_;
    $self->view->midi->free_chan($self->midi_chan);
}

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
    my $pos = $self->position;
    $pos->is_list_start and return;
    $self->position($pos->prev);
}

sub move_right :Action(view.Right)  {
    my ($self) = @_;
    my $pos = $self->position;
    $pos->is_list_end and return;
    $self->position($pos->next);
}

sub move_to_end :Action(view.End) {
    my ($self) = @_;
    $self->position($self->voice->prev);
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

sub _set_staff {
    my ($self, $n) = @_;
    
    $n < 0 || $n >= @{$self->view->doc->music}
        and return;

    my $pos = $self->position->get_time;
    $self->staff($n);
    $self->position($self->voice->find_time($pos));
}

sub up_staff :Action(view.Up)      { $_[0]->_set_staff($_[0]->staff - 1) }
sub down_staff :Action(view.Down)  { $_[0]->_set_staff($_[0]->staff + 1) }

sub insert_staff :Action(view.InsertStaff) {
    my ($self) = @_;
    
    push @{$self->view->doc->music}, 
        App::Jacana::Music::Voice->new(name => "voice");
    $self->view->refresh;
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

sub _insert_rest :Action(view.Rest) {
    my ($self) = @_;
    $self->mode eq "insert" or return;
    $self->position($self->position->insert(
        App::Jacana::Music::Rest->new(copy_from => $self)));
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
    $_[0]->_do_marks(Slur => span_start => 1);
}

sub _slur_end :Action(view.SlurEnd) {
    $_[0]->_do_marks(Slur => span_start => 0);
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
