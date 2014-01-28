package App::Jacana::View;

use 5.012;
use warnings;

use Gtk2;
use Moo;
use MooX::MethodAttributes
    use     => [qw/ MooX::Gtk2 /];

use App::Jacana::Cursor;
use App::Jacana::DrawCtx;

use Hash::Util::FieldHash ();

with qw/ 
    MooX::Gtk2
    App::Jacana::HasApp
    App::Jacana::HasActions
    App::Jacana::HasWindow
/;

has doc         => is => "ro";
has cursor      => is => "lazy";

sub _build_cursor { 
    App::Jacana::Cursor->new(
        view        => $_[0],
        position    => $_[0]->doc->music,
        note        => "c", 
        octave      => 1
    );
}

sub refresh {
    my ($self) = @_;
    $self->widget->get_window->invalidate_rect(undef, 0);
}

has selected    => (
    is      => "rw",
    trigger => 1,
);

sub _trigger_selected {
    my ($self, $new) = @_;
    $self->refresh;
}

has _playing    => (
    is      => "ro",
    lazy    => 1,
    default => sub {
        Hash::Util::FieldHash::idhash my %h;
        \%h;
    },
);

sub playing_on {
    my ($self, $note) = @_;
    $self->_playing->{$note} = 1;
    $self->refresh;
}

sub playing_off {
    my ($self, $note) = @_;
    delete $self->_playing->{$note};
    $self->refresh;
}

sub clear_playing {
    my ($self) = @_;
    undef %{$self->_playing};
    $self->refresh;
}

has widget      => is => "lazy";

sub _build_widget {
    my $d = Gtk2::DrawingArea->new;
    $d->modify_bg("normal", Gtk2::Gdk::Color->new(65535, 65535, 65535));
    $d;
}

sub _expose_event :Signal {
    my ($self, $widget, $event) = @_;

    my $c = App::Jacana::DrawCtx->new(
        copy_from   => $self,
        widget      => $widget,
    );

    $self->_show_stave($c);
    $c->save;
        $self->_show_music($c, $self->doc->music);
    $c->restore;
}

sub _show_stave {
    my ($self, $c) = @_;

    $c->save;
        for (4..8) {
            $c->move_to(0, 2*$_);
            $c->line_to($c->width, 2*$_);
        }
        $c->set_line_width(0.1);
        $c->stroke;
    $c->restore;
}

sub _show_music {
    my ($self, $c, $item) = @_;
    no warnings "uninitialized";

    my $playing = $self->_playing;
    my $ftfont  = $self->_resource("feta_font");
    my $cursor  = $self->cursor;
    my $curpos  = $cursor->position;
    my $mode    = $cursor->mode;
    my $centre;

    my $x = 4;

    for (;;) {
        if ($item->DOES("App::Jacana::HasClef")) {
            $centre = $item->centre_line($centre);
            $c->clef($item);
        }
        $item->DOES("App::Jacana::HasKey")
            and $c->key($item);
        my $pos = $item->staff_line($centre);
        $c->save;
            $c->translate($x, 12 - $pos);
            $c->move_to(0, 0);
            $item == $curpos
                and $c->set_source_rgb(0, 0, 1);
            $playing->{$item}
                and $c->set_source_rgb(1, 0, 0);
            $x += $item->draw($c, $pos) + 2;
        $c->restore;

        $mode eq "insert" && $item == $curpos 
            and $self->_show_cursor($c, $x - 1, $centre);

        $item->is_list_end and last;
        $item = $item->next;
    }

    return $x;
}

sub _show_cursor {
    my ($self, $c, $x, $centre) = @_;

    $c->save;
        $c->move_to($x, 7);
        $c->line_to($x, 17);
        $c->set_line_width(0.7);
        $c->set_line_cap("round");
        $c->stroke;
    $c->restore;

    my $curs = 12 - $self->cursor->staff_line($centre);
    $c->save;
        $c->set_source_rgb(0, 0, 1);
        $c->move_to($x - 1.5, $curs);
        $c->line_to($x + 1.5, $curs);
        $c->set_line_width(1);
        $c->set_line_cap("butt");
        $c->stroke;
    $c->restore;
}

sub _show_lily :Action(ToLily) {
    my ($self, $action) = @_;
    my $lily = $self->doc->music->to_lily;
    my $dlg = Gtk2::MessageDialog->new_with_markup(
        $self->_window->frame,
        "modal", "info", "close", "<tt>$lily</tt>"
    );
    $dlg->run;
    $dlg->destroy;
}

1;
