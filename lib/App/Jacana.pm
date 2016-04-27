package App::Jacana;

use utf8;
use 5.012;
use warnings;

our $VERSION = "0";

use App::Jacana::Moose;

use App::Jacana::Document;
use App::Jacana::MIDI;
use App::Jacana::Resource;
use App::Jacana::Window;

use Gtk2;
use Gtk2::Ex::WidgetCursor;

use File::ShareDir ();

with qw/ App::Jacana::Has::App /;

has args    => (
    is          => "ro",
    required    => 1,
);

has "+app" => (
    required    => 0, 
    default     => sub { $_[0] },
);

has resource => (
    is      => "ro",
    lazy    => 1,
    default => sub { App::Jacana::Resource->new(dist => "App-Jacana") },
);

sub busy  { Gtk2::Ex::WidgetCursor->busy }
sub yield { Gtk2::Gdk::Window->process_all_updates }

has window      => is => "lazy", clearer => 1;
sub _build_window {
    my ($self) = @_;

    my $args    = $self->args;
    my $doc     = @$args 
        ? App::Jacana::Document->open($$args[0])
        : App::Jacana::Document->new->empty_document;

    App::Jacana::Window->new(
        copy_from   => $self,
        doc         => $doc,
    );
}

has midi        => is => "lazy", predicate => 1;
sub _build_midi { App::Jacana::MIDI->new }

sub BUILD {
    my ($self) = @_;
    my $it      = Gtk2::IconTheme->get_default;
    my $icons   = File::ShareDir::dist_dir("App-Jacana") . "/icons";
    $it->prepend_search_path($icons);
}

sub DEMOLISH {
    my ($self) = @_;
    $self->clear_window;
}

sub start {
    my ($self) = @_;

    warn "START APP";

    my $res = $self->resource;
    Gtk2::AccelMap->load($res->find_user_file("accelmap"));
    
    $self->window->show;
    Gtk2->main;

    my $tmp = $res->write_user_file("accelmap");
    Gtk2::AccelMap->save_fd(fileno $tmp->fh);
}

1;
