package App::Jacana::Has::Tie;

use Moose::Role;
use MooseX::Copiable;

has tie => (
    is          => "rw", 
    traits      => [qw/Copiable/],
    #isa         => Bool, 
    default     => 0, 
);

=begin obsolete

sub _draw_tie {
    my ($self, $c, $wd) = @_;

    $self->tie or return 0;

    $c->save;
        $c->set_line_width(0.7);
        $c->move_to($wd, -1);
        $c->curve_to($wd + 1, -2, $wd + 2, -2, $wd + 3, -1);
        $c->stroke;
    $c->restore;

    return 2;
}

=end

=cut

1;
