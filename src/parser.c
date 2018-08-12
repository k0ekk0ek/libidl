#include <assert.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>

#define YYSTYPE IDL_PARSER_STYPE
#define YYLTYPE IDL_PARSER_LTYPE

#define YY_TYPEDEF_YY_SCANNER_T
typedef void* yyscan_t;

#include "idl.parser.h"
#include "yy_decl.h"
#include "idl.lexer.h"

int
idl_parse_file(const char *file)
{
  int err = 0;
  FILE *fh;

  assert(file != NULL);

  if ((fh = fopen(file, "rb")) == NULL) {
    err = errno;
    fprintf(stderr, "Cannot open %s: %s", file, strerror(err));
  } else {
    YYSTYPE yystype;
    YYLTYPE yyltype;
    yyscan_t scanner;

    idl_parser_lex_init(&scanner);
    idl_parser_set_in(fh, scanner);
    idl_parser_parse(scanner, NULL);
    idl_parser_lex_destroy(scanner);
    (void)fclose(fh);
  }

  return err;
}
