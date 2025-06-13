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

/* 當前正在解析/執行的函式名稱 */
static char *current_function = NULL;

/* ===== add(x,y) Stub 用參數暫存 ===== */
#define MAX_ARGS 10
int  arg_vals[MAX_ARGS];
int  arg_cnt;
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
%type       opt_arg_list arg_list

%%

program
    : function_list
    ;

function_list
    : function_list function
    | function
    ;

/* 在這裡用 mid-rule action 設定 current_function */
function
    : INT IDENTIFIER
        {
            /* 進入一個新的函式定義 */
            if (current_function) free(current_function);
            current_function = strdup($2);
        }
      '(' param_list_opt ')' compound_statement
    ;

/* 參數宣告也加到符號表 */
param_list_opt
    : /* empty */ 
    | param_list
    ;

param_list
    : param_decl
    | param_list ',' param_decl
    ;

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

/* 分 matched / unmatched 消除 dangling-else */
statement
    : matched_stmt
    | unmatched_stmt
    ;

/* ===== 完整配對的 statement ===== */
matched_stmt
    /* 變數宣告 */
    : INT decl_list ';'
    /* 賦值 */
    | IDENTIFIER '=' expression ';'
        { sym_set($1, $3); }
    /* return：只有在 main 才印出 */
    | RETURN expression ';'
        {
            ret_val = $2;
            if (current_function && strcmp(current_function, "main") == 0)
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

/* ===== 處理 dangling-else ===== */
unmatched_stmt
    : IF '(' expression ')' statement
    | IF '(' expression ')' matched_stmt ELSE unmatched_stmt
    ;

/* 宣告清單：把每個變數名稱加到符號表 */
decl_list
    : IDENTIFIER                { sym_add($1); }
    | decl_list ',' IDENTIFIER  { sym_add($3); }
    ;

/* ──── 運算式 & 函式呼叫 stub ──── */
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

/* 因為我們只有示範 add(x,y)，這裡加簡易 stub */
/* 也會處理一般變數和括號 */
factor
    : '(' expression ')'            { $$ = $2; }
    | IDENTIFIER '(' opt_arg_list ')' 
        {
            /* 只對 add(x,y) 做相加，其他函式一律回傳 0 */
            if (strcmp($1, "add") == 0 && arg_cnt == 2)
                $$ = arg_vals[0] + arg_vals[1];
            else
                $$ = 0;
        }
    | NUMBER                        { $$ = $1; }
    | IDENTIFIER                    { $$ = sym_get($1); }
    ;

/* 參數串解析 */
opt_arg_list
    : /* empty */                   { arg_cnt = 0; }
    | arg_list                      { /* arg_cnt 及 arg_vals 已在 arg_list 中設定 */ }
    ;

arg_list
    : expression                    { arg_cnt = 1; arg_vals[0] = $1; }
    | arg_list ',' expression      { arg_vals[arg_cnt++] = $3; }
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
