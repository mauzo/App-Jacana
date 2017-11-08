package App::Jacana::Dialog::Tempo;

use App::Jacana::Moose;
use MooseX::Gtk2;

use App::Jacana::Dialog::Widget::Length;

use namespace::autoclean;

extends "App::Jacana::Dialog";
with    qw/ 
    App::Jacana::Has::Tempo
/;

has _beat       => is => "lazy";
has _bpm        => is => "lazy";

has "+beat" => (
    isa     => My "Dialog::Widget::Length",
    coerce  => 1,
    default => sub { +{ length => 3 } },
);
has "+bpm" => (
    traits      => ["Gtk2"],
    default     => 120,
    gtk_prop    => "_bpm.text",
);

sub title   { "Tempo" }

sub _build__beat {
    my ($self) = @_;
    $self->beat->widget;
}

sub _build__bpm { Gtk2::Entry->new }

sub _build_content_area {
    my ($self, $vb) = @_;

    my $hb = Gtk2::HBox->new;
    $hb->pack_start($self->_beat, 1, 0, 0);
    $hb->pack_start(Gtk2::Label->new("="), 1, 0, 0);
    $hb->pack_start($self->_bpm, 1, 0, 0);

    $vb->pack_start(Gtk2::Label->new("Tempo:"), 0, 0, 0);
    $vb->pack_start($hb, 0, 0, 0);
}

1;
