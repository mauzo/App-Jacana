package App::Jacana::Util::Types;

use 5.012;
use warnings;

use Carp;
use Exporter "import";
use MooX::Types::MooseLike::Base ":all";

our @EXPORT = (
    @{$MooX::Types::MooseLike::Base::EXPORT_TAGS{all}},
    qw/ LinkList Match Music My /,
);

sub My ($) { "App::Jacana::$_[0]" }

sub Match {
    my ($rx, $nm) = @_;
    sub {
        ref $_[0]
            and croak "\u$nm must not be a ref!";
        $_[0] =~ /^$rx\z/
            or croak "Bad $nm: '$_[0]'";
    };
}

sub Music (;$) { InstanceOf[My "Music" . ($_[0] ? "::$_[0]" : "")] }

use constant {
    LinkList    => ConsumerOf[My "Util::LinkList"],
};

1;
