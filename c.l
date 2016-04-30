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

//#include "y.tab.h"
#define	token(x)	x

#endif 

#define	END(v)	(v-1 + sizeof v / sizeof v[0])
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

"auto"				{ count(); return(AUTO); }
"_Bool"				{ count(); return(BOOL); }
"break"				{ count(); return(BREAK); }
"case"				{ count(); return(CASE); }
"char"				{ count(); return(CHAR); }
"_Complex"			{ count(); return(COMPLEX); }
"const"				{ count(); return(CONST); }
"continue"			{ count(); return(CONTINUE); }
"default"			{ count(); return(DEFAULT); }
"do"				{ count(); return(DO); }
"double"			{ count(); return(DOUBLE); }
"else"				{ count(); return(ELSE); }
"enum"				{ count(); return(ENUM); }
"extern"			{ count(); return(EXTERN); }
"float"				{ count(); return(FLOAT); }
"for"				{ count(); return(FOR); }
"goto"				{ count(); return(GOTO); }
"if"				{ count(); return(IF); }
"_Imaginary"			{ count(); return(IMAGINARY); }
"inline"			{ count(); return(INLINE); }
"int"				{ count(); return(INT); }
"long"				{ count(); return(LONG); }
"register"			{ count(); return(REGISTER); }
"restrict"			{ count(); return(RESTRICT); }
"return"			{ count(); return(RETURN); }
"short"				{ count(); return(SHORT); }
"signed"			{ count(); return(SIGNED); }
"sizeof"			{ count(); return(SIZEOF); }
"static"			{ count(); return(STATIC); }
"struct"			{ count(); return(STRUCT); }
"switch"			{ count(); return(SWITCH); }
"typedef"			{ count(); return(TYPEDEF); }
"union"				{ count(); return(UNION); }
"unsigned"			{ count(); return(UNSIGNED); }
"void"				{ count(); return(VOID); }
"volatile"			{ count(); return(VOLATILE); }
"while"				{ count(); return(WHILE); }

L?\"(\\.|[^\\"\n])*\"		{ count(); printf("[%s]\n",yytext); return STRING_LITERAL; }

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

{letter}{letter_or_digit}*	{ s_lookup(Identifier); return Identifier; }
{digit}+			{ s_lookup(Constant); return Constant; }
 
{white_space}+

{other}				return token(yytext[0]);

%%

int column = 0;
void count()
{
	for (int i=0; yytext[i] != '\0'; i++) {
		if (yytext[i] == '\n') {
			column = 0;
		} else if (yytext[i] == '\t') {
			column += 8 - (column % 8);
		} else {
			column++;
		}
	}
//	ECHO;
}
