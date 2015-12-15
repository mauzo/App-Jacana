package App::Jacana::Music::Text::Mark;

use App::Jacana::Moose;

extends "App::Jacana::Music::Text";

with qw/
    App::Jacana::Has::Tweaks
/;

sub dialog_title { "Text mark" }

sub known_tweaks { qw/ direction self-alignment-X / }

sub lily_rx {
    my ($self) = @_;
    my $markup = $self->markup_rx;
    my $tweaks = $self->tweaks_rx;
    qr( $tweaks \\mark \s+ $markup )x;
}

sub from_lily {
    my ($self, %n) = @_;
    $self->new({
        $self->markup_from_lily(%n),
        $self->tweaks_from_lily(%n),
    });
}

sub to_lily {
    my ($self) = @_;
    my $markup = $self->markup_to_lily;
    my $tweaks = $self->tweaks_to_lily;
    "$tweaks\\mark $markup";
}

sub staff_line {
    my ($self) = @_;
    my $dir = $self->tweak("direction");
    ($dir && $dir eq "DOWN") ? -8 : 6;
}

sub draw {
    my ($self, $c) = @_;

    $c->save;
        $c->text_font($self->style, 4);
        my $wd = $c->show_text($self->text);
    $c->restore;

    $wd;
}

1;
