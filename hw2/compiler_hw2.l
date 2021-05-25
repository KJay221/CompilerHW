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

">"         {return GTR;}
"<"         {return LSS;}
">="        {return GEQ;}
"<="        {return LEQ;}
"=="        {return EQL;}
"!="        {return NEQ;}

"&&"        {return AND;}
"||"        {return OR;}
"!"         {return NOT;}

"("         {return LB;}
")"         {return RB;}
";"         {return SEMICOLON;}

"print"     {return PRINT;}
"int"       {return INT;}
"true"      {return TRUE;}
"false"     {return FALSE;}

{inumber}	{yylval.i_val = atoi(yytext); return INT_LIT;}
{fnumber}	{yylval.f_val = atof(yytext); return FLOAT_LIT;}

{id}        {yylval.s_val = strdup(yytext); return ID;}

[\n]        {yylineno++;}
.           {;}

%%
/*  C Code section */
int yywrap(void)
{
    return 1;
}