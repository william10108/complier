/* parser.y */
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* flex 產生的全域變數 */
extern FILE *yyin;
extern int yylex();
extern char *yytext;
extern int yylineno;           /* 目前行號 */
void yyerror(const char *s);

/* 用來存放整個輸入檔案每一行 */
static char **all_lines = NULL;
static int    num_lines = 0;

/* 讀檔並把每一行存到 all_lines[] */
static void load_input_lines(const char *fname) {
    FILE *fp = fname ? fopen(fname, "r") : stdin;
    if (!fp) { perror("fopen"); exit(1); }
    char *line = NULL;
    size_t len = 0;
    ssize_t rd;
    while ((rd = getline(&line, &len, fp)) != -1) {
        all_lines = realloc(all_lines, sizeof(char*) * (num_lines + 1));
        all_lines[num_lines++] = strdup(line);
    }
    free(line);
    if (fname) rewind(fp);
    yyin = fp;
}

/* ===== 符號表設定 ===== */
#define MAX_SYM 100
static char *sym_name[MAX_SYM];
static int   sym_val [MAX_SYM];
static int   sym_cnt = 0;
/* 以下符號表程式與之前相同… */
static int sym_index(const char *s) { /* ... */ }
static int sym_add(const char *s)    { /* ... */ }
static void sym_set(const char *s,int v) { /* ... */ }
static int sym_get(const char *s)     { /* ... */ }

/* 全域 return 值 */
int ret_val = 0;
/* 當前解析的函式 */
static char *current_function = NULL;
/* add(x,y) stub */
#define MAX_ARGS 10
int arg_vals[MAX_ARGS], arg_cnt;
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

/* … 其餘 grammar 規則與之前相同 … */

%%

void yyerror(const char *s) {
    /* 印出行號與錯誤訊息 */
    fprintf(stderr, "Syntax error at line %d: %s at '%s'\n",
            yylineno, s, yytext);
    /* 如果該行存在，印出原始程式碼 */
    if (yylineno >= 1 && yylineno <= num_lines) {
        fprintf(stderr, ">>> %s", all_lines[yylineno - 1]);
    }
}

int main(int argc, char *argv[]) {
    /* 如果有指定檔名，就從檔案讀；否則讀 stdin */
    load_input_lines(argc > 1 ? argv[1] : NULL);
    if (yyparse() == 0)
        printf("Parsing Successful\n");
    return 0;
}
