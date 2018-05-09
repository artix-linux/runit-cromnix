SYSCONFDIR = /etc
PREFIX ?= /usr
BINDIR = $(PREFIX)/bin
MANDIR = $(PREFIX)/share/man
LIBDIR = $(PREFIX)/lib
TMPFILESDIR = $(LIBDIR)/tmpfiles.d
RUNITDIR = $(SYSCONFDIR)/runit
SVDIR = $(RUNITDIR)/sv
RUNSVDIR = $(RUNITDIR)/runsvdir
SERVICEDIR = /etc/service
RUNDIR = /run/runit
RCDIR = $(SYSCONFDIR)/rc

RCBIN = rc/rc-sv rc/rc-sysinit rc/rc-shutdown

SYSINITD = $(wildcard rc/sysinit.d/*.sh)
SHUTDOWND = $(wildcard rc/shutdown.d/*.sh)
# SVD = $(wildcard rc/sv.d/*)
SVD = rc/sv.d/hwclock rc/sv.d/netfs rc/sv.d/lvm rc/sv.d/lvm-monitoring rc/sv.d/cryptsetup rc/sv.d/udev

TMPFILES = tmpfile.conf

BIN = zzz pause modules-load

STAGES = 1 2 3 ctrlaltdel

RC = rc/rc.local rc/rc.local.shutdown rc/rc.conf
RCFUNC = rc/functions

LN = ln -sf
CP = cp -R --no-dereference --preserve=mode,links -v
RM = rm -f
RMD = rm -fr --one-file-system
M4 = m4 -P
CHMODAW = chmod a-w
CHMODX = chmod +x

HASRC = yes

EDIT = sed \
	-e "s|@RUNITDIR[@]|$(RUNITDIR)|g" \
	-e "s|@SERVICEDIR[@]|$(SERVICEDIR)|g" \
	-e "s|@RUNSVDIR[@]|$(RUNSVDIR)|g" \
	-e "s|@RUNDIR[@]|$(RUNDIR)|g" \
	-e "s|@RCDIR[@]|$(RCDIR)|g"

%: %.in Makefile
	@echo "GEN $@"
	@$(RM) "$@"
	@$(M4) $@.in | $(EDIT) >$@
	@$(CHMODAW) "$@"
	@$(CHMODX) "$@"



all: all-runit
ifeq ($(HASRC),yes)
all: all-rc
endif

all-runit:
		$(CC) $(CFLAGS) pause.c -o pause $(LDFLAGS)

all-rc: $(RC) $(STAGES) $(RCBIN) $(SVD) $(RCFUNC)

install-runit:
	install -d $(DESTDIR)$(RUNITDIR)
	install -d $(DESTDIR)$(RUNSVDIR)
	install -d $(DESTDIR)$(RUNSVDIR)/default
	install -d $(DESTDIR)$(SVDIR)/sulogin
	$(LN) $(RUNSVDIR)/default $(DESTDIR)$(RUNSVDIR)/current
	$(CP) sv/sulogin $(DESTDIR)$(SVDIR)/
	$(CP) runsvdir/single $(DESTDIR)$(RUNSVDIR)/

	$(LN) $(RUNDIR)/reboot $(DESTDIR)$(RUNITDIR)/
	$(LN) $(RUNDIR)/stopit $(DESTDIR)$(RUNITDIR)/

	install -d $(DESTDIR)$(BINDIR)
	install -m755 $(BIN) $(DESTDIR)$(BINDIR)

	install -d $(DESTDIR)$(TMPFILESDIR)
	install -m755 $(TMPFILES) $(DESTDIR)$(TMPFILESDIR)/runit.conf

	install -d $(DESTDIR)$(MANDIR)/man1
	install -m644 pause.1 $(DESTDIR)$(MANDIR)/man1
	install -d $(DESTDIR)$(MANDIR)/man8
	install -m644 zzz.8 $(DESTDIR)$(MANDIR)/man8/zzz.8
	install -m644 modules-load.8 $(DESTDIR)$(MANDIR)/man8

install-rc:
	install -d $(DESTDIR)$(RUNITDIR)
	install -m755 $(STAGES) $(DESTDIR)$(RUNITDIR)

	install -d $(DESTDIR)$(RCDIR)
	install -d $(DESTDIR)$(RCDIR)/sysinit.d
	install -d $(DESTDIR)$(RCDIR)/shutdown.d
	install -m755 $(RC) $(DESTDIR)$(RCDIR)
	install -m644 $(SYSINITD) $(DESTDIR)$(RCDIR)/sysinit.d
	install -m644 $(SHUTDOWND) $(DESTDIR)$(RCDIR)/shutdown.d
	install -d $(DESTDIR)$(RUNITDIR)
	install -m755 $(STAGES) $(DESTDIR)$(RUNITDIR)

	install -d $(DESTDIR)$(BINDIR)
	install -m755 $(RCBIN) $(DESTDIR)$(BINDIR)

	install -d $(DESTDIR)$(LIBDIR)/rc
	install -m644 $(RCFUNC) $(DESTDIR)$(LIBDIR)/rc
	$(LN) $(LIBDIR)/rc/functions $(DESTDIR)$(RCDIR)/functions

	install -d $(DESTDIR)$(RCDIR)/sv.d
	install -m755 $(SVD) $(DESTDIR)$(RCDIR)/sv.d


install-getty:
	install -d $(DESTDIR)$(SVDIR)
	$(CP) sv/agetty-* $(DESTDIR)$(SVDIR)/

	install -d $(DESTDIR)$(RUNSVDIR)/default
	$(CP) runsvdir/default $(DESTDIR)$(RUNSVDIR)/

install: install-runit
ifeq ($(HASRC),yes)
install: install-rc
endif

clean-runit:
	-rm -f pause

clean-rc:
	-rm -f $(RC) $(STAGES) $(RCBIN) $(SVD) $(RCFUNC)

clean: clean-runit
ifeq ($(HASRC),yes)
clean: clean-rc
endif

clean:

.PHONY: all install clean install-runit install-rc install-getty clean-runit clean-rc all-runit all-rc
