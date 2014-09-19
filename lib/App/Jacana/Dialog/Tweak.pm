package App::Jacana::Dialog::Tweak;

use Moo;

use App::Jacana::Util::Types;

with    qw/ MooX::Gtk2 /;

has tweak => (
    is          => "ro",
    isa         => HashRef,
    predicate   => 1,
);
has exists => is => "ro";
has value => (
    is          => "rw",
    gtk_prop    => "_value.text",
);
has _value => is => "lazy";

sub _build__value { Gtk2::Entry->new }

1;
