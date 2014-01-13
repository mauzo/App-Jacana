package App::Jacana::Window;

use utf8;
use 5.012;
use warnings;

use Moo;
use MooX::MethodAttributes;

with qw/ App::Jacana::HasApp MooX::Gtk2 /;

has frame       => is => "lazy";
has status_ctx  => is => "rw";
has status_bar  => is => "lazy";
has view        => is => "ro";

# frame

sub _build_frame {
    my ($self) = @_;

    my $w = Gtk2::Window->new("toplevel");

    $w->set_title("Jacana");
    $w->set_default_size(400, 300);

    my $vb = Gtk2::VBox->new;
    $vb->pack_start($self->view->widget, 1, 1, 0);
    $vb->pack_start($self->status_bar, 0, 0, 0);

    $w->add($vb);
    $w;
}

sub _destroy_frame :Signal(frame::destroy) { 
    Gtk2->main_quit;
}

# status bar

sub _build_status_bar { 
    my ($self) = @_;
    my $b = Gtk2::Statusbar->new;
    my $ctx = $b->get_context_id("main status");
    $self->status_ctx($ctx);
    $b->push($ctx, "loading…");
    $b;
}

sub show {
    my ($self) = @_;
    $self->frame->show_all;
}

1;
