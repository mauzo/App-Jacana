package App::Jacana;

use 5.012;
use warnings;

our $VERSION = "0";

use Moo;
use Wx;

use App::Jacana::Frame;

extends "Wx::App";

has frame   => (
    is      => "lazy",
);

sub _build_frame {
    App::Jacana::Frame->new("Jacana");
}

sub OnInit {
    my ($self) = @_;
    $self->frame->Show(1);
    return 1;
}

1;
