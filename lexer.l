%option noyywrap
%{
#include "parser.tab.h"
#include <stdlib.h>
%}

ID      [a-zA-Z_][a-zA-Z0-9_]*
NUMBER  [0-9]+

%%

"int"           return INT;
"return"        return RETURN;
"if"            return IF;
"else"          return ELSE;
"while"         return WHILE;

"=="            return EQ;
"!="            return NE;
"<="            return LE;
">="            return GE;
"&&"            return ANDAND;
"||"            return OROR;
"!"             return NOT;

{ID}            { yylval.sval = strdup(yytext); return IDENTIFIER; }
{NUMBER}        { yylval.ival = atoi(yytext);    return NUMBER; }

[ \t\r\n]+      /* skip whitespace */;
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
