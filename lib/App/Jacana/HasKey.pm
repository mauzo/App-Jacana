package App::Jacana::HasKey;

use Moo::Role;

with qw/ MooX::Role::Copiable /;

my @Fifths = qw/
    fes ces ges des aes ees bes
    f   c   g   d   a   e   b
    fis cis gis dis ais eis bis
/;
my %Fifths = map +($Fifths[$_], $_), 0..$#Fifths;
my %Mode = qw/ major 8 minor 11 /;

has key     => (
    is      => "rw",
    isa     => sub {
        $_[0] =~ /^0|-?[1-7]$/
            or die "Bad key signature [$_[0]]";
    },
    copiable => 1,
);
has mode    => (
    is      => "rw",
    isa     => sub {
        exists $Mode{$_[0]}
            or die "Bad key signature mode [$_[0]]";
    },
    copiable => 1,
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

1;
