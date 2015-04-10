# Each of submodules Makefiles should provide default, "clean" and "list-objs" targets.
# The last one should just output all exported objects.
SUBMODULES = kbd

OBJ = $(foreach DIR, $(SUBMODULES), $(shell $(MAKE) --no-print-directory -C $(DIR) list-objs))
OUTPUT = dev.a

all: $(OUTPUT)

$(OUTPUT): $(OBJ)
	$(AR) $(ARFLAGS) $@ $^

%.a: FORCE
	@echo "Building aux/$(shell dirname $@)"
	@$(MAKE) --no-print-directory -C $(shell dirname $@)

FORCE:

clean:
	@for dir in $(SUBMODULES) ; do \
		echo "Cleaning aux/$$dir"; \
		$(MAKE) --no-print-directory clean -C $$dir; \
	done
	rm -rf $(ISO) $(ISO_ROOT)

.PHONY: all clean $(ISO)
