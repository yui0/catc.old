%{
int yywrap()
{
	return 1;
}

#ifdef	DEBUG

#include <assert.h>
int main()
{
	char *p;
	assert(sizeof(int) >= sizeof(char *));
	while (p = (char *)yylex())
		printf("%-10.10s is \"%s\"\n", p, yytext);
	return 0;
}

void s_lookup() {}
int yynerrs = 0;

#define	token(x)	(int)"x"

#else

#include "y.tab.h"
#define	token(x)	x

#endif 

#define	END(v)	(v-1 + sizeof v / sizeof v[0])
int screen();
void count();
%}

digit				[0-9]
letter				[a-zA-Z_]
letter_or_digit			[a-zA-Z_0-9]
hex				[a-fA-F0-9]
E				([Ee][+-]?{D}+)
P				([Pp][+-]?{D}+)
FS				(f|F|l|L)
IS				((u|U)|(u|U)?(l|L|ll|LL)|(l|L|ll|LL)(u|U))

white_space			[ \t\n]
blank				[ \t]
other				.

%%
"/*"				{ /*comment()*/; }
"//"[^\n]*			{ /* consume //-comment */ }

^"#"{blank}*{digit}+({blank}+.*)?\n	yymark();

">="				return token(GE);
"<="				return token(LE);
"=="				return token(EQ);
"!="				return token(NE);
"+="				return token(PE);
"-="				return token(ME);
"*="				return token(TE);
"/="				return token(DE);
"%="				return token(RE);
"++"				return token(PP);
"--"				return token(MM);

{letter}{letter_or_digit}*	return screen();

{digit}+			{
					s_lookup(token(Constant));
					return token(Constant);
				}
 
{white_space}+

{other}				return token(yytext[0]);

%%

/*
 *	reserved word screener
 */
struct rwtable {	/* reserved word table */
	char	*rw_name;	/* representation */
	int	rw_yylex;	/* ylex() value */
} rwtable[] = {		/* sorted */
	"break",	token(BREAK),
	"continue",	token(CONTINUE),
	"else",		token(ELSE),
	"if",		token(IF),
	"int",		token(INT),
	"return",	token(RETURN),
	"while",	token(WHILE)
};
 
int screen()
{
	struct rwtable *low = rwtable,
			*high = END(rwtable),
			*mid;
	int c;

	while (low <= high) {
		mid = low + (high - low)/2;
		if (!(c = strcmp(mid->rw_name, yytext)))
			return mid->rw_yylex;
		else if (c < 0)
			low = mid + 1;
		else
			high = mid -1;
	}
	s_lookup(token(Identifier));

	return token(Identifier);
}

int column = 0;
void count()
{
	for (int i=0; yytext[i] != '\0'; i++)
		if (yytext[i] == '\n') {
			column = 0;
		} else if (yytext[i] == '\t') {
			column += 8 - (column % 8);
		} else {
			column++;
		}
//	ECHO;
}
