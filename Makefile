include config.mk

install:
	@echo installing executable file to ${DESTDIR}${PREFIX}/bin
	@mkdir -p ${DESTDIR}${PREFIX}/bin
	@cp -f fondle ${DESTDIR}${PREFIX}/bin
	@chmod 755 ${DESTDIR}${PREFIX}/bin/fondle

uninstall:
	@echo removing executable file from ${DESTDIR}${PREFIX}/bin
	@rm ${DESTDIR}${PREFIX}/bin/fondle
