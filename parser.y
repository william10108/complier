/* parser.y */
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* --- 用來讀檔並儲存原始每行程式碼，供 yyerror 列印 --- */
extern FILE *yyin;
static char **all_lines = NULL;
static int    num_lines = 0;

static void load_input_lines(const char *filename) {
    FILE *fp = filename ? fopen(filename, "r") : stdin;
    if (!fp) { perror("fopen"); exit(EXIT_FAILURE); }
    char *line = NULL;
    size_t len = 0;
    ssize_t rd;
    while ((rd = getline(&line, &len, fp)) != -1) {
        all_lines = realloc(all_lines, sizeof(char*) * (num_lines + 1));
        all_lines[num_lines++] = strdup(line);
    }
    free(line);
    if (filename) rewind(fp);
    yyin = fp;
}

/* flex 提供 */
extern int   yylex();
extern char *yytext;
extern int   yylineno;           /* 目前行號 */
void yyerror(const char *s);

/* ===== 符號表設定 ===== */
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
    return (idx >= 0 ? sym_val[idx] : 0);
}

/* 全域 return 值 */
int ret_val = 0;
/* 當前正在解析的函式 */
static char *current_function = NULL;

/* add(x,y) stub */
#define MAX_ARGS 10
int arg_vals[MAX_ARGS];
int arg_cnt;
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

function
    : INT IDENTIFIER
        {
            if (current_function) free(current_function);
            current_function = strdup($2);
        }
      '(' param_list_opt ')' compound_statement
    ;

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

statement
    : matched_stmt
    | unmatched_stmt
    ;

matched_stmt
    : INT decl_list ';'
    | IDENTIFIER '=' expression ';'
        { sym_set($1, $3); }
    | RETURN expression ';'
        {
            ret_val = $2;
            if (current_function && strcmp(current_function, "main") == 0)
                printf("return %d\n", ret_val);
        }
    | WHILE '(' expression ')' matched_stmt
    | FOR '(' IDENTIFIER '=' expression ';' expression ';' IDENTIFIER '+' '+' ')' matched_stmt
    | compound_statement
    | IF '(' expression ')' matched_stmt ELSE matched_stmt
    ;

unmatched_stmt
    : IF '(' expression ')' statement
    | IF '(' expression ')' matched_stmt ELSE unmatched_stmt
    ;

decl_list
    : IDENTIFIER                { sym_add($1); }
    | decl_list ',' IDENTIFIER  { sym_add($3); }
    ;

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
            if (strcmp($1, "add") == 0 && arg_cnt == 2)
                $$ = arg_vals[0] + arg_vals[1];
            else
                $$ = 0;
        }
    | NUMBER                        { $$ = $1; }
    | IDENTIFIER                    { $$ = sym_get($1); }
    ;

opt_arg_list
    : /* empty */                   { arg_cnt = 0; }
    | arg_list
    ;

arg_list
    : expression                    { arg_cnt = 1; arg_vals[0] = $1; }
    | arg_list ',' expression      { arg_vals[arg_cnt++] = $3; }
    ;

%%

void yyerror(const char *s) {
    /* 列印行號與錯誤訊息 */
    fprintf(stderr, "Syntax error at line %d: %s at '%s'\n",
            yylineno, s, yytext);
    /* 如果該行有讀進來，就把整行原始程式碼印出 */
    if (yylineno >= 1 && yylineno <= num_lines) {
        fprintf(stderr, ">>> %s", all_lines[yylineno - 1]);
    }
}

int main(int argc, char *argv[]) {
    /* 先讀進每一行，並設定 yyin */
    load_input_lines(argc > 1 ? argv[1] : NULL);
    if (yyparse() == 0)
        printf("Parsing Successful\n");
    return 0;
}
