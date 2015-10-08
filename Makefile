.include <mauzo.perl.mk>

CONFIG=	${HOME}/.config/morrow.me.uk/Jacana

share/accelmap: ${CONFIG}/accelmap
	sort ${.ALLSRC} | grep -v '^;' >${.TARGET}
