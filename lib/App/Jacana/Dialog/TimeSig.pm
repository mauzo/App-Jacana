package App::Jacana::Dialog::TimeSig;

use 5.012;
use Moo;
use MooX::AccessorMaker     apply => [qw/ 
    MooX::MakerRole::Coercer
/];
use MooX::MethodAttributes  use => [qw/
    MooX::Gtk2
/];

use App::Jacana::Gtk2::ComboBox;
use App::Jacana::Util::Types;

use Data::Dump      qw/pp/;
use Scalar::Util    qw/blessed/;

use namespace::clean;

extends "App::Jacana::Dialog";
with    qw/ 
    MooX::Gtk2
    App::Jacana::Has::Time
/;

package App::Jacana::Dialog::TimeSig::Partial {
    use Moo;
    with qw/ MooX::Gtk2 App::Jacana::Has::Length/;

    has dialog      => is => "ro", weak_ref => 1;
    has "+length"   => gtk_prop => "dialog._plen.current-value";
    has "+dots"     => gtk_prop => "dialog._pdots.current-value";
}

has _beats      => is => "lazy";
has _divisor    => is => "lazy";
has _plen       => is => "lazy";
has _pdots      => is => "lazy";
has _p_check    => is => "lazy";

has "+beats"    => (
    default     => 4,
    gtk_prop    => "_beats.text", 
    isa         => sub { 
        $_[0] eq "" || $_[0] =~ /^[0-9]+$/
            or Carp::croak "Bad beats: [$_[0]]";
    },
);
has "+divisor"  => (
    default     => 4,
    gtk_prop    => "_divisor.current-value"
);
has "+partial"  => (
    coercer     => 1, 
);

sub title   { "Time signature" }

sub BUILD {
    my ($self) = @_;
    if ($self->has_partial) {
        $self->_p_check->set_active(1);
    }
    else {
        $self->$_->set_sensitive(0) for qw/_plen _pdots/;
    }
}

sub _notify_p_check :Signal(_p_check.notify::active) {
    my ($self) = @_;
    my $active = $self->_p_check->get_active;

    if ($active) {
        $self->has_partial
            or $self->partial({length => 4, dots => 0});
    }
    else {
        $self->clear_partial;
    }
    $self->$_->set_sensitive($active) for qw/_plen _pdots/;
}

sub _coerce_partial {
    my ($self, $new) = @_;

    warn "Dialog::TimeSig: COERCE FROM: " . pp $new;
    App::Jacana::Dialog::TimeSig::Partial->new(
        %$new,
        dialog => $self,
    );
}

sub _build__beats { Gtk2::Entry->new }

sub _build__divisor {
    my $cb = App::Jacana::Gtk2::ComboBox->new;
    $cb->add_pairs(qw/1 1 2 2 4 4 8 8 16 16 32 32/);
    $cb;
}

sub _build__plen {
    my $cb = App::Jacana::Gtk2::ComboBox->new;
    $cb->add_pairs(qw/
        1 semibreve 2 minim 3 crotchet 4 quaver
        5 semiquaver 6 d.s.quaver 7 h.d.s.quaver
    /);
    $cb;
}

sub _build__pdots {
    my $cb = App::Jacana::Gtk2::ComboBox->new;
    $cb->add_pairs(qw/0 0 1 1 2 2/);
    $cb;
}

sub _build__p_check {
    Gtk2::CheckButton->new_with_label("Upbeat:");
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

    my $par = Gtk2::HBox->new;
    $par->pack_start($self->_p_check, 1, 0, 0);
    $par->pack_start($self->_plen, 1, 0, 0);
    $par->pack_start($self->_pdots, 1, 0, 0);
    $vb->pack_start($par, 1, 0, 0);
}

1;
