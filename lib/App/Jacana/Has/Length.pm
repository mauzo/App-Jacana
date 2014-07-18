package App::Jacana::Has::Length;

use Moo::Role;

with qw/MooX::Role::Copiable/;

# length is a number, 0-8, 0=breve, 1=semibreve, 2=minim, &c.
has length  => (
    is => "rw", 
    copiable => 1,
    isa => sub {
        ref $_[0] || $_[0] !~ /^[0-8]$/
            and Carp::confess "Bad length [$_[0]]";
    },
);
has dots    => is => "rw", default => 0, copiable => 1;

my @Length = qw/ \breve 1 2 4 8 16 32 64 128 /;
my %Length = map +($Length[$_], $_), 0..$#Length;

sub _length_from_lily {
    my ($self, $length, $dots) = @_;
    +(  length => $Length{$length}, 
        dots => length $dots//""
    );
}

sub _length_to_lily {
    my ($self) = @_;
    my $dots = "." x $self->dots;
    "$Length[$self->length]$dots";
}

sub duration { 
    my ($self) = @_;
    my $base = my $bit = 128;
    $base += $bit >>= 1 for 1..$self->dots;
    my $len = $self->length;
    $len > 0 ? $base >> ($len - 1) : $base * 2;
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

1;
