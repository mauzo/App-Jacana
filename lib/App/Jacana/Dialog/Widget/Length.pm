package App::Jacana::Dialog::Widget::Length;

use utf8;

use App::Jacana::Moose;
use MooseX::Gtk2;

use App::Jacana::Gtk2::ComboBox;

use namespace::autoclean;

with qw/ App::Jacana::Has::Length/;

has dialog      => is => "ro", weak_ref => 1;
has "+length"   => (
    traits      => ["Gtk2"],
    gtk_prop    => "_length.current-value",
);
has "+dots"     => (
    traits      => ["Gtk2"],
    gtk_prop    => "_dots.current-value",
);

has _length => is => "lazy";
has _dots   => is => "lazy";

has widget  => is => "lazy";

sub _build__length {
    my $cb = App::Jacana::Gtk2::ComboBox->new;
    $cb->add_pairs(qw/
        1 semibreve 2 minim 3 crotchet 4 quaver
        5 semiquaver 6 d.s.quaver 7 h.d.s.quaver
    /);
    $cb;
}

sub _build__dots {
    my $cb = App::Jacana::Gtk2::ComboBox->new;
    $cb->add_pairs("0", " ", qw/1 · 2 ··/);
    $cb;
}

sub _build_widget {
    my ($self) = @_;

    my $hbox = Gtk2::HBox->new;
    $hbox->pack_start($self->_length, 1, 0, 0);
    $hbox->pack_start($self->_dots, 1, 0, 0);

    $hbox;
}

1;
