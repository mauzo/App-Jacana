package App::Jacana::View;

use 5.012;
use utf8;
use Gtk2;
use App::Jacana::Moose;
use MooseX::Gtk2;

use App::Jacana::Cursor;
use App::Jacana::View::Render;

use Data::Dump              qw/pp/;
use Hash::Util::FieldHash   qw/idhash/;
use List::Util              qw/min max first/;
use Module::Runtime         qw/use_module/;
use POSIX                   qw/ceil/;
use Scalar::Util            qw/blessed/;

use namespace::autoclean;

with qw/ 
    App::Jacana::Has::App
    App::Jacana::Has::Actions
    App::Jacana::Has::Zoom
    App::Jacana::Has::Window
/;

# XXX This is wrong: in the SDI model I should be creating a new View
# when we open a new document.
has doc         => is => "rw";
has cursor      => is => "lazy", predicate => 1, clearer => 1;

has clip => (
    is          => "rw",
    predicate   => 1,
    clearer     => 1,
    #isa         => Music,
);

has "+zoom" => default => 3, trigger => 1;

has renderer => is => "lazy";#, isa => InstanceOf[My "View::Render"];

has _midi_id    => is => "rw";
has _speed      => is => "rw", default => 12;
has _playing    => (
    is      => "ro",
    lazy    => 1,
    default => sub { +[] },
);

# Must come after 'cursor' attribute
with qw/App::Jacana::View::Region/;

sub _build_cursor { 
    App::Jacana::Cursor->new(
        view        => $_[0],
        position    => $_[0]->doc->next_movement->next_voice,
        note        => "c", 
        octave      => 1
    );
}

sub _trigger_zoom { $_[0]->refresh }

sub playing_on {
    my ($self, $note) = @_;
    push @{$self->_playing}, $note;
    $self->redraw;
}

sub playing_off {
    my ($self, $note) = @_;
    my $pl = $self->_playing;
    @$pl = grep $_ != $note, @$pl;
    $self->redraw;
}

sub clear_playing {
    my ($self) = @_;
    @{$self->_playing} = ();
    $self->set_status("");
    $self->redraw;
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
    my $file = $dlg->get_filename;
    $doc->filename($file);
    $dlg->destroy;
    $doc->save;
    $self->status_flash("Saved as '$file'.");
    $self->reset_title;
}

sub save :Action(Save) {
    my ($self)  = @_;
    my $doc     = $self->doc;

    my $file = $doc->filename or return $self->save_as;
    $doc->save;
    $self->status_flash("Saved '$file'.");
}

sub _open_doc {
    my ($self, $title) = @_;

    my $dlg = Gtk2::FileChooserDialog->new(
        "$title…", $self->_window->frame, "open",
        Cancel => "cancel", OK => "ok",
    );
    $dlg->run eq "ok" or $dlg->destroy, return;
    my $doc = App::Jacana::Document->open($dlg->get_filename);
    $dlg->destroy;

    $doc;
}

sub open :Action(Open) {
    my ($self) = @_;

    my $doc = $self->_open_doc("Open") or return;

    $self->doc($doc);
    $self->reset_title;
    $self->clear_mark;
    $self->clear_cursor;
}

sub file_new :Action(New) {
    my ($self) = @_;

    my $doc = App::Jacana::Document->new;
    $self->doc($doc);
    $self->clear_mark;
    $self->cursor->position($doc->music->[0]);
    $self->reset_title;
}

sub file_import :Action(Import) {
    my ($self) = @_;

    my $from    = $self->_open_doc("Import") or return;
    $from->is_movement_end and return;

    my $doc     = $self->doc;
    my $mvmt    = $from->next_movement;

    $mvmt->remove_movement($from->prev_movement);
    $doc->prev_movement->insert_movement($mvmt);
}

sub midi {
    my ($self) = @_;

    my $app = $self->app;
    $app->has_midi or $self->set_busy("Initialising MIDI…");
    $app->midi;
}

sub _play_music {
    my ($self, $time) = @_;

    $self->get_action("MidiPlay")->set_sensitive(0);
    $self->get_action("MidiPlayHere")->set_sensitive(0);
    my $midi = $self->midi;

    $self->set_status("Playing");
    my $id = $midi->play_music(
        music   => $self->cursor->movement,
        speed   => $self->_speed,
        time    => $time,
        start   => $self->weak_method("playing_on"),
        stop    => $self->weak_method("playing_off"),
        finish  => $self->weak_method("stop_playing"),
    );
    $self->_midi_id($id);
    $self->get_action("MidiStop")->set_sensitive(1);
}

sub _play_all :Action(MidiPlay) { $_[0]->_play_music(0) }
sub _play_here :Action(MidiPlayHere) {
    my ($self) = @_;
    my $pos = $self->cursor->position;
    my $dur = $pos->DOES("App::Jacana::Has::Length") ? $pos->duration : 0;
    $self->_play_music($pos->get_time - $dur + 1);
}

sub stop_playing :Action(MidiStop) {
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

sub _set_speed :Action(MidiSpeed) {
    my ($self) = @_;

    my $dlg = $self->run_dialog("Simple", undef, 
        title   => "Playback speed",
        label   => "Playback speed",
        value   => $self->_speed,
    ) or return;
    $self->_speed($dlg->value);
}

has widget      => is => "lazy";

sub _build_widget {
    my $d = Gtk2::DrawingArea->new;
    $d->modify_bg("normal", Gtk2::Gdk::Color->new(65535, 65535, 65535));

    $d;
}

has scrolled    => is => "lazy";

sub _build_scrolled {
    my ($self) = @_;

    my $scr = Gtk2::ScrolledWindow->new;
    $scr->set_policy("automatic", "automatic");
    $scr->add_with_viewport($self->widget);
    $scr;
}

sub scroll_to_cursor {
    my ($self) = @_;

    $self->has_cursor                   or return;
    my $item = $self->cursor->position  or return;

    my $scr = $self->scrolled;
    my $vaj = $scr->get_vadjustment;
    my $bbx = $item->bbox;

    unless ($bbx && @$bbx) {
        $self->renderer->render_upto(sub {
            $bbx = $item->bbox;
            $bbx && @$bbx;
        });
        $bbx && @$bbx and Glib::Idle->add(sub {
            $self->scroll_to_cursor;
            return;
        });
        return;
    }
    $vaj->clamp_page($$bbx[1] - 6, $$bbx[3] + 6);
}

sub clip_cut :Action(Cut) {
    my ($self) = @_;

    my ($start, $end) = $self->find_region or return;
    $_->break_ambient for $start, $end;
    my $pos = $self->cursor->position($start->remove($end));
    $pos->break_ambient;
    $self->clear_mark;
    $self->clip($start);
    $self->refresh;
}

sub clip_copy :Action(Copy) {
    my ($self) = @_;
    my ($start, $end) = $self->find_region or return;
    $self->clip($start->clone_music($end));
}

sub clip_paste :Action(Paste) {
    my ($self) = @_;

    my $clip = $self->clip or do {
        $self->status_flash("Nothing on the clipboard.");
        return;
    };
    $self->clear_clip;
    my $curs = $self->cursor;
    my $new = $curs->position->insert($clip);
    $new->break_ambient;
    $self->mark($clip);
    $curs->position($new);
    $self->refresh;
}

sub _realize :Signal {
    my ($self, $widget) = @_;

    my $w = $widget->get_window;
    my $e = $w->get_events;
    $e |= ["button-press-mask", "button-release-mask"];
    $w->set_events($e);

    $widget->set_size_request(100, 100);
}

sub refresh {
    my ($self) = @_;
    $self->renderer->clear_lines;
    $self->redraw;
}

sub redraw {
    $_[0]->widget->get_window->invalidate_rect(undef, 0);
}

sub _build_renderer {
    my ($self) = @_;
    my $w = $self->widget->get_allocation;
    $w = $w ? $w->width : 100;
    warn "BUILDING RENDERER [$w]";
    My("View::Render")->new(view => $self, width => $w);
}

sub _size_allocate :Signal {
    my ($self, $widget, $rect) = @_;
    my $rnd = $self->renderer;
    my $new = $rect->width;
    $new == $rnd->width and return;
    warn "SIZE ALLOCATE [$new]";
    $rnd->width($new);
}

sub _expose_event :Signal {
    my ($self, $widget, $event) = @_;

    my $rct = $event->area;
    my $top = $rct->y;
    my $bot = $top + $rct->height;
    my $c   = Gtk2::Gdk::Cairo::Context->create($widget->get_window);
    my $rnd = $self->renderer;

    $rnd->render_upto(sub { $_[0]->bottom >= $bot });
    $self->_show_highlights($c);
    my $ht = $rnd->show_lines($c, $top, $bot);
    $self->_show_cursor($c);

    $widget->set_size_request(100, $ht);
}

sub _show_highlights {
    my ($self, $c) = @_;

    my $curs = $self->cursor;
    for (
        ($curs->mode eq "edit" ? [0, 0, 1, $curs->position] : ()),
        [0, 1, 0, $self->mark],
        map([1, 0, 0, $_], @{$self->_playing}),
    ) {
        my ($r, $g, $b, $item) = @$_;
        $item or next;
        my $bbox = $item->bbox or next;
        $c->save;
        $c->set_source_rgba($r, $g, $b, 0.1);
        $c->rectangle(
            $$bbox[0], $$bbox[1],
            $$bbox[4] - $$bbox[0], $$bbox[3] - $$bbox[1],
        );
        $c->fill;
        $c->restore;
    }

    if (my $l = $curs->position->system) {
        warn sprintf "HIGHLIGHTING SYSTEM [%d][%d]-[%d][%d]",
            0, $l->top, $l->width, $l->height;
        $c->save;
        $c->set_source_rgba(1, 1, 0, 0.04);
        $c->rectangle(0, $l->top, $l->width, $l->height);
        $c->fill;
        $c->restore;
    }
    else { warn "NO SYSTEM REF FOUND" }
}

sub _show_cursor {
    my ($self, $c) = @_;

    my $curs = $self->cursor;
    $curs->mode eq "insert" or return;
    my $bb = $curs->position->bbox;

    my $x = $$bb[4] + ($$bb[2] - $$bb[4]) / 2;
    my $z = $self->zoom;

    $c->save;
        $c->move_to($x, $$bb[1] + 4*$z);
        $c->line_to($x, $$bb[3] - 4*$z);
        $c->set_source_rgb(0, 0, 0);
        $c->set_line_width(0.8*$z);
        $c->set_line_cap("round");
        $c->stroke;
    $c->restore;
}

sub _build_rendered {
    my ($self) = @_;

    my $widget = $self->widget;
    my $surf;

    RENDER: {
        my ($ox, $oy)   = $widget->get_size_request;
        $surf           = Cairo::ImageSurface->create("argb32", $ox, $oy);

        my $c = App::Jacana::DrawCtx->new(
            copy_from   => $self,
            surface     => $surf,
            widget      => $widget,
        );

        my ($wd, $ht) = $self->_show_music($c);
        $ht =           $self->_show_scale($c, $wd, $ht);
        my ($nx, $ny) = map ceil($_), $c->c->user_to_device($wd, $ht);

        $widget->set_size_request($nx, $ny);
        $nx == $ox && $ny == $oy or redo RENDER;
    }

    $surf;
}

sub _button_release_event :Signal {
    my ($self, $widget, $event) = @_;

    $event->button == 1 or return;

    my ($x, $y) = ($event->x, $event->y);
    my $line    = $self->renderer->find_line_at($y)
        or return;
    my $item    = $line->find_item_at($x, $y)
        or return;

    $self->cursor->voice($item->ambient->find_voice);
    $self->cursor->position($item);
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
    my ($self, $which, $src, @args) = @_;

    my $dlg = use_module("App::Jacana::Dialog::$which")
        ->new(copy_from => $self, src => $src, @args);
    $dlg->run eq "ok" or return;
    $dlg;
}

1;
