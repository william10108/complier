/* parser.y */
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex(void);
extern char *yytext;
extern int yylineno;
extern int yystartcol;

/* 用來把整個 stdin 讀進記憶體並分行 */
typedef struct yy_buffer_state *YY_BUFFER_STATE;
extern YY_BUFFER_STATE yy_scan_string(const char *);

/* ----- 符號表 (原版程式碼) ----- */
#define MAX_SYM 100
static char *sym_name[MAX_SYM];
static int   sym_val [MAX_SYM];
static int   sym_cnt = 0;
static int sym_index(const char *s) {
    for (int i = 0; i < sym_cnt; i++)
        if (strcmp(sym_name[i], s) == 0)
            return i;
    return -1;
}
static int sym_add(const char *s) {
    int idx = sym_index(s);
    if (idx >= 0) return idx;
    if (sym_cnt >= MAX_SYM) yyerror("too many symbols");
    sym_name[sym_cnt] = strdup(s);
    sym_val [sym_cnt] = 0;
    return sym_cnt++;
}
static void sym_set(const char *s, int v) {
    int idx = sym_add(s);
    sym_val[idx] = v;
}
static int sym_get(const char *s) {
    int idx = sym_index(s);
    return idx >= 0 ? sym_val[idx] : 0;
}
int ret_val = 0;
static char *current_function = NULL;

/* ----- 錯誤行列緩衝 ----- */
#define MAX_LINES 2000
static char *lines[MAX_LINES];
static int   total_lines = 0;
%}

/* ----- Bison 宣告 ----- */
%union {
    int  ival;
    char *sval;
}

%token <sval> IDENTIFIER
%token <ival> NUMBER
%token INT RETURN IF ELSE WHILE FOR
%token EQ NE LE GE ANDAND OROR NOT

/* 告訴 Bison 這些 nonterm 有 <ival> */
%type <ival> expression logical_or logical_and equality relational
              additive term factor ;
%type <ival> opt_arg_list arg_list ;

/* ------ 分隔 ------ */
%%

program
    : function_list
    ;

function_list
    : function_list function
    | function
    ;

/* 函式定義 */
function
    : INT IDENTIFIER
        {
            if (current_function) free(current_function);
            current_function = strdup($2);
        }
      '(' param_list_opt ')' compound_statement
    ;

/* 參數宣告 */
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

/* 區塊與敘述 */
compound_statement
    : '{' statement_list '}'
    ;

statement_list
    : /* empty */
    | statement_list statement
    ;

statement
    : INT decl_list ';'
    | IDENTIFIER '=' expression ';'
        { sym_set($1, $3); }
    | RETURN expression ';'
        {
            ret_val = $2;
            if (current_function && strcmp(current_function, "main")==0)
                printf("return %d\n", ret_val);
        }
    | IF '(' expression ')' statement
    | IF '(' expression ')' statement ELSE statement
    | WHILE '(' expression ')' statement
    | FOR '(' IDENTIFIER '=' expression ';' expression ';' IDENTIFIER "++" ')' statement
    | compound_statement
    ;

/* 宣告串 */
decl_list
    : IDENTIFIER
        { sym_add($1); }
    | decl_list ',' IDENTIFIER
        { sym_add($3); }
    ;

/* 表達式 */
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
    | IDENTIFIER '(' opt_arg_list ')'  
        {
            /* stub：其他函式都回傳0 */
            $$ = 0;
        }
    | NUMBER                        { $$ = $1; }
    | IDENTIFIER                    { $$ = sym_get($1); }
    ;

/* 呼叫參數串 */
opt_arg_list
    : /* empty */   { /* no args */ }
    | arg_list
    ;

arg_list
    : expression            { /* first */ }
    | arg_list ',' expression
    ;

%%

/* ----- 自訂 yyerror，印出行、欄，顯示該行並標記 ^ ----- */
void yyerror(const char *s) {
    int ln = yylineno, col = yystartcol;
    fprintf(stderr, "Syntax error at line %d, column %d: %s\n", ln, col, s);
    if (ln-1 < total_lines) {
        char *L = lines[ln-1];
        fprintf(stderr, "%s\n", L);
        for (int i = 1; i < col; i++)
            fputc(L[i-1]=='\t' ? '\t' : ' ', stderr);
        fprintf(stderr, "^\n");
    }
    exit(1);
}

/* ----- main：先讀所有 stdin、存 lines[]，再交給 Flex/Bison ----- */
int main(void) {
    /* 讀入全部 stdin */
    size_t cap=0, len=0;
    char *input = NULL;
    int c;
    while ((c=getchar())!=EOF) {
        if (len+1 >= cap) {
            cap = cap?cap*2:1024;
            input = realloc(input, cap);
        }
        input[len++] = c;
    }
    if (!input) return 0;
    input[len] = '\0';

    /* 分行儲存 */
    char *start = input;
    for (size_t i = 0; i < len; i++) {
        if (input[i]=='\n') {
            input[i] = '\0';
            if (total_lines < MAX_LINES) lines[total_lines++] = start;
            start = input + i + 1;
        }
    }
    /* 最後可能沒換行 */
    if (start < input + len && total_lines < MAX_LINES)
        lines[total_lines++] = start;

    /* 讓 Flex 掃描這段記憶體 */
    yy_scan_string(input);
    yyparse();
    return 0;
}
