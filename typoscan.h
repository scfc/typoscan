#include <pcre.h>

/* Buffer manipulation macros. */
#define BUF_INIT(b)        do { bufptr = b ## buf; } while (0)
#define BUF_ADD(b, c)      do                                                    \
                             {                                                   \
                               if (bufptr - b ## buf < sizeof (b ## buf) - 1)    \
                                 *(bufptr)++ = c;                                \
                               else                                              \
                                 {                                               \
                                   fprintf (stdout, #b " overflow: %-*s",        \
                                                    (int) sizeof (b ## buf) - 1, \
                                                    b ## buf);                   \
                                                                                 \
                                   return - 1;                                   \
                                 }                                               \
                             }                                                   \
                           while (0)
#define BUF_NUL(b)         do { *(bufptr) = '\0'; } while (0)

/* Regular expressions. */
extern struct typo_regex
{
  pcre *regex;
  pcre_extra *extra;
  const char *s;
} *regexes;
extern int regexalloccount, regexcount;

/* Options. */
extern int run_verbose;

/* Scanner functions. */
extern int dumpscanner_scan (void);
extern int typolist_scan_buffer (char *buf, size_t size);
extern int typolist_scan_file (FILE *f);
