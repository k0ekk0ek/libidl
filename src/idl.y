%{
#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>

/* yyscan_t is an opaque pointer, a typedef is required here to break a
   circular dependency introduced with bison 2.6 (normally a typedef is
   generated by flex). the define is required to disable the typedef in flex
   generated code */
#define YY_TYPEDEF_YY_SCANNER_T

typedef void *yyscan_t;

#include "idl/priv/tools.h"

#include "idl.parser.h"
#include "yy_decl.h" /* prevent implicit declaration of yylex */

int
yyerror(
  YYLTYPE *yylloc, yyscan_t yyscanner, idl_context_t *context, char *text);

static int
idl_parser_token_matches_keyword(const char *token);
%}


%code requires {

#include <stdbool.h>
#include "idl/type.h"

struct idl_context {
  /* FIXME: implement */
};

typedef struct idl_context idl_context_t;
}


%union {
  bool boolean;
  idl_basic_type_t type;
  idl_literal_t literal;
  idl_identifier_t identifier;
}

%define api.pure full
%define api.prefix {idl_parser_}
%define parse.trace

%locations
%param {yyscan_t scanner}
%param {idl_context_t *context}

%token-table

%start const_dcl

%token <identifier>
  IDENTIFIER

%token <literal>
  BOOLEAN_LITERAL
  CHARACTER_LITERAL
  WIDE_CHARACTER_LITERAL
  STRING_LITERAL
  WIDE_STRING_LITERAL
  INTEGER_LITERAL
  FLOATING_PT_LITERAL
  FIXED_PT_LITERAL

%type <type>
  floating_pt_type
  integer_type
  char_type
  boolean_type
  octet_type
  const_type
/*any_type*/

%type <literal>
  const_exp
  primary_expr

%type <boolean>
  unsigned

%type <identifier> identifier

/* operators */
%token LSHIFT RSHIFT

/* keywords */
%token CONST "const"
%token NATIVE "native"
%token STRUCT "struct"
%token TYPEDEF "typedef"
%token UNION "union"
%token UNSIGNED "unsigned"

%token FLOAT "float"
%token DOUBLE "double"
%token SHORT "short"
%token LONG "long"
%token CHAR "char"
%token WCHAR "wchar"
%token BOOLEAN "boolean"
%token OCTET "octet"
%token ANY "any"


%%

/* Constant Declaration */

const_dcl:
    CONST const_type identifier '=' const_exp
      { printf("const_type is of: %d\n", $2); }
  ;

const_type:
    integer_type
  | char_type
/* FIXME: wide_char_type */
  | boolean_type
  | floating_pt_type
/* FIXME: string_type */
/* FIXME: wide_string_type */
/* FIXME: fixed_pt_const_type */
/* FIXME: scoped_name */
  | octet_type
  ;

const_exp:
    or_expr
      { };

or_expr:
    xor_expr
  | or_expr '|' xor_expr
      { };

xor_expr:
    and_expr
  | xor_expr '^' and_expr
      { };

and_expr:
    shift_expr
  | and_expr '&' shift_expr
      { };

shift_expr:
    add_expr
  | shift_expr "<<" add_expr
      { }
  | shift_expr ">>" add_expr
      { };

add_expr:
    mult_expr
  | add_expr '+' mult_expr
      { }
  | add_expr '-' mult_expr
      { };

mult_expr:
    unary_expr
  | mult_expr '*' unary_expr
      { }
  | mult_expr '/' unary_expr
      { }
  | mult_expr '%' unary_expr
      { };

unary_expr:
    unary_operator primary_expr
  | primary_expr;

unary_operator:
    '-' { }
  | '+' { }
  | '~' { };

/* FIXME: scoped_name */
primary_expr:
    literal
      {
        idl_literal_t *lit = &($$);
        printf("literal is of type: %d\n", lit->type);
      }
  | '(' const_exp ')'
      { $$ = $2; };

literal:
    INTEGER_LITERAL
  | STRING_LITERAL
/* FIXME: WIDE_STRING_LITERAL */
  | CHARACTER_LITERAL
/* FIXME: WIDE_CHARACTER_LITERAL */
  | FIXED_PT_LITERAL
  | FLOATING_PT_LITERAL
  | BOOLEAN_LITERAL;


/* Basic Types */
floating_pt_type:
    FLOAT { $$ = idl_float; }
  | DOUBLE { $$ = idl_double; }
  | LONG DOUBLE { $$ = idl_longdouble; };

integer_type:
    unsigned SHORT { $$ = ($1 ? idl_ushort : idl_short); }
  | unsigned LONG { $$ = ($1 ? idl_ulong : idl_long); }
  | unsigned LONG LONG { $$ = ($1 ? idl_ulonglong : idl_longlong); }

unsigned:
             { $$ = 0; }
  | UNSIGNED { $$ = 1; };

char_type:
  CHAR { $$ = idl_char; };

/* FIXME: wide_char_type */

boolean_type:
    BOOLEAN { $$ = idl_boolean; };

octet_type:
    OCTET { $$ = idl_octet; };

/*any_type:
    ANY { $$ = idl_any; };*/


identifier:
    IDENTIFIER
      {
        size_t offset = 0;
        if ($1[0] == '_') {
          offset = 1;
        } else if (idl_parser_token_matches_keyword($1) == 0) {
          /* FIXME: come up with a better error message */
          yyerror(&yylloc, scanner, context, "Identifier matches a keyword");
          YYABORT;
        } else if (($$ = strdup($1 + offset)) == NULL) {
          /* FIXME: come up with a better error message */
          yyerror(&yylloc, scanner, context, "Memory exhausted");
          YYABORT;
        }
      };

%%

int
yyerror(
  YYLTYPE *yylloc, yyscan_t yyscanner, idl_context_t *context, char *text)
{
  /* FIXME: implement */
  fprintf(stderr, "ERROR: %s\n", text);
  return 0;
}

static int
idl_parser_token_matches_keyword(const char *token)
{
  size_t i, n;

  assert(token != NULL);

  for (i = 0, n = strlen(token); i < YYNTOKENS; i++) {
    if (yytname[i] != 0
        && yytname[i][    0] == '"'
        && idl_strncasecmp_c(yytname[i] + 1, token, n) == 0
        && yytname[i][n + 1] == '"'
        && yytname[i][n + 2] == 0)
    {
      return 1;
    }
  }

  return 0;
}

