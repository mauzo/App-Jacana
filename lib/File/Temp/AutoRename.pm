package File::Temp::AutoRename;

use autodie;
use Moo;

use Carp;
use File::Temp  qw/tempfile/;

use namespace::clean;

has fh          => is => "ro";
has tempname    => is => "ro";
has filename    => is => "ro";
has do_rename   => is => "rw", default => 1;

sub BUILDARGS {
    my ($self, $filename) = @_;

    my ($fh, $tempname) = tempfile "$filename~XXXXX", UNLINK => 0
        or croak "Can't create tempfile for '$filename': $!";
    return {
        fh          => $fh,
        filename    => $filename,
        tempname    => $tempname,
    };
}

sub DESTROY {
    my ($self) = @_;

    close $self->fh;
    if ($self->do_rename) {
        rename $self->tempname, $self->filename;
    }
    else {
        unlink $self->tempname;
    }
}

1;
