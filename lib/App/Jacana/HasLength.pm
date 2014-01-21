package App::Jacana::HasLength;

use Moo::Role;

has length  => is => "rw";
has dots    => is => "rw", default => 0;

sub duration { 
    my ($self) = @_;
    my $base = my $bit = 128;
    $base += $bit >>= 1 for 1..$self->dots;
    $base / $self->length;
}

1;
