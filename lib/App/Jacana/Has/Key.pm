package App::Jacana::Has::Key;

use App::Jacana::Moose -role;
use MooseX::Copiable;

sub _mkfifths { map "$_$_[0]", qw/f c g d a e b/ }

my @Fifths = map _mkfifths($_), "es", "", "is";
my %Fifths = map +($Fifths[$_], $_), 0..$#Fifths;
my %Mode = qw/ major 8 minor 11 /;

has key     => (
    is      => "rw",
    traits  => [qw/Copiable/],
    isa     => Key,
);
has mode    => (
    is      => "rw",
    traits  => [qw/Copiable/],
    isa     => Enum[keys %Mode],
);

sub staff_line { 0 }

sub to_lily {
    my ($self) = @_;
    sprintf "\\key %s \\%s", 
        $Fifths[$self->key + $Mode{$self->mode}],
        $self->mode;
}

sub from_lily {
    my ($self, %c) = @_;
    $self->new(
        mode    => $c{mode},
        key     => $Fifths{$c{note}} - $Mode{$c{mode}},
    );
}

sub _keys_for_mode {
    my ($self, $mode) = @_;
    map $Fifths[$_ + $Mode{$mode}], -7..7;
}

sub set_from_note {
    my ($self, $note) = @_;
    
    my $old = $self->key;
    my $new = $Fifths{$note} - $Mode{$self->mode};

    if ($new - $old > 3 and $new >= 0) {
        $new -= 7;
    }
    elsif ($old - $new > 3 and $new <= 0) {
        $new += 7;
    }
    if ($new == $old) {
        $new =  
            $old == 7   ? -7
            : $new <= 0 ? $new + 7
            : $new - 7;
    }
    $self->key($new);
}

sub chroma {
    my ($self, $note) = @_;
    my $key     = $self->key
        or return 0;
    my $count   = abs $key;
    my $fifth   = 
        $key > 0 ? $Fifths{$note} - 7
        : 13 - $Fifths{$note};

    $count > $fifth ? $key/$count : 0;
}

sub _clamp { 
    my ($l, $v) = @_;
    my $m = $l * 2 + 1;
    $v = $v % $m;
    $v > $l ? $v - $m : $v;
}

sub subtract {
    my ($self, $from) = @_;
    _clamp 7, $self->key - $from->key;
}

sub add {
    my ($self, $inc) = @_;
    $self->key(_clamp 7, $self->key + $inc);
}

my @Trans = map _mkfifths($_), "eses", "es", "", "is", "isis";
my %Trans = map +($Trans[$_], $_), 0..$#Trans;

my %Chroma = (qw/eses -2 es -1 is 1 isis 2/, "", 0);

sub transpose {
    my ($self, $by, $pos, $end) = @_;

    while (1) {
        $pos->DOES("App::Jacana::Has::Key")     and return $pos;
        $pos->DOES("App::Jacana::Has::Pitch")   or next;

        my $old = $pos->pitch_to_lily;
        $old =~ s/[',]*$//;
        my $new = $Trans{$old} + $by;
        $new < 0        and $new += 12;
        $new > $#Trans  and $new -= 12;

        warn "TRANSPOSE [$old]->[$new][$Trans[$new]] ($by)";

        my ($note, $chrm) = $Trans[$new] =~ /(.)(.*)/;
        my $near = $pos->nearest($note, $Chroma{$chrm});
        $pos->copy_from($near);
    }
    continue { 
        $pos == $end and return;
        $pos->is_music_end and die "Transpose ran off the end of the voice!";
        $pos = $pos->next;
    }
}

1;
