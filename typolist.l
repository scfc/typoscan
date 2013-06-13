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

#include <pcre.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "typoscan.h"

static char *bufptr, regexbuf [65536];
static char currentdepot [65536];
}
%x IN_REGEX
%%
\<Typo(\ +[a-z0-9]+=\"[^"]*\")*\ +find=\"   BUF_INIT(regex); BEGIN(IN_REGEX);

<IN_REGEX>{
\"     {
         BUF_NUL(regex);
         if (regexcount == regexalloccount)
         {
           regexalloccount += 10;
           regexes = regexes ? realloc (regexes, sizeof (*regexes) * regexalloccount)
                             : malloc (sizeof (*regexes) * regexalloccount);
           if (!regexes)
           {
             fputs ("Out of memory.\n", stderr);
             exit (EXIT_FAILURE);
           }
         }
         const char *errstr;
         int erroffset;
         pcre *re = pcre_compile (regexbuf, 0, &errstr, &erroffset, NULL);
         if (!re)
           {
             if (run_verbose)
               fprintf (stderr, "Warning: Couldn't compile pattern, ignoring \"%s\": %d/%s\n", regexbuf, erroffset, errstr);
           }
         else
           {
             free (re);

             if (strcmp (currentdepot, "(") && strlen (currentdepot) + strlen (regexbuf) > 18000)
             {
               strcat (currentdepot, ")");
               /* fprintf (stderr, "Adding regex \"%s\".\n", currentdepot); */
               regexes [regexcount].regex = pcre_compile (currentdepot, 0, &errstr, &erroffset, NULL);
               if (!regexes [regexcount].regex)
               {
                 fprintf (stderr, "Warning2: Couldn't compile pattern, ignoring \"%s\": %d/%s\n", currentdepot, erroffset, errstr);
                 exit (EXIT_FAILURE);
               }
               regexes [regexcount].extra = pcre_study (regexes [regexcount].regex, 0, &errstr);
               if (!regexes [regexcount].extra && run_verbose)
                 fprintf (stderr, "Warning2: Couldn't study pattern \"%s\": %s\n", currentdepot, errstr);
               regexcount++;
               strcpy (currentdepot, "(");
             }

             if (strcmp (currentdepot, "("))
               strcat (currentdepot, "|");
             strcat (currentdepot, regexbuf);
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

  strcpy (currentdepot, "(");
  regexes = NULL;
  regexalloccount = regexcount = 0;
  while (typolist_lex ());

  if (strcmp (currentdepot, "("))
  {
    const char *errstr;
    int erroffset;
    strcat (currentdepot, ")");
    /* fprintf (stderr, "Adding regex \"%s\".\n", currentdepot); */
    regexes [regexcount].regex = pcre_compile (currentdepot, 0, &errstr, &erroffset, NULL);
    if (!regexes [regexcount].regex)
    {
      fprintf (stderr, "Warning2: Couldn't compile pattern, ignoring \"%s\": %d/%s\n", currentdepot, erroffset, errstr);
      exit (EXIT_FAILURE);
    }
    regexes [regexcount].extra = pcre_study (regexes [regexcount].regex, 0, &errstr);
    if (!regexes [regexcount].extra && run_verbose)
      fprintf (stderr, "Warning2: Couldn't study pattern \"%s\": %s\n", currentdepot, errstr);
    regexcount++;
  }

  return 0;
}

int typolist_scan_file (FILE *f)
{
  typolist_in = f;

  strcpy (currentdepot, "(");
  regexes = NULL;
  regexalloccount = regexcount = 0;
  while (typolist_lex ());

  if (strcmp (currentdepot, "("))
  {
    const char *errstr;
    int erroffset;
    strcat (currentdepot, ")");
    /* fprintf (stderr, "Adding regex \"%s\".\n", currentdepot); */
    regexes [regexcount].regex = pcre_compile (currentdepot, 0, &errstr, &erroffset, NULL);
    if (!regexes [regexcount].regex)
    {
      fprintf (stderr, "Warning2: Couldn't compile pattern, ignoring \"%s\": %d/%s\n", currentdepot, erroffset, errstr);
      exit (EXIT_FAILURE);
    }
    regexes [regexcount].extra = pcre_study (regexes [regexcount].regex, 0, &errstr);
    if (!regexes [regexcount].extra && run_verbose)
      fprintf (stderr, "Warning2: Couldn't study pattern \"%s\": %s\n", currentdepot, errstr);
    regexcount++;
  }

  return 0;
}
