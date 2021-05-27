/*	Definition section */
%{
    #include "common.h"

    extern int yylineno;
    extern int yylex();
    extern FILE* yyin;
    extern char* yytext;
    void yyerror (char const *s){
        printf("error:%d: %s\n", yylineno, s);
    }

    typedef struct symbol{
        int index;
        char* name;
        char* type;
        int address;
        int lineno;
        char* elementType;
    } symbol;

    symbol symbolTable[30][30];

    int stack[30];
    int *elementIndexStack = stack;
    #define push(sp, n) (*((sp)++) = (n))
    #define pop(sp) (*--(sp))
    int symbolTableIndex = 0;
    int nowElementIndex = -1;
    int address = -1;
    char* printType = "bool";
    
    void insert_symbol(char* name, char* type, char* elementType);
    void declareFunction(char* name, char* type, char* elementType);
    void idFunction(char* id);
    void DumpSymbolTable();
    void into_zone();
    void exit_zone();
    void init_symbolTable();
    char* get_arrary_type(char* id);
    char* get_id_type(char* id);
    void change_type(char* id, char *type);
    void clean_symbolTable();
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
    : FOR LB assign_statement logical_statement_1 logical_statement_1 RB {into_zone();} LBRACE program RBRACE {exit_zone();}
;

if_statement
    : IF LB logical_statement_1 RB {into_zone();} LBRACE program RBRACE {exit_zone();}
    | ELSE {into_zone();} LBRACE program RBRACE {exit_zone();}
    | ELSE IF LB logical_statement_1 RB {into_zone();} LBRACE program RBRACE {exit_zone();}

assign_statement
    : value ASSIGN logical_statement_1 {printf("ASSIGN\n");}
    | value ADD_ASSIGN logical_statement_1 {printf("ADD_ASSIGN\n");}
    | value SUB_ASSIGN logical_statement_1 {printf("SUB_ASSIGN\n");}
    | value MUL_ASSIGN logical_statement_1 {printf("MUL_ASSIGN\n");}
    | value QUO_ASSIGN logical_statement_1 {printf("QUO_ASSIGN\n");}
    | value REM_ASSIGN logical_statement_1 {printf("REM_ASSIGN\n");}
;

while_statement
    : WHILE LB logical_statement_1 RB {into_zone();} LBRACE program RBRACE {exit_zone();}
;

declare_statement
    : type ID SEMICOLON {declareFunction($2, $1, "-");}
    | type ID ASSIGN value SEMICOLON {declareFunction($2, $1, "-");}
    | type ID LBRACK value RBRACK SEMICOLON {declareFunction($2, "array", $1);}
;

print_statement
    : PRINT LB logical_statement_1 RB SEMICOLON {printf("PRINT %s\n", printType);}
;

logical_statement_1
    : logical_statement_2 OR logical_statement_2 {printType = "bool"; printf("OR\n");}
    | logical_statement_1 OR logical_statement_2 {printType = "bool"; printf("OR\n");}
    | logical_statement_2
;

logical_statement_2
    : comparater_statement AND comparater_statement {printType = "bool"; printf("AND\n");}
    | logical_statement_2 AND comparater_statement {printType = "bool"; printf("AND\n");}
    | comparater_statement
;

comparater_statement
    : arithmetic_statement GTR arithmetic_statement {printType = "bool"; printf("GTR\n");}
    | arithmetic_statement LSS arithmetic_statement {printType = "bool"; printf("LSS\n");}
    | arithmetic_statement GEQ arithmetic_statement {printType = "bool"; printf("GEQ\n");}
    | arithmetic_statement LEQ arithmetic_statement {printType = "bool"; printf("LEQ\n");}
    | arithmetic_statement EQL arithmetic_statement {printType = "bool"; printf("EQL\n");}
    | arithmetic_statement NEQ arithmetic_statement {printType = "bool"; printf("NEQ\n");}
    | comparater_statement GTR arithmetic_statement {printType = "bool"; printf("GTR\n");}
    | comparater_statement LSS arithmetic_statement {printType = "bool"; printf("LSS\n");}
    | comparater_statement GEQ arithmetic_statement {printType = "bool"; printf("GEQ\n");}
    | comparater_statement LEQ arithmetic_statement {printType = "bool"; printf("LEQ\n");}
    | comparater_statement EQL arithmetic_statement {printType = "bool"; printf("EQL\n");}
    | comparater_statement NEQ arithmetic_statement {printType = "bool"; printf("NEQ\n");}
    | arithmetic_statement
;

arithmetic_statement
    : arithmetic_statement_1
    | arithmetic_statement_1 SEMICOLON
;

arithmetic_statement_1
    : arithmetic_statement_2 ADD arithmetic_statement_2 {printf("ADD\n");}
    | arithmetic_statement_2 SUB arithmetic_statement_2 {printf("SUB\n");}
    | arithmetic_statement_1 ADD arithmetic_statement_2 {printf("ADD\n");}
    | arithmetic_statement_1 SUB arithmetic_statement_2 {printf("SUB\n");}
    | arithmetic_statement_2
;

arithmetic_statement_2
    : arithmetic_statement_3 MUL arithmetic_statement_3 {printf("MUL\n");}
    | arithmetic_statement_3 QUO arithmetic_statement_3 {printf("QUO\n");}
    | arithmetic_statement_3 REM arithmetic_statement_3 {printf("REM\n");}
    | arithmetic_statement_2 MUL arithmetic_statement_3 {printf("MUL\n");}
    | arithmetic_statement_2 QUO arithmetic_statement_3 {printf("QUO\n");}
    | arithmetic_statement_2 REM arithmetic_statement_3 {printf("REM\n");}
    | arithmetic_statement_3
;

arithmetic_statement_3
    : value INC {printf("INC\n");}
    | value DEC {printf("DEC\n");}
    | LB arithmetic_statement_1 RB
    | ADD value {printf("POS\n");}
    | SUB value {printf("NEG\n");}
    | NOT value {printType = "bool"; printf("NOT\n");}
    | NOT arithmetic_statement_3 {printType = "bool"; printf("NOT\n");}
    | value
;

value
    : value_basic LBRACK logical_statement_1 RBRACK {printType = get_arrary_type($1);}
    | LB type RB value_change_type_ID {change_type($4, $2);}
    | LB type RB value_change_type_int {change_type("int", $2);}
    | LB type RB value_change_type_float {change_type("float", $2);}
    | value_basic
;

value_change_type_ID
    : ID {idFunction($1); printType = get_id_type($1);}
;

value_change_type_int
    : INT_LIT {printType = "int"; printf("INT_LIT %d\n", $<i_val>$);}
;

value_change_type_float
    : FLOAT_LIT {printType = "float"; printf("FLOAT_LIT %.6f\n", $<f_val>$);}
;

value_basic
    : INT_LIT {printType = "int"; printf("INT_LIT %d\n", $<i_val>$);}
    | FLOAT_LIT {printType = "float"; printf("FLOAT_LIT %.6f\n", $<f_val>$);}
    | STRING_LIT {printType = "string"; printf("STRING_LIT %s\n", $<s_val>$);}
    | TRUE {printType = "bool"; printf("TRUE\n");}
    | FALSE {printType = "bool"; printf("FALSE\n");}
    | ID {idFunction($1); printType = get_id_type($1);}
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
    init_symbolTable();

    yyparse();
    DumpSymbolTable();
	printf("Total lines: %d\n", yylineno);
    fclose(yyin);
    return 0;
}

void insert_symbol(char* name, char* type, char* elementType){
    nowElementIndex++;
    address++;
    symbolTable[symbolTableIndex][nowElementIndex].index = nowElementIndex;
    symbolTable[symbolTableIndex][nowElementIndex].name = name;
    symbolTable[symbolTableIndex][nowElementIndex].type = type;
    symbolTable[symbolTableIndex][nowElementIndex].address = address;
    symbolTable[symbolTableIndex][nowElementIndex].lineno = yylineno;
    symbolTable[symbolTableIndex][nowElementIndex].elementType = elementType;
}

void declareFunction(char* name, char* type, char* elementType){
    insert_symbol(name, type, elementType);
    printf("> Insert {%s} into symbol table (scope level: %d)\n", 
        name, 
        symbolTableIndex);
}

void idFunction(char* id){
    int nowAddress = 0;
    int flag = 0;
    for(int i=29;i>=0;i--){
        for(int j=0;j<30;j++){
            if(!strcmp(symbolTable[i][j].name, id)){
                nowAddress = symbolTable[i][j].address;
                flag = 1;
                break;
            }    
        }
        if(flag)
            break;
    }
    printf("IDENT (name=%s, address=%d)\n", 
        id, 
        nowAddress);
}

void DumpSymbolTable(){
    printf("> Dump symbol table (scope level: %d)\n", symbolTableIndex);
    printf("Index     Name      Type      Address   Lineno    Element type\n");
    for(int i=0;i<=nowElementIndex;i++)
        printf("%-10d%-10s%-10s%-10d%-10d%s\n",
            symbolTable[symbolTableIndex][i].index,
            symbolTable[symbolTableIndex][i].name,
            symbolTable[symbolTableIndex][i].type,
            symbolTable[symbolTableIndex][i].address,
            symbolTable[symbolTableIndex][i].lineno,
            symbolTable[symbolTableIndex][i].elementType);
}

void into_zone(){
    push(elementIndexStack, nowElementIndex);
    symbolTableIndex++;
    nowElementIndex = -1;
}

void exit_zone(){
    DumpSymbolTable();
    nowElementIndex = pop(elementIndexStack);
    clean_symbolTable();
    symbolTableIndex--;
}

void init_symbolTable(){
    for(int i=0;i<30;i++){
        for(int j=0;j<30;j++){
            symbolTable[i][j].index = 0;
            symbolTable[i][j].name = "";
            symbolTable[i][j].type = "";
            symbolTable[i][j].address = 0;
            symbolTable[i][j].lineno = 0;
            symbolTable[i][j].elementType = "";
        }
    }
}

char* get_arrary_type(char* id){
    for(int i=0;i<=nowElementIndex;i++){
        if(!strcmp(symbolTable[symbolTableIndex][i].name, id))
            return symbolTable[symbolTableIndex][i].elementType;
    }
    return "";
}

char* get_id_type(char* id){
    for(int i=29;i>=0;i--){
        for(int j=0;j<30;j++){
            if(!strcmp(symbolTable[i][j].name, id))
                return symbolTable[i][j].type;
        }
    }
    return "";
}

void change_type(char* id, char *type){
    if(!strcmp(id, "int"))
        printf("I to F\n");
    else if(!strcmp(id, "float"))
        printf("F to I\n");
    else
        for(int i=0;i<=nowElementIndex;i++){
            if(!strcmp(symbolTable[symbolTableIndex][i].name, id)){
                if(!strcmp(symbolTable[symbolTableIndex][i].type, "int")
                && !strcmp(type, "float"))
                    printf("I to F\n");
                if(!strcmp(symbolTable[symbolTableIndex][i].type, "float")
                && !strcmp(type, "int"))
                    printf("F to I\n");
                break;
            }   
        }
}

void clean_symbolTable(){
    for(int i=0;i<30;i++){
        symbolTable[symbolTableIndex][i].index = 0;
        symbolTable[symbolTableIndex][i].name = "";
        symbolTable[symbolTableIndex][i].type = "";
        symbolTable[symbolTableIndex][i].address = 0;
        symbolTable[symbolTableIndex][i].lineno = 0;
        symbolTable[symbolTableIndex][i].elementType = "";
    }
}