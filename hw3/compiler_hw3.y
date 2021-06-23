/*	Definition section */
%{
    #include "common.h"

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;
    void yyerror (char const *s){
        printf("error:%d: %s\n", yylineno, s);
    }

    typedef struct symbol{
        int index;
        char* name;
        char* type;
        char* elementType;
    } symbol;

    symbol symbolTable[30][30];
    int stack[30];
    int *elementIndexStack = stack;
    #define push(sp, n) (*((sp)++) = (n))
    #define pop(sp) (*--(sp))
    int symbolTableIndex = 0;
    int nowElementIndex = -1;
    char* printType = "bool";
    int lastIndex = 1000;
    int labelIndex = 0;
    int last_int = 0;
    float last_float = 0;
    char* last_string = "";
    int last_bool;

    void insert_symbol(char* name, char* type, char* elementType);
    void declareFunction(char* name, char* type, char* elementType,int init);
    void idFunction(char* id);
    void init_symbolTable();
    char* get_id_type(char* id);
    int get_id_index(char *id);
    char* get_id_elementType(char* id);
    
    FILE *fout = NULL;
    bool HAS_ERROR = false;
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
;

assign_statement
    : value_basic ASSIGN logical_statement_1
    {
        if(!strcmp(printType,"int")) fprintf(fout,"istore %d\n",get_id_index($1));
        else if(!strcmp(printType,"float")) fprintf(fout,"fstore %d\n",get_id_index($1));
        else if(!strcmp(printType,"string")) fprintf(fout,"astore %d\n",get_id_index($1));
        else if(!strcmp(printType,"bool")) fprintf(fout,"istore %d\n",get_id_index($1));
    }
    | value_basic ADD_ASSIGN logical_statement_1
    {
        if(!strcmp(printType,"int")) {fprintf(fout,"iadd\n"); fprintf(fout,"istore %d\n",get_id_index($1));}
        else if(!strcmp(printType,"float")) {fprintf(fout,"fadd\n"); fprintf(fout,"fstore %d\n",get_id_index($1));}
    }
    | value_basic SUB_ASSIGN logical_statement_1
    {
        if(!strcmp(printType,"int")) {fprintf(fout,"isub\n"); fprintf(fout,"istore %d\n",get_id_index($1));}
        else if(!strcmp(printType,"float")) {fprintf(fout,"fsub\n"); fprintf(fout,"fstore %d\n",get_id_index($1));}
    }
    | value_basic MUL_ASSIGN logical_statement_1
    {
        if(!strcmp(printType,"int")) {fprintf(fout,"imul\n"); fprintf(fout,"istore %d\n",get_id_index($1));}
        else if(!strcmp(printType,"float")) {fprintf(fout,"fmul\n"); fprintf(fout,"fstore %d\n",get_id_index($1));}
    }
    | value_basic QUO_ASSIGN logical_statement_1
    {
        if(!strcmp(printType,"int")) {fprintf(fout,"idiv\n"); fprintf(fout,"istore %d\n",get_id_index($1));}
        else if(!strcmp(printType,"float")) {fprintf(fout,"fdiv\n"); fprintf(fout,"fstore %d\n",get_id_index($1));}
    }
    | value_basic REM_ASSIGN logical_statement_1
    {fprintf(fout,"irem\n"); fprintf(fout,"istore %d\n",get_id_index($1));}
    | value_basic LBRACK logical_statement_1 RBRACK {fprintf(fout,"aload %d\n",get_id_index($1)); fprintf(fout,"swap\n");}
      ASSIGN logical_statement_1
    {
        if(!strcmp(get_id_elementType($1),"int")) fprintf(fout,"iastore\n");
        else fprintf(fout,"fastore\n");
    }
;

while_statement
    : WHILE LB logical_statement_1 RB LBRACE program RBRACE
;

declare_statement
    : type ID SEMICOLON {declareFunction($2, $1, "-", 0);}
    | type ID ASSIGN value SEMICOLON {declareFunction($2, $1, "-", 1);}
    | type ID LBRACK value RBRACK SEMICOLON {declareFunction($2, "array", $1, 0);}
;

print_statement
    : PRINT LB logical_statement_1 RB SEMICOLON
    {
        if(!strcmp(printType,"int"))
            fprintf(fout,"getstatic java/lang/System/out Ljava/io/PrintStream;\nswap\ninvokevirtual java/io/PrintStream/print(I)V\n");
        else if(!strcmp(printType,"float"))
            fprintf(fout,"getstatic java/lang/System/out Ljava/io/PrintStream;\nswap\ninvokevirtual java/io/PrintStream/print(F)V\n");
        else if(!strcmp(printType,"string"))
            fprintf(fout,"getstatic java/lang/System/out Ljava/io/PrintStream;\nswap\ninvokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
        else if(!strcmp(printType,"bool")){
            fprintf(fout,"ifne L_cmp_%d\n",labelIndex); labelIndex++; fprintf(fout,"ldc \"false\"\n"); fprintf(fout,"goto L_cmp_%d\n",labelIndex); labelIndex--;
            fprintf(fout,"L_cmp_%d:\n",labelIndex); labelIndex++; fprintf(fout,"ldc \"true\"\n"); fprintf(fout,"L_cmp_%d:\n",labelIndex); labelIndex++;
            fprintf(fout,"getstatic java/lang/System/out Ljava/io/PrintStream;\n"); fprintf(fout,"swap\n"); fprintf(fout,"invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
        }
    }
;

logical_statement_1
    : logical_statement_2 OR logical_statement_2 {fprintf(fout,"ior\n");}
    | logical_statement_1 OR logical_statement_2 {fprintf(fout,"ior\n");}
    | logical_statement_2
;

logical_statement_2
    : comparater_statement AND comparater_statement {fprintf(fout,"iand\n");}
    | logical_statement_2 AND comparater_statement {fprintf(fout,"iand\n");}
    | comparater_statement
;

comparater_statement
    : arithmetic_statement GTR arithmetic_statement
    {   if(!strcmp(printType,"int")){
            fprintf(fout,"isub\n"); fprintf(fout,"ifgt L_cmp_%d\n",labelIndex); labelIndex++; fprintf(fout,"iconst_0\n"); fprintf(fout,"goto L_cmp_%d\n",labelIndex); labelIndex--;
            fprintf(fout,"L_cmp_%d:\n",labelIndex); labelIndex++; fprintf(fout,"iconst_1\n"); fprintf(fout,"L_cmp_%d:\n",labelIndex); labelIndex++;}
        else if(!strcmp(printType,"float")){
            fprintf(fout,"fcmpl\n"); fprintf(fout,"ifgt L_cmp_%d\n",labelIndex); labelIndex++; fprintf(fout,"iconst_0\n"); fprintf(fout,"goto L_cmp_%d\n",labelIndex); labelIndex--;
            fprintf(fout,"L_cmp_%d:\n",labelIndex); labelIndex++; fprintf(fout,"iconst_1\n"); fprintf(fout,"L_cmp_%d:\n",labelIndex); labelIndex++;}
    }
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
    {   if(!strcmp(printType,"int")) fprintf(fout,"iadd\n");
        else if(!strcmp(printType,"float")) fprintf(fout,"fadd\n");}
    | arithmetic_statement_2 SUB arithmetic_statement_2
    {   if(!strcmp(printType,"int")) fprintf(fout,"isub\n");
        else if(!strcmp(printType,"float")) fprintf(fout,"fsub\n");}
    | arithmetic_statement_1 ADD arithmetic_statement_2
    {   if(!strcmp(printType,"int")) fprintf(fout,"iadd\n");
        else if(!strcmp(printType,"float")) fprintf(fout,"fadd\n");}
    | arithmetic_statement_1 SUB arithmetic_statement_2
    {   if(!strcmp(printType,"int")) fprintf(fout,"isub\n");
        else if(!strcmp(printType,"float")) fprintf(fout,"fsub\n");}
    | arithmetic_statement_2
;

arithmetic_statement_2
    : arithmetic_statement_3 MUL arithmetic_statement_3
    {   if(!strcmp(printType,"int")) fprintf(fout,"imul\n");
        else if(!strcmp(printType,"float")) fprintf(fout,"fmul\n");}
    | arithmetic_statement_3 QUO arithmetic_statement_3
    {   if(!strcmp(printType,"int")) fprintf(fout,"idiv\n");
        else if(!strcmp(printType,"float")) fprintf(fout,"fdiv\n");}
    | arithmetic_statement_3 REM arithmetic_statement_3
    {fprintf(fout,"irem\n");}
    | arithmetic_statement_2 MUL arithmetic_statement_3
    {   if(!strcmp(printType,"int")) fprintf(fout,"imul\n");
        else if(!strcmp(printType,"float")) fprintf(fout,"fmul\n");}
    | arithmetic_statement_2 QUO arithmetic_statement_3
    {   if(!strcmp(printType,"int")) fprintf(fout,"idiv\n");
        else if(!strcmp(printType,"float")) fprintf(fout,"fdiv\n");}
    | arithmetic_statement_2 REM arithmetic_statement_3
    {fprintf(fout,"irem \n");}
    | arithmetic_statement_3
;

arithmetic_statement_3
    : value INC
    {   if(!strcmp(printType,"int")){fprintf(fout,"ldc 1\n");fprintf(fout,"iadd\n");fprintf(fout,"istore %d\n",lastIndex);}
        else if(!strcmp(printType,"float")){fprintf(fout,"ldc 1.0\n");fprintf(fout,"fadd\n");fprintf(fout,"fstore %d\n",lastIndex);}}    
    | value DEC
    {   if(!strcmp(printType,"int")){fprintf(fout,"ldc 1\n");fprintf(fout,"isub\n");fprintf(fout,"istore %d\n",lastIndex);}
        else if(!strcmp(printType,"float")){fprintf(fout,"ldc 1.0\n");fprintf(fout,"fsub\n");fprintf(fout,"fstore %d\n",lastIndex);}}    
    | LB arithmetic_statement_1 RB
    | ADD value
    | SUB value
    {   if(!strcmp(printType,"int")) fprintf(fout,"ineg\n");
        else if(!strcmp(printType,"float")) fprintf(fout,"fneg\n");} 
    | NOT value {fprintf(fout,"iconst_1\n"); fprintf(fout,"ixor\n");}
    | NOT arithmetic_statement_3 {fprintf(fout,"iconst_1\n"); fprintf(fout,"ixor\n");}
    | value
;

value
    : value_basic LBRACK logical_statement_1 RBRACK
    {   fprintf(fout,"aload %d\n",get_id_index($1)); fprintf(fout,"swap\n");
        if(!strcmp(get_id_elementType($1),"int")) {fprintf(fout,"iaload\n"); printType = "int";}
        else {fprintf(fout,"faload\n"); printType = "float";}}
    | LB type RB value_change_type_ID
    | LB type RB value_change_type_int
    | LB type RB value_change_type_float
    | value_basic
;

value_change_type_ID
    : ID
    {
        idFunction($1); printType = get_id_type($1);
        if(!strcmp(printType,"int")) {fprintf(fout,"i2f\n"); printType = "float";}
        else if(!strcmp(printType,"float")) {fprintf(fout,"f2i\n"); printType = "int";}
    }
;

value_change_type_int
    : INT_LIT {printType = "float"; fprintf(fout,"ldc %i\n",$1); fprintf(fout,"i2f\n"); last_float=(float)$1;}
;

value_change_type_float
    : FLOAT_LIT {printType = "int"; fprintf(fout,"ldc %f\n",$1); fprintf(fout,"f2i\n"); last_int=(int)$1;}
;

value_basic
    : INT_LIT {printType = "int"; fprintf(fout,"ldc %d\n",$1); last_int=$1;}
    | FLOAT_LIT {printType = "float"; fprintf(fout,"ldc %f\n",$1); last_float=$1;}
    | STRING_LIT {printType = "string"; fprintf(fout,"ldc \"%s\"\n",$1); last_string=$1;}
    | TRUE {printType = "bool"; fprintf(fout,"iconst_1\n"); last_bool=1;}
    | FALSE {printType = "bool"; fprintf(fout,"iconst_0\n"); last_bool=0;}
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

    /*output init */
    char *bytecode_filename = "hw3.j";
    fout = fopen(bytecode_filename, "w");
    fprintf(fout,".source hw3.j\n");
    fprintf(fout,".class public Main\n");
    fprintf(fout,".super java/lang/Object\n");
    fprintf(fout,".method public static main([Ljava/lang/String;)V\n");
    fprintf(fout,".limit stack 1000\n");
    fprintf(fout,".limit locals 1000\n");

    yyparse();

	printf("Total lines: %d\n", yylineno);

    /*end */
    fprintf(fout,"return\n");
    fprintf(fout,".end method\n");
    fclose(fout);
    fclose(yyin);

    if(HAS_ERROR)
        remove(bytecode_filename);
    return 0;
}

void insert_symbol(char* name, char* type, char* elementType){
    nowElementIndex++;
    symbolTable[symbolTableIndex][nowElementIndex].index = nowElementIndex;
    symbolTable[symbolTableIndex][nowElementIndex].name = name;
    symbolTable[symbolTableIndex][nowElementIndex].type = type;
    symbolTable[symbolTableIndex][nowElementIndex].elementType = elementType;  
}

void declareFunction(char* name, char* type, char* elementType, int init){
    insert_symbol(name, type, elementType);
    if(!strcmp(type,"int")){
        if(!init)
            fprintf(fout,"ldc 0\n");
        fprintf(fout,"istore %d\n",symbolTableIndex*30+nowElementIndex);
    } 
    else if(!strcmp(type,"float")){
        if(!init)
            fprintf(fout,"ldc 0.0\n");
        fprintf(fout,"fstore %d\n",symbolTableIndex*30+nowElementIndex);
    }
    else if(!strcmp(type,"string")){
        if(!init)
            fprintf(fout,"ldc \"\"\n");
        fprintf(fout,"astore %d\n",symbolTableIndex*30+nowElementIndex);
    }
    else if(!strcmp(type,"bool")){
        if(!init)
            fprintf(fout,"ldc 1\n");
        fprintf(fout,"istore %d\n",symbolTableIndex*30+nowElementIndex);
    }
    else if(!strcmp(type,"array")){
        fprintf(fout,"newarray %s\n",elementType);
        fprintf(fout,"astore %d\n",symbolTableIndex*30+nowElementIndex);
    }     
}

void idFunction(char* id){
    char* nowType;
    int flag = 0;
    int index_table = 0;
    int index_element = 0;
    for(int i=29;i>=0;i--){
        for(int j=0;j<30;j++){
            if(!strcmp(symbolTable[i][j].name, id)){
                nowType = symbolTable[i][j].type;
                index_table = i;
                index_element = j;
                flag = 1;
                break;
            }    
        }
        if(flag)
            break;
    }
    
    if(!strcmp(nowType,"int"))
        fprintf(fout,"iload %d\n",index_table*30+index_element);
    else if(!strcmp(nowType,"float"))
        fprintf(fout,"fload %d\n",index_table*30+index_element);
    else if(!strcmp(nowType,"string"))
        fprintf(fout,"aload %d\n",index_table*30+index_element);
    else if(!strcmp(nowType,"bool"))
        fprintf(fout,"iload %d\n",index_table*30+index_element);
    lastIndex = index_table*30+index_element;
}

void init_symbolTable(){
    for(int i=0;i<30;i++){
        for(int j=0;j<30;j++){
            symbolTable[i][j].index = 0;
            symbolTable[i][j].name = "";
            symbolTable[i][j].type = "";
            symbolTable[i][j].elementType = "";
        }
    }
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

int get_id_index(char *id){
    for(int i=29;i>=0;i--){
        for(int j=0;j<30;j++){
            if(!strcmp(symbolTable[i][j].name, id))
                return i*30+j;
        }
    }
    return 1000;
}

char* get_id_elementType(char* id){
    for(int i=29;i>=0;i--){
        for(int j=0;j<30;j++){
            if(!strcmp(symbolTable[i][j].name, id))
                return symbolTable[i][j].elementType;
        }
    }
    return "";
}