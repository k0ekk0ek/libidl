#ifndef IDL_TYPE_H
#define IDL_TYPE_H

#include <stdbool.h>
#include <stdint.h>

typedef enum {
  idl_float,
  idl_double,
  idl_longdouble,
  idl_short,
  idl_long,
  idl_longlong,
  idl_ushort,
  idl_ulong,
  idl_ulonglong,
  idl_char,
  idl_wchar,
  idl_boolean,
  idl_octet,
  idl_any
} idl_basic_type_t;

typedef enum {
  idl_integer_literal,
  idl_string_literal,
  idl_wide_string_literal,
  idl_character_literal,
  idl_wide_character_literal,
  idl_fixed_pt_literal,
  idl_floating_pt_literal,
  idl_boolean_literal
} idl_literal_type_t;

typedef struct {
  idl_literal_type_t type;
  union {
    bool bln;
    char chr;
    char *str;
    long long llng;
    long double ldbl;
  } value;
} idl_literal_t;

typedef char *idl_identifier_t;

#endif /* IDL_TYPE_H */
