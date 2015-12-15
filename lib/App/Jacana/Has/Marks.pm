package App::Jacana::Has::Marks;

use Moose::Role;

use Module::Runtime qw/use_module/;

use namespace::autoclean;

my $Mark = "App::Jacana::Music::Mark";

has marks => (
    is          => "rw",
    #isa         => ArrayRef[InstanceOf[$Mark]],
    default     => sub { [] },
);

my @Marks   = map "$Mark\::$_", 
    qw/ Articulation Dynamic Slur /;
use_module $_ for @Marks;

sub marks_rx {
    my $mrk = join "|", map $_->lily_rx, @Marks;
    qr/(?:$mrk)*/;
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
    my ($self, $type, @args) = @_;
    push @{$self->marks}, "$Mark\::$type"->new(@args);
}

sub delete_marks {
    my ($self, $type) = @_;
    my $mrk = $self->marks or die "No marks on [$self]";
    @$mrk = grep !$_->isa("$Mark\::$type"), @$mrk;
}

1;
