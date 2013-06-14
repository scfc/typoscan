%option noinput nounput noyywrap nodefault prefix="dumpscanner_" outfile="lex.yy.c"

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

#include <stdio.h>

#include "error.h"

#include "typoscan.h"

static char pagebuf [65536];
static char pageidbuf [16];
static char textbuf [10 * 1024 * 1024];
static char *bufptr;
static int ns0seen;
}

%x IN_PAGE IN_TITLE IN_PAGEID IN_TEXT
%%
"<page>"   { BEGIN(IN_PAGE); ns0seen = 0; }

<IN_PAGE>"<ns>0</ns>"   ns0seen = 1;

<IN_PAGE>"</page>"   {
                        if (ns0seen)
                        {
                          int i;
                          size_t textbuflen = strlen (textbuf);

                          for (i = 0; i < regexcount; i++)
                          {
                            int rc = pcre_exec (regexes [i].regex,
                                                regexes [i].extra,
                                                textbuf,
                                                textbuflen,
                                                0,
                                                0,
                                                NULL,
                                                0);
                            if (!rc)   /* Matched. */
                            {
                              printf ("%s\n", pagebuf);
                              break;
                            }
                            if (rc != PCRE_ERROR_NOMATCH)
                              error (0, 0, "Error while matching: %d\n", rc);
                          }
                        }
                        BEGIN(INITIAL);
                      }

<IN_PAGE>{
"<title>"                         BUF_INIT(page); BEGIN(IN_TITLE);
\n"    <id>"                      BUF_INIT(pageid); BEGIN(IN_PAGEID);
"<text xml:space=\"preserve\">"   BUF_INIT(text); BEGIN(IN_TEXT);
}

<IN_TITLE>{
"</title>"   BUF_NUL(page); BEGIN(IN_PAGE);
"\\"         BUF_ADD(page, '\\'); BUF_ADD(page, '\\');
"&amp;"      BUF_ADD(page, '&');
"&quot;"     BUF_ADD(page, '"');
"&lt;"       BUF_ADD(page, '<');
"&gt;"       BUF_ADD(page, '>');
"&#039;"     BUF_ADD(page, '\'');
.|\n         BUF_ADD(page, *yytext);
}

<IN_PAGEID>{
"</id>"    BUF_NUL(pageid); BEGIN(IN_PAGE);
.|\n       BUF_ADD(pageid, *yytext);
}

<IN_TEXT>{
"</text>"   {
              BUF_NUL(text);
              BEGIN(IN_PAGE);
            }
"&amp;"     BUF_ADD(text, '&');
"&quot;"    BUF_ADD(text, '"');
"&lt;"      BUF_ADD(text, '<');
"&gt;"      BUF_ADD(text, '>');
"&#039;"    BUF_ADD(text, '\'');
.|\n        BUF_ADD(text, *yytext);
}

<*>.|\n   /* ignore */
%%
int dumpscanner_scan (void)
{
  while (dumpscanner_lex ());

  return 0;
}
