package App::Jacana::Music::Lily;

use Moo;

extends "App::Jacana::Music";
with    qw/
    App::Jacana::Has::Dialog
    App::Jacana::Has::Lily
/;

sub dialog { "Lily" }

sub to_lily { 
    my ($self) = @_;
    my $lily = $self->lily;
    s/^\s+//, s/\s+$// for $lily;
    "\n$lily\n";
}

sub staff_line { -3 }

sub draw {
    my ($self, $c) = @_;

    $c->save;
        $c->text_font("bold", 8);
        my $wd = $c->show_text("?");
    $c->restore;

    return $wd;
}

1;
