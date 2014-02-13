package App::Jacana::Music;

use Moo;

with qw/
    MooX::Role::Copiable
    App::Jacana::Util::LinkList
/;

# Otherwise we get a method conflict (grr)
sub BUILD { }

sub to_lily { "" }

# position($centre)
# $centre is the note on the centre staff line, where middle C is 0.
# Returns the staff line on which this should be drawn.
sub staff_line { 0 }

# draw($cairo)
# Draws this object. $cairo is positioned at the requested height, and
# the feta font is selected and scaled appropriately.
sub draw { return }

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
