/*
 * Using of ifunc results in GNU specific OS ABI
 * See
 *     https://gcc.gnu.org/onlinedocs/gcc-4.7.4/gcc/Function-Attributes.html
 *     for ifunc attribute
 */

int my_foo(void) { return 42; }

static int (*resolve_foo (void)) (void)
{ return my_foo; }

int foo (void) __attribute__ ((ifunc ("resolve_foo")));

int main() { return foo(); }
