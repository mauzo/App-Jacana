package App::Jacana::Dialog::Tweaks;

use Moose::Role;
use MooseX::AttributeShortcuts;

use Module::Runtime qw/use_module/;

use namespace::autoclean;

with        qw/ App::Jacana::Has::Tweaks /;
requires    qw/ src /;

my $Tw = "App::Jacana::Dialog::Tweak";

has _tweaks_panel => is => "lazy";

has _tweaks => (
    is          => "ro",
    init_arg    => undef,
    default     => sub { [] },
);

sub _build__tweaks_panel {
    my ($self) = @_;

    my $tws = $self->_tweaks;
    my $src = $self->src;
    my @tw  = $src->known_tweaks;
    my $tab = Gtk2::Table->new(scalar @tw, 3, 0);
    $tab->set_row_spacings(5);
    $tab->set_col_spacings(5);

    for my $r (0..$#tw) {
        my $inf = $self->_tweak_info($tw[$r]);

        my $chk = Gtk2::CheckButton->new;
        $tab->attach_defaults($chk, 0, 1, $r, $r + 1);

        my $lab = Gtk2::Label->new($$inf{desc});
        $lab->set_alignment(0, 0.5);
        $tab->attach_defaults($lab, 1, 2, $r, $r + 1);

        my $typ = "$Tw\::$$inf{type}";
        my $val = use_module($typ)->new(
            exists  => $chk,
            tweak   => $inf,
            value   => $src->tweak($tw[$r]),
        );

        push @$tws, $val;
        $tab->attach_defaults($val->_value, 2, 3, $r, $r + 1);
    }

    my $ex = Gtk2::Expander->new("Tweaks");
    $ex->set_border_width(5);
    $ex->add($tab);
    $ex;
}

1;
