#include <ctype.h>

__asm__(".symver asymbol_1,asymbol@");
__asm__(".symver asymbol_2,asymbol@@VERSION1");

char asymbol_1(char t) {
  return tolower(t);
}

char asymbol_2(char t) {
  return tolower(t);
}
