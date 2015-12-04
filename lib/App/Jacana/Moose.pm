package App::Jacana::Moose;

use 5.018;

use Moose::Exporter;

use Moose ();
use Moose::Util ();
use MooseX::AttributeShortcuts ();

Moose::Exporter->setup_import_methods(
    also    => [qw/ 
        Moose
        MooseX::AttributeShortcuts
    /],
);

Moose::Util::meta_attribute_alias "Shortcuts",
    "MooseX::AttributeShortcuts::Trait::Attribute";

sub init_meta {
    feature->import(":5.18");
}

1;
