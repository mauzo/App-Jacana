package App::Jacana::Cursor;

use Moo;
use MooX::MethodAttributes use => ["MooX::Gtk2"];

use App::Jacana::Util::Types;

with qw/ 
    MooX::Gtk2 
    App::Jacana::HasPitch
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

has "+chroma"   => (
    default  => 0,
    gtk_prop => "view.get_action(NoteChroma)::current-value",
);
has "+length"   => (
    default  => 4,
    gtk_prop => "view.get_action(NoteLength)::current-value",
);

sub _trigger_mode { 
    my ($self, $mode) = @_;
    my $pos = $self->position;
    $mode eq "edit" and $pos->is_list_start
        and $pos = $pos->next;
    $self->position($pos);
}
sub insert_mode :Action(view::InsertMode)   { $_[0]->mode("insert") }
sub edit_mode :Action(view::EditMode)       { $_[0]->mode("edit") }

sub _trigger_position {
    my ($self, $note) = @_;
    $self->copy_from($note, "App::Jacana::HasPitch");
    $self->mode eq "insert" and $self->chroma(0);
    $self->mode eq "edit" 
        and $self->copy_from($note, "App::Jacana::HasLength");
    warn "POSITION " . join ",", map "$_=>$$self{$_}", keys %$self;
    $self->view and $self->view->refresh;
}

sub _reset_length :Action(view::NoteLength) {
    my ($self) = @_;
    $self->dots(0);
    $self->mode eq "edit" or return;
    $self->position->copy_from($self, "App::Jacana::HasLength");
    $self->view->refresh;
}

sub _reset_chroma :Action(view::NoteChroma) {
    my ($self) = @_;
    $self->mode eq "edit" or return;
    $self->position->copy_from($self, { only => "chroma" });
    $self->_play_note;
    $self->view->refresh;
}

method_attrs octave_up      => "Action(view::OctaveUp)";
method_attrs octave_down    => "Action(view::OctaveDown)";

after qw/ octave_up octave_down /, sub { 
    my ($self) = @_;
    if ($self->mode eq "edit") {
        $self->position->copy_from($self, { only => "octave" });
    }
    $self->view->refresh;
};

my %nearest = (
    cg => -1, ca => -1, cb => -1, cc =>  0, cd =>  0, ce =>  0, cf =>  0,
    da => -1, db => -1, dc =>  0, dd =>  0, de =>  0, df =>  0, dg =>  0,
    eb => -1, ec =>  0, ed =>  0, ee =>  0, ef =>  0, eg =>  0, ea =>  0,
    fc =>  0, fd =>  0, fe =>  0, ff =>  0, fg =>  0, fa =>  0, fb =>  0,
    gd =>  0, ge =>  0, gf =>  0, gg =>  0, ga =>  0, gb =>  0, gc =>  1,
    ae =>  0, af =>  0, ag =>  0, aa =>  0, ab =>  0, ac =>  1, ad =>  1,
    bf =>  0, bg =>  0, ba =>  0, bb =>  0, bc =>  1, bd =>  1, be =>  1,
);
    
sub nearest {
    my ($self, $new) = @_;
    my $oct = $self->octave + $nearest{$self->note . $new};
    $self->octave($oct);
    $self->note($new);
    $oct;
}
    
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

sub _play_note {
    my ($self) = @_;
    $self->view->app->midi->play_note($self->pitch, 8);
}

sub _adjust_chroma {
    my ($self, $by) = @_;

    my $new = $self->chroma + $by;
    abs($new) > 2 and return $self->view->silly;
    $self->chroma($new);
    $self->_reset_chroma;
}

sub sharpen :Action(view::Sharpen) { $_[0]->_adjust_chroma(+1) }
sub flatten :Action(view::Flatten) { $_[0]->_adjust_chroma(-1) }

method_attrs change_pitch => map "Action(view::Pitch$_)", "A".."G";

sub change_pitch {
    my ($self, $action) = @_;

    my ($note) = $action->get_name =~ /^Pitch([A-Z])$/ or return;
    $note = lc $note;
    $self->nearest($note);

    # this must come before position, because that resets chroma
    $self->_play_note;

    if ($self->mode eq "insert") {
        my $new = App::Jacana::Music::Note->new(copy_from => $self);
        $self->position($self->position->insert($new));
    }
    else {
        $self->position->copy_from($self, "App::Jacana::HasPitch");
    }
}

sub _add_dot :Action(view::AddDot) {
    my ($self) = @_;

    my $note = $self->position;
    $note->isa("App::Jacana::Music::Note") or return;

    my $view = $self->view;

    my $dots = $note->dots + 1;
    $dots > 6 and return $view->silly;
    $note->dots($dots);

    $note->duration != int($note->duration) and
        $view->status_flash("Divisions this small will not play correctly.");
    $view->refresh;
}

sub _backspace :Action(view::Backspace) {
    my ($self) = @_;
    $self->position($self->position->remove);
}

1;
