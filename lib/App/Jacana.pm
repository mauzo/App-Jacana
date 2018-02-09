package App::Jacana;

=head1 NAME

App::Jacana - A GUI for editing Lilypond files

=cut

use utf8;
use 5.012;
use warnings;

our $VERSION = "4";

use App::Jacana::Moose;
use App::Jacana::Log;
use MooseX::Gtk2;

use App::Jacana::Document;
use App::Jacana::MIDI;
use App::Jacana::Resource;
use App::Jacana::Window;

use Gtk2;
use Gtk2::Ex::WidgetCursor;

use File::Path      ();
use File::ShareDir  ();
use Hash::Merge     ();
use POSIX           ();
use YAML::XS        ();

with qw/ 
    MooseX::Role::Signal
    MooseX::Role::WeakClosure
    App::Jacana::Has::App
/;

has "+app" => (
    required    => 0, 
    default     => sub { $_[0] },
);

has logfile => (
    is          => "ro",
    isa         => Str,
    required    => 1,
);

has _config => (
    is          => "ro",
    isa         => HashRef,
    default     => sub { +{} },
);

sub config {
    my ($self, $key) = @_;
    
    my $h = $self->_config;
    for (split /\./, $key) {
        $h = $h->{$_};
    }

    $h;
}

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
    App::Jacana::Window->new(copy_from => $self);
}

has midi        => is => "lazy", predicate => 1;
sub _build_midi { App::Jacana::MIDI->new(copy_from => $_[0]) }

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

sub load_config {
    my ($self, $file) = @_;

    my $c = $self->_config;
    my $n = YAML::XS::LoadFile $file;

    HashRef->check($n) or die "Invalid config file '$file'\n";
    %$c = %{ Hash::Merge::merge $n, $c };

    msg APP => "NEW CONFIG [$file]: ", $c;
}

sub _setup_logging {
    my ($self, $d) = @_;

    my @levels = $d 
        ? $d eq "-" 
            ? 1 
            : split /,/, $d
        : ();

    App::Jacana::Log::add_logger \*STDERR, @levels;
    App::Jacana::Log::resume_log;
}

sub connect_unix_signals {
    my ($self) = @_;

    $SIG{INFO} = $self->weak_closure(
        "signal_emit", sub { $SIG{INFO} = "DEFAULT" }, ["sig-info"]
    );
}

sub start {
    my ($self, $opts, @files) = @_;

    $self->_setup_logging($$opts{d});

    msg APP => "START APP";

    my $res = $self->resource;
    Gtk2::AccelMap->load($res->find_user_file("accelmap"));
    $self->load_config($_) for $res->find_all("config");
    
    my $w = $self->window;
    for (@files) {
        my $doc = App::Jacana::Document->open($_) or next;
        $w->add_tab($doc);
    }
    $w->show;

    Gtk2->main;

    $res->write_user_file("accelmap", sub {
        Gtk2::AccelMap->save_fd(fileno $_);
    });
    $res->write_user_file("config", sub {
        my $yaml = YAML::XS::Dump $self->_config;
        print { $_ } $yaml;
    });
}

1;

=head1 BUGS

Please report bugs to <L<bug-App-Jacana@rt.cpan.org>>.

=head1 AUTHOR

Ben Morrow <ben@morrow.me.uk>

=head1 COPYRIGHT

Copyright 2018 Ben Morrow.

Released under the 2-clause BSD licence.

