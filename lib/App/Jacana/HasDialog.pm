package App::Jacana::HasDialog;

use Moo::Role;

requires "dialog";

sub run_dialog {
    my ($self, $view) = @_;

    warn "OPENING DIALOG";
    my $dlg = $view->run_dialog($self->dialog, $self)
        or return;
    warn "CLOSED DIALOG, COPYING";
    $self->copy_from($dlg);
}

1;
