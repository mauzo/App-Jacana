package App::Jacana::Util::LinkList;

use 5.012;
use warnings;

use Scalar::Util    qw/ refaddr blessed weaken isweak /;

use App::Jacana::Util::Types;

use Moo::Role;

with qw/ MooX::NoGlobalDestruction /;

has next    => (
    is      => "rw", 
    isa     => LinkList,
);
has prev    => (
    is      => "rw", 
    isa     => LinkList,
    weak_ref => 1,
    default => sub { $_[0] },
);

push @Data::Dump::FILTERS, sub {
    my ($ctx, $obj) = @_;

    my $class = blessed $obj;
    $class && $obj->DOES(__PACKAGE__) or return;

    my %atts = %{$obj};
    delete @atts{qw/prev next/};
    $atts{ambient} and $atts{ambient} = 1;

    my $next    = $obj->is_list_end ? "" 
        : "->" . Data::Dump::pp($obj->next);
    my $atts    = Data::Dump::pp(\%atts);

    +{ dump => "$class$atts$next" };
};

# This has to manipulate the hash directly, because of the irritating
# no-copy semantics of weakrefs.
sub is_list_end { isweak $_[0]{next} }
# OK, so weaken is even more irritating than I thought
sub mk_list_end { isweak $_[0]{next} or weaken $_[0]{next} }

sub BUILD {}

before BUILD => sub {
    my ($self) = @_;
    if (!$self->next) {
        $self->next($self);
        $self->mk_list_end;
    }
};

sub is_list_start { $_[0]->prev->is_list_end }

sub fornext {
    my ($self, $cb) = @_;

    my $sub = ref $cb ? $cb : sub { $_[0]->$cb };
    for (;;) {
        $sub->($self);
        $self->is_list_end and last;
        $self = $self->next;
    }
}

sub forprev {
    my ($self, $cb) = @_;

    my $sub = ref $cb ? $cb : sub { $_[0]->$cb };
    for (;;) {
        $sub->($self);
        $self = $self->prev;
        $self->is_list_end and last;
    }
}

sub insert {
    my ($self, $from) = @_;

    my $last    = $from->prev;
    my $next    = $self->next;
    my $isend   = $self->is_list_end;

    $self->next($from);
    $from->prev($self);
    $last->next($next);
    $next->prev($last);

    $isend and $from->mk_list_end;

    return $last;
}

sub remove {
    my ($self, $upto) = @_;
    $upto //= $self;

    my $prev    = $self->prev;
    my $next    = $upto->next;
    my $isend   = $upto->is_list_end;

    $self->prev($upto);
    $upto->next($self);
    $prev->next($next);
    $next->prev($prev);

    $upto->mk_list_end;
    $isend and $prev->mk_list_end;

    return $prev;
}

1;
