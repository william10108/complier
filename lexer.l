%option noyywrap
%{
#include "parser.tab.h"
#include <stdlib.h>
#include <stdio.h>

/* 追蹤行號、欄號與當前行內容 */
int yylineno = 1;
int yycolumn = 1;
char yylinebuf[1024] = "";

/* 每次讀到一個 token，都把它加到 yylinebuf 並更新 yycolumn */
#define STORE \
    do { \
        int len = yyleng; \
        if (yycolumn + len < (int)sizeof(yylinebuf)) { \
            memcpy(yylinebuf + yycolumn - 1, yytext, len); \
            yylinebuf[yycolumn - 1 + len] = '\0'; \
        } \
        yycolumn += len; \
    } while (0)
%}

ID      [a-zA-Z_][a-zA-Z0-9_]*
NUMBER  [0-9]+

%%

\n              { /* 換行：行號＋1，欄號歸 1，清空行緩衝 */ \
                  yylineno++; yycolumn = 1; yylinebuf[0] = '\0'; }
[ \t]+          { STORE; }

"int"           { STORE; return INT; }
"return"        { STORE; return RETURN; }
"if"            { STORE; return IF; }
"else"          { STORE; return ELSE; }
"while"         { STORE; return WHILE; }
"for"           { STORE; return FOR; }

"=="            { STORE; return EQ; }
"!="            { STORE; return NE; }
"<="            { STORE; return LE; }
">="            { STORE; return GE; }
"&&"            { STORE; return ANDAND; }
"||"            { STORE; return OROR; }
"!"             { STORE; return NOT; }

{NUMBER}        { STORE; yylval.ival = atoi(yytext); return NUMBER; }
{ID}            { STORE; yylval.sval = strdup(yytext); return IDENTIFIER; }

"("             { STORE; return '('; }
")"             { STORE; return ')'; }
"{"             { STORE; return '{'; }
"}"             { STORE; return '}'; }
";"             { STORE; return ';'; }
","             { STORE; return ','; }
"="             { STORE; return '='; }
"<"             { STORE; return '<'; }
">"             { STORE; return '>'; }
"+"             { STORE; return '+'; }
"-"             { STORE; return '-'; }
"*"             { STORE; return '*'; }
"/"             { STORE; return '/'; }

.               { STORE; return yytext[0]; }
%%
