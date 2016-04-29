# ©2016 YUICHIRO NAKADA

CC = clang
CFLAGS = -Wall -Os
LEX = flex
YACC = yacc -dv

PROGRAM = catc
OBJS = y.tab.o gen.o symtab.o

.SUFFIXES: .c .o

$(PROGRAM): $(OBJS)
	$(CC) -o $(PROGRAM) $^

.c.o:
	$(CC) $(CFLAGS) -c $<

lex.yy.c: c.l
	$(LEX) c.l
y.tab.c: c.y
	$(YACC) c.y
y.tab.o: c.y lex.yy.c

.PHONY: clean
clean:
	$(RM) $(PROGRAM) $(OBJS) lex.yy.c y.tab.[ch] y.output
