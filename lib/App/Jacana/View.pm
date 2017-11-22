package App::Jacana::View;

use 5.012;
use utf8;
use Gtk2;
use App::Jacana::Moose;
use MooseX::Gtk2;

use App::Jacana::Cursor;
use App::Jacana::MIDI::Player;
use App::Jacana::View::Render;

use Data::Dump              qw/pp/;
use Hash::Util::FieldHash   qw/idhash/;
use List::Util              qw/min max first/;
use Module::Runtime         qw/use_module/;
use POSIX                   qw/ceil/;
use Scalar::Util            qw/blessed/;
use Try::Tiny;

use namespace::autoclean;

with qw/ 
    App::Jacana::Has::App
    App::Jacana::Has::Actions
    App::Jacana::Has::Zoom
    App::Jacana::Has::Window
/;

has doc         => is => "ro", required => 1;
has cursor      => is => "lazy", predicate => 1, clearer => 1;

has clip => (
    is          => "rw",
    predicate   => 1,
    clearer     => 1,
    #isa         => Music,
);

has "+zoom" => default => 3, trigger => 1;

has renderer => is => "lazy";#, isa => InstanceOf[My "View::Render"];

has _speed      => is => "rw", default => 15.625;
has _player     => (
    is      => "rw",
    clearer => 1,
);
has _playing    => (
    is      => "ro",
    lazy    => 1,
    default => sub { +[] },
);

# Must come after 'cursor' attribute
with qw/App::Jacana::View::Region/;

sub actions_name { "doc" }

sub _build_cursor { 
    App::Jacana::Cursor->new(
        view        => $_[0],
        #position    => $_[0]->doc->next_movement->next_voice,
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
    $note or return;
    my $pl = $self->_playing;
    @$pl = grep $_ != $note, @$pl;
    $self->redraw;
}

sub clear_playing {
    my ($self) = @_;
    @{$self->_playing} = ();
    $self->set_status("");
}

sub BUILD {
    my ($self) = @_;
    $self->get_action("MidiStop")->set_sensitive(0);
}

sub DEMOLISH {
    my ($self) = @_;
    warn "DEMOLISH VIEW [$self]: STOP MIDI";
    $self->_stop_playing;
    warn "DEMOLISH VIEW [$self]: REMOVE CURSOR";
    $self->clear_cursor;
    warn "FINISHED DEMOLISHING [$self]";
}

sub system_for {
    my ($self, $item) = @_;
    $item->system;
}

sub _doc_changed :Signal(doc.changed) {
    my ($self, $item) = @_;
    warn "DOC CHANGED [$item]";
    $self->refresh($self->system_for($item));
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
    $self->_window->update;
}

sub save :Action(Save) {
    my ($self)  = @_;
    my $doc     = $self->doc;

    my $file = $doc->filename or return $self->save_as;
    $doc->save;
    $self->status_flash("Saved '$file'.");
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

sub file_close :Action(Close) {
    my ($self) = @_;

    if ($self->doc->dirty) {
        warn "CLOSING DIRTY DOCUMENT";
    }
    $self->_window->remove_tab($self);
}

sub midi {
    my ($self) = @_;

    my $app = $self->app;
    $app->has_midi or $self->set_busy("Initialising MIDI…");
    $app->midi;
}

sub _play_music {
    my ($self, $time) = @_;

    my $curs    = $self->cursor;
    my $tempo   = $curs->position->ambient->find_role("Tempo");

    try {
        my $midi    = $self->midi;
        my $player  = App::Jacana::MIDI::Player->new(
            midi    => $midi,
            music   => $self->cursor->movement,
            time    => $time,
            on_start    => $self->weak_method("playing_on"),
            on_stop     => $self->weak_method("playing_off"),
            on_finish   => $self->weak_method("stop_playing"),
        );
        $self->_player($player);
        $self->get_action("MidiPlay")->set_sensitive(0);
        $self->get_action("MidiPlayHere")->set_sensitive(0);
        $self->get_action("MidiStop")->set_sensitive(1);
        $self->set_status("Playing");
        $player->start;
    }
    catch { 
        warn "CAN'T PLAY: $_";
        s/\n$//;
        s/ at \S+ line \d+.*//a;
        $self->status_flash("Can't play: $_");
    };
}

sub _play_all :Action(MidiPlay) { $_[0]->_play_music(0) }
sub _play_here :Action(MidiPlayHere) {
    my ($self) = @_;
    my $pos = $self->cursor->position;
    my $dur = $pos->DOES("App::Jacana::Has::Length") ? $pos->duration : 0;
    $self->_play_music($pos->get_time - $dur + 1);
}

sub _stop_playing {
    my ($self) = @_;
    $self->_clear_player;
    $self->clear_playing;
}

sub stop_playing :Action(MidiStop) {
    # don't rely on getting passed the action
    my ($self) = @_;

    $self->_stop_playing;
    $self->get_action("MidiStop")->set_sensitive(0);
    $self->get_action("MidiPlay")->set_sensitive(1);
    $self->get_action("MidiPlayHere")->set_sensitive(1);
    $self->redraw;
}

sub _set_speed :Action(MidiSpeed) {
    my ($self) = @_;

    my $minute  = 60_000 / 32;

    my $speed   = $self->_speed;
    my $bpm     = $minute / $speed;

    my $dlg = $self->run_dialog("Simple", undef, 
        title   => "Playback speed",
        label   => "Crotchets per minute",
        value   => $bpm,
    ) or return;

    $bpm     = $dlg->value;
    $speed   = $minute / $bpm;
    $self->_speed($speed);
}

has widget      => is => "lazy";

gtk_default_target signal => "widget";

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
    $self->doc->signal_emit(changed => $pos);
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
    #$self->clear_clip;
    my $start = $clip->clone_music($clip->prev_music);
    my $curs = $self->cursor;
    my $end = $curs->position->insert($start);
    $start->break_ambient;
    $self->mark($start);
    $curs->position($end);
    $self->doc->signal_emit(changed => $end);
}

sub _realize :Signal {
    my ($self, $widget) = @_;

    my $w = $widget->get_window;
    my $e = $w->get_events;
    $e |= ["button-press-mask", "button-release-mask"];
    $w->set_events($e);

    $widget->set_size_request(100, 100);
}

sub refresh :Action(Refresh) {
    my ($self, $from) = @_;
    Carp::carp("VIEW REFRESH [$from]");
    if ($from) {
       $self->renderer->clear_lines_from($from);
    }
    else {
        $self->renderer->clear_lines;
    }
    $self->redraw;
}

sub redraw {
    my ($self) = @_;
    try {
        $self->widget->get_window->invalidate_rect(undef, 0);
    }
    catch {
        Carp::cluck("INVALIDATE RECT FAILED [$_]");
    };
    $self->_window->update;
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

    my $to = $rnd->render_upto(sub {
        my ($l) = @_;
#        warn "RENDER UP TO CB [$l]["
#            . $l->bottom . "] > [$bot]";
        $l && $l->bottom > $bot;
    });
    $self->_show_highlights($c);
    $rnd->show_lines($c, $top, min($to, $bot));
    $self->_show_cursor($c);

    $widget->set_size_request(100, $to);
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
        #warn sprintf "HIGHLIGHTING SYSTEM [%d][%d]-[%d][%d]",
        #    0, $l->top, $l->width, $l->height;
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
    my $lily = $self->doc->to_lily;
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
