package App::Jacana::Dialog::MIDI::Transpose;

use 5.012;
use utf8;
use App::Jacana::Moose;
use MooseX::Gtk2;

use App::Jacana::Gtk2::ComboBox;

use namespace::autoclean;

extends "App::Jacana::Dialog";
with qw/
    App::Jacana::Has::MidiTranspose
/;

has _note   => is => "lazy";
has _chroma => is => "lazy";
has _octave => is => "lazy";

has "+into" => (
    traits  => ["Coercer"],
    builder => "_coerce_into",
);

package App::Jacana::Dialog::MIDI::Transpose::Pitch {
    use App::Jacana::Moose;
    use MooseX::Gtk2;

    with qw/App::Jacana::Has::Pitch/;

    has dialog => is => "ro", weak_ref => 1, required => 1;
    has "+note" => (
        traits      => ["Gtk2"],
        gtk_prop    => "dialog._note.current-value",
        default     => "c",
    );
    has "+chroma" => (
        traits      => ["Gtk2"],
        gtk_prop    => "dialog._chroma.current-value",
        default     => 0,
    );
    has "+octave" => (
        traits      => ["Gtk2"],
        gtk_prop    => "dialog._octave.value",
        default     => 0,
    );

    1;
}

my $Pitch = "App::Jacana::Dialog::MIDI::Transpose::Pitch";

sub title { "Transposition" }

sub _coerce_into {
    my ($self, $new) = @_;
    $Pitch->new(%$new, dialog => $self);
}

sub _build__note {
    my $cb = App::Jacana::Gtk2::ComboBox->new;
    $cb->add_pairs(qw/c C d D e E f F g G a A b B/);
    $cb;
}

sub _build__chroma {
    my $cb = App::Jacana::Gtk2::ComboBox->new;
    $cb->add_pairs(qw/1 ♯ 0 ♮ -1 ♭/);
    $cb;
}

sub _build__octave {
    Gtk2::SpinButton->new_with_range(-2, 2, 1);
}

sub _build_content_area {
    my ($self, $vb) = @_;

    my $hb = Gtk2::HBox->new;
    $hb->pack_start($self->_note, 1, 0, 0);
    $hb->pack_start($self->_chroma, 1, 0, 0);
    $hb->pack_start($self->_octave, 1, 0, 0);

    $vb->pack_start($hb, 1, 0, 0);
}

1;
