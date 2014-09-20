package App::Jacana::Util::Types;

use 5.012;
use warnings;

use Exporter "import";
use MooX::Types::MooseLike::Base ":all";

our @EXPORT = (
    @{$MooX::Types::MooseLike::Base::EXPORT_TAGS{all}},
    qw/ LinkList Music My /,
);

sub My ($) { "App::Jacana::$_[0]" }

use constant {
    LinkList    => ConsumerOf[My "Util::LinkList"],
    Music       => InstanceOf[My "Music"],
};

1;
