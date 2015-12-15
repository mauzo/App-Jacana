package App::Jacana::Dialog::Simple;

use utf8;
use App::Jacana::Moose;
use MooseX::Gtk2;

extends "App::Jacana::Dialog";

has title   => is => "ro";
has label   => is => "ro";

has _value => is => "lazy";
has value => is => "rw", gtk_prop => "_value.text";

sub _build__value {
    my ($self) = @_;
    Gtk2::Entry->new;
}

sub _build_content_area {
    my ($self, $vb) = @_;

    my $hb = Gtk2::HBox->new;
    $hb->pack_start(Gtk2::Label->new($self->label), 1, 1, 5);
    $hb->pack_start($self->_value, 1, 1, 5);

    $vb->pack_start($hb, 1, 1, 5);
}

1;
