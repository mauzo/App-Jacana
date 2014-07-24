package App::Jacana::Music::RehearsalMark;

use Moo;

use App::Jacana::Util::Types;

extends "App::Jacana::Music";
with    qw/ 
    App::Jacana::Has::RehearsalMark
    App::Jacana::Has::Dialog
/;

sub dialog { "RehearsalMark" }

sub lily_rx {
    qr( \\mark \s* (?: \\default | \# (?<number> [0-9]+ ) ) )x;
}

sub to_lily {
    my ($self) = @_;
    my $num = $self->has_number 
        ? "#" . $self->number
        : "\\default";
    "\\mark $num";
}

sub staff_line { 7 }

sub draw {
    my ($self, $c) = @_;

    $c->save;
        $c->text_font("bold", 6);
        my ($wd, $ht) = $c->show_text(
            $self->has_number ? $self->number : "?");
        $c->set_line_width(0.3);
        $c->move_to(-0.7, 0.7);
        $c->line_to(-0.7, -$ht - 0.7);
        $c->line_to($wd + 0.7, -$ht - 0.7);
        $c->line_to($wd + 0.7, 0.7);
        $c->close_path;
        $c->stroke;
    $c->restore;

    return $wd;
}

1;

