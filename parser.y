/* parser.y */
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex(void);
extern char *yytext;
extern int yylineno;
extern int yystartcol;
void yyerror(const char *s);

/* 支援把 stdin 全部讀進來，再用 yy_scan_string() 解析 */
typedef void* YY_BUFFER_STATE;
extern YY_BUFFER_STATE yy_scan_string(const char *);

/* 符號表 */
#define MAX_SYM 100
static char *sym_name[MAX_SYM];
static int   sym_val [MAX_SYM];
static int   sym_cnt = 0;

/* 錯誤顯示用：儲存每一行文字 */
#define MAX_LINES 1000
static char *lines[MAX_LINES];
static int total_lines = 0;

int ret_val = 0;
static char *current_function = NULL;

/* 符號表函式 ...（略，與原版相同） */
static int sym_index(const char *s) { /* ... */ }
static int sym_add(const char *s)    { /* ... */ }
static void sym_set(const char *s,int v) { /* ... */ }
static int sym_get(const char *s)     { /* ... */ }

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

/* 以下語法規則與原版完全相同，省略以示簡潔 */

%%

void yyerror(const char *s) {
    int col = yystartcol;
    fprintf(stderr, "Syntax error at line %d, column %d: %s\n", yylineno, col, s);
    /* 印出該行 */
    if (yylineno-1 < total_lines) {
        char *errline = lines[yylineno-1];
        fprintf(stderr, "%s\n", errline);
        /* 在正確位置印 ^ */
        for (int i = 1; i < col; i++)
            fputc(errline[i-1]=='\t' ? '\t' : ' ', stderr);
        fprintf(stderr, "^\n");
    }
    exit(1);
}

int main(void) {
    /* 1) 讀取 stdin 全部內容 */
    int bufsize = 1024;
    char *input = malloc(bufsize);
    if (!input) { perror("malloc"); exit(1); }
    int len = 0, c;
    while ((c = getchar()) != EOF) {
        if (len+1 >= bufsize) {
            bufsize *= 2;
            input = realloc(input, bufsize);
            if (!input) { perror("realloc"); exit(1); }
        }
        input[len++] = c;
    }
    input[len] = '\0';

    /* 2) 分行存入 lines[] */
    char *start = input;
    for (int i = 0; i < len; i++) {
        if (input[i] == '\n') {
            input[i] = '\0';
            if (total_lines < MAX_LINES) lines[total_lines++] = start;
            start = input + i + 1;
        }
    }
    if (start < input + len && total_lines < MAX_LINES)
        lines[total_lines++] = start;

    /* 3) 初始化位置計數器 */
    yylineno = 1;
    yycolumn = 1;  /* 由 lexer.l 定義 */

    /* 4) 告訴 Flex 用這個 buffer 來掃描 */
    YY_BUFFER_STATE buf = yy_scan_string(input);

    /* 5) 解析 */
    yyparse();
    return 0;
}
