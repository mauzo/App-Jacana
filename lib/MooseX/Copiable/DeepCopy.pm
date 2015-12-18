package MooseX::Copiable::DeepCopy;

# This is not a Moose class

# This is the constructor, but it does not necessarily return an object.
sub new {
    my ($class, $att, $v) = @_;
    my $d = $att->deep_copy or return $v;
    bless [$d, $v, $att->name], $class;
}

sub evaluate {
    my ($self, $obj) = @_;
    my ($d, $v, $n) = @$self;

    ref $d      and return $d->($v);
    $d =~ /::/  and return $d->new({copy_from => $v});
    $d eq "1"   and $d = "_copy_$n";
    return $obj->$d($v);
}

1;
