package App::Jacana::Music;

use Moo;

with "App::Jacana::Util::LinkList";

sub to_lily { "" }

# position($centre)
# $centre is the note on the centre staff line, where middle C is 0.
# Returns the staff line on which this should be drawn.
sub staff_line { 0 }

# draw($cairo)
# Draws this object. $cairo is positioned at the requested height, and
# the feta font is selected and scaled appropriately.
sub draw { return }

# Returns a MIDI pitch number, or undef.
sub pitch { return }

# Returns duration, or undef.
sub duration { return }

1;
