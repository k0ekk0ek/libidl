# Preprocessor

The task of the preprocessor is to offer a file, and all the files it includes
to the compiler in one stream. The stream must be sanitized, have all macros
expanded and disabled conditional sections removed.

## Backslash-newline sequences
Backslash-newline sequences are tricky. The difficulty is not so much in their
recognition, though they can appear just about anywhere, but what to feed the
compiler in order to make sure error messages make any sense. i.e. ensure the
line and column count for a given token corresponds to the line and column
in which it appears in the source file.

* Backslash-newline sequences in non-preprocessor directives can simply be
  discarded until a whitespace character is encountered. Before pushing the
  whitespace character to the parser, unput the discarded number of newlines
  and horizontal whitespace characters to correct the location.

* Macros introduce an exception to the above text. Since expanded macros
  usually take up more space than the original macro, correcting the location
  may require the use of a #line pragma.

* Newline characters terminatee a preprocessor directive. To correct line and
  column counts, necessary whitespace characters must be pushed after the
  entire line is consumed by the compiler.

* Certain backslash-newline sequences simply cannot be corrected. Of course,
  this is not a problem if the internal preprocessor is used, because of the
  source location map, which ensures each token can be mapped to a location
  in the original source file.

