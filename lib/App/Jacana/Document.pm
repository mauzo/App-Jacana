package App::Jacana::Document;

use 5.012;
use warnings;

use App::Jacana::Moose;
use MooseX::Gtk2;

use File::Slurp     qw/read_file write_file/;
use List::Util      qw/first/;
use Module::Runtime qw/use_module/;
use Regexp::Common;

use App::Jacana::Document::Movement;

use namespace::autoclean;

with qw/
    MooseX::Role::Signal
    App::Jacana::Has::Movements
/;

# SIGNALS
#
# changed(ev)
# Emitted when the document changes. <ev> is an Event::Change.
#

has filename => (
    is          => "rw",
    isa         => Str,
    predicate   => 1,
    clearer     => 1,
);
has dirty => (
    is      => "rw",
    isa     => Bool,
    default => 0,
);

sub BUILD { }

sub DEMOLISH { warn "DEMOLISH DOCUMENT [$_[0]]" }

sub _changed :Signal {
    my ($self, $ev) = @_;
    warn "DOC CHANGED: " . Data::Dump::pp($ev);
    $self->dirty(1);
}

sub empty_document {
    my ($self) = @_;
    my $m = $self->find_movement("");
    $m->prev_voice->insert_voice(
        App::Jacana::Music::Voice->new(name => "voice"));
    $self->dirty(1);
    $self;
}

sub open {
    my ($self, $file) = @_;

    my $lily    = read_file $file;
    my $new     = $self->new(filename => $file);

    $new->parse_music($lily);
    $new->dirty(0);
    $new;
}

sub to_lily {
    my ($self) = @_;
    my ($lily, $m) = ("", $self->next_movement);
    while (1) {
        warn sprintf "SAVING MOVEMENT [%s] [%s]",
            $m, $m->name;
        $lily .= $m->to_lily;
        $m->is_movement_end and last;
        $m = $m->next_movement;
    }
    $lily;
}

sub save {
    my ($self) = @_;

    $self->has_filename or die "No filename";
    warn sprintf "SAVING TO [%s]", $self->filename;
    my $lily = $self->to_lily;
    write_file $self->filename, $lily;
    $self->dirty(0);
}

sub find_movement {
    my ($self, $n) = @_;

    my $m = $self;
    while (1) {
        $m = $m->next_movement;
        $m == $self     and last;
        $m->name eq $n  and last;
    }
    if ($m == $self) {
        $m = App::Jacana::Document::Movement->new(name => $n);
        $self->prev_movement->insert_movement($m);
    }
    warn "FOUND MVMT [$n] [$m]: " . $self->dump_movement;
    return $m;
}

sub parse_music {
    my ($self, $text) = @_;

    while ($text) {
        $text =~ s/^\s+//;
        if ($text =~ s( ^
            (?: (?<mvmt>[a-zA-Z]+) - )? (?<voice>[a-zA-Z]+) 
            \s* = \s*
            (?<music> $RE{balanced}{-parens => "{}"} )
        )()x) {
            my $m = $self->find_movement($+{mvmt} // "");
            my $v = $m->prev_voice->insert_voice(
                App::Jacana::Music::Voice->from_lily(%+));
        }
        else { last }
    }
    $text and die "Unparsable music [$text]";
}

1;
