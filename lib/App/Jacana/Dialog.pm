package App::Jacana::Dialog;

use Moo;
use App::Jacana::Util::Types;

with qw/ App::Jacana::HasWindow /;

has dialog => is => "lazy";

sub title   { ... }
sub buttons { "gtk-cancel" => "cancel", "gtk-ok" => "ok" }

sub _build_dialog {
    my ($self) = @_;

    my $dlg = Gtk2::Dialog->new_with_buttons(
        $self->title,
        $self->_window->frame,
        ["modal", "destroy-with-parent"],
        $self->buttons,
    );
    $dlg->set_property("has-separator", 1);
    my $vb = $dlg->get_content_area;
    $self->_build_content_area($vb);
    $vb->show_all;
    $dlg;
}

sub vbox { $_[0]->dialog->get_content_area }

sub run {
    my ($self) = @_;
    my $dlg = $self->dialog;
    my $rsp = $dlg->run;
    $dlg->destroy;
    $rsp;
}

1; 