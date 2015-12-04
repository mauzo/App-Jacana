package App::Jacana::MUtil::LinkList;

use Moose::Exporter;
use Moose::Util     qw/ensure_all_roles find_meta/;

use B               qw/perlstring/;
use Scalar::Util    qw/blessed looks_like_number refaddr/;
use List::Util      qw/max/;

Moose::Exporter->setup_import_methods(
    with_meta   => [qw/ linklist /],
);

sub qperl {
    my ($val) = @_;
    ref $val                and return "$val";
    looks_like_number $val  and return "$val";
    perlstring $val;
}

sub build_names {
    my ($nm)    = @_;
    my ($p)     = $nm =~ s/^(_)//;

    return {
        map(($_ =>"${p}${_}_${nm}"), 
            qw/next prev insert remove order dump clone/),
        map(("is$_" => "${p}is_${nm}_${_}"),
            qw/start end/),
        ("mkend" => "${p}mk_${nm}_end"),
    };
}

sub build_attributes {
    my ($class, $m) = @_;

    my ($next, $prev, $mkend) = @$m{qw/next prev mkend/};

    $class->add_attribute($$m{next},
        is          => "rw",
        isa         => $class->name,
    );
    $class->add_attribute($$m{prev},
        is          => "rw",
        isa         => $class->name,
        weak_ref    => 1,
        default     => sub { $_[0] },
    );

    $class->add_before_method_modifier(BUILD => sub {
        my ($self) = @_;
        if (!$self->$next) {
            $self->$next($self);
            $self->$mkend;
        }
    });
}

sub build_ends {
    my ($class, $m) = @_;

    my ($next, $prev, $isend) = @$m{qw/next prev isend/};

    $class->add_method($$m{isend}, sub {
        my ($self) = @_;
        find_meta($self)->get_meta_instance
            ->slot_value_is_weak($self, $next);
    });
    $class->add_method($$m{mkend}, sub {
        my ($self)  = @_;
        my $inst    = find_meta($self)->get_meta_instance;
        $inst->slot_value_is_weak($self, $next)
            or $inst->weaken_slot_value($self, $next);
    });

    $class->add_method($$m{isstart}, sub { $_[0]->$prev->$isend });
}

sub build_insert_remove {
    my ($class, $m) = @_;

    my ($_next, $_prev, $isend, $mkend) = @$m{qw/next prev isend mkend/};

    $class->add_method($$m{insert}, sub {
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
    });

    $class->add_method($$m{remove}, sub {
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
    });
}

sub build_clone {
    my ($class, $m) = @_;

    my ($_next, $_prev, $_insert, $isend) = 
        @$m{qw/next prev insert isend/};

    $class->add_method($$m{clone}, sub {
        my ($pos, $end) = @_;
        $end //= $pos;
        
        my $new;
        while (1) {
            # assume Copiable
            my $n = blessed($pos)->new(copy_from => $pos);
            $new ? $new->$_prev->$_insert($n) : ($new = $n);
            $pos == $end || $pos->$isend and last;
            $pos = $pos->$_next;
        }
        $new;
    });
}

sub build_others {
    my ($class, $m) = @_;

    my ($_next, $isend) = @$m{qw/next isend/};

    $class->add_method($$m{order}, sub {
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
    });

    $class->add_method($$m{dump}, sub {
        my ($i) = @_;

        my $dump;
        while (1) {
            $dump .= sprintf "%s(0x%x)={\n", blessed $i, refaddr $i;
            my $w = max map length, keys %$i;
            for (sort keys %$i) {
                $dump .= sprintf "  %-*s => %s,\n", $w, $_, qperl($$i{$_});
            }
            $dump .= "}";
            $i->$isend and last;
            $dump .= "->";
            $i = $i->$_next;
        }
        $dump;
    });
}

sub linklist {
    my ($class, $nm, %args) = @_;

    my $m = build_names $nm;

    ensure_all_roles $class, "MooseX::Role::NoGlobalDestruction";
     
    build_attributes $class, $m;
    build_ends $class, $m;
    build_insert_remove $class, $m;
    build_clone $class, $m;
    build_others $class, $m;
}

=begin later

sub fornext {
    my ($self, $cb) = @_;

    my $sub = ref $cb ? $cb : sub { $_[0]->$cb };
    for (;;) {
        $sub->($self);
        $self->is_music_end and last;
        $self = $self->next;
    }
}

sub forprev {
    my ($self, $cb) = @_;

    my $sub = ref $cb ? $cb : sub { $_[0]->$cb };
    for (;;) {
        $sub->($self);
        $self = $self->prev;
        $self->is_music_end and last;
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
    my $next    = $obj->is_music_end ? "" 
        : "->" . Data::Dump::pp($obj->next);
    my $atts    = Data::Dump::pp(\%atts);

    +{ dump => "$class($addr)$atts$next" };
};

=end later
=cut

1;
