package App::Jacana::Music;

use Moo;

# position($centre)
# $centre is the note on the centre staff line, where middle C is 0.
# Returns the staff line on which this should be drawn.
sub position;

# draw($cairo)
# Draws this object. $cairo is positioned at the requested height, and
# the feta font is selected and scaled appropriately.
sub draw;

# Returns a MIDI pitch number, or undef.
sub pitch { return }

1;
