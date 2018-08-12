#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

#include "parser.h"

static void
usage(const char *prog)
{
  fprintf(stderr, "Usage: %s FILE\n", prog);
}

int
main(int argc, char *argv[])
{
  int ret = EXIT_FAILURE;

  if (argc != 2) {
    usage(argv[0]);
  } else if (idl_parse_file(argv[1]) == 0) {
    ret = EXIT_SUCCESS;
  }

  return ret;
}
