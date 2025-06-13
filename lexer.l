%option noyywrap yylineno
%{
#include "parser.tab.h"
#include <stdlib.h>
#include <string.h>

/* 用來儲存當前行和上一行的 buffer */
char line_buf[1024];
int line_pos = 0;
char prev_line_buf[1024] = "";
int prev_line_num = 1;

/* 每次 matched token 前都會執行：累積到 line_buf，遇到 '\n' 轉存到 prev_line_buf */
#define YY_USER_ACTION \
    do { \
        for (int i = 0; i < yyleng; ++i) { \
            if (yytext[i] == '\n') { \
                line_buf[line_pos] = '\0'; \
                strcpy(prev_line_buf, line_buf); \
                prev_line_num = yylineno; \
                line_pos = 0; \
            } else if (line_pos < 1023) { \
                line_buf[line_pos++] = yytext[i]; \
            } \
        } \
    } while (0)
%}

ID      [a-zA-Z_][a-zA-Z0-9_]*
NUMBER  [0-9]+

%%

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

[ \t]+          /* skip spaces/tabs */;
\n              /* newline handled in YY_USER_ACTION, skip */;

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
