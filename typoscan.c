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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "typoscan.h"

/* Regular expressions. */
struct typo_regex *regexes;
int regexalloccount, regexcount;

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

int main (int argc, char *argv [])
{
  struct Buffer b;

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
  typolist_scan (b.buf, b.size);

  /* Match against STDIN. */
  dumpscanner_scan ();

  return 0;
}
