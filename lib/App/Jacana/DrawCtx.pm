package App::Jacana::DrawCtx;

use App::Jacana::Moose;

with qw/ 
    App::Jacana::Has::App
    App::Jacana::Has::Zoom
/;

has surface => (
    is          => "ro",
    required    => 1,
    #isa         => InstanceOf["Cairo::Surface"],
);
has c       => (
    is      => "lazy",
    #isa     => InstanceOf["Cairo::Context"],
    handles => [qw/
        save restore push_group pop_group pop_group_to_source
        translate scale move_to line_to curve_to close_path
        stroke fill show_glyphs paint_with_alpha
        set_line_width set_line_cap set_source_rgb set_operator
    /],
);
has font    => (
    is      => "lazy",
    #isa     => InstanceOf["Font::FreeType::Face"],
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

sub width { $_[0]->d2u($_[0]->surface->get_width) }

sub u2d { $_[1] * $_[0]->zoom }
sub d2u { $_[1] / $_[0]->zoom }

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

# use glyph names for consistency, even though numbers would be easier
my %Num = qw/
    0 zero 1 one 2 two 3 three 4 four 
    5 five 6 six 7 seven 8 eight 9 nine
/;

sub layout_num {
    my ($self, $num) = @_;
    $self->layout_glyphs(\%Num, $num);
}

sub _decode_matrix {
    my ($m) = @_;

    my ($xx, $yx) = $m->transform_distance(1, 0);
    my ($xy, $yy) = $m->transform_distance(0, 1);
    my ($x0, $y0) = $m->transform_point(0, 0);

    [[$xx, $xy, $x0], [$yx, $yy, $y0]];
}

sub text_font {
    my ($self, $style, $size) = @_;

    my $c = $self->c;

    $c->select_font_face(
        "Century Schoolbook L",
        ($style eq "italic" ? "italic" : "normal"),
        ($style eq "bold" ? "bold" : "normal"),
    );
    $c->set_font_size($size);
}

sub show_text {
    my ($self, $text) = @_;
    $self->c->show_text($text);
    my $ext = $self->c->text_extents($text);
    wantarray ? @$ext{"width", "height"} : $$ext{width};
}

Moose::Util::find_meta(__PACKAGE__)->make_immutable;
