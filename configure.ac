AC_INIT([typoscan], [0.1dev], [tim@tim-landscheidt.de])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_TESTDIR([tests])

AM_INIT_AUTOMAKE([foreign no-dist color-tests parallel-tests silent-rules -Wall -Werror])
AC_PROG_INSTALL

AC_PROG_CC
gl_EARLY

AM_PROG_LEX

# For gnulib.
gl_INIT

# Libraries.
AC_CHECK_HEADER([pcre.h], , [AC_MSG_ERROR([pcre is required])])
AC_CHECK_LIB([pcre], [pcre_compile], , [AC_MSG_ERROR([pcre is required])])
LIBCURL_CHECK_CONFIG([yes], , , [AC_MSG_ERROR([libcurl is required])])

AC_CONFIG_HEADERS([config.h])
AC_CONFIG_FILES([Makefile lib/Makefile tests/Makefile])

AC_OUTPUT
