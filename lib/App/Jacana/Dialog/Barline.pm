package App::Jacana::Dialog::Barline;

use utf8;
use App::Jacana::Moose;
use MooseX::Gtk2;

use App::Jacana::Gtk2::ComboBox;

extends "App::Jacana::Dialog";
with    qw/ 
    App::Jacana::Has::Barline
/;

has _barline    => is => "lazy";

has "+barline" => (
    traits      => ["Gtk2"],
    default     => "|.",
    gtk_prop    => "_barline.current-value",
);

sub title { "Barline" }

sub _build__barline {
    my ($self) = @_;
    my $bl = App::Jacana::Gtk2::ComboBox->new;
    $bl->add_pairs(map +($_, $_), $self->barline_types);
    $bl;
}

sub _build_content_area {
    my ($self, $vb) = @_;

    my $hb = Gtk2::HBox->new;
    $hb->pack_start(Gtk2::Label->new("Barline:"), 1, 1, 5);
    $hb->pack_start($self->_barline, 1, 1, 0);

    $vb->pack_start($hb, 1, 1, 5);
}
    
1;
