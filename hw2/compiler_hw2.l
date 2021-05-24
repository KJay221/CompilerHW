/* Definition section */
%{
    #include "common.h"
    #include "y.tab.h"

    extern int yylineno;
%}


/* Define regular expression label */
letter  [a-zA-Z_]
digit [0-9]
id {letter}+({letter}|{digit})*
inumber {digit}+
fnumber ({digit}*\.{digit}+)

/* Rules section */
%%
"+"         {printf("ADD\n"); return ADD;}
"-"         {printf("SUB\n"); return SUB;}
"*"         {printf("MUL\n"); return MUL;}
"/"         {printf("QUO\n"); return QUO;}
"%"         {printf("REM\n"); return REM;}
"++"        {printf("INC\n"); return INC;}
"--"        {printf("DEC\n"); return DEC;}

";"         {return SEMICOLON;}

"int"       {return INT;}

{id}        {return ID;}

[\n]        {yylineno++;}
.           {;}

%%
/*  C Code section */
int yywrap(void)
{
    return 1;
}