/*
 * Copyright (c) 2008-2010 Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND INTERNET SOFTWARE CONSORTIUM DISCLAIMS
 * ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL INTERNET SOFTWARE
 * CONSORTIUM BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
 * DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
 * PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
 * ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
 * SOFTWARE.
 */

/* We need static unused symbols to be emitted nonetheless.  ICC
 * avoids emitting all the static unused symbols unless it's told
 * explicitly to emit them by the used attribute.
 */
#if defined(__GNUC__)
# define tc_used __attribute__((used))
#else
# define tc_used
#endif

/* We need .data.rel symbols to be emitted */
#if !defined(__PIC__)
# error "This testcase has to be built with PIC enabled"
#endif

char external_variable[] = "foo";
static char static_variable[] tc_used = "foo";

const char external_constant[] = "foo";
static const char static_constant[] tc_used = "foo";

const char *relocated_external_variable = "foo";
const char *const relocated_external_constant = "foo";

static const char *relocated_static_variable tc_used = "foo";
static const char *const relocated_static_constant tc_used = "foo";

char external_uninitialised_variable;
static char static_uninitialised_variable tc_used;

__thread char external_tls_variable[] = "foo";
static __thread char static_tls_variable[] tc_used = "foo";

__thread char external_uninitialised_tls_variable;
static __thread char static_uninitialised_tls_variable tc_used;

__thread const char *relocated_external_tls_variable = "foo";
static __thread const char *relocated_static_tls_variable tc_used = "foo";

void external_function() {
}

extern int undefined_external_variable;

static void tc_used static_function() {
  undefined_external_variable = 0;
}

/* Attributes cold and hot needs to be supported */
#if defined(__GNUC__) && !defined(__ICC) && \
  (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 3))

void __attribute__((cold)) external_cold_function() {
}

static void __attribute__((cold)) tc_used static_cold_function() {
}

void __attribute__((hot)) external_hot_function() {
}

static void __attribute__((hot)) tc_used static_hot_function() {
}

#endif

#if defined(__GNUC__)
int weak_reference_to_variable __attribute__((weak));
void weak_reference_to_function() __attribute__((weak,alias("static_function")));

void *gnu_indirect_function() __asm__ ("gnu_function");
__asm__(".type gnu_function, %gnu_indirect_function");

void *gnu_indirect_function()
{
  return 0l;
}

int gnu_unique_object = 1;
__asm__(".type gnu_unique_object, %gnu_unique_object");

#endif
