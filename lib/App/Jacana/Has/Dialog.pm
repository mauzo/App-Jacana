package App::Jacana::Has::Dialog;

use App::Jacana::Moose -role;

requires "dialog";

sub run_dialog {
    my ($self, $view) = @_;

    my $dlg = $view->run_dialog($self->dialog, $self)
        or return;
    $self->copy_from($dlg);
}

1;
