package App::Jacana::Has::Actions;

use App::Jacana::Moose -role;
use App::Jacana::Log;
use MooseX::Copiable;

use App::Jacana::Gtk2::RadioGroup;
use XML::LibXML;

with qw/App::Jacana::Has::App/;

has actions => (
    is          => "rwp",
#    isa         => InstanceOf["Gtk2::ActionGroup"],
#    handles     => ["get_action"],
);

has uimgr => (
    is          => "ro",
    required    => 1,
    traits      => [qw/Copiable/],
);

has _uixml =>       is => "rwp";
has _ui_id =>       is => "rwp";
has _ui_accels =>   is => "rwp";

requires qw/actions_name/;

sub _actions_parse_xml {
    my ($self, $file) = @_;

    my $xml = $self->app->resource->find($file);
    my $XML = XML::LibXML->load_xml(location => $xml);

    my (%radios, %hasr);
    for my $r ($XML->getElementsByTagName('radiogroup')) {
        my $grp = $$r{action};
        $hasr{$grp} = 1;
        my $p = $r->parentNode;
        foreach my $i ($r->childNodes) {
            if ($i->isa('XML::LibXML::Element') &&
                $i->nodeName ne "separator"
            ) {
                push @{$radios{$grp}}, {%$i};
                $hasr{$$i{action}} = 1;
            }
            $r->removeChild($i);
            $p->insertBefore($i, $r);
        }
        $p->removeChild($r);
    }

    my %actions;
    for my $e ($XML->findnodes(q!//*[@action]!)) {
        my $act = $$e{action};
        $hasr{$act} and next;
        my $h = $actions{$act} ||= {};
        for (qw/label toggle stock_id icon_name/) {
            exists $$e{$_} and $$h{$_} = $$e{$_};
        }
    }

    my @accels = map $$_{action}, $XML->getElementsByTagName("accelerator");

    return ($XML, \%actions, \%radios, \@accels);
}

sub _actions_build_group {
    my ($self, $name, $actions, $radios) = @_;
    
    my $grp = Gtk2::ActionGroup->new($name);
    for my $nm (keys %$actions) {
        my $def     = $$actions{$nm};
        my $class   = delete $$def{toggle} 
            ? "Gtk2::ToggleAction" : "Gtk2::Action";
        my $label = $$def{label} // 
            $nm =~ s/([a-z])([A-Z])/$1 \L$2/gr;
        my $act     = $class->new(
            name        => $nm,
            label       => $label,
        );
        $$def{icon_name} and $act->set_icon_name($$def{icon_name});
        $$def{stock_id} and $act->set_stock_id($$def{stock_id});
        $grp->add_action_with_accel($act, "");
    }

    for my $gnm (keys %$radios) {
        my $gact = App::Jacana::Gtk2::RadioGroup->new(
            name => $gnm,
        );
        $grp->add_action_with_accel($gact, "");
        for my $def (@{$$radios{$gnm}}) {
            my $label = $$def{label} // 
                $$def{action} =~ s/([a-z])([A-Z])/$1 \L$2/gr;
            my $act = App::Jacana::Gtk2::RadioMember->new(
                name        => $$def{action},
                label       => $label,
                value       => $$def{value},
            );
            $gact->add_member($act);
            $$def{icon_name} and $act->set_icon_name($$def{icon_name});
            $grp->add_action_with_accel($act, "");
        }
    }

    $grp;
}

sub BUILD { }

before BUILD => sub {
    my ($self) = @_;

    my $name    = $self->actions_name;

    msg DEBUG => "BUILD ACTIONS FOR [$self]";

    my ($xml, $actions, $radios, $accels) = 
        $self->_actions_parse_xml("actions.$name");
    my $grp = $self->_actions_build_group($name, $actions, $radios);
    my @accels = map $grp->get_action($_), @$accels;

    # stringify the docElem rather than the whole doc because otherwise
    # Gtk chokes on the <?xml?>. <sigh>
    my $str = $xml->documentElement->toString;

    $self->_set_actions($grp);
    $self->_set__uixml($str);
    $self->_set__ui_accels(\@accels);
};

sub get_action {
    my ($self, $which) = @_;
    my $actions = $self->actions
        or Carp::confess("No actions for [$self]");
    my $act = $self->actions->get_action($which);
    $act or Carp::carp("Can't find action [$which] on [$self]");
    return $act;
}

sub insert_ui {
    my ($self) = @_;

    $self->_ui_id and Carp::confess("Attempt to reinsert UI for [$self]");

    my $ui  = $self->uimgr;
    my $xml = $self->_uixml;
    my $grp = $self->actions;

    my $id = $ui->add_ui_from_string($xml);
    $ui->insert_action_group($grp, 0);

    $self->_set__ui_id($id);

    msg DEBUG => "ADDED UI FOR [$self]: [$id]\n";# .
        #join "", map "  [$_]\n", 
        #sort map $_->get_accel_path, $grp->list_actions;
}

sub remove_ui {
    my ($self) = @_;

    my $id  = $self->_ui_id
        or Carp::confess("Attempt to remove UI for [$self]");
    my $ui  = $self->uimgr;
    my $grp = $self->actions;

    $ui->remove_ui($id);
    $ui->remove_action_group($grp);
    # Bug in UIManager, I think…
    $_->disconnect_accelerator for @{$self->_ui_accels};
    $self->_set__ui_id(undef);

    msg DEBUG => "REMOVED UI FOR [$self]: [$id]\n";# .
        #join "", map "  [$_]\n", 
        #sort map $_->get_accel_path, $grp->list_actions;
}

1;
