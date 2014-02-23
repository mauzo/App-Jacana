package App::Jacana::View;

use utf8;
use Gtk2;
use Moo;
use MooX::MethodAttributes
    use     => [qw/ MooX::Gtk2 /];

use App::Jacana::Cursor;
use App::Jacana::DrawCtx;
use App::Jacana::StaffCtx::Draw;

use Data::Dump              qw/pp/;
use Hash::Util::FieldHash   qw/idhash/;
use List::Util              qw/min max first/;
use Module::Runtime         qw/use_module/;
use POSIX                   qw/ceil/;
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

has rendered    => is => "lazy", clearer => 1;

has bbox => is => "ro", default => sub { +[] };

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

has scrolled    => is => "lazy";

sub _build_scrolled {
    my ($self) = @_;

    my $scr = Gtk2::ScrolledWindow->new;
    $scr->set_policy("automatic", "automatic");
    $scr->add_with_viewport($self->widget);
    $scr;
}

sub scroll_to {
    my ($self, $item) = @_;

    my $scr = $self->scrolled;
    my $haj = $scr->get_hadjustment;
    my $vaj = $scr->get_vadjustment;
    my $bbx = $item->bbox or return;

    $haj->clamp_page($$bbx[0] - 6, $$bbx[2] + 6);
    $vaj->clamp_page($$bbx[1] - 6, $$bbx[3] + 6);
}

sub _realize :Signal {
    my ($self, $widget) = @_;

    my $w = $widget->get_window;
    my $e = $w->get_events;
    $e |= ["button-press-mask", "button-release-mask"];
    $w->set_events($e);
}

sub refresh {
    my ($self) = @_;
    $self->clear_rendered;
    $self->widget->get_window->invalidate_rect(undef, 0);
}

sub _expose_event :Signal {
    my ($self, $widget, $event) = @_;

    my $surf = $self->rendered;
    my $c = Gtk2::Gdk::Cairo::Context->create($widget->get_window);

    $c->set_source_surface($surf, 0, 0);
    $c->paint;
}

sub _build_rendered {
    my ($self) = @_;

    my $widget = $self->widget;
    my $surf;

    RENDER: {
        my ($ox, $oy)   = $widget->get_size_request;
        $surf           = $widget->get_window->create_similar_surface(
            "color-alpha", $ox, $oy);

        my $c = App::Jacana::DrawCtx->new(
            copy_from   => $self,
            surface     => $surf,
            widget      => $widget,
        );

        my ($wd, $ht) = $self->_show_music($c);
        $ht +=          $self->_show_scale($c, $wd, $ht);
        my ($nx, $ny) = map ceil($_), $c->c->user_to_device($wd, $ht);

        $widget->set_size_request($nx, $ny);
        $nx == $ox && $ny == $oy or redo RENDER;
    }

    $surf;
}

sub _show_scale {
    my ($self, $c, $wd, $ht) = @_;

    my ($nx) = $c->c->user_to_device($wd, 0);

    $ht += 6;
    $c->set_line_width(0.2); $c->set_source_rgb(0, 0.7, 0);
    $c->move_to(0, $ht); $c->line_to($wd, $ht);
    for (0..($nx / 10)) {
        my ($x) = $c->c->device_to_user($_*10, 0);
        $c->move_to($x, $ht);
        $c->line_to($x, $ht + (
            $_ % 10 ?
                $_ % 5 ? 3 : 5
            : 7));
        unless ($_ % 10) {
            $c->move_to($x, $ht + 12);
            $c->c->show_text($_/10);
        }
    }
    $c->stroke;
    $ht + 18;
}

#        $c->save;
#            $c->set_line_width(0.1);
#            $c->set_source_rgb(0.8, 0, 0);
#            $c->move_to($x, 0);
#            $c->line_to($x, 24*@voices);
#            $c->stroke;
#        $c->restore;
#            $c->save;
#                $c->set_line_width(0.1);
#                if (my $lsb = $item->lsb($c)) {
#                    $c->set_source_rgb(0.8, 0, 0.8);
#                    $c->move_to($x - $lsb, $y - 6);
#                    $c->line_to($x - $lsb, $y + 6);
#                    $c->stroke;
#                }
#                $c->set_source_rgb(0, 0.8, 0);
#                $c->move_to($x + $mywd, $y - 10);
#                $c->line_to($x + $mywd, $y + 10);
#                $c->stroke;
#            $c->restore;

sub _reset_bb { @{$_[0]->bbox} = () }

sub _add_to_bb {
    my ($self, $c, $x, @voices) = @_;

    my $bb = [
        ($c->c->user_to_device($x, 0))[0],
        map [
            ($c->c->user_to_device(0, $_->y + 12))[1],
            $_->item,
        ], @voices,
    ];
    Scalar::Util::weaken $_ for
        map $_->[1],
        @$bb[1..$#$bb];

    push @{$self->bbox}, $bb;
}

sub _show_music {
    my ($self, $c) = @_;

    my $voices  = $self->doc->music;
    my @voices  =
        map App::Jacana::StaffCtx::Draw->new(
            item    => $$voices[$_],
            y       => 24*$_ + 12,
        ),
        0..$#$voices;

    $c->set_source_rgb(0, 0, 0);
    $self->_show_stave($c, $_) for map $_->y, @voices;

    my $x = max map $self->_show_item($c, 0, $_), @voices;
    $self->_reset_bb;
    $self->_add_to_bb($c, $x, @voices);
    @{$_->item->bbox}[0,1] = $c->c->user_to_device(0, $_->y - 12) 
        for @voices;

    for (;;) {
        my $skip = min map $_->when, @voices;
        $_->skip($skip) for @voices;

        my @draw = grep !$_->when, @voices;
        @{$_->item->bbox}[2,3] = $c->c->user_to_device($x, $_->y + 12) 
            for @draw;

        @draw = grep $_->next, @draw;
        @{$_->item->bbox}[0,1] = $c->c->user_to_device($x, $_->y - 12) 
            for @draw;

        $x += max 0, 
            map $self->_show_barline($c, $x, $_),
            grep $_->barline,
            @draw;
        $x += max 0, map $_->lsb($c), map $_->item, @draw;
        $x += max 0, map $self->_show_item($c, $x, $_), @draw;

        @voices = grep $_->has_item, @voices or last;
        $self->_add_to_bb($c, $x, @voices);
    }

    ($x + 6, 24*@$voices);
}

sub _show_stave {
    my ($self, $c, $y) = @_;

    $c->save;
        for (-2..2) {
            $c->move_to(0, 2*$_ + $y);
            $c->line_to($c->width, 2*$_ + $y);
        }
        $c->set_line_width(0.1);
        $c->stroke;
    $c->restore;
}

sub _show_item {
    my ($self, $c, $x, $v) = @_;
    my $y       = $v->y;
    my $item    = $v->item;

    $v->has_tie and $self->_show_tie($c, $x, $v);

    $c->save;
        $c->translate($x, $y);
        my $wd = $self->_draw_item($c, $item);
    $c->restore;

    $item->isa("App::Jacana::Music::Note") && $item->tie
        and $v->start_tie($x + $wd);

    ($wd // 0) + $item->rsb;
}

sub _draw_item {
    my ($self, $c, $item) = @_;
    no warnings "uninitialized";

    my $playing = $self->_playing;
    my $cursor  = $self->cursor;
    my $curpos  = $cursor->position;
    my $mode    = $cursor->mode;

    my $pos = $item->staff_line;
    $c->save;
        $c->translate(0, -$pos);
        $c->move_to(0, 0);
        $item == $curpos
            and $c->set_source_rgb(0, 0, 1);
        $playing->{$item}
            and $c->set_source_rgb(1, 0, 0);
        my $wd = $item->draw($c, $pos);
    $c->restore;

    $mode eq "insert" && $item == $curpos
        and $self->_show_cursor($c, $wd + 1);

    return $wd;
}

sub _show_tie {
    my ($self, $c, $x, $v) = @_;
    my $item    = $v->item;
    my $from    = $v->tie_from;

    $c->save;
        if ($item->isa("App::Jacana::Music::Note")
            && $from->pitch == $item->pitch
        )       { $c->set_source_rgb(0, 0, 0) }
        else    { $c->set_source_rgb(1, 0, 0) }
        $c->set_line_width(0.5);

        my $x1  = $v->tie_x;
        my $x2  = $x - $item->lsb($c);
        my $xc  = ($x2 - $x1) / 4;
        my $y   = $v->y - $from->staff_line - 1;
        $c->move_to($x1, $y);
        $c->curve_to(
            $x1 + $xc,  $y - 2,
            $x2 - $xc,  $y - 2,
            $x2,        $y,
        );
        $c->stroke;
    $c->restore;

    $v->clear_tie;
}

sub _show_barline {
    my ($self, $c, $x, $bar) = @_;

    my $y = $bar->y;
    $c->save;
        $bar->pos and $c->set_source_rgb(0.9, 0, 0);
        $c->set_line_width(0.5);
        $c->set_line_cap("butt");
        $c->move_to($x + 1, $y - 4);
        $c->line_to($x + 1, $y + 4);
        $c->stroke;
    $c->restore;
    return 3;
}

sub _show_cursor {
    my ($self, $c, $x) = @_;

    $c->save;
        $c->move_to($x, -6);
        $c->line_to($x, +6);
        $c->set_line_width(0.7);
        $c->set_line_cap("round");
        $c->stroke;
    $c->restore;
}

sub _button_release_event :Signal {
    my ($self, $widget, $event) = @_;

    $event->button == 1 or return;
    my $bb = first { $$_[0] > $event->x } @{$self->bbox}
        or return;
    my $it = first { $$_[0] > $event->y } @$bb[1..$#$bb]
        or return;
    $self->cursor->position($$it[1]);
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
