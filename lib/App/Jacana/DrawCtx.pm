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
has clef    => (
    is      => "rw",
    isa     => ConsumerOf["App::Jacana::HasClef"],
);
has key     => (
    is      => "rw",
    isa     => ConsumerOf["App::Jacana::HasKey"],
);

sub _build_c {
    my ($self) = @_;

    my $w = $self->widget->get_window;
    my $c = Gtk2::Gdk::Cairo::Context->create($w);

    my $zoom = $self->zoom;

    $c->set_antialias("gray");
    $c->scale($zoom, $zoom); # zoooom!
    $c->set_font_face(Cairo::FtFontFace->create($self->font));
    $c->set_font_size(8);
    $c;
}

sub _build_font {
    my ($self) = @_;
    $self->_resource("feta_font");
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

1;
