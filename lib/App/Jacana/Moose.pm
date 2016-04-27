package App::Jacana::Moose;

use 5.018;
use strict;
use warnings;

use Moose::Exporter;

use Moose ();
use Moose::Role ();
use Moose::Util qw/find_meta/;

use MooseX::AttributeShortcuts ();
use MooseX::Trait::Coercer;
use MooseX::Trait::IgnoreUndef;

use App::Jacana::Types;
use Types::Standard;

use B::Hooks::AtRuntime qw/after_runtime/;

Moose::Util::meta_attribute_alias "Shortcuts",
    "MooseX::AttributeShortcuts::Trait::Attribute";

my ($import_class) = Moose::Exporter->build_import_methods(
    also => [
        "Moose",
        "MooseX::AttributeShortcuts",
    ],
);
my ($import_role) = Moose::Exporter->build_import_methods(
    also => [
        "Moose::Role",
        "MooseX::AttributeShortcuts",
    ],
);

sub import {
    my ($self, @args) = @_;

    my $opts = ref $args[0] ? shift @args : {};
    $$opts{into} ||= caller;

    my %args;
    @_ = ($self, grep !(/^-(\w+)/ && ($args{$1} = 1)), @args);
    
    strict->import;
    warnings->import;
    feature->import(":5.18");
    Types::Standard->import($opts, "-types");
    App::Jacana::Types->import($opts, "-all");

    if ($args{role}) {
        goto &$import_role;
    }
    else {
        after_runtime { 
            Carp::cluck("Making [$$opts{into}] immutable");
            find_meta($$opts{into})->make_immutable;
        };
        goto &$import_class;
    }
}

1;
