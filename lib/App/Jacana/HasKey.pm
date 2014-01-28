package App::Jacana::HasKey;

use Moo::Role;

# Accepts a note name, and returns the ambient chroma for that note.
requires "chroma";

1;
