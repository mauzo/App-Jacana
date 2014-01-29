package App::Jacana::Music::TimeSig;

use Moo;

use App::Jacana::Util::Length;

use List::Util qw/sum max/;

use namespace::clean;

extends "App::Jacana::Music";
with qw/ App::Jacana::HasTime /;

sub from_lily {
    my ($self, %c) = @_;
    if (my $pl = delete $c{plen}) {
        $c{partial} = App::Jacana::Util::Length->new(
            App::Jacana::HasLength->_length_from_lily(
                $pl, delete $c{pdots}));
    }
    $self->new(\%c);
}

sub to_lily {
    my ($self) = @_;
    my $par = $self->partial;
    sprintf("\\time %u/%u", $self->beats, $self->divisor)
        . ($par && " \\partial " . $par->_length_to_lily);
}

sub staff_line { 0 }

# use glyph names for consistency, even though numbers would be easier
my @Num = qw/zero one two three four five six seven eight nine/;

sub _num_glyphs {
    my ($self, $c, $nums) = @_;

    my @gly =
        map [$_, $c->glyph_width($_)],
        map $c->glyph($Num[$_]), 
        split //, $nums;
    my $wd = sum map $$_[1], @gly;
    return $wd, @gly;
}

sub draw {
    my ($self, $c, $pos) = @_;
    
    my ($nwd, @num) = $self->_num_glyphs($c, $self->beats);
    my ($dwd, @den) = $self->_num_glyphs($c, $self->divisor);

    my $doff = ($nwd - $dwd) / 2;

    my $show = sub {
        $c->save;
        for (@_) {
            $c->show_glyphs($$_[0]);
            $c->translate($$_[1], 0);
        }
        $c->restore;
    };

    $c->save;
        $doff < 0 and $c->translate(-$doff, 0);
        $show->(@num);
        $c->translate($doff, 4);
        $show->(@den);
    $c->restore;

    return max $nwd, $dwd;
}

1;
