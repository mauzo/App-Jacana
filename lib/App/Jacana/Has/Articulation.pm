package App::Jacana::Has::Articulation;

use Moo::Role;

use App::Jacana::Util::Types;

with qw/MooX::Role::Copiable/;

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

sub articulation_types { qw/
    staccato accent tenuto marcato staccatissimo
    - trill turn prall mordent
    - fermata segno coda
    - upbow downbow
/ }

sub articulation_rx {
    my $artic = join "|", keys %Artic;
    qr( \s* \\ (?<articulation>$artic) )x;
}

has articulation     => (
    is          => "rw",
    copiable    => 1,
    clearer     => 1,
    isa         => Maybe[Enum[keys %Artic]],
);

sub _draw_articulation {
    my ($self, $c, $pos, $up) = @_;

    my $artic   = $self->articulation       or return;
    my $meta    = $Artic{$artic};

    my $glyph   = "scripts." 
        . ($$meta{glyph} ? $up ? "d" : "u" : "")
        . ($$meta{name} || $artic);

    my $y = $$meta{pos}
        ? ($up ? 2.5 : -2.5)
        : ($pos > 4) ? -3.5 : $pos - 8.5;

    $c->save;
        $c->translate(2, $y);
        $c->show_glyphs($c->glyph($glyph));
    $c->restore;
}

1;
