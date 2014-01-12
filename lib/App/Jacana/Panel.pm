package App::Jacana::Panel;

use 5.012;
use warnings;

use Wx qw":color :pen :font";
use Wx::Event   qw/EVT_PAINT/;
use Moo;

extends "Wx::Panel";

sub BUILDARGS { +{} }
sub FOREIGNBUILDARGS { $_[1] }

sub BUILD {
    my ($self) = @_;

    $self->SetBackgroundColour(wxWHITE);

    EVT_PAINT($self, \&onPAINT);
}

sub onPAINT {
    my ($self, $ev) = @_;
    my $dc = Wx::PaintDC->new($self);
    my $w = $self->GetClientSize->x;

    my $gc = Wx::GraphicsContext::Create($dc);
    $gc->SetPen(wxGREY_PEN);
    for (2..6) {
        $gc->StrokeLine(0, 10*$_, $w, 10*$_);
    }

    my $fn = Wx::Font::New(50, wxFONTFAMILY_DEFAULT,
        wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL, 0,
        "Feta", wxFONTENCODING_DEFAULT);
    $gc->SetFont($fn, wxBLACK);
    $gc->DrawText("(\xca", 10, 20);
}

1;

