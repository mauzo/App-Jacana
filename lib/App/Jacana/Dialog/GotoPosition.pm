package App::Jacana::Dialog::GotoPosition;

use utf8;
use Moo;
use MooX::MethodAttributes use => ["MooX::Gtk2"];

extends "App::Jacana::Dialog";
with    qw/ MooX::Gtk2 /;

has _pos => is => "lazy";
has pos => is => "rw", gtk_prop => "_pos::text";

sub title { "Goto…" }

sub _build__pos {
    my ($self) = @_;
    Gtk2::Entry->new;
}

sub _build_content_area {
    my ($self, $vb) = @_;

    my $hb = Gtk2::HBox->new;
    $hb->pack_start(Gtk2::Label->new("Position (qhdsq):"), 1, 1, 5);
    $hb->pack_start($self->_pos, 1, 1, 5);

    $vb->pack_start($hb, 1, 1, 5);
}

1;
