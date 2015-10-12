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

sub init_meta {
    feature->import(":5.18");
}

1;
