#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <gtk2perl.h>

static GtkWidget *
create_menu_item (GtkAction *act)
{
    dTHX; dSP;
    GtkWidget   *wid;

    ENTER; SAVETMPS;

    PUSHMARK(SP);
    mXPUSHs(newSVGtkAction(act));
    PUTBACK;
    call_method("create_menu_item", G_SCALAR);
    SPAGAIN;

    wid = SvGtkWidget(POPs);
    g_object_ref(wid);

    FREETMPS; LEAVE;

    PUTBACK;
    return wid;
}

static GtkWidget *
create_tool_item (GtkAction *act)
{
    dTHX; dSP;
    GtkWidget   *wid;

    ENTER; SAVETMPS;

    PUSHMARK(SP);
    mXPUSHs(newSVGtkAction(act));
    PUTBACK;
    call_method("create_tool_item", G_SCALAR);
    SPAGAIN;

    wid = SvGtkWidget(POPs);
    g_object_ref(wid);

    FREETMPS; LEAVE;

    PUTBACK;
    return wid;
}

MODULE = App::Jacana::Gtk2::RadioMember  PACKAGE = App::Jacana::Gtk2::RadioMember

void
_INSTALL_OVERRIDES (pkg)
        const char *pkg
    PREINIT:
        GType           otype;
        GObjectClass    *oclass;
        GtkActionClass  *aclass;
    CODE:
        otype = gperl_object_type_from_package(pkg);
        if (!otype)
            croak("%s not a glib type", pkg);
        oclass = g_type_class_ref(otype);
        if (!oclass)
            croak("could not find type class for %s", pkg);
        aclass = GTK_ACTION_CLASS(oclass);

        aclass->create_menu_item = create_menu_item;
        aclass->create_tool_item = create_tool_item;

        g_type_class_unref(oclass);
