package App::Jacana::Document::Movement;

use Moo;

use App::Jacana::Music::Voice;
use App::Jacana::Util::Types;

use namespace::clean;

warn "CAN BUILD: " . __PACKAGE__->can("BUILD");
with qw/ 
    App::Jacana::Has::Movements
    App::Jacana::Has::Voices
/;

has name => (
    is      => "rw",
    default => "",
    isa     => Match("[a-zA-Z]*", "movement name"),
);

sub BUILD { }

sub to_lily {
    my ($self) = @_;
    my $nm = $self->name;
    warn "TO_LILY MOVEMENT [%s]: " . $self->dump_voice;
    length $nm and $nm .= "-";
    my ($lily, $v) = ("", $self->next_voice);
    while (1) {
        warn sprintf "TO_LILY VOICE [%s] [%s]",
            $nm, $v->name;
        $lily .= $nm . $v->to_lily . "\n";
        $v->is_voice_end and last;
        $v = $v->next_voice;
    }
    $lily;
}

sub add_lily_voice {
    my ($self, %n) = @_;
    my $v = App::Jacana::Music::Voice->from_lily(%n);
    $self->prev_voice->insert_voice($v);
    return $v;
}

sub add_voice {
    my ($self, $n, $nm) = @_;
    my $vs = $self->voices;
    $n  //= @$vs;
    $nm //= "voice$n";
    my $v = App::Jacana::Music::Voice->new(
        name        => $nm,
        movement    => $self,
    );
    splice @$vs, $n, 0, $v;
    return $v;
}

sub delete_voice {
    my ($self, $n) = @_;
    splice @{$self->voices}, $n, 1;
}

sub move_voice_down {
    my ($self, $n) = @_;
    my $vs = $self->voices;
    @$vs[$n, $n + 1] = @$vs[$n + 1, $n];
}

1;
