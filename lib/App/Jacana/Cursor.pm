package App::Jacana::Cursor;

use Moo;
use MooX::MethodAttributes use => ["MooX::Gtk2"];
use Class::Method::Modifiers qw/:all/;

use App::Jacana::Util::Types;

use Try::Tiny;

use namespace::clean;

with qw/ 
    MooX::Gtk2 
    App::Jacana::HasLength
/;

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
    gtk_prop    => "view.status_mode::label",
    trigger     => 1,
);

has "+length"   => (
    # default doesn't fire the trigger, set it in BUILD instead
    #default     => 3,
    gtk_prop    => "view.get_action(NoteLength)::current-value",
    trigger     => 1,
);

sub _trigger_mode { 
    my ($self, $mode) = @_;
    $self->view->get_action("Rest")->set_sensitive($mode eq "insert");
    my $pos = $self->position;
    $self->position($pos);
}
sub insert_mode :Action(view::InsertMode)   { $_[0]->mode("insert") }
sub edit_mode :Action(view::EditMode)       { $_[0]->mode("edit") }

sub _trigger_position {
    my ($self, $note) = @_;
    my $view = $self->view or return;
    $self->mode eq "edit" and $note->is_list_start
        and return $self->position($note->next);

    my %does    = map +($_, $note->DOES("App::Jacana::Has$_")),
        qw/Pitch Length Key Dialog/;
    my %act     = map +($_, $view->get_action($_)), qw/
        AddDot NoteChroma Sharpen Flatten OctaveUp OctaveDown
        Properties
    /;

    $act{AddDot}->set_sensitive($does{Length});
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

    $self->copy_from($note, "App::Jacana::HasLength");
    $self->view->refresh;
}

sub BUILD {
    my ($self) = @_;
    $self->length(3);
    $self->position($self->position);
}

sub _trigger_length {
    my ($self, $new) = @_;
    my $view = $self->view;
    $self->view->get_action("Rest")->set_icon_name("icon-rest-$new");
}

sub _reset_length :Action(view::NoteLength) {
    my ($self) = @_;
    $self->dots(0);
    $self->position->copy_from($self, "App::Jacana::HasLength");
    $self->view->refresh;
}

sub _reset_chroma :Action(view::NoteChroma) {
    my ($self, $action) = @_;
    $self->position->chroma($action->get_current_value);
    $self->_play_note;
    $self->view->refresh;
}

sub _change_octave {
    my ($self, $by) = @_;
    my $pos = $self->position;
    $pos->DOES("App::Jacana::HasPitch") or return;
    $pos->octave($pos->octave + $by);
    $self->_play_note;
    $self->view->refresh;
}

sub _octave_up   :Action(view::OctaveUp)   { $_[0]->_change_octave(+1) }
sub _octave_down :Action(view::OctaveDown) { $_[0]->_change_octave(-1) }

sub move_left :Action(view::Left) {
    my ($self) = @_;
    my $pos = $self->position;
    $pos->is_list_start and return;
    $self->position($pos->prev);
}

sub move_right :Action(view::Right)  {
    my ($self) = @_;
    my $pos = $self->position;
    $pos->is_list_end and return;
    $self->position($pos->next);
}

sub move_to_end :Action(view::End) {
    my ($self) = @_;
    $self->position($self->view->doc->music->prev);
}

sub move_to_start :Action(view::Home) {
    my ($self) = @_;
    $self->position($self->view->doc->music);
}

sub goto_position :Action(view::GotoPosition) {
    my ($self) = @_;

    my $dlg = $self->view->run_dialog("GotoPosition", undef,
        pos => $self->position->get_time);
    my $pos = $self->view->doc->music->find_time($dlg->pos);
    warn "GOTO POSITION [$pos]";
    $self->position($pos);
}

sub _play_note {
    my ($self) = @_;
    my $pos = $self->position;
    $pos->DOES("App::Jacana::HasPitch") or return;
    $self->view->midi->play_note($pos->pitch, 8);
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

    $pos->DOES("App::Jacana::HasPitch") or return;
    my $new = $pos->chroma + $by;
    abs($new) > 2 and return $view->silly;
    $pos->chroma($new);
    $self->_play_note;
    $self->position($pos);
}

sub sharpen :Action(view::Sharpen) { $_[0]->_adjust_chroma(+1) }
sub flatten :Action(view::Flatten) { $_[0]->_adjust_chroma(-1) }

sub _find_ambient {
    my ($self, $role) = @_;
    my $pos = $self->position;
    $pos = $pos->prev until $pos->is_list_start 
        || $pos->DOES("App::Jacana::Has$role");
    $pos;
}

method_attrs change_pitch => map "Action(view::Pitch$_)", "A".."G";

sub change_pitch {
    my ($self, $action) = @_;

    my $pos = $self->position;
    my $Dp  = $pos->DOES("App::Jacana::HasPitch");
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
    my $ref     = $Dp ? $pos : $self->_find_ambient("Clef")->centre_pitch;
    my $pitch   = $ref->nearest($note);

    # changing note always resets chroma
    my $key     = $self->_find_ambient("Key");
    $pitch->chroma($key->chroma($note));

    if ($self->mode eq "insert") {
        my $new = App::Jacana::Music::Note->new(copy_from => $self);
        $pos = $self->position($pos->insert($new));
    }
    $pos->copy_from($pitch);
    $self->_play_note;
    $self->view->refresh;
}

sub _add_dot :Action(view::AddDot) {
    my ($self) = @_;

    my $note = $self->position;
    $note->DOES("App::Jacana::HasLength") or return;

    my $view = $self->view;

    my $dots = $note->dots + 1;
    $dots > 6 and return $view->silly;
    $note->dots($dots);

    $note->duration != int($note->duration) and
        $view->status_flash("Divisions this small will not play correctly.");
    $view->refresh;
}

sub _insert_rest :Action(view::Rest) {
    my ($self) = @_;
    $self->mode eq "insert" or return;
    $self->position($self->position->insert(
        App::Jacana::Music::Rest->new(copy_from => $self)));
}

sub _backspace :Action(view::Backspace) {
    my ($self) = @_;
    $self->position($self->position->remove);
}

sub _insert_clef {
    my ($self, $type) = @_;
    my $pos = $self->position;
    if ($self->mode eq "insert") {
        $self->position($self->position->insert(
            App::Jacana::Music::Clef->new(clef => $type)));
    }
    else {
        $pos->isa("App::Jacana::Music::Clef") or return;
        $pos->clef($type);
    }
    $self->view->refresh;
}

for my $c (qw/Treble Alto Tenor Bass Soprano/) {
    my $m = "_clef_\L$c";
    fresh $m, sub { $_[0]->_insert_clef(lc $c) };
    method_attrs $m, "Action(view::Clef$c)";
}

sub _insert_key :Action(view::KeySig) {
    my ($self) = @_;
    $self->mode eq "insert" or return;

    my $dlg = $self->view->run_dialog("KeySig", undef,
        key => 0, mode => "major")
        or return;
    $self->position($self->position->insert(
        App::Jacana::Music::KeySig->new(copy_from => $dlg)));
    $self->view->refresh;
}

sub _insert_time :Action(view::TimeSig) {
    my ($self) = @_;
    $self->mode eq "insert" or return;

    require App::Jacana::Dialog::TimeSig;
    my $dlg = $self->view->run_dialog("TimeSig", undef,
        beats   => 4, 
        divisor => 4,
    ) or return;
    $self->position($self->position->insert(
        App::Jacana::Music::TimeSig->new(copy_from => $dlg)));
    $self->view->refresh;
}

sub _properties :Action(view::Properties) {
    my ($self) = @_;

    my $pos = $self->position;
    $pos->DOES("App::Jacana::HasDialog") or return;

    $pos->run_dialog($self->view);
    $self->view->refresh;
}

1;
