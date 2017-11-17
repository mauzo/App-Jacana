package App::Jacana::Music;

use App::Jacana::Moose;

use App::Jacana::Util::LinkList;
use List::Util      qw/first/;

use namespace::autoclean;

linklist "music";

has rendered    => (
    is      => "lazy",
    clearer => 1,
    #isa     => InstanceOf["Cairo::RecordingSurface"],
);

has bbox => is => "rw", default => sub { +[] };
has system => (
    traits          => ["IgnoreUndef"],
    is              => "rw",
    #isa             => InstanceOf[My "View::System"],
    predicate       => 1,
    weak_ref        => 1,
);

# Otherwise we get a method conflict (grr)
sub BUILD { }

sub prev { $_[0]->is_music_start and return; $_[0]->prev_music }
sub next { $_[0]->is_music_end and return; $_[0]->next_music }
*insert = \&insert_music;
*remove = \&remove_music;

sub lily_rx { die "LILY_RX [$_[0]]" }

sub to_lily { "" }

sub from_lily { 
    my ($class, %args) = @_;
    $class->new(\%args);
}

# position($centre)
# $centre is the note on the centre staff line, where middle C is 0.
# Returns the staff line on which this should be drawn.
sub staff_line { 0 }

# draw($drawctx)
# Draws this object. $cairo is positioned at the requested height, and
# the feta font is selected and scaled appropriately.
sub draw { return }

# lsb($drawctx)
# Returns the left-side-bearing of this object.
sub lsb { 0 }
sub rsb { 2 }

sub get_time {
    my ($self) = @_;

    my $dur = 0;
    while (!$self->is_music_start) {
        $self->DOES("App::Jacana::Has::Length")
            and $dur += $self->duration;
        $self = $self->prev;
    }

    $dur;
}

sub break_ambient {
    my ($self) = @_;
    $self->ambient->owner->clear_ambient;
}

sub find_next_with {
    my ($pos, @roles) = @_;
    $pos = $pos->next
        until !$pos || grep $pos->DOES("App::Jacana::Has::$_"), @roles;
    $pos;
}

1;
