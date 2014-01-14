package App::Jacana::View;

use 5.012;
use warnings;

use Gtk2;
use Moo;
use MooX::MethodAttributes;

use Hash::Util::FieldHash ();

with qw/ App::Jacana::HasApp MooX::Gtk2 /;

has doc         => is => "ro";

sub _refresh {
    my ($self) = @_;
    $self->widget->get_window->invalidate_rect(undef, 0);
}

has selected    => (
    is      => "rw",
    trigger => 1,
);

sub _trigger_selected {
    my ($self, $new) = @_;
    $self->_refresh;
}

has _playing    => (
    is      => "ro",
    lazy    => 1,
    default => sub {
        Hash::Util::FieldHash::idhash my %h;
        \%h;
    },
);

sub playing_on {
    my ($self, $note) = @_;
    $self->_playing->{$note} = 1;
    $self->_refresh;
}

sub playing_off {
    my ($self, $note) = @_;
    delete $self->_playing->{$note};
    $self->_refresh;
}

sub clear_playing {
    my ($self) = @_;
    undef %{$self->_playing};
    $self->_refresh;
}

has widget      => is => "lazy";

sub _build_widget {
    my $d = Gtk2::DrawingArea->new;
    $d->modify_bg("normal", Gtk2::Gdk::Color->new(65535, 65535, 65535));
    $d;
}

sub _expose_event :Signal {
    my ($self, $widget, $event) = @_;
    my $w = $widget->get_window;
    my ($wd, undef) = $w->get_size;
    my $c = Gtk2::Gdk::Cairo::Context->create($w);

    $c->set_antialias("gray");
    $c->scale(5, 5);

    for (2..6) {
        $c->move_to(0, 2*$_);
        $c->line_to($wd, 2*$_);
    }
    $c->set_line_width(0.1);
    $c->stroke;

    my $fn = $self->_resource("cairo_feta_font");
    $c->save;
        $c->set_font_face($fn);
        $c->set_font_size(8);
        $self->_show_music($c, $self->doc->music);
    $c->restore;
}

sub _show_music {
    my ($self, $c, $music) = @_;

    my $playing = $self->_playing;

    my $x = 4;
    for my $id (0..$#$music) {
        my $item = $$music[$id];
        my $pos = $item->position(7);

        $c->save;
        $c->translate($x, 8 - $pos);
        $c->move_to(0, 0);
        $playing->{$item}
            and $c->set_source_rgb(1, 0, 0);
        $item->draw($c);
        $x += $item->width($c) + 2;
        $c->restore;
    }
}

1;
