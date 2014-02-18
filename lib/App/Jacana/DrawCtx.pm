package App::Jacana::DrawCtx;

use Moo;
use App::Jacana::Util::Types;

with qw/ 
    App::Jacana::HasApp
    App::Jacana::HasZoom
/;

has widget  => (
    is          => "ro",
    required    => 1,
    isa         => InstanceOf["Gtk2::Widget"],
    weak_ref    => 1,
);
has c       => (
    is      => "lazy",
    isa     => InstanceOf["Cairo::Context"],
    handles => [qw/
        save restore push_group pop_group pop_group_to_source
        translate scale move_to line_to close_path
        stroke fill show_glyphs paint_with_alpha
        set_line_width set_line_cap set_source_rgb 
    /],
);
has font    => (
    is      => "lazy",
    isa     => InstanceOf["Font::FreeType::Face"],
);
has bar_length => (
    is      => "rw",
    isa     => Int,
    default => 0,
);

sub _build_c {
    my ($self) = @_;

    my $w = $self->widget->get_window;
    my $c = Gtk2::Gdk::Cairo::Context->create($w);

    $c->set_antialias("gray");
    $c->set_font_face(Cairo::FtFontFace->create($self->font));
    $c->set_font_size(8);
    my $o = Cairo::FontOptions->create;
    #$o->set_hint_style("none");
    $o->set_hint_metrics("off");
    $c->set_font_options($o);

    my $zoom = $self->zoom;
    $c->scale($zoom, $zoom); # zoooom!
    $c;
}

sub _build_font {
    my ($self) = @_;
    $self->_resource("feta_font");
}

sub BUILD { }

sub reset {
    my ($self) = @_;
    $self->bar_length(0);
}

sub width {
    my ($self) = @_;
    my ($wd) = $self->widget->get_window->get_size;
    $wd;
}

sub glyph {
    my ($self, $gly) = @_;
    +{
        index   => $self->font->get_name_index($gly),
        x       => 0,
        y       => 0,
    };
}

sub glyph_width {
    my ($self, $gly) = @_;
    $self->c->glyph_extents($gly)->{x_advance};
}

sub add_to_bar {
    my ($self, $x, $note) = @_;

    if ($note->DOES("App::Jacana::HasTime")) {
        my $par = $note->partial;
        $par and $self->bar_length($note->length - $par->duration);
        return 0;
    }

    my $time = $note->ambient->find_role("HasTime")
        or return;
    $note->DOES("App::Jacana::HasLength")   or return;

    my $new = $self->bar_length + $note->duration;
    my $bar = $time->length;
    $new < $bar and $self->bar_length($new), return 0;

    $self->bar_length($new - $bar);
    return 1;
}

1;
