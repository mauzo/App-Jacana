package App::Jacana::Has::Marks;

use Moo::Role;

use Module::Runtime qw/use_module/;

use App::Jacana::Util::Types;

use namespace::autoclean;

has marks => (
    is          => "rw",
    isa         => ArrayRef[InstanceOf["App::Jacana::Music::Mark"]],
    default     => sub { [] },
);

my @Marks   = map "App::Jacana::Music::Mark::$_",
    qw/ Articulation Slur /;
use_module $_ for @Marks;

sub marks_rx {
    join "|", map $_->lily_rx, @Marks;
}

sub marks_from_lily {
    my ($self, %n) = @_;
    return marks => [
        map $_->from_lily(%n), @Marks
    ];
}

sub marks_to_lily {
    my ($self) = @_;
    my $marks = $self->marks;
    join "", map $_->to_lily, @$marks;
}

sub add_mark {
    my ($self, $mark) = @_;
    push @{$self->marks}, $mark;
}

sub delete_mark {
    my ($self, $mark) = @_;
    my $mrk = $self->marks or die "No marks on [$self]";
    @$mrk = grep $_ != $mark, @$mrk;
}

1;
