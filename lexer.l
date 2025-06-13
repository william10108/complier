// 檔名：lexer.l
%option noyywrap yylineno
%{
#include "parser.tab.h"
#include <stdlib.h>
#include <stdio.h>
%}

ID      [a-zA-Z_][a-zA-Z0-9_]*
NUMBER  [0-9]+

%%

\n              /* flex 自動更新 yylineno，這裏只跳過 */
[ \t\r]+        /* skip whitespace */

"int"           return INT;
"return"        return RETURN;
"if"            return IF;
"else"          return ELSE;
"while"         return WHILE;
"for"           return FOR;

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

/* 其他任何單一字元都當作字面回傳 */
.               { return yytext[0]; }

%%
