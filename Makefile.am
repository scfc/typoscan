ACLOCAL_AMFLAGS = -I m4

SUBDIRS = lib tests

# For gnulib.
AM_CPPFLAGS = -I$(top_builddir)/lib -I$(top_srcdir)/lib
EXTRA_DIST = m4/gnulib-cache.m4
LDADD = lib/libgnu.a

bin_PROGRAMS = typoscan

typoscan_LDADD = $(LDADD) @LIBCURL@
typoscan_SOURCES = typoscan.c typolist.l dumpscanner.l
