package App::Jacana::Cursor;

use Moo;

with    qw/ App::Jacana::HasPitch /;

has view        => is => "ro", weak_ref => 1;
has position    => (
    is      => "rw",
    trigger => sub { $_[0]->view and $_[0]->view->refresh },
);

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
    
sub _move_lr {
    my ($self, $left) = @_;

    my $dir     = $left ? "LEFT" : "RIGHT";
    my $view    = $self->view;
    my $pos     = $self->position;
    my $notes   = $view->doc->music;

    my $new;
    if (defined $pos) {
        my ($old) = grep($$notes[$_] == $pos, 0..$#$notes);
        warn "FOUND CURSOR [$old]";
        if ($left) {
            $new = $old ? $$notes[$old - 1] : undef;
        }
        else {
            $old == $#$notes and warn("CURSOR RIGHT AT END"), return;
            $new = $$notes[$old + 1];
        }
    }
    else {
        if ($left)  { warn("CURSOR LEFT AT START"), return }
        else        { $new = $$notes[0] }
    }

    warn "CURSOR $dir [$new]";
    $self->position($new);
    if ($new) {
        $self->note($new->note);
        $self->octave($new->octave);
    }
}

sub move_left   { $_[0]->_move_lr(1) }
sub move_right  { $_[0]->_move_lr(0) }

1;
