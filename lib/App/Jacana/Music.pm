package App::Jacana::Music;

use Moo;
use MooX::AccessorMaker
    apply => [qw/ MooX::MakerRole::IgnoreUndef /];

use App::Jacana::Util::Types;

use namespace::clean;

with qw/
    MooX::Role::Copiable
    App::Jacana::Util::LinkList
/;

has ambient     => (
    is          => "rw",
    lazy        => 1,
    builder     => 1,
    isa         => InstanceOf["App::Jacana::Music::Ambient"],
    weak_ref    => 1,
    ignore_undef    => 1,
    clearer     => 1,
);

has rendered    => (
    is      => "lazy",
    clearer => 1,
    isa     => InstanceOf["Cairo::RecordingSurface"],
);

sub _build_ambient {
    my ($self) = @_;

    $self->is_list_start and die "Start of list must be HasAmbient";
    $self->prev->ambient;
}

# Otherwise we get a method conflict (grr)
sub BUILD { }

sub to_lily { "" }

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

sub get_time {
    my ($self) = @_;

    my $dur = 0;
    while (!$self->is_list_start) {
        $self->DOES("App::Jacana::HasLength")
            and $dur += $self->duration;
        $self = $self->prev;
    }

    $dur;
}

1;
