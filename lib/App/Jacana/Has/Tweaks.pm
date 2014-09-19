package App::Jacana::Has::Tweaks;

use Moo::Role;

use App::Jacana::Util::Types;

has tweaks  => (
    is          => "ro",
    isa         => HashRef,
    predicate   => 1,
    clearer     => 1,
);

my %Known = (
    direction   => {
        desc    => "Vertical direction",
        type    => "Enum",
        values  => [qw/ UP Up DOWN Down NORMAL Normal /],
    },
    "self-alignment-X"  => {
        desc    => "Horizontal alignment",
        type    => "Enum",
        values  => [qw/ LEFT Left CENTER Centre RIGHT Right /],
    },
);
$Known{$_}{name} = $_ for keys %Known;

sub known_tweaks { return }
sub _tweak_info  { $Known{$_[1]} }

sub tweaks_rx {
    # I would rather capture these individually, but neither %+ nor %-
    # returns captures from (?<>)* properly.
    qr( (?<tweaks> (?: \\tweak \s+ \S+ \s+ \#\S+ \s* )* ) )x
}

sub tweaks_from_lily {
    my ($self, %n) = @_;

    my $tw = $n{tweaks} or return;
    my %tw;

    $tw{$1} = $2 
        while $tw =~ s/^\\tweak \s+ (\S+) \s+ \#(\S+) \s*//x;

    return tweaks => \%tw;
}

sub tweaks_to_lily {
    my ($self) = @_;
    my $tw = $self->tweaks;
    my @tw = map "\\tweak $_ #$$tw{$_}", keys %$tw;
    return wantarray ? @tw : join "", map "$_ ", @tw;
}

sub tweak {
    my ($self, @tw) = @_;
    my $tw = $self->tweaks;
    wantarray ? @$tw{@tw} : $$tw{$tw[0]};
}

1;
