package App::Jacana::View;

use utf8;
use Gtk2;
use Moo;
use MooX::MethodAttributes
    use     => [qw/ MooX::Gtk2 /];

use App::Jacana::Cursor;
use App::Jacana::DrawCtx;

use Data::Dump              qw/pp/;
use Hash::Util::FieldHash   qw/idhash/;
use List::Util              qw/max/;
use Module::Runtime         qw/use_module/;
use Scalar::Util            qw/blessed/;

use namespace::clean;

with qw/ 
    MooX::Gtk2
    App::Jacana::HasApp
    App::Jacana::HasActions
    App::Jacana::HasZoom
    App::Jacana::HasWindow
/;

# XXX This is wrong: in the SDI model I should be creating a new View
# when we open a new document.
has doc         => is => "rw";
has cursor      => is => "lazy";

sub _build_cursor { 
    App::Jacana::Cursor->new(
        view        => $_[0],
        position    => $_[0]->doc->music->[0],
        note        => "c", 
        octave      => 1
    );
}

has "+zoom"    => default => 4, trigger => 1;

sub _trigger_zoom { $_[0]->refresh }

has _midi_id    => is => "rw";
has _playing    => (
    is      => "ro",
    lazy    => 1,
    default => sub { idhash my %h; \%h },
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
    $self->set_status("");
    $self->refresh;
}

sub BUILD {
    my ($self) = @_;
    $self->get_action("MidiStop")->set_sensitive(0);
}

sub save_as :Action(SaveAs) {
    my ($self)  = @_;
    my $doc     = $self->doc;

    my $dlg = Gtk2::FileChooserDialog->new(
        "Save as…", $self->_window->frame, "save",
        Cancel => "cancel", OK => "ok",
    );
    $doc->has_filename and $dlg->set_filename($doc->filename);
    $dlg->run eq "ok" or $dlg->destroy, return;
    $doc->filename($dlg->get_filename);
    $dlg->destroy;
    $doc->save;
}

sub save :Action(Save) {
    my ($self)  = @_;
    my $doc     = $self->doc;

    $doc->has_filename or return $self->save_as;
    $doc->save;
}

sub open :Action(Open) {
    my ($self) = @_;

    my $dlg = Gtk2::FileChooserDialog->new(
        "Open…", $self->_window->frame, "open",
        Cancel => "cancel", OK => "ok",
    );
    $dlg->run eq "ok" or $dlg->destroy, return;
    my $doc = App::Jacana::Document->open($dlg->get_filename);
    $dlg->destroy;

    $self->doc($doc);
    $self->cursor->position($doc->music->[0]);
}

sub midi {
    my ($self) = @_;

    $self->set_busy("Initialising MIDI…");
    my $midi = $self->app->midi;
    $midi;
}

sub _play_music {
    my ($self, $time) = @_;

    $self->get_action("MidiPlay")->set_sensitive(0);
    $self->get_action("MidiPlayHere")->set_sensitive(0);
    my $midi = $self->midi;

    $self->set_status("Playing");
    my $id = $midi->play_music(
        $self->doc->music, $time,
        $self->weak_method("playing_on"),
        $self->weak_method("playing_off"),
        $self->weak_method("_stop_playing"),
    );
    $self->_midi_id($id);
    $self->get_action("MidiStop")->set_sensitive(1);
}

sub _play_all :Action(MidiPlay) { $_[0]->_play_music(0) }
sub _play_here :Action(MidiPlayHere) {
    my ($self) = @_;
    my $pos = $self->cursor->position;
    my $dur = $pos->DOES("App::Jacana::HasLength") ? $pos->duration : 0;
    $self->_play_music($pos->get_time - $dur + 1);
}

sub _stop_playing :Action(MidiStop) {
    # don't rely on getting passed the action
    my ($self) = @_;

    my $id = $self->_midi_id;
    $id and $self->midi->remove_active($id);
    $self->_midi_id(undef);
    $self->clear_playing;

    $self->get_action("MidiStop")->set_sensitive(0);
    $self->get_action("MidiPlay")->set_sensitive(1);
    $self->get_action("MidiPlayHere")->set_sensitive(1);
}

has widget      => is => "lazy";

sub _build_widget {
    my $d = Gtk2::DrawingArea->new;
    $d->modify_bg("normal", Gtk2::Gdk::Color->new(65535, 65535, 65535));

    $d;
}

sub _realize :Signal {
    my ($self, $widget) = @_;

    my $w = $widget->get_window;
    my $e = $w->get_events;
    $e |= "button-press-mask";
    $w->set_events($e);
}

sub refresh {
    my ($self) = @_;
    $self->widget->get_window->invalidate_rect(undef, 0);
}

sub _expose_event :Signal {
    my ($self, $widget, $event) = @_;

    my $c = App::Jacana::DrawCtx->new(
        copy_from   => $self,
        widget      => $widget,
    );

    my ($wd, $ht) = $self->_show_music($c);

    my ($x1, $y1) = $c->c->user_to_device(0, 0);
    my ($x2, $y2) = $c->c->user_to_device($wd, $ht);
    $widget->set_size_request($x2 - $x1, $y2 - $y1);
}

sub _show_music {
    my ($self, $c) = @_;

    my $voices  = $self->doc->music;
    my $wd      = 0;

    for my $n (0..$#$voices) {
        my $v = $$voices[$n];

        $c->reset;
        $c->save;
            $c->translate(0, 24*$n + 12);
            $self->_show_stave($c);
            $wd = max $wd, $self->_show_voice($c, $v);
        $c->restore;
    }

    ($wd, 24*@$voices);
}

sub _show_stave {
    my ($self, $c) = @_;

    $c->save;
        for (-2..2) {
            $c->move_to(0, 2*$_);
            $c->line_to($c->width, 2*$_);
        }
        $c->set_line_width(0.1);
        $c->stroke;
    $c->restore;
}

sub _show_voice {
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
        }

        my $pos = $item->staff_line($centre);
        $c->save;
            $c->translate($x, -$pos);
            $c->move_to(0, 0);
            $item == $curpos
                and $c->set_source_rgb(0, 0, 1);
            $playing->{$item}
                and $c->set_source_rgb(1, 0, 0);
            $x += $item->draw($c, $pos) + 2;
        $c->restore;

        $mode eq "insert" && $item == $curpos 
            and $self->_show_cursor($c, $x - 1, $centre);

        $c->add_to_bar($x, $item)
            and $x += $self->_show_barline($c, $x);

        $item->is_list_end and last;
        $item = $item->next;
    }

    return $x;
}

sub _show_barline {
    my ($self, $c, $x) = @_;

    $c->save;
        $c->bar_length and $c->set_source_rgb(0.9, 0, 0);
        $c->set_line_width(0.5);
        $c->set_line_cap("butt");
        $c->move_to($x + 1, -4);
        $c->line_to($x + 1, 4);
        $c->stroke;
    $c->restore;
    return 3;
}

sub _show_cursor {
    my ($self, $c, $x, $centre) = @_;

    $c->save;
        $c->move_to($x, -6);
        $c->line_to($x, +6);
        $c->set_line_width(0.7);
        $c->set_line_cap("round");
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

sub _adjust_zoom {
    my ($self, $by) = @_;
    $self->zoom($self->zoom * $by);
}

sub _zoom_in  :Action(ZoomIn)  { $_[0]->_adjust_zoom(1.2)   }
sub _zoom_out :Action(ZoomOut) { $_[0]->_adjust_zoom(1/1.2) }
sub _zoom_off :Action(ZoomOff) { $_[0]->zoom(4) }

sub _scroll_event :Signal {
    my ($self, $widget, $event) = @_;
    
    $event->state == "control-mask" or return;
    $self->_adjust_zoom($event->direction eq "up" ? 1.2 : 1/1.2);
}

sub run_dialog {
    my ($self, $which, $copy, @args) = @_;

    my $dlg = use_module("App::Jacana::Dialog::$which")
        ->new(copy_from => $self, @args);
    $copy and $dlg->copy_from($copy);
    $dlg->run eq "ok" or return;
    $dlg;
}

1;
