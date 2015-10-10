package App::Jacana::Gtk2::RadioGroup;

use App::Jacana::Gtk2::RadioMember;

use Carp ();

use Glib::Object::Subclass
    "Gtk2::Action",
    properties  => [
        Glib::ParamSpec->object(
            "current", "", "",
            "App::Jacana::Gtk2::RadioMember",
            [qw"readable writable"],
        ),
        Glib::ParamSpec->string(
            "current-value", "", "",
            undef,
            [qw"readable writable"],
        ),
    ],
    signals     => {
        activate    => \&_do_activate,
    };

sub GET_PROPERTY {
    my ($self, $prop) = @_;
    my $name = $prop->get_name;

    $name eq "current_value"
        and return $self->get_current_value;
    return $self->{$name} // $prop->get_default_value;
}

sub SET_PROPERTY {
    my ($self, $prop, $new) = @_;
    my $name = $prop->get_name;

    $name eq "current"
        and return $self->set_current($new);
    $name eq "current_value"
        and return $self->set_current_value($new);
    $name eq "sensitive"
        and return $self->set_sensitive($new);

    $self->{$name} = $new;
}

sub get_current { 
    my ($self) = @_;
    $self->{current};
}
sub set_current {
    my ($self, $new) = @_;
    my $old = $self->{current};

    $old and $old != $new and $old->set_property("active", 0);
    $new and $new->set_property("active", 1);
    $self->{current} = $new;
    $self->notify("current");
    $self->notify("current-value");
}

sub get_current_value {
    my ($self) = @_;
    my $cur = $self->{current} or return;
    $cur->get_value;
}

sub set_current_value {
    my ($self, $val) = @_;

    defined $val or return $self->set_current(undef);

    my $new = $self->find_member($val);
    $self->set_current($new);
}

sub set_sensitive {
    my ($self, $val) = @_;
    $self->{sensitive} = $val;
    $_->set_sensitive($val) for @{$self->{members}};
    $val or $self->set_current(undef);
}

sub _do_activate {
    my ($self) = @_;
    my $cur = $self->get_current;
}

sub add_member {
    my ($self, $new) = @_;
    $new->isa("App::Jacana::Gtk2::RadioMember")
        or Carp::croak "'$new' is not a RadioMember";
    push @{$self->{members}}, $new;
    $new->set_group($self);
}

sub get_members { @{$_[0]->{members}} }

sub find_member {
    my ($self, $val) = @_;

    my @new = grep $_->get_value eq $val, @{$self->{members}};
    @new or return;
    @new > 1 and Carp::croak "Duplicate values ($val) for " .
        join ", ", map $_->get_name, @new;

    $new[0];
}


1;

