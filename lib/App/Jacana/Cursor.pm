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

has "+chroma"   => (
    default  => 0,
    gtk_prop => "view.get_action(Natural)::current-value",
);
has "+length"   => (
    default  => 4,
    gtk_prop => "view.get_action(Breve)::current-value",
);

sub _trigger_position {
    my ($self, $note) = @_;
    $self->copy_from($note, "App::Jacana::HasPitch");
    $self->chroma(0);
    $self->view and $self->view->refresh;
}

method_attrs octave_up      => "Action(view::OctaveUp)";
method_attrs octave_down    => "Action(view::OctaveDown)";

after qw/ octave_up octave_down /,
    sub { $_[0]->view->refresh };

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

sub _silly { $_[0]->view->app->window->_silly }
sub status_flash { $_[0]->view->app->window->status_flash(@_[1..$#_]) }

sub sharpen :Action(view::Sharpen) {
    my ($self) = @_;
    my $chrm = $self->chroma;
    $chrm > 1 and return $self->_silly;
    $self->chroma($chrm + 1);
}

sub flatten :Action(view::Flatten) {
    my ($self) = @_;
    my $chrm = $self->chroma;
    $chrm < -1 and return $self->_silly;
    $self->chroma($chrm - 1);
}

method_attrs pitch => map "Action(view::Pitch$_)", "A".."G";

sub pitch {
    my ($self, $action) = @_;

    my $note    = $action->get_name =~ s/^Pitch([A-G])$/lc $1/er
        or return;
    $self->nearest($note);

    my $new = App::Jacana::Music::Note->new(copy_from => $self);
    $self->position($self->position->insert($new));
    $self->view->app->midi->play_note($new->pitch, 8);
}

sub _add_dot :Action(view::AddDot) {
    my ($self) = @_;

    my $note = $self->position;
    $note->isa("App::Jacana::Music::Note") or return;

    my $dots = $note->dots + 1;
    $dots > 6 and return $self->_silly;
    $note->dots($dots);

    $note->duration != int($note->duration) and
        $self->status_flash("Divisions this small will not play correctly.");
    $self->view->refresh;
}

sub _backspace :Action(view::Backspace) {
    my ($self) = @_;
    $self->position($self->position->remove);
}

1;
