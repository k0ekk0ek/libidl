#ifndef IDL_YY_DECL_H
#define IDL_YY_DECL_H

#define YY_DECL int idl_parser_lex \
  (YYSTYPE * yylval_param, \
   YYLTYPE * yylloc_param, \
   yyscan_t yyscanner, \
   idl_context_t *context)

extern YY_DECL;

#endif /* IDL_YY_DECL_H */

