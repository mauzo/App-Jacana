package App::Jacana::Window;

use utf8;
use 5.012;
use warnings;

use App::Jacana::Moose;
use MooseX::Gtk2;

use App::Jacana::Gtk2::RadioGroup;
use App::Jacana::View;

use XML::LibXML;

with qw/
    App::Jacana::Has::App
    App::Jacana::Has::Actions
/;

has doc         => is => "ro";
has view        => is => "lazy", clearer => 1;

has frame       => is => "lazy";
has status_bar  => is => "lazy";
has status_mode => is => "lazy";

# we need to BUILD the actions and uimgr
has "+actions"  => is => "rw", writer => "_set_actions", required => 0;
has uimgr       => is => "rwp";

sub BUILD {
    my ($self, @args) = @_;

    my ($xml, $actions, $radios) = $self->_parse_actions_xml();
    $self->_set_actions($self->_build_actions($actions, $radios));
    $self->_set_uimgr($self->_build_uimgr($xml));
}

sub DEMOLISH {
    my ($self) = @_;
    $self->clear_view;
}

# view

sub _build_view {
    my ($self) = @_;
    App::Jacana::View->new(
        copy_from   => $self,
        window      => $self,
        doc         => $self->doc,
    );
}

# frame

sub _build_frame {
    my ($self) = @_;

    my $w = Gtk2::Window->new("toplevel");

    $w->set_title("Jacana");
    $w->set_default_size(800, 600);

    my $ui = $self->uimgr;
    $ui->ensure_update;
    $w->add_accel_group($ui->get_accel_group);

    my $vb = Gtk2::VBox->new;
    $vb->pack_start($_, 0, 0, 0) for $ui->get_toplevels("menubar");
    for my $tb ($ui->get_toplevels("toolbar")) {
        $tb->set_style("icons");
        $tb->set_icon_size("small-toolbar");
        $vb->pack_start($tb, 0, 0, 0);
    }

    $vb->pack_start($self->view->scrolled, 1, 1, 0);

    $vb->pack_start($self->status_bar, 0, 0, 0);

    $w->add($vb);
    $w;
}

sub reset_title {
    my ($self) = @_;
    $self->frame->set_title(
        sprintf "%s: %s: Jacana",
            $self->view->cursor->movement->name,
            $self->doc->filename,
    );
}

sub _quit :Action(Quit) { 
    my ($self) = @_;
    $self->frame->destroy;
}

sub _destroy :Signal(frame.destroy) {
    my ($self) = @_;
    Gtk2->main_quit;
}

# actions

sub _parse_actions_xml {
    my ($self) = @_;

    my $xml = $self->app->resource->find("actions.xml");
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

    return ($XML, \%actions, \%radios);
}

sub _build_actions {
    my ($self, $actions, $radios) = @_;
    
    my $grp = Gtk2::ActionGroup->new("edit");
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

sub _build_uimgr {
    my ($self, $xml) = @_;

    my $ui = Gtk2::UIManager->new;
    # stringify the docElem rather than the whole doc because otherwise
    # Gtk chokes on the <?xml?>. <sigh>
    $ui->add_ui_from_string($xml->documentElement->toString);
    $ui->insert_action_group($self->actions, 0);
    $ui;
}

# status bar

sub _build_status_mode { Gtk2::Label->new("insert") }

sub _build_status_bar { 
    my ($self) = @_;
    my $b = Gtk2::Statusbar->new;

    my $l = $self->status_mode;
    my $r = $l->size_request;
    $l->set_size_request($r->width + 4, -1);
    my $f = Gtk2::Frame->new;
    $f->add($l);
    $f->set_shadow_type("in");
    my $m = $b->get_message_area;
    $m->pack_start($f, 0, 0, 0);
    $m->reorder_child($f, 0);

    my $id = $b->push(0, "loading…");
    Glib::Idle->add(sub { $b->remove(0, $id) });
    $b;
}

sub set_status {
    my ($self, $msg) = @_;
    my $b = $self->status_bar;
    $b->pop(0);
    $b->push(0, $msg);
}

sub status_flash {
    my ($self, $msg) = @_;
    my $b = $self->status_bar;
    my $id = $b->push(1, $msg);
    Glib::Timeout->add(4000, sub { $b->remove(1, $id) });
}

sub silly {
    my ($self) = @_;
    $self->status_flash("Don't be *silly*.");
    return;
}

sub set_busy {
    my ($self, $msg) = @_;
    my $a = $self->app;
    my $b = $self->status_bar;
    my $id = $b->push(2, $msg);
    Glib::Idle->add(sub { $b->remove(2, $id) }, undef,
        # This is what ->busy uses
        Glib::G_PRIORITY_DEFAULT_IDLE - 10);
    $a->busy;
    $a->yield;
}

# show

sub show {
    my ($self) = @_;
    $self->frame->show_all;
    $self->reset_title;
}

Moose::Util::find_meta(__PACKAGE__)->make_immutable;
