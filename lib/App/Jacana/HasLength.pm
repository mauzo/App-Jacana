package App::Jacana::HasLength;

use Moo::Role;

with qw/MooX::Role::Copiable/;

has length  => is => "rw", copiable => 1;
has dots    => is => "rw", default => 0, copiable => 1;

sub duration { 
    my ($self) = @_;
    my $base = my $bit = 128;
    $base += $bit >>= 1 for 1..$self->dots;
    $base / $self->length;
}

1;
