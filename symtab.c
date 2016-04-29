#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>

#include "symtab.h"
#include "y.tab.h"

extern	FILE	* yyerfp;
extern	int	yynerrs;

void message(char *fmt, ...)
{
	va_list argp;
	va_start(argp, fmt);
	yywhere();
	vfprintf(yyerfp, fmt, argp);
	putc('\n', yyerfp);
	va_end(argp);
}

void error(char *fmt, ...)
{
	va_list argp;
	va_start(argp, fmt);
	fprintf(yyerfp, "[error %d ", ++yynerrs);
	message(argp);
	va_end(argp);
}

void warning(char *fmt, ...)
{
	va_list argp;
	va_start(argp, fmt);
	fputs("[warning] ", yyerfp);
	message(argp);
	va_end(argp);
}

void fatal(char *fmt, ...)
{
	va_list argp;
	va_start(argp, fmt);
	fputs("[fatal error] ", yyerfp);
	message(argp);
	exit(1);
}

void bug(char *fmt, ...)
{
	va_list argp;
	va_start(argp, fmt);
	fputs("BUG: ", yyerfp);
	message(argp);
	exit(1);
}

char *strsave(char *s)
{
	char *cp = calloc(strlen(s)+1, 1);
	if (cp) {
		strcpy(cp, s);
		return cp;
	}
	fatal("N more room to save strings.");
	return 0;
}


// symbol table
struct symtab symtab,		/* blind element */
	* s_gbl;		/* global end of chain */
#define	s_lcl	(& symtab)	/* local end of chain */

// block table
int blknum = 0;		/* current static block depth */

// add a new name to local region
struct symtab *s_create(char *name)
{
	struct symtab * new_entry = (struct symtab *)calloc(1, sizeof(struct symtab));

	if (new_entry) {
		new_entry->s_next = s_lcl->s_next;
		s_lcl->s_next = new_entry;
		new_entry->s_name = strsave(name);
		new_entry->s_type = UDEC;
		new_entry->s_blknum = 0;
		new_entry->s_pnum = NOT_SET;
		return new_entry;
	}
	fatal("No more room for symbols");
	/* NOTREACHED */
}

// move an entry from local to global region
void s_move(struct symtab *symbol)
{
	struct symtab * ptr;

	/* find desired entry in symtab chain (bug if missing) */
	for (ptr = s_lcl; ptr->s_next != symbol; ptr = ptr->s_next)
		if (! ptr->s_next) {
			bug("s_move");
		}

	/* unlink it from its present position */
	ptr->s_next = symbol->s_next;

	/* relink at global end of symtab */
	s_gbl->s_next = symbol;
	s_gbl = symbol;
	s_gbl->s_next = (struct symtab *) 0;

}

// push block table
void blk_push()
{
	++blknum;
}

// initialize symbol and block table
void init()
{
	blk_push();
	s_gbl = s_create("main");
	s_gbl->s_type = UFUNC;
}

// locate entry by name
struct symtab *s_find(char *name)
{
	struct symtab * ptr;
	/* search symtab until match or end of symtab chain */
	for (ptr = s_lcl->s_next; ptr; ptr = ptr->s_next)
		if (! ptr->s_name) {
			bug("s_find");
		} else
			/* return ptr if names match */
			if (strcmp(ptr->s_name, name) == 0) {
				return ptr;
			}
	/* search fails, return NULL */
	return (struct symtab *) 0;
}

/*
 *	interface for lexical analyzer:
 *	locate or enter Identifier, save text of Constant
 */
//int yylex;		/* Constant or Identifier */
void s_lookup(int yylex)
{
	extern char *yytext;	/* text of symbol */

	switch (yylex) {
	case Constant:
		yylval.y_str = strsave(yytext);
		break;
	case Identifier:
		if (yylval.y_sym = s_find(yytext)) {
			break;
		}
		yylval.y_sym = s_create(yytext);
		break;
	default:
		bug("s_lookup");
	}
}

// mark entry as part of parameter_list
struct symtab *link_parm(struct symtab *symbol, struct symtab *next)
{
	switch (symbol->s_type) {
	case PARM:
		error("duplicate parameter %s", symbol->s_name);
		return next;
	case FUNC:
	case UFUNC:
	case VAR:
		symbol = s_create(symbol->s_name);
	case UDEC:
		break;
	default:
		bug("link_parm");
	}
	symbol->s_type = PARM;
	symbol->s_blknum = blknum;
	symbol->s_plist = next;
	return symbol;
}

// declare a parameter
struct symtab *make_parm(struct symtab *symbol)
{
	switch (symbol->s_type) {
	case VAR:
		if (symbol->s_blknum == 2) {
			error("parameter %s declared twice",
			      symbol->s_name);
			return symbol;
		}
	case UDEC:
	case FUNC:
	case UFUNC:
		error("%s is not a parameter", symbol->s_name);
		symbol = s_create(symbol->s_name);
	case PARM:
		break;
	default:
		bug("make_parm");
	}
	symbol->s_type = VAR;
	symbol->s_blknum = blknum;
	return symbol;
}

// define a variable
struct symtab *make_var(struct symtab *symbol)
{
	switch (symbol->s_type) {
	case VAR:
	case FUNC:
	case UFUNC:
		if (symbol->s_blknum == blknum
		                || symbol->s_blknum == 2 && blknum == 3) {
			error("duplicate name %s", symbol->s_name);
		}
		symbol = s_create(symbol->s_name);
	case UDEC:
		break;
	case PARM:
		error("unexpected parameter %s", symbol->s_name);
		break;
	default:
		bug("make_var");
	}
	symbol->s_type = VAR;
	symbol->s_blknum = blknum;
	return symbol;
}

// define a function
struct symtab *make_func(struct symtab *symbol)
{
	switch (symbol->s_type) {
	case UFUNC:
	case UDEC:
		break;
	case VAR:
		error("function name %s same as blobal varialble",
		      symbol->s_name);
		return symbol;
	case FUNC:
		error("duplicate function definition %s",
		      symbol->s_name);
		return symbol;
	case PARM:
	default:
		bug("make_func");
	}
	symbol->s_type = FUNC;
	symbol->s_blknum = 1;
	return symbol;
}

// set or verify number of parameters
void chk_parm(struct symtab *symbol, int count)
{
	if (symbol->s_pnum == NOT_SET) {
		symbol->s_pnum = count;
	} else if ((int) symbol->s_pnum != count)
		warning("function %s should have %d argument(s)",
		        symbol->s_name, symbol->s_pnum);
}

// pop block table
int parm_default(struct symtab *symbol)
{
	int count = 0;

	while (symbol) {
		++count;
		if (symbol->s_type == PARM) {
			symbol->s_type = VAR;
		}
		symbol = symbol->s_plist;
	}
	return count;
}

void blk_pop()
{
	struct symtab * ptr;

	for (ptr = s_lcl->s_next;
	                ptr &&
	                (ptr->s_blknum >= blknum || ptr->s_blknum == 0);
	                ptr = s_lcl->s_next) {
		if (! ptr->s_name) {
			bug("blk_pop null name");
		}

#ifdef TRACE
		{
			static char * type[] =
			        { SYMmap };

			message("Popping %s: %s, depth %d, offset %d",
			        ptr->s_name, type[ptr->s_type],
			        ptr->s_blknum, ptr->s_offset);
		}
#endif
		if (ptr->s_type == UFUNC)
			error("undefined fuction %s",
			      ptr->s_name);
		free(ptr->s_name);
		s_lcl->s_next = ptr->s_next;
		free(ptr);
	}
	--blknum;
}

/*
 *	check reference or assignment to variable
 */
void chk_var(struct symtab *symbol)
{
	switch (symbol->s_type) {
	case UDEC:
		error("undeclared variable %s", symbol->s_name);
		break;
	case PARM:
		error("unexpected parameter %s", symbol->s_name);
		break;
	case FUNC:
	case UFUNC:
		error("function %s used as variable",
		      symbol->s_name);
	case VAR:
		return;
	default:
		bug("chk_var");
	}
	symbol->s_type = VAR;
	symbol->s_blknum = blknum;
}

/*
 *	check reference to function, implicitly declare it
 */
void chk_func(struct symtab *symbol)
{
	switch (symbol->s_type) {
	case UDEC:
		break;
	case PARM:
		error("unexpected parameter %s", symbol->s_name);
		symbol->s_pnum = NOT_SET;
		return;
	case VAR:
		error("variable %s used as function",
		      symbol->s_name);
		symbol->s_pnum = NOT_SET;
	case UFUNC:
	case FUNC:
		return;
	default:
		bug("chk_func");
	}
	s_move(symbol);
	symbol->s_type = UFUNC;
	symbol->s_blknum = 1;
}


int g_offset = 1,	/* offset in global region */
        l_offset = 0,	/* offset in local region */
        l_max;		/* size of local region */

// allocate a (global or local) variable
void all_var(struct symtab *symbol)
{
	extern struct symtab * make_var();
	symbol = make_var(symbol);

	// if not in parameter region, assing suitable offset
	switch (symbol->s_blknum) {
	default:	// local region
		symbol->s_offset = l_offset++;
	case 2:	// parameter region
		break;
	case 1:
		symbol->s_offset = g_offset++;
		break;
	case 0:
		bug("all_var");
	}
}

// complete allocation
void all_program()
{
	blk_pop();
#ifdef	TRACE
	message("global region has %d word(s)", g_offset);
#endif
}

// allocate all parameters
void all_parm(struct symtab *symbol)
{
	int p_offset = 0;

	while (symbol) {
		symbol->s_offset = p_offset++;
		symbol = symbol->s_plist;
	}
#ifdef	TRACE
	message("parameter region has %d word(s)", p_offset);
#endif
}

// complete allocation of a function
void all_func(struct symtab *symbol)
{
	blk_pop();
#ifdef	TRACE
	message("local region has %d word(s)", l_max);
#endif
}
