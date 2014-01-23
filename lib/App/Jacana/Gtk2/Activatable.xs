#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <gtk2perl.h>

#define PREP		\
	dSP;		\
	ENTER;		\
	SAVETMPS;	\
	PUSHMARK (SP);	\
	PUSHs (sv_2mortal (newSVGObject (G_OBJECT (self))));

#define CALL		\
	PUTBACK;	\
	call_sv ((SV *)GvCV (slot), G_VOID|G_DISCARD);

#define FINISH		\
	FREETMPS;	\
	LEAVE;

#define GET_METHOD(method)	\
	HV * stash = gperl_object_stash_from_type (G_OBJECT_TYPE (self)); \
	GV * slot = gv_fetchmethod (stash, method);

#define METHOD_EXISTS (slot && GvCV (slot))
		
static void
gtk2perl_activatable_update (
    GtkActivatable  *self,
    GtkAction       *action,
    const gchar     *property_name
) {
    dTHX;
    GET_METHOD("UPDATE");

    if (METHOD_EXISTS) {
        PREP;
        mXPUSHs(newSVGtkAction(action));
        mXPUSHs(newSVpv(property_name, 0));
        CALL;
        FINISH;
    }
    else {
        Perl_warn("No method found for UPDATE");
    }
}

static void
gtk2perl_activatable_sync_action_properties (
    GtkActivatable  *self,
    GtkAction       *action
) {
    dTHX;
    GET_METHOD("SYNC_ACTION_PROPERTIES");

    if (METHOD_EXISTS) {
        PREP;
        mXPUSHs(newSVGtkAction(action));
        CALL;
        FINISH;
    }
    else {
        Perl_warn("No method found for SYNC_ACTION_PROPERTIES");
    }
}

static void
gtk2perl_activatable_init (GtkActivatableIface *iface)
{
    iface->update   = gtk2perl_activatable_update;
    iface->sync_action_properties
                    = gtk2perl_activatable_sync_action_properties;
}

static GtkActivatableIface *if_MenuItem;

static GtkActivatableIface *
find_if_MenuItem ()
{
    if (!if_MenuItem) {
        if_MenuItem = g_type_interface_peek(
            g_type_class_peek(GTK_TYPE_MENU_ITEM),
            GTK_TYPE_ACTIVATABLE
        );
    }
    return if_MenuItem;
}

static GtkActivatableIface *if_ToolButton;

static GtkActivatableIface *
find_if_ToolButton ()
{
    if (!if_ToolButton) {
        if_ToolButton = g_type_interface_peek(
            g_type_class_peek(GTK_TYPE_TOOL_BUTTON),
            GTK_TYPE_ACTIVATABLE
        );
    }
    return if_ToolButton;
}

MODULE = App::Jacana::Gtk2::Activatable  PACKAGE = Gtk2::Activatable

void
_ADD_INTERFACE (self, target)
        SV          *self;
        const char  *target;
    PREINIT:
        static const GInterfaceInfo ifinfo = {
            (GInterfaceInitFunc) gtk2perl_activatable_init,
            NULL,
            NULL
        };
        GType gtype;
    CODE:
        gtype = gperl_object_type_from_package(target);
        g_type_add_interface_static(gtype, GTK_TYPE_ACTIVATABLE, &ifinfo);
       
MODULE = App::Jacana::Gtk2::Activatable  PACKAGE = Gtk2::MenuItem

void
UPDATE (self, action, prop)
        GtkMenuItem     *self;
        GtkAction       *action;
        const gchar     *prop;
    PREINIT:
        GtkActivatableIface *iface;
    CODE:
        iface = find_if_MenuItem();
        iface->update(GTK_ACTIVATABLE(self), action, prop);

void
SYNC_ACTION_PROPERTIES (self, action)
        GtkMenuItem     *self;
        GtkAction       *action;
    PREINIT:
        GtkActivatableIface *iface;
    CODE:
        iface = find_if_MenuItem();
        iface->sync_action_properties(GTK_ACTIVATABLE(self), action);

MODULE = App::Jacana::Gtk2::Activatable  PACKAGE = Gtk2::ToolButton

void
UPDATE (self, action, prop)
        GtkToolButton   *self;
        GtkAction       *action;
        const gchar     *prop;
    PREINIT:
        GtkActivatableIface *iface;
    CODE:
        iface = find_if_ToolButton();
        iface->update(GTK_ACTIVATABLE(self), action, prop);

void
SYNC_ACTION_PROPERTIES (self, action)
        GtkToolButton   *self;
        GtkAction       *action;
    PREINIT:
        GtkActivatableIface *iface;
    CODE:
        iface = find_if_ToolButton();
        iface->sync_action_properties(GTK_ACTIVATABLE(self), action);
