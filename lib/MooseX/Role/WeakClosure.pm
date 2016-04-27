package MooseX::Role::WeakClosure;

use Moose::Role;
use Scalar::Util    ();

# XXX
# There is no point in calling the sub if we don't have an object.
# There is point in passing the returned ref to the dtor.

sub weak_method {
    my ($self, $meth, $dtor, $args) = @_;

    Scalar::Util::weaken($self);
    $dtor ||= sub { return };

    my ($rv, $cv);
    if ($args) {
        $rv = $cv = sub { 
            $self ? $self->$meth(@$args) : $dtor->($cv, @$args)
        };
    }
    else {
        $rv = $cv = sub {
            $self ? $self->$meth(@_) : $dtor->($cv, @_)
        };
    }
    Scalar::Util::weaken($cv);

    $rv;
}

*weak_closure = \&weak_method;

1;
