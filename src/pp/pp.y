%{
/* C-code */

/* FIXME: maybe define YYPRINT here to have token numbers available too */
%}

/* parser configuration */
%define api.pure full
%define api.prefix {idl_pp_}
%define parse.trace
%locations
%param {yyscan_t scanner}
%param {idl_pp_context_t *context}
%token-table

/* keywords */
%token IFDEF "ifdef"
%token IFNDEF "ifndef"
%token IF "if"
%token ELIF "elif"
%token ELSE "else"
%token ENDIF "endif"
%token INCLUDE "include"
%token DEFINE "define"
%token UNDEF "undef"
%token LINE "line"
%token PRAGMA "pragma"

/* '\r', '\n', '\r\n' and '\n\r' are all considered newline characters */
%token NEWLINE

%start __foobar__

%%

directive:
    '#' directive_name

directive_name:
    IFDEF
  | IFNDEF
  | IF
  | ELIF
  | ELSE
  | ENDIF
  | INCLUDE
  | DEFINE
  | UNDEF
  | LINE
    PRAGMA;

%%

/* C-code */
