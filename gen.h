/*
 *	operation codes for pseudo machine
 */

#define OP_ALU	"alu"		/* arithmetic-logic-op	*/
#define OP_DEC	"dec"		/* region,offset	*/
#define OP_INC	"inc"		/* region,offset	*/
#define OP_LOAD	  "load"	/* region,offset	*/
#define OP_STORE  "store"	/* region,offset	*/
#define OP_POP	  "pop"		/* 			*/
#define OP_JUMPZ  "jumpz"	/* label		*/
#define OP_JUMP   "jump"	/* label		*/
#define OP_CALL   "call"	/* parm-count,address	*/
#define OP_ENTRY  "entry"	/* local-frame-size	*/
#define OP_RETURN "return"	/* 			*/

/*
 *	region modifiers
 */

#define	MOD_GLOBAL "gbl"	/* global region	*/
#define	MOD_PARAM  "par"	/* parameter region	*/
#define MOD_LOCAL  "lcl"	/* local region		*/
#define MOD_IMMED  "con"	/* load only: Constant	*/

/*
 *	OP_ALU modifiers
 */

#define ALU_ADD "+"		/* addtion		*/
#define ALU_SUB "-"		/* subtraction		*/
#define ALU_MUL "*"		/* multiplication	*/
#define ALU_DIV "/"		/* division		*/
#define ALU_MOD	"%"		/* remainder		*/
#define ALU_LT	"<"		/* compares as: <	*/
#define ALU_GT	">"		/*		>	*/
#define ALU_LE	"<="		/*		<=	*/
#define ALU_GE	">="		/*		>=	*/
#define ALU_EQ	"=="		/*		==	*/
#define ALU_NE	"!="		/*		!=	*/
#define ALU_AND	"&"		/* bit-wise and		*/
#define ALU_OR	"|"		/* bit-wise or		*/
#define ALU_XOR	"^"		/* bit-wise excl. or	*/

/*
 *	typed functions, code generator
 */

char * gen_mod();		/* region modifier	*/
