package App::Jacana::Resource;

use 5.012;
use warnings;

use Moo;

use Cairo;
use File::Path      qw/mkpath/;
use File::ShareDir  qw/dist_file/;
use File::Temp::AutoRename;
use Font::FreeType;

has dist    => is => "ro";
has userdir => is => "lazy";

sub _build_userdir {
    my ($self) = @_;
    my $dir = "$ENV{HOME}/.config/morrow.me.uk/Jacana";
    mkpath $dir;
    return $dir;
}

sub _find {
    my ($self, $res) = @_;
    File::ShareDir::dist_file($self->dist, $res);
}

sub find_user_file {
    my ($self, $file) = @_;
    -r and return $_
        for $self->userdir . "/$file", $self->_find($file);
}

sub write_user_file {
    my ($self, $file) = @_;
    my $dir = $self->userdir;
    File::Temp::AutoRename->new("$dir/$file");
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
    $self->_freetype->face($font, load_flags => FT_LOAD_NO_HINTING);
}

sub cairo_feta_font { 
    my ($self) = @_;
    my $font = $self->feta_font;
    Cairo::FtFontFace->create($font);
}

1;
