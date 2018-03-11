package App::Jacana::Types;

use 5.012;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;
use Types::Common::Numeric qw/PositiveOrZeroInt/;

use Memoize;

our @EXPORT_OK = qw/Has My Music StaffCtx/;

declare Chroma =>
    as Int, where { $_ > -3 && $_ < 3 };

declare Key =>
    as Int, where { $_ > -8 && $_ < 8 };

declare NoteLength =>
    as Int, where { $_ >= 0 && $_ <= 8 };

declare Name =>
    as Str, where { /^[a-zA-Z]+$/ };

declare Pitch =>
    as Str, where { /^[a-g]$/ };

declare Tick => as PositiveOrZeroInt;

declare ChangeType =>
    as Enum[qw/ insert remove length staff movement other /];

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

memoize "My";

sub Music (;$) {
    my ($which) = @_;
    my $name    = @_ ? "Music::$which" : "Music";
    My $name;
}

sub StaffCtx (;$) {
    my ($which) = @_;
    my $name    = @_ ? "StaffCtx::$which" : "StaffCtx";
    My $name;
}

sub Has ($) {
    my ($which) = @_;
    my $role    = "App::Jacana::Has::$which";
    role_type { role => $role };
}

memoize "Has";

__PACKAGE__->meta->make_immutable;
