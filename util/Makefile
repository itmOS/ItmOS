MODULE_NAME = $(shell basename $(shell pwd))
# Each of submodules Makefiles should provide default, "clean" and "list-objs" targets.
# The "list-objs" target should just output all exported objects.
SUBMODULES = string log test

OBJ = $(foreach DIR, $(SUBMODULES), $(shell $(MAKE) --no-print-directory -C $(DIR) list-objs))
OUTPUT = $(MODULE_NAME).a

all: $(OUTPUT)

$(OUTPUT): $(OBJ)
	$(AR) $(ARFLAGS) $@ $^

%.a: FORCE
	@echo "Building $(MODULE_NAME)/$(shell dirname $@)"
	@$(MAKE) --no-print-directory -C $(shell dirname $@)

FORCE:

clean:
	@for dir in $(SUBMODULES) ; do \
		echo "Cleaning $(MODULE_NAME)/$$dir"; \
		$(MAKE) --no-print-directory clean -C $$dir; \
	done
	rm -rf $(OUTPUT)

.PHONY: all clean $(ISO)
