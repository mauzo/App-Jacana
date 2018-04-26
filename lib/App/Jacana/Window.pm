package App::Jacana::Window;

use utf8;
use 5.012;
use warnings;

use App::Jacana::Moose;
use MooseX::Gtk2;

use App::Jacana::Gtk2::RadioGroup;
use App::Jacana::View;

use Hash::Util::FieldHash ();

with qw/
    App::Jacana::Has::App
    App::Jacana::Has::Actions
/;

has views       => is => "lazy";

has frame           => is => "lazy";
has notebook        => is => "lazy";
has status_bar      => is => "lazy";
has status_items    => is => "lazy";
has status_flash_id => is => "rw", clearer => 1, predicate => 1;

has "+uimgr"        => builder => 1;

sub DEMOLISH {
    my ($self) = @_;
    %{$self->views} = ();
}

sub actions_name { "app" }

push @Data::Dump::FILTERS, sub {
    my ($ctx, $obj) = @_;
    $ctx->object_isa(__PACKAGE__) and
        return { dump => __PACKAGE__ };
    return;
};

# notebook

sub _build_notebook { 
    my $nb = Gtk2::Notebook->new;
    $nb->set_scrollable(1);
    $nb;
}

# views

sub _build_views { 
    Hash::Util::FieldHash::fieldhash my %h;
    \%h;
}

sub add_tab {
    my ($self, $doc) = @_;

    my $nb = $self->notebook;
    my $vw = App::Jacana::View->new(
        copy_from   => $self,
        window      => $self,
        doc         => $doc,
    );
    my $kd = $vw->scrolled;
    my $nm = $doc->filename;
    my $lb = Gtk2::Label->new;

    if ($nm) {
        $lb->set_text(File::Basename::basename $nm);
    }
    else {
        $lb->set_markup("<i>???</i>");
    }

    $self->views->{$kd} = $vw;
    $kd->show_all;
    my $ix = $nb->append_page($kd, $lb);
    $nb->set_current_page($ix);

    return $vw;
}

sub remove_tab {
    my ($self, $tab) = @_;
    my $kid = $tab->scrolled;
    my $nb  = $self->notebook;
    my $ix  = $nb->page_num($kid);
    $ix < 0 and return;
    $nb->remove_page($ix);
}

sub current_tab {
    my ($self) = @_;

    my $nb = $self->notebook;
    my $ix = $nb->get_current_page;
    $ix < 0 and return;
    my $kd = $nb->get_nth_page($ix);

    return $self->views->{$kd};
}

sub _switch_tab :Signal(notebook.switch-page) {
    my ($self, $nb, $ptr, $ix) = @_;

    if (my $old = $self->current_tab) {
        warn "SWITCH AWAY FROM [$old]";
        $old->remove_ui;
    }

    my $kid = $nb->get_nth_page($ix);
    my $tab = $self->views->{$kid};
    warn "SWITCH TAB TO [$tab] [$ix] [$kid]";
    $tab->insert_ui;
    $self->update;
}

sub _add_tab :Signal(notebook.page-added) {
    my ($self, $nb, $kid, $ix) = @_;
    warn "TAB ADDED [$kid] [$ix]";
    $nb->set_tab_reorderable($kid, 1);
}

sub _remove_tab :Signal(notebook.page-removed) {
    my ($self, $nb, $kid, $ix) = @_;
    my $tab = $self->views->{$kid};
    $tab->remove_ui;
    warn "TAB REMOVED [$ix] [$kid] [$tab]";
    delete $self->views->{$kid};
}

sub _reorder_tab :Signal(notebook.page-reordered) {
    my ($self, $nb, $kid, $ix) = @_;
    my $cur = $nb->get_current_page;
    warn "TAB REORDERED [$kid] [$cur]->[$ix]";
}

# frame

sub _build_frame {
    my ($self) = @_;

    my $w = Gtk2::Window->new("toplevel");

    $w->set_icon_from_file($self->app->resource->find("Jacana.png"));
    $w->set_title("Jacana");
    $w->set_default_size(800, 600);

    my $ui = $self->uimgr;
    $self->insert_ui;
    $ui->ensure_update;
    $w->add_accel_group($ui->get_accel_group);

    my $vb = Gtk2::VBox->new(0, 0);
    $vb->pack_start($_, 0, 0, 0) for $ui->get_toplevels("menubar");
    for my $tb ($ui->get_toplevels("toolbar")) {
        $tb->set_style("icons");
        $tb->set_icon_size("small-toolbar");
        $vb->pack_start($tb, 0, 0, 0);
    }

    $vb->pack_start($self->notebook, 1, 1, 0);

    $vb->pack_start($self->status_bar, 0, 0, 0);

    $w->add($vb);
    $w;
}

sub update {
    my ($self) = @_;
    Glib::Idle->add(sub {
        my ($self) = @_;

        my $vw      = $self->current_tab or return;
        my $curs    = $vw->cursor;
        
        $self->frame->set_title(
            sprintf "%s: %s: Jacana",
                $curs ? $curs->movement->name : "",
                $vw->doc->filename,
        );

        my %status = (
            ($curs
                ? (mode => $curs->mode) 
                : (mode => "")),
        );
        warn "SET STATUS: " . Data::Dump::pp(\%status);
        $self->set_status_items(%status);

        return;
    }, $self);
}

sub _quit :Action(Quit) { 
    my ($self) = @_;
    $self->frame->destroy;
}

sub _destroy :Signal(frame.destroy) {
    my ($self) = @_;
    Gtk2->main_quit;
}

sub _open_doc {
    my ($self, $title) = @_;

    my $dlg = Gtk2::FileChooserDialog->new(
        "$title…", $self->frame, "open",
        Cancel => "cancel", OK => "ok",
    );
    $dlg->run eq "ok" or $dlg->destroy, return;
    my $doc = App::Jacana::Document->open($dlg->get_filename);
    $dlg->destroy;

    $doc;
}

sub open :Action(Open) {
    my ($self) = @_;

    my $doc = $self->_open_doc("Open") or return;
    $self->add_tab($doc);
}

sub file_new :Action(New) {
    my ($self) = @_;

    my $doc = App::Jacana::Document->new;
    $doc->empty_document;
    $self->add_tab($doc);
}

# actions

sub _build_uimgr { Gtk2::UIManager->new }

# status bar

sub _build_status_items {
    my ($self) = @_;

    return +{ 
        map {
            my $l = Gtk2::Label->new;
            $l->set_width_chars(6);
            ($_, $l);
        } qw/ mode cursor mark /
    };
}

sub _build_status_bar { 
    my ($self) = @_;
    my $b = Gtk2::Statusbar->new;

    my $ls = $self->status_items;
    my $m = $b->get_message_area;
    $m->foreach(sub {
        $m->set_child_packing($_[0], 1, 1, 0, "end");
    });
    for (qw/mode cursor mark/) {
        my $f = Gtk2::Frame->new;
        $f->add($$ls{$_});
        $f->set_shadow_type("in");
        $m->pack_start($f, 0, 0, 0);
    }
    my $ver = Gtk2::Label->new("version " . App::Jacana->VERSION);
    $m->pack_end($ver, 0, 0, 0);
    $m->reorder_child($ver, 0);

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

sub set_status_items {
    my ($self, %items) = @_;

    my $ls = $self->status_items;
    for (keys %items) {
        $$ls{$_}->set_text($items{$_});
    }
}

sub _status_flash_clear :Signal(actions.pre-activate) {
    my ($self) = @_;

    if ($self->has_status_flash_id) {
        Glib::Source->remove($self->status_flash_id);
        $self->clear_status_flash_id;
    }
    $self->status_bar->remove_all(1);
}

sub status_flash {
    my ($self, $msg) = @_;
    $self->status_bar->push(1, $msg);
    $self->status_flash_id(
        Glib::Timeout->add(4000, $self->weak_closure(sub {
            $_[0]->_status_flash_clear;
            return;
        })));
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
    $self->update;
}

1;
