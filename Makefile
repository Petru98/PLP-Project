PROJECTNAME := asm


all: test



test: test.o
	gcc -no-pie -o test test.o


test.o: test.s
	nasm -f elf64 -o test.o test.s


test.s: $(PROJECTNAME)-kompiled test.$(PROJECTNAME)
	krun -o none test.$(PROJECTNAME) > test.s


$(PROJECTNAME)-kompiled: $(PROJECTNAME).k
	kompile $(PROJECTNAME).k
	@touch $(PROJECTNAME)-kompiled



nasm:
	@nasm -f elf64 -o test.o test.s && gcc -no-pie -o test test.o

clean:
	@rm -f test test.s test.o



.PHONY: all nasm clean
