package App::Jacana::Cursor;

use Moo;
use App::Jacana::Util::Types;

with    qw/ App::Jacana::HasPitch /;

has view        => is => "ro", weak_ref => 1;
has position    => (
    is      => "rw",
    isa     => Music,
    trigger => 1,
);
has "+chroma"   => trigger => 1;

sub _trigger_position {
    my ($self, $note) = @_;
    $self->copy_pitch_from($note);
    $self->chroma(0);
    $self->view and $self->view->refresh;
}

sub _trigger_chroma {
    my ($self, $chroma) = @_;
    my $vw = $self->view or return;
    my $w = $vw->app->window;
    $w->actions->get_action("Natural")->set_current_value($chroma);
}

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
    
sub move_left   {
    my ($self) = @_;
    my $pos = $self->position;
    $pos->is_list_start and return;
    $self->position($pos->prev);
}

sub move_right  {
    my ($self) = @_;
    my $pos = $self->position;
    $pos->is_list_end and return;
    $self->position($pos->next);
}

1;
