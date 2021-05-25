/* Definition section */
%{
    #include "common.h"
    #include "y.tab.h"

    extern YYSTYPE yylval;
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
"+"         {return ADD;}
"-"         {return SUB;}
"*"         {return MUL;}
"/"         {return QUO;}
"%"         {return REM;}
"++"        {return INC;}
"--"        {return DEC;}

";"         {return SEMICOLON;}

"int"       {return INT;}

{id}        {yylval.s_val = strdup(yytext); return ID;}

[\n]        {yylineno++;}
.           {;}

%%
/*  C Code section */
int yywrap(void)
{
    return 1;
}