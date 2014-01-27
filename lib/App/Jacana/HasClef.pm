package App::Jacana::HasClef;

use Moo::Role;

# A named clef type. This must be provided so key signatures know where
# to draw their sharps and flats.
requires "clef";

# The note on the centre line, counting in staff lines above 4' C = 0.
requires "centre_line";

1;
