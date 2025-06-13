/* lexer.l */
%option noyywrap yylineno

%{
#include "parser.tab.h"
#include <stdlib.h>
int yycolumn = 1;        /* 全域目前欄位 */
int yystartcol;          /* 本次 token 起始欄位 */
#define YY_USER_ACTION (yystartcol = yycolumn, yycolumn += yyleng)
%}

ID      [a-zA-Z_][a-zA-Z0-9_]*
NUMBER  [0-9]+

%%

\n              { yylineno++; yycolumn = 1; }
[ \t\r]+        { yycolumn += yyleng; }  /* 跳過空白但要累加欄位 */

"int"           { return INT; }
"return"        { return RETURN; }
"if"            { return IF; }
"else"          { return ELSE; }
"while"         { return WHILE; }
"for"           { return FOR; }

"=="            { return EQ; }
"!="            { return NE; }
"<="            { return LE; }
">="            { return GE; }
"&&"            { return ANDAND; }
"||"            { return OROR; }
"!"             { return NOT; }

{ID}            { yylval.sval = strdup(yytext); return IDENTIFIER; }
{NUMBER}        { yylval.ival = atoi(yytext);    return NUMBER; }

"("             { return '('; }
")"             { return ')'; }
"{"             { return '{'; }
"}"             { return '}'; }
";"             { return ';'; }
","             { return ','; }
"="             { return '='; }
"<"             { return '<'; }
">"             { return '>'; }
"+"             { return '+'; }
"-"             { return '-'; }
"*"             { return '*'; }
"/"             { return '/'; }

.               { return yytext[0]; }
%%
