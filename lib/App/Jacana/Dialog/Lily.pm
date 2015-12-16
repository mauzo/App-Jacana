package App::Jacana::Dialog::Lily;

use utf8;
use App::Jacana::Moose;
use MooseX::Gtk2;

use Pango;

extends "App::Jacana::Dialog";
with    qw/ App::Jacana::Has::Lily /;

has buffer => is => "lazy";
has view   => is => "lazy";
has "+lily" => trigger => 1;

sub title { "Edit Lilypond code" }

sub _build_buffer { 
    Gtk2::TextBuffer->new;
}

# TextBuffer doesn't seem to properly emit notify::text, so I can't use
# gtk_prop. Do it manually instead.

our $recurse;

sub _trigger_lily {
    my ($self, $text) = @_;
    $recurse and return; local $recurse = 1;
    $self->buffer->set_text($text);
}

sub buffer_changed :Signal(buffer.changed) {
    my ($self) = @_;
    $recurse and return; local $recurse = 1;
    $self->lily($self->buffer->get_property("text"));
}

sub _build_view {
    my ($self) = @_;
    my $v = Gtk2::TextView->new_with_buffer($self->buffer);
    $v->set_accepts_tab(0);
    $v->modify_font(Pango::FontDescription->from_string("monospace 11"));
    $v;
}

sub _build_content_area {
    my ($self, $vb) = @_;

    $vb->pack_start(Gtk2::Label->new("Lilypond code:"), 1, 1, 5);
    $vb->pack_start($self->view, 1, 1, 5);
}

Moose::Util::find_meta(__PACKAGE__)->make_immutable;
