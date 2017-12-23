RM := rm -f



# The name of the project. If you change this make sure to change it everywhere else
NAME := asmconv



# Build the converter
build: $(NAME)-kompiled

$(NAME)-kompiled: $(NAME).k
	@./build $(NAME).k \
	;touch $(NAME)-kompiled



# Build everything. The test target depends on build target
all: test



# Clean everything
clean:
	@$(RM) -r test.$(NAME).out test.$(NAME).s test.$(NAME).o $(NAME)-kompiled



# Use the test file and print useful information (for debug)
debug: $(NAME)-kompiled
	@./debug test.$(NAME)



# Convert and compile the test file
test: test.$(NAME).out

test.$(NAME).out: build test.$(NAME)
	@./convert test.$(NAME)



# Phony targets
.PHONY: all build clean debug test
