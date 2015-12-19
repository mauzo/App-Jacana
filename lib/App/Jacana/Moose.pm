package App::Jacana::Moose;

use 5.018;

use Moose::Exporter;

use Moose ();
use Moose::Util;
use Moose::Util::TypeConstraints;
use MooseX::AttributeShortcuts ();

use MooseX::Trait::Coercer;
use MooseX::Trait::IgnoreUndef;

Moose::Exporter->setup_import_methods(
    as_is   => [qw/ My /],
    also    => [qw/ 
        Moose
        MooseX::AttributeShortcuts
    /],
);

Moose::Util::meta_attribute_alias "Shortcuts",
    "MooseX::AttributeShortcuts::Trait::Attribute";

sub My ($) { "App::Jacana::$_[0]" }

sub init_meta {
    my ($self, %args) = @_;

    feature->import(":5.18");

    my $class = $args{for_class};
    class_type $class;
    coerce $class, from "HashRef", via { $class->new($_) };
}

1;
