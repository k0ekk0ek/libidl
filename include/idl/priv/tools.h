#ifndef IDL_TOOLS_H
#define IDL_TOOLS_H

int idl_strcasecmp_c(const char *s1, const char *s2);

int idl_strncasecmp_c(const char *s1, const char *s2, size_t n);

int idl_unescape_char(const char *str, char **endptr);

#endif /* IDL_TOOLS_H */
