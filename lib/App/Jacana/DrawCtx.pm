package App::Jacana::DrawCtx;

use Moo;
use App::Jacana::Util::Types;

with qw/ 
    App::Jacana::Has::App
    App::Jacana::Has::Zoom
/;

has widget  => (
    is          => "ro",
    required    => 1,
    isa         => InstanceOf["Gtk2::Widget"],
    weak_ref    => 1,
);
has surface => (
    is      => "ro",
    isa     => InstanceOf["Cairo::Surface"],
);
has c       => (
    is      => "lazy",
    isa     => InstanceOf["Cairo::Context"],
    handles => [qw/
        save restore push_group pop_group pop_group_to_source
        translate scale move_to line_to curve_to close_path
        stroke fill show_glyphs paint_with_alpha
        set_line_width set_line_cap set_source_rgb 
    /],
);
has font    => (
    is      => "lazy",
    isa     => InstanceOf["Font::FreeType::Face"],
);

sub _build_c {
    my ($self) = @_;

    my $c = Cairo::Context->create($self->surface);

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

sub width {
    my ($self) = @_;
    my ($wd) = $self->widget->get_size_request;
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
    my ($self, @gly) = @_;
    $self->c->glyph_extents(@gly)->{x_advance};
}

sub layout_glyphs {
    my ($self, $map, $text) = @_;

    $map //= {};

    my @gly =
        map $self->glyph($$map{$_} // $_), 
        split //, $text;
    my $wd = 0;
    for (@gly) {
        $_->{x} = $wd;
        $wd += $self->glyph_width($_);
    }
    return $wd, @gly;
}

sub text_font {
    my ($self, $style, $size) = @_;

    $self->c->select_font_face(
        "Century Schoolbook",
        ($style eq "italic" ? "italic" : "normal"),
        ($style eq "bold" ? "bold" : "normal"),
    );
    $self->c->set_font_size($size);
}

sub show_text {
    my ($self, $text) = @_;
    $self->c->show_text($text);
    $self->c->text_extents($text)->{width};
}

1;
