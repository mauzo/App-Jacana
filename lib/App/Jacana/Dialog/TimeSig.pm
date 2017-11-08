package App::Jacana::Dialog::TimeSig;

use 5.012;
use App::Jacana::Moose;
use MooseX::Gtk2;

use App::Jacana::Dialog::Widget::Length;
use App::Jacana::Gtk2::ComboBox;

use Data::Dump      qw/pp/;
use Scalar::Util    qw/blessed/;

use namespace::autoclean;

extends "App::Jacana::Dialog";
with    qw/ 
    App::Jacana::Has::Time
/;

has _beats      => is => "lazy";
has _divisor    => is => "lazy";
has _partial    => is => "lazy";
has _p_check    => is => "lazy";

has "+beats"    => (
    traits      => ["Gtk2"],
    default     => 4,
    gtk_prop    => "_beats.text", 
#    isa         => sub { 
#        $_[0] eq "" || $_[0] =~ /^[0-9]+$/
#            or Carp::croak "Bad beats: [$_[0]]";
#    },
);
has "+divisor"  => (
    traits      => ["Gtk2"],
    default     => 4,
    gtk_prop    => "_divisor.current-value"
);
has "+partial"  => isa => My "Dialog::Widget::Length", coerce => 1;

sub title   { "Time signature" }

sub BUILD {
    my ($self) = @_;

    if ($self->has_partial) {
        $self->_p_check->set_active(1);
        # Hmm hacky hacky hack
        # I think the signal isn't installed early enough
        $self->_notify_p_check;
    }
}

sub _notify_p_check :Signal(_p_check.notify::active) {
    my ($self) = @_;
    my $active  = $self->_p_check->get_active;
    my $part    = $self->_partial;

    if ($active) {
        $self->has_partial
            or $self->partial({length => 4, dots => 0});
        my $wid = $self->partial->widget;
        $part->add($wid);
        $part->show_all;
    }
    else {
        $part->remove($part->get_child);
        $self->clear_partial;
    }
}

sub _build__beats { Gtk2::Entry->new }

sub _build__divisor {
    my $cb = App::Jacana::Gtk2::ComboBox->new;
    $cb->add_pairs(qw/1 1 2 2 4 4 8 8 16 16 32 32/);
    $cb;
}

sub _build__p_check {
    Gtk2::CheckButton->new_with_label("Upbeat:");
}

sub _build__partial {
    my ($self) = @_;

    my $f   = Gtk2::Frame->new;
    $f->set_label_widget($self->_p_check);
    $f;
}

sub _build_content_area {
    my ($self, $vb) = @_;

    my $hb = Gtk2::HBox->new;
    $hb->pack_start(Gtk2::Label->new("Time signature:"), 1, 0, 0);

    my $ts = Gtk2::VBox->new;
    $ts->pack_start($self->_beats, 0, 0, 0);
    $ts->pack_start($self->_divisor, 0, 0, 0);
    $hb->pack_start($ts, 1, 0, 0);

    $vb->pack_start($hb, 1, 0, 0);
    $vb->pack_start($self->_partial, 1, 0, 0);
}

1;
