package App::Jacana;

use utf8;
use 5.012;
use warnings;

our $VERSION = "0";

use Moo;

use App::Jacana::Document;
use App::Jacana::MIDI;
use App::Jacana::Resource;
use App::Jacana::View;
use App::Jacana::Window;

use File::ShareDir ();

has resource => (
    is      => "ro",
    lazy    => 1,
    default => sub { App::Jacana::Resource->new(dist => "App-Jacana") },
);

sub yield { Gtk2::Gdk::Window->process_all_updates }

has document    => is => "lazy";
sub _build_document {
    my ($self) = @_;
    my $doc = App::Jacana::Document->new;
    $doc->parse_music(<<'LILY');
        ees'4 f'2 c''4 bes'2 g'4 ees'4 f'2 bes2 g4 c'2 d'4 g'4 f'2 bes'1.
LILY
    $doc;
}

has view        => is => "lazy";
sub _build_view {
    my ($self) = @_;
    App::Jacana::View->new(
        app => $self,
        doc => $self->document,
    );
}

has window      => is => "lazy";
sub _build_window {
    my ($self) = @_;
    App::Jacana::Window->new(
        app     => $self,
        view    => $self->view,
    );
}

has midi        => is => "lazy";
sub _build_midi { App::Jacana::MIDI->new }

sub BUILD {
    my ($self) = @_;
    my $it      = Gtk2::IconTheme->get_default;
    my $icons   = File::ShareDir::dist_dir("App-Jacana") . "/icons";
    $it->prepend_search_path($icons);
}

sub start {
    my ($self) = @_;

    my $res = $self->resource;
    Gtk2::AccelMap->load($res->find_user_file("accelmap"));

    $self->window->show;
    Gtk2->main;

    my $tmp = $res->write_user_file("accelmap");
    Gtk2::AccelMap->save_fd(fileno $tmp->fh);
}

1;
