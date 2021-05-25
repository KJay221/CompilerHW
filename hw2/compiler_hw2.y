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
    int symbolElementIndex[30];
    int *sp = symbolElementIndex;
    #define push(sp, n) (*((sp)++) = (n))
    #define pop(sp) (*--(sp))
    int symbolTableIndex = 0;
    int nowElementIndex = -1;
    int address = -1;
    
    void insert_symbol(char* name, char* type, char* elementType);
    void declareFunction(char* name, char* type, char* elementType);
    void idFunction(char* id);
    void DumpSymbolTable();
%}

%union {
    int i_val;
    float f_val;
    char *s_val;
}

/* Token without return */
%token ADD SUB MUL QUO REM INC DEC
%token SEMICOLON
%token INT

/* Token with return, which need to sepcify type */
%token <i_val> INT_LIT
%token <f_val> FLOAT_LIT
%token <s_val> STRING_LIT
%token <s_val> ID

/* Nonterminal with return, which need to sepcify type */

/* Yacc will start at this nonterminal */
%start program

/* Grammar section */
%%

program
    : program statements
    | statements
;

statements
    : arithmetic
    | declare

declare
    : INT ID SEMICOLON {declareFunction($2, "int", "-");}
;

arithmetic
    : arithmetic ADD arithmetic SEMICOLON {printf("ADD\n");}
    | arithmetic SUB arithmetic SEMICOLON {printf("SUB\n");}
    | arithmetic MUL arithmetic SEMICOLON {printf("MUL\n");}
    | arithmetic QUO arithmetic SEMICOLON {printf("QUO\n");}
    | arithmetic REM arithmetic SEMICOLON {printf("REM\n");}
    | arithmetic INC SEMICOLON {printf("INC\n");}
    | arithmetic DEC SEMICOLON {printf("DEC\n");}
    | value
;

value
    : INT_LIT
    | FLOAT_LIT
    | STRING_LIT
    | ID {idFunction($1);}

%%

/* C code section */
int main(int argc, char *argv[])
{
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }

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
    
    for(int i=0;i<=nowElementIndex;i++){
        if(!strcmp(symbolTable[symbolTableIndex][i].name, id))
            nowAddress = symbolTable[symbolTableIndex][i].address;
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