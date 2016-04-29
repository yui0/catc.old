%{
#include "symtab.h"	/* symbol table mnemonics */
#ifdef SIMULATOR
#include "sim.h"	/* simulator mnemonics */
#else
#include "gen.h"	/* code genneration mnemonics */
#endif

#define	OFFSET(x)	( ((struct symtab *) x) -> s_offset)
#define	NAME(x)		( ((struct symtab *) x) -> s_name)

extern int l_offset, l_max;
%}

%union  {
	struct symtab * y_sym;	/* Identifier */
	char * y_str;		/* Constant */
	int y_num;		/* count */
	int y_lab;		/* label */
}
	
/*
 *	terminal symbols
 */

%token	IDENTIFIER I_CONSTANT F_CONSTANT STRING_LITERAL FUNC_NAME SIZEOF
%token	PTR_OP INC_OP DEC_OP LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
%token	AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token	SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token	XOR_ASSIGN OR_ASSIGN
%token	TYPEDEF_NAME ENUMERATION_CONSTANT

%token	TYPEDEF EXTERN STATIC AUTO REGISTER INLINE
%token	CONST RESTRICT VOLATILE
%token	BOOL CHAR SHORT INT LONG SIGNED UNSIGNED FLOAT DOUBLE VOID
%token	COMPLEX IMAGINARY 
%token	STRUCT UNION ENUM ELLIPSIS

%token	CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN

%token	ALIGNAS ALIGNOF ATOMIC GENERIC NORETURN STATIC_ASSERT THREAD_LOCAL

%token	<y_sym> Identifier
%token	<y_str> Constant
//%token	STRING_LITERAL
//%token	INT
//%token	IF
//%token	ELSE
//%token	WHILE
//%token	BREAK
//%token	CONTINUE
//%token	RETURN
%token	';'
%token	'('
%token	')'
%token	'{'
%token	'}'
%token	'+'
%token	'-'
%token	'*'
%token	'/'
%token	'%'
%token	'>'
%token	'<'
%token	GE	/* >= */
%token	LE	/* <= */
%token	EQ	/* == */
%token	NE	/* != */
%token	'&'
%token	'^'
%token	'|'
%token	'='
%token	PE	/* += */
%token	ME	/* -= */
%token	TE	/* *= */
%token	DE	/* /= */
%token	RE	/* %= */
%token	PP	/* ++ */
%token	MM	/* -- */
%token	','

/*
 *	typed non-terminal symbols
 */

%type	<y_sym> optional_parameter_list, parameter_list
%type	<y_num>	optional_argument_list, argument_list
%type	<y_lab>	if_prefix, loop_prefix

/*
 *	precedentce table
 */

%right	'=' PE ME TE DE RE
%left	'|'
%left	'^'
%left	'&'
%left	EQ NE
%left	'<' '>' GE LE
%left	'+' '-'
%left	'*' '/' '%'
%right	PP MM

%%

program
	:	{ init(); }
	  definitions
		{ end_program(); }

definitions
	: definition
	| definitions definition
		{ yyerrok; }
	| error
	| definitions error

definition
	: function_definition
	| INT function_definition
	| declaration

function_definition
	: Identifier '('
		{ make_func($1);
		  blk_push();
		}
	  optional_parameter_list rp
	  parameter_declarations
		{ chk_parm($1, parm_default($4));
		  all_parm($4);
		  l_max = 0;
		  $<y_lab>$ = gen_entry($1);
		}
	  compound_statement
		{ all_func($1);
		  gen_pr(OP_RETURN, "end of function");
		  fix_entry($1, $<y_lab>7);
		}

optional_parameter_list
	: /* no formal parameters */
		{ $$ = (struct symtab *) 0; }
	| parameter_list
		/* $$ = $1 = chain of formal parameters */

parameter_list
	: Identifier
		{ $$ = link_parm($1, (struct symtab *) 0); }
	| Identifier ',' parameter_list
		{ $$ = link_parm($1, $3);
		  yyerrok;
		}
	| error
		{ $$ = 0; }
	| error parameter_list
		{ $$ = $2; }
	| Identifier error parameter_list
		{ $$ = (struct symtab *)link_parm($1, $3); }
	| error ',' parameter_list
		{ $$ = $3;
		  yyerrok;
		}

parameter_declarations
	: /* null */
	| parameter_declarations parameter_declaration
		{ yyerrok; }
	| parameter_declarations error	

parameter_declaration
	: INT parameter_declarator_list sc

parameter_declarator_list
	: Identifier
		{ make_parm($1); }
	| parameter_declarator_list ',' Identifier
		{ make_parm($3);
		  yyerrok;
		}
	| error
	| parameter_declarator_list error
	| parameter_declarator_list error Identifier
		{ make_parm($3);
		  yyerrok;
		}
	| parameter_declarator_list ',' error

compound_statement
	: '{'
		{ $<y_lab>$ = l_offset;
		  blk_push();
		}
	  declarations statements rr
		{ if (l_offset > l_max)
			l_max = l_offset;
		  l_offset = $<y_lab>2;
		  blk_pop();
		}

declarations
	: /* null */
	| declarations declaration
		{ yyerrok; }
	| declarations error

declaration
	: INT declarator_list sc
	;

declarator_list
	: Identifier
		{ all_var($1); }
	| declarator_list ',' Identifier
		{ all_var($3);
		  yyerrok;
		}
	| error
	| declarator_list error
	| declarator_list error Identifier
		{ all_var($3);
		  yyerrok;
		}
	| declarator_list ',' error
	;

static_assert_declaration
	: STATIC_ASSERT '(' constant_expression ',' STRING_LITERAL ')' ';'
	;

statements
	: /* null */
	| statements statement
		{ yyerrok; }
	| statements error
	;

statement
	: expression sc
		{ gen_pr(OP_POP, "clear stack"); }
	| sc
	| BREAK sc
		{ gen_break(); }
	| CONTINUE sc
		{ gen_continue(); }
	| RETURN sc
		{ gen_pr(OP_RETURN, "RETURN"); }
	| RETURN expression sc
		{ gen(OP_STORE, MOD_GLOBAL, 0, "save result");
		  gen_pr(OP_RETURN, "RETRUN");
		}
	| compound_statement
	| if_prefix statement
		{ gen_label($1); }
	| if_prefix statement ELSE 
		{ $<y_lab>$ = gen_jump(OP_JUMP, new_label(),
			"past ELSE");
		  gen_label($1);
		}
	  statement
		{ gen_label($<y_lab>4); }
	| loop_prefix
		{ $<y_lab>$ = gen_jump(OP_JUMPZ, new_label(),
			"WHILE");
		  push_break($<y_lab>$);
		}
	  statement
		{ gen_jump(OP_JUMP, $1, "repeat WHILE");
		  gen_label($<y_lab>2);
		  pop_break();
		  pop_continue();
		}
	;

if_prefix
	: IF '(' expression rp
		{ $<y_lab>$ = gen_jump(OP_JUMPZ, new_label(), "IF"); }
	| IF error
		{ $<y_lab>$ = gen_jump(OP_JUMPZ, new_label(), "IF"); }
	;

loop_prefix
	: WHILE '('
		{ $<y_lab>$ = gen_label(new_label());
		  push_continue($<y_lab>$);
		}
	  expression rp
		{ $<y_lab>$ = $<y_lab>3; }
	| WHILE error
		{ $<y_lab>$ = gen_label(new_label());
		  push_continue($<y_lab>$);
		}
	;

expression
	: binary
	| expression ','
		{ gen_pr(OP_POP, "discard"); }
	  binary
		{ yyerrok; }
	| error ',' binary
		{ yyerrok; }
	| expression error
	| expression ',' error
	| string
	;

string
	: STRING_LITERAL
	| FUNC_NAME
	;

binary
	: Identifier
		{ chk_var($1);
		  gen(OP_LOAD, gen_mod($1), OFFSET($1), NAME($1));
		}
	| Constant
		{ gen_li($1); }
	| '(' expression rp
	| '(' error rp
	| Identifier '('
		{ chk_func($1); }
	  optional_argument_list rp
	  	{ gen_call($1,$4); }
	| PP Identifier
		{ chk_var($2);
		  gen(OP_INC, gen_mod($2), OFFSET($2), NAME($2));
		}
	| MM Identifier
		{ chk_var($2);
		  gen(OP_DEC, gen_mod($2), OFFSET($2), NAME($2));
		}
	| binary '+' binary
		{ gen_alu(ALU_ADD, "+"); }
	| binary '-' binary
		{ gen_alu(ALU_SUB, "-"); }
	| binary '*' binary
		{ gen_alu(ALU_MUL, "*"); }
	| binary '/' binary
		{ gen_alu(ALU_DIV, "/"); }
	| binary '%' binary
		{ gen_alu(ALU_MOD, "%"); }
	| binary '>' binary
		{ gen_alu(ALU_GT, ">"); }
	| binary '<' binary
		{ gen_alu(ALU_LT, "<"); }
	| binary GE binary
		{ gen_alu(ALU_GE, ">="); }
	| binary LE binary
		{ gen_alu(ALU_LE, "<="); }
	| binary EQ binary
		{ gen_alu(ALU_EQ, "=="); }
	| binary NE binary
		{ gen_alu(ALU_NE, "!="); }
	| binary '&' binary
		{ gen_alu(ALU_AND, "&"); }
	| binary '^' binary
		{ gen_alu(ALU_XOR, "^"); }
	| binary '|' binary
		{ gen_alu(ALU_OR, "|+"); }
	| Identifier '=' binary
		{ chk_var($1);
		  gen(OP_STORE, gen_mod($1), OFFSET($1), NAME($1));
		}
	| Identifier PE
		{ chk_var($1);
		  gen(OP_LOAD, gen_mod($1), OFFSET($1), NAME($1));
		}
	  binary
		{ gen_alu(ALU_ADD, "+");
		  gen(OP_STORE, gen_mod($1), OFFSET($1), NAME($1));
		}
	| Identifier ME
		{ chk_var($1);
		  gen(OP_LOAD, gen_mod($1), OFFSET($1), NAME($1));
		}
	  binary
		{ gen_alu(ALU_SUB, "-");
		  gen(OP_STORE, gen_mod($1), OFFSET($1), NAME($1));
		}
	| Identifier TE
		{ chk_var($1);
		  gen(OP_LOAD, gen_mod($1), OFFSET($1), NAME($1));
		}
	  binary
		{ gen_alu(ALU_MUL, "*");
		  gen(OP_STORE, gen_mod($1), OFFSET($1), NAME($1));
		}
	| Identifier DE
		{ chk_var($1);
		  gen(OP_LOAD, gen_mod($1), OFFSET($1), NAME($1));
		}
	  binary
		{ gen_alu(ALU_DIV, "/");
		  gen(OP_STORE, gen_mod($1), OFFSET($1), NAME($1));
		}
	| Identifier RE
		{ chk_var($1);
		  gen(OP_LOAD, gen_mod($1), OFFSET($1), NAME($1));
		}
	  binary
		{ gen_alu(ALU_MOD, "%");
		  gen(OP_STORE, gen_mod($1), OFFSET($1), NAME($1));
		}

optional_argument_list
	: /* no actual arguments */
		{ $$ = 0; /* # of actual arguments */ }
	| argument_list
		/* $$ = $1 = # of actual arguments */

argument_list
	: binary
		{ $$ = 1; }
	| argument_list ',' binary
		{ ++ $$;
		  yyerrok;
		}
	| error
		{ $$ = 0; }
	| argument_list error
	| argument_list ',' error

/*
 *	make certain terminal symbols very important
 */
rp	: ')'	{ yyerrok; }
sc	: ';'	{ yyerrok; }
rr	: '}'	{ yyerrok; }

;
%%
//#include "y.tab.h"
#include "lex.yy.c"
#include <stdio.h>

FILE *yyerfp;

char *source;		/* current input file name */
// position stamp
void yywhere()
{
	char colon = 0;		/* a flag */

	if (source && *source && strcmp(source, "\"\"")) {
		char	*cp = source;
		int	len = strlen(source);

		if (*cp == '"') {
			++cp, len -= 2;
		}
		if (strncmp(cp, "./", 2) == 0) {
			cp += 2, len -= 2;
		}
		fprintf(yyerfp, "file %.*s", len, cp);
		colon = 1;
	}

	if (yylineno > 0) {
		if (colon) {
			fputs(", ", yyerfp);
		}
		fprintf(yyerfp, "line %d", yylineno - (*yytext == '\n' || !*yytext));
		colon = 1;
	}
	if (*yytext) {
		int i;
		for (i=0; i<20; i++) {
			if (!yytext[i] || yytext[i] == '\n') break;
		}
		if (i) {
			if (colon) {
				putc(' ', yyerfp);
			}
			fprintf(yyerfp, "near \"%.*s\"", i, yytext);
			colon = 1;
		}
	}
	if (colon) {
		fputs(": ", yyerfp);
	}
}

// retrieve from '# digits text'
yymark()
{
	if (source) free(source);
	source = (char *)calloc(yyleng, sizeof(char));
	if (source) {
		sscanf(yytext, "# %d %s", &yylineno, source);
	}
}

void yyerror(char *s)
{
	extern int yynerrs;	// total number of errors
	yyerfp = stdout;

	fprintf(yyerfp, "[error %d] ", yynerrs+1);
	yywhere();
	fprintf(yyerfp, "%s\n", s);
//	fputs(s, yyerfp);
//	putc('\n', yyerfp);
}

int main()
{
	yyerfp = stderr;
	yyparse();
	return 0;
}
