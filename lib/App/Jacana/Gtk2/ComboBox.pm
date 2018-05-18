package App::Jacana::Gtk2::ComboBox;

# This is a combobox which keeps a string key for each item, and returns
# it when asked. I should probably be doing some nonsense with a
# TreeModel or some such, but this is easier.

use warnings;
use strict;

use Gtk2;
use Glib::Object::Subclass 
    "Gtk2::ComboBox",
    properties => [
        Glib::ParamSpec->string(
            "current-value", "", "",
            undef,
            [qw"readable writable"],
        ),
    ],
    signals => {
        changed         => \&_do_changed,
        key_press_event => \&_do_keypress,
    };

sub INIT_INSTANCE {
    my ($self) = @_;

    # We have to call ->new, rather than ->new_text, or something goes
    # wrong with the gobject subclassing and we end up with a plain
    # GtkComboBox. So we need to do this here... <sigh>
    my $store = Gtk2::ListStore->new("Glib::String");
    $self->set_model($store);

    my $cell = Gtk2::CellRendererText->new;
    $self->pack_start($cell, 1);
    $self->set_attributes($cell, "text", 0);

    $self->{kton} = {};
    $self->{ntok} = [];
}

sub GET_PROPERTY {
    my ($self, $prop) = @_;
    my $name = $prop->get_name;

    $name eq "current_value" and return $self->get_current_value;
    Carp::croak "Bad ComboBox property '$name'";
}

sub SET_PROPERTY {
    my ($self, $prop, $new) = @_;
    my $name = $prop->get_name;

    $name eq "current_value" and return $self->set_current_value($new);
    Carp::croak "Bad ComboBox property '$name'";
}

sub get_current_value {
    my ($self) = @_;

    my $n = $self->get_active;
    $self->{ntok}[$n];
}

sub set_current_value {
    my ($self, $k) = @_;

    defined $k or return $self->set_active(-1);

    my $n = $self->{kton}{$k};
    defined $n or Carp::croak "$self doesn't have a '$k' entry";
    $self->set_active($n);
}

sub _do_changed {
    my ($self) = @_;
    $self->notify("current-value");
}

sub _do_keypress {
    my ($self, $event) = @_;
    my $key = Gtk2::Gdk->keyval_name($event->keyval);
    return;
}

sub add_pairs {
    my ($self, @pairs) = @_;

    my ($kton, $ntok)   = @$self{"kton", "ntok"};
    my $list            = $self->get_model;

    while (my ($k, $v) = splice @pairs, 0, 2) {
        my $n = @$ntok;
        push @$ntok, $k;
        $$kton{$k} = $n;
        $list->insert_with_values($n, 0, $v);
    }
}

sub set_values {
    my ($self, @v) = @_;

    my $list = $self->get_model;
    while (my ($n, $v) = each @v) {
        defined $v or next;
        $list->set($list->iter_nth_child(undef, $n), 0, $v);
    }
}

sub set_pairs {
    my ($self, %v) = @_;

    $self->set_values(@v{@{$self->{ntok}}});
}

1;
