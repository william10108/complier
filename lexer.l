/* lexer.l */
%option noyywrap
%option yylineno

%{
#include "parser.tab.h"
#include <stdlib.h>
%}

ID      [a-zA-Z_][a-zA-Z0-9_]*
NUMBER  [0-9]+

%%

\n              { yylineno++;            /* 記錄行號 */ }
[ \t\r]+        /* skip whitespace */;
"int"           return INT;
"return"        return RETURN;
"if"            return IF;
"else"          return ELSE;
"while"         return WHILE;
"for"           return FOR;        /* 新增 for */

"=="            return EQ;
"!="            return NE;
"<="            return LE;
">="            return GE;
"&&"            return ANDAND;
"||"            return OROR;
"!"             return NOT;

{ID}            { yylval.sval = strdup(yytext); return IDENTIFIER; }
{NUMBER}        { yylval.ival = atoi(yytext);    return NUMBER; }

"("             return '(';
")"             return ')';
"{"             return '{';
"}"             return '}';
";"             return ';';
","             return ',';
"="             return '=';
"<"             return '<';
">"             return '>';
"+"             return '+';
"-"             return '-';
"*"             return '*';
"/"             return '/';

.               { return yytext[0]; }
%%
