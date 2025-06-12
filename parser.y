%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
extern int yylex();
extern char *yytext;
void yyerror(const char *s);
%}

%union {
    int  ival;
    char *sval;
}

%token <sval> IDENTIFIER
%token <ival> NUMBER
%token INT RETURN IF ELSE WHILE
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

param_decl
    : INT IDENTIFIER
    ;

compound_statement
    : '{' statement_list '}'
    ;

statement_list
    : /* empty */
    | statement_list statement
    ;

statement
    : declaration
    | assignment
    | RETURN expression ';'
    | if_statement
    | while_statement
    | compound_statement
    ;

declaration
    : INT decl_list ';'
    ;

decl_list
    : IDENTIFIER
    | decl_list ',' IDENTIFIER
    ;

assignment
    : IDENTIFIER '=' expression ';'
    ;

if_statement
    : IF '(' expression ')' statement
    | IF '(' expression ')' statement ELSE statement
    ;

while_statement
    : WHILE '(' expression ')' statement
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
    | NUMBER                        { $$ = $1; }
    | IDENTIFIER                    { $$ = 0; /* 變數值暫不追蹤 */ }
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
