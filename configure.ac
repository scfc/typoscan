AC_INIT([typoscan], [0.1dev], [tim@tim-landscheidt.de])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_TESTDIR([tests])

AM_INIT_AUTOMAKE([foreign no-dist color-tests parallel-tests silent-rules -Wall -Werror])
AC_PROG_INSTALL

AC_PROG_CC

AM_PROG_LEX

# Libraries.
AC_CHECK_LIB([pcre], [pcre_compile])
LIBCURL_CHECK_CONFIG()

AC_CONFIG_FILES([Makefile tests/Makefile])

AC_OUTPUT
