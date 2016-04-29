/*
 *	sample c -- code generation
 */
#include <stdio.h>

#include "symtab.h"
#include "gen.h"

/*
 *	generate various instrction formats
 */

//char * mod;		/* mnemonic modifier */
//char * comment;	/* istruction comment */
void gen_alu(char *mod, char *comment)
{
	printf("\t%s\t%s\t\t; %s\n", OP_ALU, mod, comment);
}

char * constant;	/* Constant value */
void gen_li(char *constant)
{
	printf("\t%s\t%s,%s\n", OP_LOAD, MOD_IMMED, constant);
}

char *gen_mod(struct symtab *symbol)
{
	switch (symbol->s_blknum) {
	case 1:
		return MOD_GLOBAL;
	case 2:
		return MOD_PARAM;
	}
	return MOD_LOCAL;
}

gen(op, mod, val, comment)
char * op;		/* mnemonic operation code */
char * mod;		/* mnemonic modifier */
int val;		/* offset field */
char * comment;		/* instruction comment */
{
	printf("\t%s\t%s,%d\t\t; %s\n", op, mod, val, comment);
}

gen_pr(op, comment)
char * op;		/* mnemonic operation code */
char * comment;		/* instruction comment */
{
	printf("\t%s\t\t\t; %s\n", op, comment);
}

/*
 *	generate pritable internal label
 */

#define	LABEL	"$$%d"

static char * format_label(label)
int label;
{
	static char buffer[sizeof LABEL + 2];

	sprintf(buffer, LABEL, label);
	return buffer;
}

/*
 *	generate jumps, return target
 */

int gen_jump(op, label, comment)
char * op;		/* mnemonic operation code */
int label;		/* target of jump */
char * comment;		/* instruction comment	*/
{
	printf("\t%s\t%s\t\t; %s\n", op, format_label(label),
	       comment);
	return label;
}

/*
 *	generate unique internal label
 */

int new_label()
{
	static int new_label = 0;
	return ++new_label;
}

/*
 *	define internal label
 */
int gen_label(label)
int label;
{
	printf("%s\tequ\t*\n", format_label(label));
	return label;
}

/*
 *	label stack manager
 */

static struct bc_stack {
	int bc_label;		/* label from new_label */
	struct bc_stack *bc_next;
} * b_top,		/* head of break stack */
* c_top;		/* head of continue stack */

static struct bc_stack * push(stack, label)
struct bc_stack * stack;
int label;
{
	struct bc_stack * new_entry = (struct bc_stack *)
	                              calloc(1, sizeof(struct bc_stack));

	if (new_entry) {
		new_entry->bc_next = stack;
		new_entry->bc_label = label;
		return new_entry;
	}
	fatal("No more room to compile loops.");
	/*NOTREACHED*/
}

static struct bc_stack * pop(stack)
struct bc_stack * stack;
{
	struct bc_stack * old_entry;

	if (stack) {
		old_entry = stack;
		stack = old_entry->bc_next;
		free(old_entry);
		return stack;
	}
	bug("break/continue stack underflow");
	/*notREACHED*/
}

static int top(stack)
struct bc_stack * stack;
{
	if (! stack) {
		error("no loop opne");
		return 0;
	} else {
		return stack->bc_label;
	}
}

/*
 *	BREAK and CONTINUE
 */
void push_break(int label)
{
	b_top = push(b_top, label);
}

void push_continue(int label)
{
	c_top = push(c_top, label);
}

void pop_break()
{
	b_top = pop(b_top);
}

void pop_continue()
{
	c_top = pop(c_top);
}

void gen_break()
{
	gen_jump(OP_JUMP, top(b_top), "BREAK");
}

void gen_continue()
{
	gen_jump(OP_JUMP, top(c_top), "CONTINUE");
}

/*
 *	function call
 */

void gen_call(symbol, count)
struct symtab * symbol;	/* function */
int count;		/* # of arguments */
{
	chk_parm(symbol, count);
	printf("\t%s\t%d,%s\n", OP_CALL, count, symbol->s_name);
	while (count-- > 0) {
		gen_pr(OP_POP, "pop argument");
	}
	gen(OP_LOAD, MOD_GLOBAL, 0, "push result");
}

/*
 *	function prologue
 */
gen_entry(symbol)
struct symtab * symbol;	/* function */
{
	int label = new_label();

	printf("%s\t", symbol->s_name);
	printf("%s\t%s\n", OP_ENTRY, format_label(label));
	return label;
}

fix_entry(symbol, label)
struct symtab * symbol;	/* function */
int label;
{
	extern int l_max;	/* size of local region */

	printf("%s\tequ=\t%d\t\t; %s\n", format_label(label),
	       l_max, symbol->s_name);
}

/*
 *	warp-up
 */
void end_program()
{
	extern int g_offset;	/* size of global region */
	all_program();		/* allocate global variables */
	printf("\tend\t%d,main\n", g_offset);
}
