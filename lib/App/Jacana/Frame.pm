package App::Jacana::Frame;

use utf8;
use 5.012;

use Wx;
use Moo;

use Data::Dump qw/pp/;

use App::Jacana::Panel;

extends "Wx::Frame";

sub BUILDARGS { +{} }
sub FOREIGNBUILDARGS {
    (undef, -1, $_[1], [-1,-1], [-1,-1]);
}

has content => (
    is  => "lazy",
);

sub _build_content { App::Jacana::Panel->new($_[0]) }

sub BUILD {
    my ($self) = @_;

    $self->CreateStatusBar();
    $self->SetStatusText("loading…");

    $self->content->Refresh;
}

1;
