void log_errf(char*, ...);
void log_okf(char*, ...);
void log_warnf(char*, ...);
void tty_printf(char*, ...);
#define ASSERT(c) do { if (!(c)) {					\
      log_errf("Assertion error at %s:%d\n", __FILE__, __LINE__);	\
      return 1;							\
    } } while (0)
