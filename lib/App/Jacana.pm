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

has resource => (
    is      => "ro",
    lazy    => 1,
    default => sub { App::Jacana::Resource->new(dist => "App-Jacana") },
);

has document    => is => "lazy";
sub _build_document {
    my ($self) = @_;
    my $doc = App::Jacana::Document->new;
    $doc->parse_music("a'4 g'4 c''4 d''8 g''8 e''4 d''8 g''8 e''4 " .
        "c''4 d''4 a'4 g'4 " .
        "c''4 c''8 c''16 c''32 c''64 c''128 " .
        "a'4 a'8 a'16 a'32 a'64 a'128 "
    );
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

sub start {
    my ($self) = @_;
    $self->window->show;
    Gtk2->main;
}

1;
