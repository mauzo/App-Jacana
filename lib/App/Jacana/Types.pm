package App::Jacana::Types;

use Type::Library
    -base,
    -declare => qw/Chroma Key Name Pitch/;
use Type::Utils -all;
use Types::Standard -types;

our @EXPORT_OK = qw/Has My Music/;

declare Chroma,
    as Int, where { $_ > -3 && $_ < 3 };

declare Key,
    as Int, where { $_ > -8 && $_ < 8 };

declare NoteLength,
    as Int, where { $_ >= 0 && $_ <= 8 };

declare Name,
    as Str, where { /^[a-zA-Z]+$/ };

declare Pitch,
    as Str, where { /^[a-g]$/ };

sub My ($) {
    my ($which) = @_;
    my $class   = "App::Jacana::$which";

    class_type { 
        class       => $class,
        coercion    => [
            HashRef,    sub { $class->new($_) },
        ],
    };
}

sub Music (;$) {
    my ($which) = @_;
    my $name    = @_ ? "Music::$which" : "Music";
    My $name;
}

sub Has ($) {
    my ($which) = @_;
    my $role    = "App::Jacana::Has::$which";
    role_type { role => $role };
}

__PACKAGE__->meta->make_immutable;
