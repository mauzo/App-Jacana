package App::Jacana::Resource;

use App::Jacana::Moose;

use Cairo;
use File::Path      qw/mkpath/;
use File::ShareDir  qw/dist_file/;
use File::Temp::AutoRename;
use Font::FreeType  0.10; 

has dist    => is => "ro";
has userdir => is => "lazy";

sub _build_userdir {
    my ($self) = @_;
    my $dir = "$ENV{HOME}/.config/morrow.me.uk/Jacana";
    mkpath $dir;
    return $dir;
}

sub find {
    my ($self, $res) = @_;
    File::ShareDir::dist_file($self->dist, $res);
}

sub find_all {
    my ($self, $file) = @_;
    ($self->find($file), $self->userdir . "/$file");
}

sub find_user_file {
    my ($self, $file) = @_;
    -r and return $_ for reverse $self->find_all($file);
}

sub write_user_file {
    my ($self, $file, $cb) = @_;
    my $dir = $self->userdir;
    my $fh  = File::Temp::AutoRename->new("$dir/$file");

    $cb or return $fh;
    local *_; local $_ = $fh->fh;
    $cb->($fh);
}

has _freetype   => (
    is      => "ro",
    lazy    => 1,
    default => sub { Font::FreeType->new },
);

has feta_font   => is => "lazy";

sub _build_feta_font {
    my ($self) = @_;
    my $font = $self->find("emmentaler-26.otf");
    $self->_freetype->face($font, load_flags => FT_LOAD_NO_HINTING);
}

sub cairo_feta_font { 
    my ($self) = @_;
    my $font = $self->feta_font;
    Cairo::FtFontFace->create($font);
}

1;
