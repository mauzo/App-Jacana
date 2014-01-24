package App::Jacana;

use utf8;
use 5.012;
use warnings;

our $VERSION = "0";

use Moo;

use App::Jacana::Document;
use App::Jacana::MIDI;
use App::Jacana::Resource;
use App::Jacana::Window;

use File::ShareDir ();

with qw/ App::Jacana::HasApp /;

has "+app" => (
    required    => 0, 
    default     => sub { $_[0] },
);

has resource => (
    is      => "ro",
    lazy    => 1,
    default => sub { App::Jacana::Resource->new(dist => "App-Jacana") },
);

sub yield { Gtk2::Gdk::Window->process_all_updates }

has window      => is => "lazy";
sub _build_window {
    my ($self) = @_;

    my $doc = App::Jacana::Document->new;
    $doc->parse_music(<<'LILY');
        \clef tenor ees4 f2 c'4 bes2 g4 ees4 f2
        \clef bass bes,2 g,4 c2 d4 g4 f2 bes1.
LILY

    App::Jacana::Window->new(
        copy_from   => $self,
        doc         => $doc,
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
