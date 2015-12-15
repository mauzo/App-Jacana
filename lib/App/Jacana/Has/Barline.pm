package App::Jacana::Has::Barline;

use Moose::Role;
use MooseX::Copiable;

sub barline_types { qw/
    |   ||  .|  |.|     |.
    .|: :..:    :|.|:   :|.
/ }

has barline     => (
    is          => "rw",
    copiable    => 1,
    #isa         => Enum[barline_types()],
);

sub to_lily {
    my $b = $_[0]->barline;
    qq/\\bar "$b"/
}

sub _draw_barline {
    my ($self, $c, $bar) = @_;

    my @chars = split //, $bar;
    my $x = 1;

    for (@chars) {
        if (/:/) {
            $c->set_line_width(1);
            $c->set_line_cap("round");
            $c->move_to($x, -1);
            $c->line_to($x, -1);
            $c->move_to($x, 1);
            $c->line_to($x, 1);
            $c->stroke;
        }
        else {
            $c->set_line_width(/\./ ? 1 : 0.5);
            $c->set_line_cap("butt");
            $c->move_to($x, -4);
            $c->line_to($x, 4);
            $c->stroke;
        }
        $x += 1.5;
    }

    return $x + 1;
}

1;
