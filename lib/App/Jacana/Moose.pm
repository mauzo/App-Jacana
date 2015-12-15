package App::Jacana::Moose;

use 5.018;

use Moose::Exporter;

use Moose ();
use Moose::Util ();
use MooseX::AttributeShortcuts ();

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
    feature->import(":5.18");
}

1;
