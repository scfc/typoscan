%option noinput nounput noyywrap nodefault prefix="typolist_" outfile="lex.yy.c"

%top {
/*
 * This file is part of typoscan.
 *
 * typoscan is free software: you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation,
 * either version 3 of the License, or (at your option) any
 * later version.
 *
 * typoscan is distributed in the hope that it will be
 * useful, but WITHOUT ANY WARRANTY; without even the
 * implied warranty of MERCHANTABILITY or FITNESS FOR A
 * PARTICULAR PURPOSE.  See the GNU General Public License
 * for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with typoscan.  If not, see
 * <http://www.gnu.org/licenses/>.
 */

#include <config.h>

#include <pcre.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "error.h"

#include "typoscan.h"

static char *bufptr, regexbuf [65536];
}
%x IN_REGEX
%%
\<Typo(\ +[a-z0-9]+=\"[^"]*\")*\ +find=\"   BUF_INIT(regex); BEGIN(IN_REGEX);

<IN_REGEX>{
\"     {
         BUF_NUL(regex);

         /* Copy regular expression string. */
         char *s = strdup (regexbuf);
         if (!s)
           error (EXIT_FAILURE, errno, "out of memory");

         if (regexcount == regexalloccount)
         {
           regexalloccount += 1000;
           regexes = regexes ? realloc (regexes, sizeof (*regexes) * regexalloccount)
                             : malloc (sizeof (*regexes) * regexalloccount);
           if (!regexes)
             error (EXIT_FAILURE, errno, "out of memory");
         }
         const char *errstr;
         int erroffset;
         pcre *re = pcre_compile (regexbuf, 0, &errstr, &erroffset, NULL);
         if (!re)
           {
             if (run_verbose)
               error (0, 0, "Warning: Couldn't compile pattern, ignoring '%s': %d/%s\n", regexbuf, erroffset, errstr);
           }
         else
           {
             /* fprintf (stderr, "Adding regex \"%s\".\n", currentdepot); */
             regexes [regexcount].regex = re;
             regexes [regexcount].extra = pcre_study (regexes [regexcount].regex, 0, &errstr);
             if (!regexes [regexcount].extra && run_verbose)
               error (0, 0, "Warning2: Couldn't study pattern '%s': %s", s, errstr);
             regexes [regexcount].s = s;
             regexcount++;
           }

         BEGIN(INITIAL);
       }
.|\n   BUF_ADD(regex, *yytext);
}

<*>.|\n   /* ignore */
%%
int typolist_scan_buffer (char *buf, size_t size)
{
  typolist__scan_bytes (buf, size);

  regexes = NULL;
  regexalloccount = regexcount = 0;
  while (typolist_lex ());

  return 0;
}

int typolist_scan_file (FILE *f)
{
  typolist_in = f;

  regexes = NULL;
  regexalloccount = regexcount = 0;
  while (typolist_lex ());

  return 0;
}
