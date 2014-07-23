package App::Jacana::Dialog::KeySig;

use utf8;
use Moo;
use MooX::MethodAttributes use => ["MooX::Gtk2"];

use App::Jacana::Gtk2::ComboBox;

extends "App::Jacana::Dialog";
with    qw/ 
    MooX::Gtk2 
    App::Jacana::Has::Key
/;

has _key  => is => "lazy";
has _mode => is => "lazy";

has "+key"  => (
    default     => 0,
    gtk_prop    => "_key.current-value",
);
has "+mode" => (
    #default     => "major",
    gtk_prop    => "_mode.current-value", 
    trigger => 1,
);

# grr, defaults don't trigger triggers
sub BUILD { $_[0]->mode or $_[0]->mode("major") }

sub title { "Key signature" }

sub _build__key {
    my $key = App::Jacana::Gtk2::ComboBox->new;
    $key->add_pairs(map +($_, $_), -7..7);
    $key->set_current_value(0);
    $key;
}

sub _build__mode {
    my $mode = App::Jacana::Gtk2::ComboBox->new;
    $mode->add_pairs(qw/
        major major minor minor
    /);
    $mode->set_current_value("major");
    $mode;
}

sub _trigger_mode {
    my ($self, $new) = @_;

    my @keys = 
        map uc, map s/es$/♭/r, map s/is$/♯/r,
        $self->_keys_for_mode($new);
    $self->_key->set_values(@keys);
}

sub _build_content_area {
    my ($self, $vb) = @_;

    my $hb = Gtk2::HBox->new;
    $hb->pack_start(Gtk2::Label->new("Key:"), 1, 1, 5);
    $hb->pack_start($self->_key, 1, 1, 0);
    $hb->pack_start($self->_mode, 1, 1, 5);

    $vb->pack_start($hb, 1, 1, 5);
}
    
1;
