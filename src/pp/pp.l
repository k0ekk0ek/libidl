%{
/* The GNU Compiler Collection uses cpplib, which offers tokens as input.
   While that certainly leads to much better performance, it also requires the
   preprocessor to know the grammer of the language it is preprocessing and
   makes it harder to test each individual component (preprocessor vs.
   compiler). For these reasons the preprocessor will simply provide the
   preprocessed output to the compiler as a text stream, at least for now.

   To ensure compiler messages report the correct source location, the
   preprocessor provides a source location map that the compiler can use to
   retrieve the location of a token in the source file. The preprocessor will
   only recognize preprocessor directives, identifiers and numbers. All other
   tokens will simply be pushed directly to the compiler. */

#include <assert.h>
#include <stdlib.h>
#include <string.h>

#include "idl/ctype.h"
#include "idl/tools.h"

static int unesclf(char *yytext);
%}

%option noyywrap
%option nounistd
%option never-interactive
%option prefix="idl_pp_"
%option reentrant
%option bison-bridge
%option bison-locations

%x DIRECTIVE
%x INCLUDE_DIRECTIVE
%x ANGLED_INCLUDE_DIRECTIVE
%x QUOTED_INCLUDE_DIRECTIVE
%x NAMED_DIRECTIVE

%{
/* like cpplib, treat each '\r', '\n', '\r\n' and '\n\r' as a single newline
   to transparently preprocess MS-DOS, Macintosh and Unix files */

/* backslash-newline sequences are tricky, they can just about appear anywhere,
   including in the middle of identifiers and preprocessor directives. to make
   keeping line and column count easier, identifiers are matched escaped
   newlines included. escaped newlines are then removed before the user action
   is executed */
%}
newline         (\r\n|\n\r|[\r\n])
horiz_wspace    [ \t]
esclf           \\{horiz_wspace}*{newline}
identifier      [a-zA-Z_](([a-zA-Z0-9_]|{esclf})*[a-zA-Z0-9_])?

%{
/* these operator patterns are only used within preprocessor directives.
   tokenization for the compiler is explicitly not handled within the
   preprocessor */
%}

lshift          \<{esclf}*\<
rshift          \>{esclf}*\>
lteq            \<{esclf}*\=
gteq            \>{esclf}*\>
eq              \={esclf}*\=
neq             \!{esclf}*\=
and             \&{esclf}*\&
or              \|{esclf}*\|

%{
/* YY_USER_ACTION is executed before the action and keeps track of the source
   location for each token */
#define YY_USER_ACTION                          \
  do {                                          \
    yylloc->first_line = yylloc->last_line;     \
    yylloc->first_column = yylloc->last_column; \
    for(int i = 0; yytext[i] != '\0'; i++) {    \
      if (yytext[i] == '\n') {                  \
        yylloc->last_line++;                    \
        yylloc->last_column = 0;                \
      } else {                                  \
        yylloc->last_column++;                  \
      }                                         \
    }                                           \
  } while (0);

/* to push characters back onto the input stream unput cannot be used as that
   would corrupt line and column counts */

%}

%%

^{horiz_wspace}*#
  { /* preprocessor directives may be preceeded by whitespace */
    BEGIN(DIRECTIVE);
  }

<*>{esclf}
  { /* ignore backslash-newline sequences */ }

<*>{newline}
  { /* newlines terminate preprocessor directives (and line comments) */
    BEGIN(INITIAL);
    return NEWLINE;
  }

<DIRECTIVE>{identifier}
  {
    int tok;
    char *ident;

    unesclf(yytext);

    if ((tok = idl_pp_istoken(yytext))) {
      if (tok == INCLUDE) {
        BEGIN(INCLUDE_DIRECTIVE);
      }
      return tok;
    } else {
      tok = IDENTIFIER;
      if ((ident = strdup(yytext)) == NULL) {
        // FIXME: use yyerror
        fprintf(stderr, "Out of memory\n");
      } else {
        yylval->ident = ident;
      }
    }

    return tok;
  }

<INCLUDE_DIRECTIVE,NAMED_DIRECTIVE>{identifier}
  {
    unesclf(yytext);
    if ((yylval->ident = strdup(yytext)) == NULL) {
      // FIXME: use yyerror
      fprintf("Out of memory\n");
    }

    return IDENTIFIER;
  }

<DIRECTIVE,INCLUDE_DIRECTIVE,NAMED_DIRECTIVE>{lshift} |
<DIRECTIVE,INCLUDE_DIRECTIVE,NAMED_DIRECTIVE>{rshift} |
<DIRECTIVE,INCLUDE_DIRECTIVE,NAMED_DIRECTIVE>{lteq}   |
<DIRECTIVE,INCLUDE_DIRECTIVE,NAMED_DIRECTIVE>{gteq}   |
<DIRECTIVE,INCLUDE_DIRECTIVE,NAMED_DIRECTIVE>{eq}     |
<DIRECTIVE,INCLUDE_DIRECTIVE,NAMED_DIRECTIVE>{new}    |
<DIRECTIVE,INCLUDE_DIRECTIVE,NAMED_DIRECTIVE>{and}    |
<DIRECTIVE,INCLUDE_DIRECTIVE,NAMED_DIRECTIVE>{or}
  {
    int tok;

    unesclf(yytext);
    tok = idl_pp_istoken(yytext);
    assert(tok != 0);

    return tok;
  }

<INCLUDE_DIRECTIVE>\<
  {
    BEGIN(ANGLED_INCLUDE_DIRECTIVE);
    return yytext[0];
  }

<ANGLED_INCLUDE_DIRECTIVE>[^\>\n]*
  { /* argument of #include behaves like a string constant. comments are not
       recognized, and macro names are not expanded. however, if backslashes
       occur within file, they are considered ordinary text characters, not
       escape characters. */
  }

<ANGLED_INCLUDE_DIRECTIVE>\>
  {
    BEGIN(NAMED_DIRECTIVE);
    return yytext[0];
  }

<INCLUDE_DIRECTIVE>"\""
  {
    BEGIN(QUOTED_INCLUDE_DIRECTIVE);
  }

<QUOTED_INCLUDE_DIRECTIVE>[^\"\n]*
  { /* see ANGLED_INCLUDE_DIRECTIVE comment */
  }

<QUOTED_INCLUDE_DIRECTIVE>"\""
  {
    BEGIN(NAMED_DIRECTIVE);
  }

%%

/* FIXME: unesclf should return the number of discarded newlines so the lexer
          can keep track of the number of newlines to push back onto the input
          stream */
/* FIXME: unesclf should warn if there is any whitespace between the backslash
          and the newline */
/* remove all backslash-newline sequences */
#if !defined(TESTING)
static
#endif
void unesclf(char *yytext)
{
#define NONE (0)
#define ESC (1)
  int c, s = 0;
  size_t i, j, k;

  assert(yytext != NULL);

  i = j = k = 0;
  do {
    c = yytext[i];
    if (s == NONE) {
      if (c == '\\') {
        k = i;
        s = ESC;
      } else if (i != j) {
        /* simply copy the character */
        yytext[j++] = yytext[i];
      }
      i++;
    } else if (c != ' ' && c != '\t' && c != '\r') {
      assert(s == ESC);
      if (c == '\n') {
        /* discard backslash-newline */
        s = NONE;
        k = ++i;
      } else {
        /* copy everything up to 'i', but don't increment it as the current
           character might be a '\\', which could be the first character of a
           backslash-newline sequence */
        while (k < i) {
          yytext[j++] = yytext[k++];
        }
      }
    }
  } while (yytext[i] != '\0');

  yytext[j] = '\0'; /* just to be safe */

#undef ESC
#undef NONE

  return 0;
}

