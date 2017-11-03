package App::Jacana::Has::Length;

use App::Jacana::Moose -role;
use MooseX::Copiable;

# length is a number, 0-8, 0=breve, 1=semibreve, 2=minim, &c.
has length  => (
    is      => "rw", 
    traits  => [qw/Copiable/],
    isa     => NoteLength,
);
has dots    => (
    is      => "rw", 
    traits  => [qw/Copiable/],
    default => 0,
);
# A scale factor for ->duration. This is a float because it's easier,
# and the accuracy seems to be sufficient.
has tuplet  => (
    is      => "rw",
    isa     => StrictNum,
    traits  => [qw/Copiable/],
    default => 1,
);

my @Length = qw/ \breve 1 2 4 8 16 32 64 128 /;
my %Length = map +($Length[$_], $_), 0..$#Length;

sub length_rx {
    qr( (?<length>\\breve|[0-9]+) (?<dots>\.*) )x;
}

sub _length_from_lily {
    my ($self, %n) = @_;
    +(  length => $Length{$n{length}}, 
        dots => length $n{dots} // ""
    );
}

sub _length_to_lily {
    my ($self) = @_;
    my $dots = "." x $self->dots;
    "$Length[$self->length]$dots";
}

sub duration { 
    my ($self) = @_;
    # 256 qhdsq in a breve
    my $base = my $bit = 256;
    $base += $bit >>= 1 for 1..$self->dots;
    my $len = $self->length;
    my $dur = $base >> $len;
    $dur * $self->tuplet;
}

sub _draw_dots {
    my ($self, $c, $wd, $pos) = @_;

    my $dots    = $self->dots   or return 0;
    my $yoff    = ($pos % 2) ? 0 : -1;

    $c->save;
        $c->set_line_width(0.8);
        $c->set_line_cap("round");
        for (1..$dots) {
            $c->move_to($wd + $_ * 1.6 - 0.8, $yoff);
            $c->close_path;
            $c->stroke;
        }
    $c->restore;

    return $dots * 1.6;
}

sub _draw_tuplet {
    my ($self, $c, $pos) = @_;

    my $tuplet  = $self->tuplet;
    $tuplet == 1 and return;

    $c->save;
        $c->move_to(0, -$pos - 0.5);
        $c->text_font("italic", 0.5);
        $c->show_text(sprintf "%.2f", $tuplet);
    $c->restore;
}

1;
