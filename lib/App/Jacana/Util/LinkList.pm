package App::Jacana::Util::LinkList;

use 5.012;
use warnings;

use Class::Method::Modifiers    qw/install_modifier/;
use Exporter        qw/import/;
use Role::Tiny;
use Scalar::Util    qw/ refaddr blessed weaken isweak /;

use App::Jacana::Util::Types;

our @EXPORT = qw/linklist/;

sub mod { 
    my $pkg = caller 1;
    my ($mod, $meth) = @_;
    warn "LINKLIST: [$mod] [$pkg] [$meth]";
    install_modifier $pkg, @_;
}

sub linklist {
    my ($nm, %args) = @_;
    my $pkg     = caller;
    my $role    = Role::Tiny->is_role($pkg);
    my $TypeOf  = $role ? "ConsumerOf" : "InstanceOf";

    (my $p, $nm)        = $nm =~ /^(_?)(.*)/;
    my ($_prev, $_next) = map "$p$_\_$nm", qw/prev next/;
    my ($isend, $mkend) = map "${p}${_}_${nm}_end", qw/is mk/;

    Role::Tiny->apply_roles_to_package("MooX::NoGlobalDestruction");
     
    warn "LINKLIST: [$pkg] [$_next] [$_prev]";
    # eval because Moo doesn't have apply_has_to_package
    eval qq{
        package $pkg;
        use Moo;
        use App::Jacana::Util::Types;
        use namespace::clean;

        has $_next    => (
            is      => "rw", 
            isa     => $TypeOf\["\Q$pkg\E"],
        );
        has $_prev    => (
            is      => "rw", 
            isa     => $TypeOf\["\Q$pkg\E"],
            weak_ref => 1,
            default => sub { \$_[0] },
        );

        1;
    } or die;
    $pkg->can($_next) or die "Failed to install $pkg\->$_next";

    # This has to manipulate the hash directly, because of the irritating
    # no-copy semantics of weakrefs.
    mod fresh => $isend, sub { isweak $_[0]{$_next} };
    mod fresh => $mkend, 
        sub { isweak $_[0]{$_next} or weaken $_[0]{$_next} };

    $pkg->can("BUILD") or mod fresh => BUILD => sub {};
    mod before => BUILD => sub {
        my ($self) = @_;
        if (!$self->$_next) {
            $self->$_next($self);
            $self->$mkend;
        }
    };

    mod fresh => "${p}is_${nm}_start", sub { $_[0]->$_prev->$isend };

    mod fresh => "${p}insert_${nm}" => sub {
        my ($self, $from) = @_;

        my $last    = $from->$_prev;
        my $next    = $self->$_next;
        my $end     = $self->$isend;

        $self->$_next($from);
        $from->$_prev($self);
        $last->$_next($next);
        $next->$_prev($last);

        $end and $last->$mkend;

        return $last;
    };

    mod fresh => "${p}remove_${nm}" => sub {
        my ($self, $upto) = @_;
        $upto //= $self;

        my $prev    = $self->$_prev;
        my $next    = $upto->$_next;
        my $end     = $upto->$isend;

        $self->$_prev($upto);
        $upto->$_next($self);
        $prev->$_next($next);
        $next->$_prev($prev);

        $upto->$mkend;
        $end and $prev->$mkend;

        return $prev;
    };

    mod fresh => "${p}order_${nm}" => sub {
        my ($self, $other) = @_;

        my ($x, $y) = ($self, $other);
        while (1) {
            $x == $other || $y->$isend 
                and return ($self, $other);
            $y == $self || $x->$isend
                and return ($other, $self);

            $x = $x->$_next;
            $y = $y->$_next;
        }

        require Carp;
        Carp::confess("Badly formed list!");
    };
}

=begin later

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

push @Data::Dump::FILTERS, sub {
    my ($ctx, $obj) = @_;

    my $class = blessed $obj;
    $class && $obj->DOES($pkg) or return;

    my $addr = sprintf "0x%x", refaddr $obj;
    my %atts = %{$obj};
    delete $atts{prev};
    $atts{ambient} and $atts{ambient} = 1;

    no warnings "recursion";
    my $next    = $obj->is_list_end ? "" 
        : "->" . Data::Dump::pp($obj->next);
    my $atts    = Data::Dump::pp(\%atts);

    +{ dump => "$class($addr)$atts$next" };
};

=end later
=cut

1;
