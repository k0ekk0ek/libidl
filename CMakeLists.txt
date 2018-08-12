project(idlpp C)
cmake_minimum_required(VERSION 3.6)

# Find Bison and Flex
find_package(BISON REQUIRED)
find_package(FLEX REQUIRED)

# Create directory where Bison and Flex generated sources will be placed.
set(GENERATED_SOURCE_DIR "${CMAKE_BINARY_DIR}/src")
file(MAKE_DIRECTORY "${GENERATED_SOURCE_DIR}")

set(PARSER_BASENAME "idl.parser.c")
set(PARSER_PATH "${GENERATED_SOURCE_DIR}/${PARSER_BASENAME}")
set(LEXER_BASENAME "idl.lexer.c")
set(LEXER_PATH "${GENERATED_SOURCE_DIR}/${LEXER_BASENAME}")

bison_target(parser "src/idl.y" "${PARSER_PATH}")
flex_target(
  lexer "src/idl.l" "${LEXER_PATH}"
  COMPILE_FLAGS
    "--header-file=${GENERATED_SOURCE_DIR}/idl.lexer.h")

add_executable(idlpp "src/main.c" "src/tools.c" "src/parser.c" "${BISON_parser_OUTPUTS}" "${FLEX_lexer_OUTPUTS}")
target_include_directories(idlpp PRIVATE "${CMAKE_SOURCE_DIR}/include")
target_include_directories(idlpp PRIVATE "${CMAKE_SOURCE_DIR}/src")
target_include_directories(idlpp PRIVATE "${GENERATED_SOURCE_DIR}")

