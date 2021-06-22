/*	Definition section */
%{
    #include "common.h"

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;
    void yyerror (char const *s){
        printf("error:%d: %s\n", yylineno, s);
    }
    
    FILE *fout = NULL;
    bool HAS_ERROR = false;
    int INDENT = 0;
%}

%union {
    int i_val;
    float f_val;
    char *s_val;
}

/* Token without return */
%token ADD SUB MUL QUO REM INC DEC
%token SEMICOLON LB RB LBRACE RBRACE LBRACK RBRACK
%token ASSIGN ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN QUO_ASSIGN REM_ASSIGN
%token INT FLOAT STRING BOOL
%token WHILE PRINT IF ELSE FOR
%token AND OR NOT
%token TRUE FALSE
%token GTR LSS GEQ LEQ EQL NEQ

/* Token with return, which need to sepcify type */
%token <i_val> INT_LIT
%token <f_val> FLOAT_LIT
%token <s_val> STRING_LIT //string won't send "" to .y file
%token <s_val> ID

/* Nonterminal with return, which need to sepcify type */
%type <s_val> type
%type <s_val> value_basic
%type <s_val> value_change_type_ID
%type <i_val> value_change_type_int
%type <f_val> value_change_type_float

/* Yacc will start at this nonterminal */
%start program

/* Grammar section */
%%

program
    : program statements
    | statements
;

statements
    : logical_statement_1 //comparater arithmetic 
    | declare_statement
    | print_statement
    | while_statement
    | assign_statement
    | if_statement
    | for_statement
;

for_statement
    : FOR LB assign_statement logical_statement_1 logical_statement_1 RB  LBRACE program RBRACE
;

if_statement
    : IF LB logical_statement_1 RB LBRACE program RBRACE 
    | ELSE LBRACE program RBRACE
    | ELSE IF LB logical_statement_1 RB LBRACE program RBRACE

assign_statement
    : value ASSIGN logical_statement_1 {printf("ASSIGN\n");}
    | value ADD_ASSIGN logical_statement_1 {printf("ADD_ASSIGN\n");}
    | value SUB_ASSIGN logical_statement_1 {printf("SUB_ASSIGN\n");}
    | value MUL_ASSIGN logical_statement_1 {printf("MUL_ASSIGN\n");}
    | value QUO_ASSIGN logical_statement_1 {printf("QUO_ASSIGN\n");}
    | value REM_ASSIGN logical_statement_1 {printf("REM_ASSIGN\n");}
;

while_statement
    : WHILE LB logical_statement_1 RB LBRACE program RBRACE
;

declare_statement
    : type ID SEMICOLON
    | type ID ASSIGN value SEMICOLON
    | type ID LBRACK value RBRACK SEMICOLON
;

print_statement
    : PRINT LB logical_statement_1 RB SEMICOLON
;

logical_statement_1
    : logical_statement_2 OR logical_statement_2
    | logical_statement_1 OR logical_statement_2
    | logical_statement_2
;

logical_statement_2
    : comparater_statement AND comparater_statement
    | logical_statement_2 AND comparater_statement
    | comparater_statement
;

comparater_statement
    : arithmetic_statement GTR arithmetic_statement
    | arithmetic_statement LSS arithmetic_statement
    | arithmetic_statement GEQ arithmetic_statement
    | arithmetic_statement LEQ arithmetic_statement
    | arithmetic_statement EQL arithmetic_statement
    | arithmetic_statement NEQ arithmetic_statement
    | comparater_statement GTR arithmetic_statement
    | comparater_statement LSS arithmetic_statement
    | comparater_statement GEQ arithmetic_statement
    | comparater_statement LEQ arithmetic_statement
    | comparater_statement EQL arithmetic_statement
    | comparater_statement NEQ arithmetic_statement
    | arithmetic_statement
;

arithmetic_statement
    : arithmetic_statement_1
    | arithmetic_statement_1 SEMICOLON
;

arithmetic_statement_1
    : arithmetic_statement_2 ADD arithmetic_statement_2
    | arithmetic_statement_2 SUB arithmetic_statement_2
    | arithmetic_statement_1 ADD arithmetic_statement_2
    | arithmetic_statement_1 SUB arithmetic_statement_2
    | arithmetic_statement_2
;

arithmetic_statement_2
    : arithmetic_statement_3 MUL arithmetic_statement_3
    | arithmetic_statement_3 QUO arithmetic_statement_3
    | arithmetic_statement_3 REM arithmetic_statement_3
    | arithmetic_statement_2 MUL arithmetic_statement_3
    | arithmetic_statement_2 QUO arithmetic_statement_3
    | arithmetic_statement_2 REM arithmetic_statement_3
    | arithmetic_statement_3
;

arithmetic_statement_3
    : value INC
    | value DEC
    | LB arithmetic_statement_1 RB
    | ADD value
    | SUB value
    | NOT value
    | NOT arithmetic_statement_3
    | value
;

value
    : value_basic LBRACK logical_statement_1 RBRACK
    | LB type RB value_change_type_ID
    | LB type RB value_change_type_int
    | LB type RB value_change_type_float
    | value_basic
;

value_change_type_ID
    : ID
;

value_change_type_int
    : INT_LIT
;

value_change_type_float
    : FLOAT_LIT
;

value_basic
    : INT_LIT
    | FLOAT_LIT
    | STRING_LIT
    | TRUE
    | FALSE
    | ID
;

type
    : INT {$$ = "int";}
    | FLOAT {$$ = "float";}
    | STRING {$$ = "string";}
    | BOOL {$$ = "bool";}
;


%%

/* C code section */
int main(int argc, char *argv[])
{
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }

    /*output init */
    char *bytecode_filename = "hw3.j";
    fout = fopen(bytecode_filename, "w");
    fprintf(fout,".source hw3.j\n");
    fprintf(fout,".class public Main\n");
    fprintf(fout,".super java/lang/Object\n");
    fprintf(fout,".method public static main([Ljava/lang/String;)V\n");
    fprintf(fout,".limit stack 100\n");
    fprintf(fout,".limit locals 100\n");
    INDENT++;

    yyparse();

	printf("Total lines: %d\n", yylineno);

    /*end */
    fprintf(fout,"return\n");
    INDENT--;
    fprintf(fout,".end method\n");
    fclose(fout);
    fclose(yyin);

    if(HAS_ERROR)
        remove(bytecode_filename);
    return 0;
}