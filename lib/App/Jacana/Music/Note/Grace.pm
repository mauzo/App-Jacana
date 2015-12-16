package App::Jacana::Music::Note::Grace;

use App::Jacana::Moose;

extends "App::Jacana::Music::Note";

around lily_rx => sub {
    my ($super, $self) = @_;

    my $note = $self->$super;
    qr{ \\grace \s+ $note }x;
};

around to_lily => sub {
    my ($super, $self) = @_;

    "\\grace " . $self->$super;
};

sub duration { 0 }

sub _tail_dir { 1 }

around draw => sub {
    my ($super, $self, $c, @args) = @_;

    $c->scale(0.6, 0.6);
    $self->$super($c, @args) * 0.5;
};

Moose::Util::find_meta(__PACKAGE__)->make_immutable;
