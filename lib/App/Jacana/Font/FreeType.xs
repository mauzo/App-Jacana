#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

UV FT_Get_Name_Index(void *, char *);

MODULE = App::Jacana::Font::FreeType  PACKAGE = Font::FreeType::Face

UV
get_name_index (SV *ffobj, SV *nmsv)
    PREINIT:
        void    *ff;
        char    *name;
    CODE:
        if (!sv_isobject(ffobj) ||
            !sv_derived_from(ffobj, "Font::FreeType::Face"))
        {
            Perl_croak(aTHX_ "Object is not of type Font::FreeType::Face");
        }
        ff      = (void *)SvIV((SV*)SvRV(ffobj));
        name    = SvPV_nolen(nmsv);
        RETVAL  = FT_Get_Name_Index(ff, name);
    OUTPUT:
        RETVAL


