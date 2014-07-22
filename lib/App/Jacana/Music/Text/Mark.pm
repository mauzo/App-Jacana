package App::Jacana::Music::Text::Mark;

use Moo;

extends "App::Jacana::Music::Text";

sub dialog_title { "Text mark" }

sub lily_rx {
    my ($self) = @_;
    my $markup = $self->markup_rx;
    qr( \\mark \s+ $markup )x;
}

sub from_lily {
    my ($self, %n) = @_;
    my @markup = $self->markup_from_lily(%n);
    $self->new({ @markup });
}

sub to_lily {
    my ($self) = @_;
    my $markup = $self->markup_to_lily;
    "\\mark $markup";
}

sub staff_line { 6 }

sub draw {
    my ($self, $c) = @_;

    $c->save;
        $c->text_font($self->style, 4);
        my $wd = $c->show_text($self->text);
    $c->restore;

    $wd;
}

1;
