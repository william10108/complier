/* lexer.l */
%option noyywrap yylineno

%{
#include "parser.tab.h"
#include <stdlib.h>
#include <string.h>

int yycolumn = 1;
#define MAXLINE 1024
char yylinebuf[MAXLINE];
int yylinepos = 0;
%}

/* token 定義 */
ID      [a-zA-Z_][a-zA-Z0-9_]*
NUMBER  [0-9]+

%%

/* 處理空白(不包含換行)，更新 column & line buffer */
[ \t\r]+   {
              for (int i = 0; yytext[i]; ++i) {
                  ++yycolumn;
                  if (yylinepos < MAXLINE-1)
                      yylinebuf[yylinepos++] = yytext[i];
              }
          }
/* 處理換行：行號＋＋，重置 column & line buffer */
\n         {
              ++yylineno;
              yycolumn = 1;
              yylinepos = 0;
              yylinebuf[0] = '\0';
          }

/* 關鍵字與符號 */
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

{ID}            { yylval.sval = strdup(yytext); yycolumn += strlen(yytext);
                  if (yylinepos + yyleng < MAXLINE-1) {
                      memcpy(yylinebuf + yylinepos, yytext, yyleng);
                      yylinepos += yyleng;
                  }
                  return IDENTIFIER;
                }
{NUMBER}        { yylval.ival = atoi(yytext); yycolumn += strlen(yytext);
                  if (yylinepos + yyleng < MAXLINE-1) {
                      memcpy(yylinebuf + yylinepos, yytext, yyleng);
                      yylinepos += yyleng;
                  }
                  return NUMBER;
                }

/* 其他符號 */
"("             { yycolumn++;  yylinebuf[yylinepos++]='('; return '('; }
")"             { yycolumn++;  yylinebuf[yylinepos++]=')'; return ')'; }
"{"             { yycolumn++;  yylinebuf[yylinepos++]='{'; return '{'; }
"}"             { yycolumn++;  yylinebuf[yylinepos++]='}'; return '}'; }
";"             { yycolumn++;  yylinebuf[yylinepos++]=';'; return ';'; }
","             { yycolumn++;  yylinebuf[yylinepos++]=','; return ','; }
"="             { yycolumn++;  yylinebuf[yylinepos++]='='; return '='; }
"<"             { yycolumn++;  yylinebuf[yylinepos++]='<'; return '<'; }
">"             { yycolumn++;  yylinebuf[yylinepos++]='>'; return '>'; }
"+"             { yycolumn++;  yylinebuf[yylinepos++]='+'; return '+'; }
"-"             { yycolumn++;  yylinebuf[yylinepos++]='-'; return '-'; }
"*"             { yycolumn++;  yylinebuf[yylinepos++]='*'; return '*'; }
"/"             { yycolumn++;  yylinebuf[yylinepos++]='/'; return '/'; }

.               { yycolumn++;  yylinebuf[yylinepos++]=yytext[0]; return yytext[0]; }

%%
