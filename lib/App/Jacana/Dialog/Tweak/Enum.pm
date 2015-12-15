package App::Jacana::Dialog::Tweak::Enum;

use App::Jacana::Moose;
use MooseX::Gtk2;

use App::Jacana::Gtk2::ComboBox;

extends "App::Jacana::Dialog::Tweak";

has "+value" => gtk_prop => "_value.current-value";

sub _build__value {
    my ($self) = @_;
    my $cb = App::Jacana::Gtk2::ComboBox->new;
    $cb->add_pairs(@{$self->tweak->{values}});
    $cb;
}

1;
