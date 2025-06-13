%option noyywrap yylineno
%{
#include "parser.tab.h"
#include <stdlib.h>
#include <stdio.h>

/* 追蹤欄號與當前行內容 */
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

\n              { /* flex 會自動 ++yylineno */ yycolumn = 1; yylinebuf[0] = '\0'; }
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

/* bottom code, 不要再定義 yylineno ！ */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern char *yytext;
extern int yylineno;       /* flex 自動產生 */
extern int yycolumn;       /* 我們自己追蹤的欄號 */
extern char yylinebuf[];   /* 當前行內容 */

void yyerror(const char *s) {
    fprintf(stderr, "Syntax error at line %d, column %d: %s\n",
            yylineno, yycolumn, s);
    fprintf(stderr, "%s\n", yylinebuf);
    fprintf(stderr, "%*s^\n", yycolumn - 1, "");
    exit(1);
}
