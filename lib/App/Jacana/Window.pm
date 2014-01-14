package App::Jacana::Window;

use utf8;
use 5.012;
use warnings;

use Moo;
use MooX::MethodAttributes;

with qw/ App::Jacana::HasApp MooX::Gtk2 /;

has frame       => is => "lazy";
has status_bar  => is => "lazy";
has toolbar     => is => "lazy";
has view        => is => "ro";

# frame

sub _build_frame {
    my ($self) = @_;

    my $w = Gtk2::Window->new("toplevel");

    $w->set_title("Jacana");
    $w->set_default_size(400, 300);

    my $vb = Gtk2::VBox->new;
    $vb->pack_start($self->toolbar, 0, 0, 0);
    $vb->pack_start($self->view->widget, 1, 1, 0);
    $vb->pack_start($self->status_bar, 0, 0, 0);

    $w->add($vb);
    $w;
}

sub _destroy_frame :Signal(frame::destroy) { 
    Gtk2->main_quit;
}

# toolbar

sub _build_toolbar {
    my ($self) = @_;
    my $bar = Gtk2::Toolbar->new;
    my $but = Gtk2::ToolButton->new_from_stock("gtk-media-play");
    $but->signal_connect("clicked", sub { $self->_play_music });
    $bar->insert($but, -1);
    $bar;
}

sub _play_music {
    my ($self) = @_;
    my $app     = $self->app;
    my $view    = $self->view;

    $self->set_status("playing");

    $app->midi->play_music(
        $app->document->music,
        sub { $view->playing_on($_[0]) },
        sub { $view->playing_off($_[0]) },
        sub { 
            $self->set_status("");
        },
    );
}

# status bar

sub _build_status_bar { 
    my ($self) = @_;
    my $b = Gtk2::Statusbar->new;
    $b->push(0, "loading…");
    $b;
}

sub set_status {
    my ($self, $msg) = @_;
    my $b = $self->status_bar;
    $b->pop(0);
    $b->push(0, $msg);
}

# show

sub show {
    my ($self) = @_;
    $self->frame->show_all;
}

1;
