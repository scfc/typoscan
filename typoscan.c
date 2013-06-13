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

#include <curl/curl.h>
#include <errno.h>
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "typoscan.h"

/* Regular expressions. */
struct typo_regex *regexes;
int regexalloccount, regexcount;

/* Options. */
int run_verbose = 0;

struct Buffer
{
  char *buf;
  size_t size;
};

static size_t writememorycallback (void *contents, size_t size, size_t nmemb, void *userp)
{
  size_t realsize = size * nmemb;
  struct Buffer *b = (struct Buffer *) userp;

  b->buf = b->buf ? realloc (b->buf, b->size + realsize) : malloc (b->size + realsize);
  if (!b->buf) {
    fprintf (stderr, "Not enough memory (realloc returned NULL).\n");

    return 0;
  }

  memcpy (&(b->buf [b->size]), contents, realsize);
  b->size += realsize;

  return realsize;
}

int gettypolist (const char *URL, struct Buffer *b)
{
  b->buf = NULL;
  b->size = 0;

  /* Init the curl session. */
  CURL *curl_handle = curl_handle = curl_easy_init();

  /* Specify URL to get. */
  curl_easy_setopt (curl_handle, CURLOPT_URL, URL);

  /* Set data callback. */
  curl_easy_setopt (curl_handle, CURLOPT_WRITEFUNCTION, writememorycallback);

  /* Set callback parameter. */
  curl_easy_setopt (curl_handle, CURLOPT_WRITEDATA, (void *) b);

  /* Set User-Agent header. */
  curl_easy_setopt (curl_handle, CURLOPT_USERAGENT, "http://tools.wmflabs.org/typoscan/");

  /* Set Accept-Encoding header. */
  curl_easy_setopt (curl_handle, CURLOPT_ACCEPT_ENCODING, "gzip,deflate");

  /* Get content. */
  CURLcode res = curl_easy_perform (curl_handle);

  /* Check for errors. */
  if (res != CURLE_OK)
  {
    fprintf (stderr, "curl_easy_perform() failed: %s\n",
             curl_easy_strerror (res));
    return 0;
  }

  /* Check response code. */
  long http_code;
  curl_easy_getinfo (curl_handle, CURLINFO_RESPONSE_CODE, &http_code);
  if (http_code != 200)
  {
    fprintf (stderr, "Didn't get 200, but %ld.\n",
             http_code);
    return 0;
  }

  return 1;
}

void help (void)
{
  puts ("Usage: typoscan [--help] [--version]                                 \n" \
        "                                                                     \n" \
        "Retrieve a list of regular expressions from                          \n" \
        "http://en.wikipedia.org/wiki/WP:AWB/T, read a Wikipedia dump file on \n" \
        "STDIN and output a list of all page titles that match any of the     \n" \
        "regular expressions to STDOUT.  Diagnostic output is directed to     \n" \
        "STDERR.                                                              \n" \
        "                                                                     \n" \
        "Report bugs to: tim@tim-landscheidt.de                               \n" \
        PACKAGE " home page: <http://tools.wmflabs.org/typoscan/>");

  exit (0);
}

void version (void)
{
  puts (PACKAGE_STRING "                                                               \n" \
        "Copyright (C) 2013 Tim Landscheidt                                            \n" \
        "License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html> \n" \
        "This is free software: you are free to change and redistribute it.            \n" \
        "There is NO WARRANTY, to the extent permitted by law.");

  exit (0);
}

int main (int argc, char *argv [])
{
  struct Buffer b;
  struct option long_options [] =
  {
    {"help",               no_argument,       NULL, 'h'},
    {"typos-pattern-file", required_argument, NULL, 't'},
    {"verbose",            no_argument,       NULL, 'v'},
    {"version",            no_argument,       NULL, 'V'},
    {NULL,                 0,                 NULL, 0}
  };
  int c, option_index = 0;
  char *typos_pattern_filename = NULL;

  while ((c = getopt_long (argc, argv, "ht:vV", long_options, &option_index)) != - 1)
    switch (c)
      {
        case 'h':
          help ();
          break;

        case 't':
          if (!typos_pattern_filename)
            typos_pattern_filename = optarg;
          else
            {
              fprintf (stderr, "%s: option --typos-pattern-file given more than once\n", argv [0]);

              return 1;
            }
          break;

        case 'v':
          run_verbose = 1;
          break;

        case 'V':
          version ();
          break;

        default:
          /* Unknown option.  An error message has already
             been printed by getopt_long (), so we can just
             exit here.  */
          return 1;
      }

  if (optind != argc)
    {
      fprintf (stderr, "%s: no arguments allowed\n", argv [0]);

      return 1;
    }

  if (typos_pattern_filename)
    {
      FILE *f = fopen (typos_pattern_filename, "r");
      if (!f)
        {
          fprintf (stderr,
                   "%s: Cannot open typos pattern file '%s': %s\n",
                   argv [0],
                   typos_pattern_filename,
                   strerror (errno));

          return 1;
        }
      typolist_scan_file (f);
      if (fclose (f))
        {
          fprintf (stderr,
                   "%s: Cannot close typos pattern file '%s': %s\n",
                   argv [0],
                   typos_pattern_filename,
                   strerror (errno));

          return 1;
        }
    }
  else
    {
      /* Initialize curl. */
      curl_global_init (CURL_GLOBAL_ALL);

      /* Get typo list. */
      if (!gettypolist ("http://en.wikipedia.org/w/index.php?title=Wikipedia:AutoWikiBrowser/Typos&action=raw", &b))
      {
        printf ("Couldn't get typo list.\n");

        return 2;
      }

      /* Clean up curl. */
      curl_global_cleanup ();

      /* Parse typo regular expressions. */
      typolist_scan_buffer (b.buf, b.size);
    }

  /* Match against STDIN. */
  dumpscanner_scan ();

  return 0;
}
