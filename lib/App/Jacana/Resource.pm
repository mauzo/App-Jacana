package App::Jacana::Resource;

use 5.012;
use warnings;

use Moo;

use Cairo;
use File::ShareDir ();
use Font::FreeType;

has dist    => is => "ro";

sub _find {
    my ($self, $res) = @_;
    File::ShareDir::dist_file($self->dist, $res);
}

has _freetype   => (
    is      => "ro",
    lazy    => 1,
    default => sub { Font::FreeType->new },
);

has feta_font   => is => "lazy";

sub _build_feta_font {
    my ($self) = @_;
    my $font = $self->_find("emmentaler-26.otf");
    $self->_freetype->face($font);
}

sub cairo_feta_font { 
    my ($self) = @_;
    my $font = $self->feta_font;
    Cairo::FtFontFace->create($font);
}

1;
