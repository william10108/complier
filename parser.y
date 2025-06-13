%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern char *yytext;
void yyerror(const char *s);

/* ===== 符號表設定 ===== */
#define MAX_SYM 100
static char *sym_name[MAX_SYM];
static int   sym_val [MAX_SYM];
static int   sym_cnt = 0;

/* 找變數在符號表的 index；找不到回傳 -1 */
static int sym_index(const char *s) {
    for (int i = 0; i < sym_cnt; i++)
        if (strcmp(sym_name[i], s) == 0)
            return i;
    return -1;
}

/* 新增變數（若已存在則回傳原來的 index） */
static int sym_add(const char *s) {
    int idx = sym_index(s);
    if (idx >= 0) return idx;
    if (sym_cnt >= MAX_SYM) yyerror("too many symbols");
    sym_name[sym_cnt] = strdup(s);
    sym_val [sym_cnt] = 0;  /* 預設初值 0 */
    return sym_cnt++;
}

/* 設定變數值 */
static void sym_set(const char *s, int v) {
    int idx = sym_add(s);
    sym_val[idx] = v;
}

/* 取得變數值；不存在則回傳 0 */
static int sym_get(const char *s) {
    int idx = sym_index(s);
    return (idx >= 0 ? sym_val[idx] : 0);
}

/* 全域 return 值 */
int ret_val = 0;
%}

%union {
    int  ival;
    char *sval;
}

%token <sval> IDENTIFIER
%token <ival> NUMBER
%token INT RETURN IF ELSE WHILE FOR
%token EQ NE LE GE ANDAND OROR NOT

%type <ival>
      expression logical_or logical_and equality relational
      additive term factor

%%

program
    : function_list
    ;

function_list
    : function_list function
    | function
    ;

function
    : INT IDENTIFIER '(' param_list_opt ')' compound_statement
    ;

param_list_opt
    : /* empty */
    | param_list
    ;

param_list
    : param_decl
    | param_list ',' param_decl
    ;

/* 如果要追蹤參數，也可在這裡 sym_add */
param_decl
    : INT IDENTIFIER
        { sym_add($2); }
    ;

compound_statement
    : '{' statement_list '}'
    ;

statement_list
    : /* empty */
    | statement_list statement
    ;

/* 分成 matched / unmatched 消除 dangling‐else */
statement
    : matched_stmt
    | unmatched_stmt
    ;

/* ===== 已配對的 statement (matched) ===== */
matched_stmt
    /* 變數宣告 */
    : INT decl_list ';'
    /* 賦值 */
    | IDENTIFIER '=' expression ';'
        { sym_set($1, $3); }
    /* return */
    | RETURN expression ';'
        {
            ret_val = $2;
            printf("return %d\n", ret_val);
        }
    /* while */
    | WHILE '(' expression ')' matched_stmt
    /* for (最簡化示範) */
    | FOR '(' IDENTIFIER '=' expression ';' expression ';' IDENTIFIER '+' '+' ')' matched_stmt
    /* 區塊 */
    | compound_statement
    /* if…else */
    | IF '(' expression ')' matched_stmt ELSE matched_stmt
    ;

/* ===== 未配對的 statement (unmatched) ===== */
unmatched_stmt
    /* 如果沒帶 else */
    : IF '(' expression ')' statement
    /* else 要配給外層的 if */
    | IF '(' expression ')' matched_stmt ELSE unmatched_stmt
    ;

/* 宣告清單，把每個 IDENTIFIER 加入符號表 */
decl_list
    : IDENTIFIER
        { sym_add($1); }
    | decl_list ',' IDENTIFIER
        { sym_add($3); }
    ;

/* ──── 運算式層次 ──── */
expression
    : logical_or
    ;

logical_or
    : logical_or OROR logical_and   { $$ = ($1 || $3); }
    | logical_and                   { $$ = $1; }
    ;

logical_and
    : logical_and ANDAND equality   { $$ = ($1 && $3); }
    | equality                      { $$ = $1; }
    ;

equality
    : equality EQ relational        { $$ = ($1 == $3); }
    | equality NE relational        { $$ = ($1 != $3); }
    | relational                    { $$ = $1; }
    ;

relational
    : relational '<' additive       { $$ = ($1 < $3); }
    | relational '>' additive       { $$ = ($1 > $3); }
    | relational LE additive        { $$ = ($1 <= $3); }
    | relational GE additive        { $$ = ($1 >= $3); }
    | additive                      { $$ = $1; }
    ;

additive
    : additive '+' term             { $$ = $1 + $3; }
    | additive '-' term             { $$ = $1 - $3; }
    | term                          { $$ = $1; }
    ;

term
    : term '*' factor               { $$ = $1 * $3; }
    | term '/' factor               { $$ = $1 / $3; }
    | factor                        { $$ = $1; }
    ;

factor
    : '(' expression ')'            { $$ = $2; }
    | NUMBER                        { $$ = $1; }
    | IDENTIFIER                    { $$ = sym_get($1); }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Syntax error: %s at '%s'\n", s, yytext);
}

int main() {
    if (yyparse() == 0)
        printf("Parsing Successful\n");
    return 0;
}
