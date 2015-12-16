package App::Jacana::Music::Mark;

use App::Jacana::Moose;

extends qw/App::Jacana::Music/;
with    qw/App::Jacana::Music::FindAmbient/;

sub lily_rx     {...}
sub to_lily     {...}

sub from_lily { 
    my ($class, %args) = @_;
    $class->new(\%args);
}

sub draw        {...}

Moose::Util::find_meta(__PACKAGE__)->make_immutable;
