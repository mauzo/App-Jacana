package MooseX::Gtk2::Meta::Attribute;

use Moose::Role;

use Hash::Util::FieldHash;

Moose::Util::meta_attribute_alias "Gtk2";

has gtk_prop => (
    is          => "ro",
);
has _gtk_prop_targs => (
    is          => "ro",
    default     => sub { Hash::Util::FieldHash::fieldhash my %h },
);

sub _gtk_prop_set_sub {
    sub {
        my ($obj, $targs, $path, $prop, $value) = @_;

        my $targ = $$targs{$obj};
        unless ($targ) {
            $targ = $$targs{$obj} = $obj->_resolve_object_path($path)
                or Carp::croak("Can't resolve '$path' from $obj");
            Scalar::Util::weaken $$targs{$obj};
        }

        warn "M GTK2: SET [$obj] = [$value] -> [$targ][$prop]";
        $value eq $targ->get_property($prop) and return;
        $targ->set_property($prop, $value);
    };
}

sub _gtk_prop_args {
    my ($self) = @_;

    my $pspec = $self->gtk_prop or return;
    my $targs = $self->_gtk_prop_targs;

    my ($path, $prop) = $pspec =~ /^(.*)\.([\w-]+)$/
        or Carp::croak("Bad property spec '$pspec'");

    return ($targs, $path, $prop);
}

after set_value => sub {
    my ($self, $obj, $value) = @_;

    my @args    = $self->_gtk_prop_args or return;
    my $set     = $self->_gtk_prop_set_sub;

    $obj->$set(@args, $value);
};

around _eval_environment => sub {
    my ($super, $self, @args) = @_;

    my $env     = $self->$super(@args);
    my @pargs   = $self->_gtk_prop_args or return $env;
    my $set     = $self->_gtk_prop_set_sub;

    $$env{'$gtk_prop_set'}  = \$set;
    $$env{'@gtk_prop_args'} = \@pargs;

    $env;
};

around _inline_set_value => sub {
    my ($super, $self, @args)   = @_;
    my ($obj, $value, $ctor)    = @args[0,1,5];

    my @code = $self->$super(@args);
    $ctor           and return @code;
    $self->gtk_prop or return @code;

    (@code, qq{ $obj->\$gtk_prop_set(\@gtk_prop_args, $value); });
};

1;
