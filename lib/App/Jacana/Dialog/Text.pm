package App::Jacana::Dialog::Text;

use utf8;
use App::Jacana::Moose;
use MooseX::Gtk2;

use App::Jacana::Gtk2::ComboBox;

extends "App::Jacana::Dialog";
with    qw/
    App::Jacana::Dialog::Tweaks
    App::Jacana::Has::Markup
/;

has _text => is => "lazy";
has "+text" => (
    traits      => ["Gtk2"],
    gtk_prop    => "_text.text",
);

has _style => is => "lazy";
has "+style" => (
    traits      => ["Gtk2"],
    gtk_prop    => "_style.current-value",
);

sub title { $_[0]->src->dialog_title }

sub _build__text {
    my ($self) = @_;
    Gtk2::Entry->new;
}

sub _build__style {
    my ($self) = @_;
    my $cb = App::Jacana::Gtk2::ComboBox->new;
    $cb->add_pairs(qw/normal Normal italic Italic bold Bold/);
    $cb;
}

sub _build_content_area {
    my ($self, $vb) = @_;

    my $hb = Gtk2::HBox->new;
    $hb->pack_start(Gtk2::Label->new("Text:"), 1, 1, 5);
    $hb->pack_start($self->_text, 1, 1, 5);
    $vb->pack_start($hb, 1, 1, 5);

    $hb = Gtk2::HBox->new;
    $hb->pack_start(Gtk2::Label->new("Style:"), 1, 1, 5);
    $hb->pack_start($self->_style, 1, 1, 5);
    $vb->pack_start($hb, 1, 1, 5);

    $vb->pack_start($self->_tweaks_panel, 1, 1, 5);
}

1;
