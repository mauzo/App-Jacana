package App::Jacana::Has::Articulation;

use Moose::Role;
use MooseX::AttributeShortcuts;
use MooseX::Copiable;

my %Artic = (
    staccato    => { pos => 1,  glyph => 0  },
    accent      => { pos => 1,  glyph => 0, name => "sforzato"  },
    tenuto      => { pos => 1,  glyph => 0  },
    marcato     => { pos => 1,  glyph => 1  },
    portato     => { pos => 1,  glyph => 1  },
    staccatissimo 
                => { pos => 1,  glyph => 1  },
    trill       => { pos => 0   },
    turn        => { pos => 0   },
    prall       => { pos => 0   },
    mordent     => { pos => 0   },
    fermata     => { pos => 1,  glyph => 1  },
    segno       => { pos => 0   },
    coda        => { pos => 0   },
    upbow       => { pos => 0   },
    downbow     => { pos => 0   },
);

has articulation     => (
    is          => "rw",
    copiable    => 1,
    clearer     => 1,
    #isa         => Maybe[Enum[keys %Artic]],
);

sub articulation_types { \%Artic }

1;
