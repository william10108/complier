/* parser.y */
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* 由 lexer.l 提供 */
extern int yylex();
extern char *yytext;
extern int yylineno;           /* 取得目前行號 */
void yyerror(const char *s);

/* ===== 符號表設定 ===== */
#define MAX_SYM 100
static char *sym_name[MAX_SYM];
static int   sym_val [MAX_SYM];
static int   sym_cnt = 0;
… （其餘符號表程式不變） …
%}

%union {
    int  ival;
    char *sval;
}

%token <sval> IDENTIFIER
%token <ival> NUMBER
%token INT RETURN IF ELSE WHILE FOR
%token EQ NE LE GE ANDAND OROR NOT

… （其餘 bison 語法規則不變） …

%%

void yyerror(const char *s) {
    /* 列印行號、錯誤訊息與當前字串 */
    fprintf(stderr, "Syntax error at line %d: %s at '%s'\n",
            yylineno, s, yytext);
}

int main() {
    if (yyparse() == 0)
        printf("Parsing Successful\n");
    return 0;
}
