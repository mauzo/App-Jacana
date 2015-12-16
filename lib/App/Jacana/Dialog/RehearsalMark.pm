package App::Jacana::Dialog::RehearsalMark;

use utf8;
use App::Jacana::Moose;
use MooseX::Gtk2;

extends "App::Jacana::Dialog";
with    qw/ App::Jacana::Has::RehearsalMark /;

has _automatic  => is => "lazy";
has _number     => is => "lazy";

has "+number"   => (
    traits      => ["Gtk2"],
    #isa         => Str,
    gtk_prop    => "_number.text",
);

sub title { "Rehearsal mark" }

# Hmmm
sub _build__automatic {
    my ($self) = @_;
    my $r = Gtk2::RadioButton->new_with_label(undef, "Automatic");
}

sub _automatic_changed :Signal(_automatic.toggled) {
    my ($self, $auto) = @_;
    my $active = $auto->get_active;
    $self->_number->set_sensitive(!$active);
    if ($active)    { $self->clear_number }
    else            { $self->has_number or $self->number(1) } 
}

sub _build__number {
    my ($self) = @_;
    my $e = Gtk2::Entry->new;
    $e->set_sensitive($self->has_number);
    $e;
}

sub _build_content_area {
    my ($self, $vb) = @_;

    my $auto    = $self->_automatic;
    # Hmmm
    my $manual  = Gtk2::RadioButton->new_with_label_from_widget(
        $auto, "Manual");

    $vb->pack_start($auto, 1, 1, 5);
    $vb->pack_start($manual, 1, 1, 5);
    $vb->pack_start($self->_number, 1, 1, 5);

    # this has to be here, as we've only just created the other button
    my $hn = $self->has_number;
    ($hn ? $manual : $auto)->set_active(1);
    my $ac = $auto->get_active;
    warn "AUTO ACTIVE [$ac] HAS NUMBER [$hn]";
}

1;
