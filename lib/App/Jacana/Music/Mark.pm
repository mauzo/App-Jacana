package App::Jacana::Music::Mark;

use Moo;

extends qw/App::Jacana::Music/;
with    qw/App::Jacana::Music::FindAmbient/;

sub lily_rx     {...}
sub to_lily     {...}

sub from_lily { 
    my ($class, %args) = @_;
    $class->new(\%args);
}

sub draw        {...}

1;
