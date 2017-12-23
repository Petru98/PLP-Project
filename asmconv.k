/*
$ krun --output none test.asm > test.s && nasm -f elf64 test.s && ld -o test test.o && ./test
*/

module ASMCONV-SYNTAX

    imports GLOBAL-SCOPE-SYNTAX
    imports FUNCTION-SCOPE-SYNTAX



    syntax Pgm ::= GlobalDecl
endmodule



module ASMCONV

    imports ASMCONV-SYNTAX
    imports CONFIGURATION
    imports GLOBAL-SCOPE
    imports SECTION-RODATA
    imports SECTION-DATA
    imports SECTION-BSS
    imports SECTION-TEXT
    imports FUNCTION-SCOPE
    imports SECTION-STRINGS



    rule <k> ___startpoint => ___createsectionrodata ~> ___createsectiondata ~> ___createsectionbss ~> ___createsectiontext
                           ~> ___createsectionstrings ~> ___declareexternaldependencies
                           ~> ___flushasmout
         </k>



    syntax KItem ::= "___declareexternaldependencies"
    rule ___declareexternaldependencies => ___declare_printf ~> ___declare_scanf

    syntax KItem ::= "___declare_printf"
    rule <k> (___declare_printf => .) ...</k>
         <strs> Strs </strs>
         when notBool("%s" in keys(Strs)) andBool notBool("%lld" in keys(Strs))
    rule <k> (___declare_printf => ___printasmout("extern printf\n")) ...</k>
         <strs> Strs </strs>
         when ("%s" in keys(Strs)) orBool ("%lld" in keys(Strs))

    syntax KItem ::= "___declare_scanf"
    rule <k> (___declare_scanf => .) ...</k>
         <strs> Strs </strs>
         when notBool("%s" in keys(Strs)) andBool notBool("%lld" in keys(Strs))
    rule <k> (___declare_scanf => ___printasmout("extern scanf\n")) ...</k>
         <strs> Strs </strs>
         when ("%s" in keys(Strs)) orBool ("%lld" in keys(Strs))
endmodule



////////////////////////////////////////////////////////////////
/// Data types, constants and other related things
////////////////////////////////////////////////////////////////
module TYPE
    syntax Type  ::= "int" | "char" "*"
    syntax Int   ::= "sizeof" "(" Type ")"                          [klabel(sizeof), function]
    syntax KItem ::= "___varinfo" "(" Type "," String "," Const ")" [klabel(___varinfo)]

    rule sizeof(int) => 8
    rule sizeof(char*) => 8



    syntax Const   ::= Int | Bool | String
    syntax Consts  ::= List{Const, ","}

    syntax Ids     ::= List{Id, ","}
    syntax Ints    ::= List{Int, ","}
    syntax Bools   ::= List{Bool, ","}
    syntax Strings ::= List{String, ","}
endmodule



////////////////////////////////////////////////////////////////
/// Syntax for the global scope of input file
////////////////////////////////////////////////////////////////
module GLOBAL-SCOPE-SYNTAX
    imports TYPE



    syntax Exp   ::= Const | Id
    syntax Block ::= "{""}"
    syntax Exps  ::= List{Exp, ","} [klabel(Exps)]



    syntax ParamDecl    ::= Type Id                    [klabel(ParamDecl)]
    syntax VarAssign    ::= Id "=" Exp                 [klabel(VarAssign), strict(2)]
    syntax VarConstruct ::= Id | VarAssign

    syntax ParamDeclList    ::= List{ParamDecl,","}    [klabel(ParamDeclList)]
    syntax VarAssignList    ::= List{VarAssign,","}    [klabel(VarAssignList)]
    syntax VarConstructList ::= List{VarConstruct,","} [klabel(VarConstructList)]



    syntax VarDecl ::= Type VarConstructList ";"       [klabel(VarDecl)]
    syntax VarDecl ::= "const" Type VarAssignList ";"  [klabel(VarDecl_const)]



    syntax GlobalFuncDecl ::= "function" Id "(" ParamDeclList ")" Block [klabel(GlobalFuncDecl)]
    syntax GlobalVarDecl  ::= VarDecl
    syntax GlobalDecl     ::= GlobalFuncDecl | GlobalVarDecl
                            > GlobalDecl GlobalDecl                     [klabel(GlobalDecl_seq), right]
endmodule



////////////////////////////////////////////////////////////////
/// Syntax for the function scope of input file
////////////////////////////////////////////////////////////////
module FUNCTION-SCOPE-SYNTAX
    imports GLOBAL-SCOPE-SYNTAX



    syntax FunctionCall ::= "read" "(" ")"  [klabel(read)]
                          | Id "(" Exps ")" [klabel(call)]

    syntax Block ::= "{" Stmt "}"



    syntax Exp ::= Int
                 | Id
                 | BExp
                 | VarAssign

                 | FunctionCall

                 | "++" Id       [klabel(PreInc)]
                 | Id "++"       [klabel(PostInc)]
                 | "--" Id       [klabel(PreDec)]
                 | Id "--"       [klabel(PostDec)]

                 > left:
                   Exp "*" Exp   [klabel(AMul), left, strict]
                 | Exp "/" Exp   [klabel(ADiv), left, strict]
                 | Exp "%" Exp   [klabel(AMod), left, strict]

                 > left:
                   Exp "+" Exp   [klabel(AAdd), left, strict]
                 | Exp "-" Exp   [klabel(ASub), left, strict]

                 > "(" Exp ")"   [bracket]



    syntax BExp ::= Bool
                  | "!" BExp        [klabel(Not), left]

                  > left:
                    Exp "<"  Exp    [klabel(SmallThan)]
                  | Exp ">"  Exp    [klabel(GreatThan)]
                  | Exp "<=" Exp    [klabel(SmallEqThan)]
                  | Exp ">=" Exp    [klabel(GreatEqThan)]
                  | Exp "==" Exp    [klabel(Eq)]
                  | Exp "!=" Exp    [klabel(NotEq)]

                  > BExp "&&" BExp  [klabel(And), left]
                  > BExp "||" BExp  [klabel(Or), left]

                  > "(" BExp ")"    [bracket]



    syntax Stmt ::= ";"                                        [klabel(;)]
                  | Exp ";"                                    [klabel(Exp;), strict]
                  | VarDecl

                  | Block

                  | "if" "("BExp")" Stmt                       [klabel(if), prefer, strict(1)]
                  | "if" "("BExp")" Stmt  "else" Stmt          [klabel(if_else), avoid, strict(1)]

                  | "while" "("BExp")" Stmt                    [klabel(while)]

                  | "for" "("Id "=" Exp";" BExp";" Exp")" Stmt [klabel(for)]

                  | "return" ";"
                  | "return" Exp ";"                           [strict]

                  | "print" "(" Exps ")" ";"                   [klabel(print)]
                  | "exit" "(" ")" ";"                         [klabel(exit)]

                  | "halt" ";"                                 [klabel(halt)]

                  > Stmt Stmt                                  [klabel(Stmt_seq), right]
endmodule



////////////////////////////////////////////////////////////////
/// Configuration and related information / functions
////////////////////////////////////////////////////////////////
module CONFIGURATION
    imports TYPE



    syntax Pgm
    syntax KResult ::= Const | Consts | Id

    syntax KItem ::= "___startpoint"
    syntax KItem ::= Id

    syntax Id ::= "main"   [token]



    configuration
    <T>
        <k> $PGM:Pgm ~> ___startpoint </k>

        <bss> .Set </bss>       //< Uninitialized global variables
        <data> .Set </data>     //< Initialized global variables
        <rodata> .Set </rodata> //< Constants and readonly variables
        <text> .Map </text>     //< Functions (code)
        <strs> .Map </strs>     //< Strings found in code mapped to auto-generated ids

        <env> .Map </env>            //< Information about all variables / parameters
        <localenv> .Set </localenv>  //< Variables defined in the current scope
        <envstack> .List </envstack> //< Stack for saving the environment before entering a block (scope)

        <rsp> 0 ~> 0 </rsp>     //< current rsp offset from rbp ~> how many bytes must be allocated on the stack for the declared variables at some point

        <level> 0 </level>               //< How many blocks deep we are (0 = global (no function is being converted to assembly))
        <currfuncname> . </currfuncname> //< Name of the current function that is being converted to assembly

        <asmout> .List </asmout>         //< Used to hold asm output before writting to stdout

        <stdin stream="stdin"> .List </stdin>
        <stdout stream="stdout"> .List </stdout>
        <stderr stream="stdout"> .List </stderr>
    </T>



    // Error, warning and info
    syntax KItem ::= "___error" "(" String ")" [klabel(___error)]

    rule <k> ___error(S:String) => . </k>
         <stderr>... (.List => ListItem("ERROR: " +String S +String "\n")) </stderr>
    rule <k> ___error(S:String) ~> X => . </k>
         <stderr>... (.List => ListItem("ERROR: " +String S +String "\n")) </stderr>



    syntax KItem ::= "___warning" "(" String ")" [klabel(___warning)]

    rule <k> (___warning(S:String) => .) ...</k>
         <stdout>... (.List => ListItem("; WARNING: " +String S +String "\n")) </stdout>



    syntax KItem ::= "___info" "(" String ")" [klabel(___info)]

    rule <k> (___info(S:String) => .) ...</k>
         <stdout>... (.List => ListItem("; INFO: " +String S +String "\n")) </stdout>



    // Flush the <asmout> cell
    syntax KItem ::= "___flushasmout"

    rule <k> (___flushasmout) ...</k>
         <asmout> (ListItem(X:Const) => .List) ...</asmout>
         <stdout>... (.List => ListItem(X)) </stdout>
    rule <k> (___flushasmout) ...</k>
         <asmout> (ListItem(X:Id) => .List) ...</asmout>
         <stdout>... (.List => ListItem(Id2String(X))) </stdout>

    rule <k> (___flushasmout => .) ...</k>
         <asmout> .List </asmout>



    // Print to <asmout>
    syntax KItem ::= "___printasmout" "(" K ")" [klabel(___printasmout)]
    rule <k> (___printasmout(X) => .) ...</k>
         <asmout>... (.List => ListItem(X)) </asmout>

    syntax KItem ::= "___printasmoutlist" "(" List ")" [klabel(___printasmoutlist)]
    rule <k> (___printasmoutlist(L) => .) ...</k>
         <asmout>... (.List => L) </asmout>



    // Structure used to remember <rsp>, <env> and <localenv>
    syntax KItem ::= "___envinfo" "(" Int "," Map "," Set ")"



    // Add string to <strs>
    syntax KItem ::= "___addstring" "(" String ")" [klabel(___addstring)]
    syntax Id ::= "___stringuid" "(" String "," Map ")" [klabel(___stringuid), function]

    rule ___stringuid(S:String, Strs:Map) => String2Id("___string" +String Int2String(size(Strs)))

    rule <k> (___addstring(S:String) => .) ...</k>
         <env> Env => Env[___stringuid(S,Strs) <- ___varinfo(char*, Id2String(___stringuid(S,Strs)), S)] </env>
         <envstack> ListItem(___envinfo(0, (GEnv => GEnv[___stringuid(S,Strs) <- ___varinfo(char*, Id2String(___stringuid(S,Strs)), S)]), .Set)) </envstack>
         <strs> Strs => Strs[S <- ___stringuid(S,Strs)] </strs>
         when notBool(S in keys(Strs))

    rule <k> (___addstring(S:String) => .) ...</k>
         <env> Env => Env[___stringuid(S,Strs) <- ___varinfo(char*, Id2String(___stringuid(S,Strs)), S)] </env>
         <envstack>... ListItem(___envinfo(0, (GEnv => GEnv[___stringuid(S,Strs) <- ___varinfo(char*, Id2String(___stringuid(S,Strs)), S)]), .Set)) </envstack>
         <strs> Strs => Strs[S <- ___stringuid(S,Strs)] </strs>
         when notBool(S in keys(Strs))
endmodule



////////////////////////////////////////////////////////////////
/// Rules for parsing the global scope
////////////////////////////////////////////////////////////////
module GLOBAL-SCOPE
    imports GLOBAL-SCOPE-SYNTAX
    imports CONFIGURATION



    // Global declaration sequence
    rule D:GlobalDecl Ds:GlobalDecl => D ~> Ds



    // Global variable declaration
    rule <k> (T:Type .VarConstructList; => .) ...</k>
         <currfuncname> . </currfuncname>
    rule <k> (const T:Type .VarAssignList; => .) ...</k>
         <currfuncname> . </currfuncname>

    rule <k> T:Type (X:Id, Xs => Xs); ...</k>
         <bss>... (.Set => SetItem(X)) ...</bss>
         <env>... (.Map => X |-> ___varinfo(T, "[" +String Id2String(X) +String "]", 0)) ...</env>
         <currfuncname> . </currfuncname>

    rule <k> T:Type (X:Id = V:Const, Xs => Xs); ...</k>
         <data>... (.Set => SetItem(X)) ...</data>
         <env>... (.Map => X |-> ___varinfo(T, "[" +String Id2String(X) +String "]", V)) ...</env>
         <currfuncname> . </currfuncname>

    rule <k> const T:Type (X:Id = V:Const, Xs => Xs); ...</k>
         <rodata>... (.Set => SetItem(X)) ...</rodata>
         <env>... (.Map => X |-> ___varinfo(T, Id2String(X), V)) ...</env>
         <currfuncname> . </currfuncname>



    // Function declaration
    syntax KItem ::= "___lambda" "(" ParamDeclList "," Block ")"

    rule <k> (function F:Id(Ds:ParamDeclList) B:Block => .) ...</k>
         <text> Text => Text[F <- ___lambda(Ds,B)] </text>
         <currfuncname> . </currfuncname>
endmodule



////////////////////////////////////////////////////////////////
/// Rules for creating the rodata section
////////////////////////////////////////////////////////////////
module SECTION-RODATA
    imports CONFIGURATION



    syntax KItem ::= "___createsectionrodata"

    rule <k> (___createsectionrodata => .) ...</k>
         <rodata> RoData </rodata>
         when size(RoData) ==Int 0
    rule <k> (___createsectionrodata => ___printasmout("section .rodata\n") ~> ___sectionrodata(RoData)) ...</k>
         <rodata> RoData </rodata>
         when size(RoData) =/=Int 0



    syntax KItem ::= "___sectionrodata" "(" Set ")"

    rule <k> (___sectionrodata(.Set) => ___printasmout("\n")) ...</k>

    rule <k> (___sectionrodata(SetItem(X:Id) Xs:Set) => ___printasmoutlist(ListItem("    ") ListItem(X) ListItem(": equ ") ListItem(V) ListItem("\n"))
                                                     ~> ___sectionrodata(Xs -Set SetItem(X)))
         ...</k>
         <env>... (X |-> ___varinfo(int, _, V)) ...</env>
endmodule



////////////////////////////////////////////////////////////////
/// Rules for creating the data section
////////////////////////////////////////////////////////////////
module SECTION-DATA
    imports CONFIGURATION



    syntax KItem ::= "___createsectiondata"

    rule <k> (___createsectiondata => .) ...</k>
         <data> Data </data>
         when size(Data) ==Int 0
    rule <k> (___createsectiondata => ___printasmout("section .data\n") ~> ___sectiondata(Data)) ...</k>
         <data> Data </data>
         when size(Data) =/=Int 0



    syntax KItem ::= "___sectiondata" "(" Set ")"

    rule <k> (___sectiondata(.Set) => ___printasmout("\n")) ...</k>
    rule <k> (___sectiondata(SetItem(X:Id) Xs) => ___printasmoutlist(ListItem("    ") ListItem(X) ListItem(": dq ") ListItem(V) ListItem("\n"))
                                               ~> ___sectiondata(Xs -Set SetItem(X)))
         ...</k>
         <env>... (X |-> ___varinfo(int, _, V)) ...</env>
endmodule



////////////////////////////////////////////////////////////////
/// Rules for creating the bss section
////////////////////////////////////////////////////////////////
module SECTION-BSS
    imports CONFIGURATION



    syntax KItem ::= "___createsectionbss"

    rule <k> (___createsectionbss => .) ...</k>
         <bss> Bss </bss>
         when size(Bss) ==Int 0
    rule <k> (___createsectionbss => ___printasmout("section .bss\n") ~> ___sectionbss(Bss)) ...</k>
         <bss> Bss </bss>
         when size(Bss) =/=Int 0



    syntax KItem ::= "___sectionbss" "(" Set ")"

    rule <k> (___sectionbss(.Set) => ___printasmout("\n")) ...</k>
    rule <k> (___sectionbss(SetItem(X:Id) Xs) => ___printasmoutlist(ListItem("    ") ListItem(X) ListItem(": resb ") ListItem(sizeof(int)) ListItem("\n"))
                                              ~> ___sectionbss(Xs -Set SetItem(X)))
         ...</k>
         <env>... (X |-> ___varinfo(int, _, _)) ...</env>
endmodule



////////////////////////////////////////////////////////////////
/// Rules for creating the rodata section
////////////////////////////////////////////////////////////////
module SECTION-STRINGS
    imports CONFIGURATION



    syntax KItem ::= "___createsectionstrings"

    rule <k> (___createsectionstrings => .) ...</k>
         <strs> Strs </strs>
         when size(Strs) ==Int 0
    rule <k> (___createsectionstrings => ___printasmout("section .rodata\n") ~> ___sectionstrings(Strs)) ...</k>
         <strs> Strs </strs>
         when size(Strs) =/=Int 0



    syntax KItem ::= "___str2fmt" "(" String ")" [klabel(___str2fmt), function]

    rule ___str2fmt(S:String) => replaceAll(replaceAll(S,"\n","\\n"),"\t","\\t")



    syntax KItem ::= "___sectionstrings" "(" Map ")"

    rule <k> (___sectionstrings(.Map) => ___printasmout("\n")) ...</k>

    rule <k> (___sectionstrings((S:String |-> X:Id) Xs:Map) => ___printasmoutlist(ListItem("    ") ListItem(X) ListItem(": db `") ListItem(___str2fmt(S)) ListItem("`, 0\n"))
                                                            ~> ___sectionstrings(Xs -Map (S |-> X)))
         ...</k>
endmodule



////////////////////////////////////////////////////////////////
/// Rules for creating the text section
////////////////////////////////////////////////////////////////
module SECTION-TEXT
    imports FUNCTION-SCOPE-SYNTAX
    imports GLOBAL-SCOPE
    imports ASMINSTR



    syntax KItem ::= "___createsectiontext"

    rule <k> (___createsectiontext => .) ...</k>
         <text> Text </text>
         when size(Text) ==Int 0
    rule <k> (___createsectiontext => ___printasmout("section .text\n") ~> ___sectiontext(Text)) ...</k>
         <text> Text </text>
         when size(Text) =/=Int 0



    syntax KItem ::= "___sectiontext" "(" Map ")"

    rule <k> (___sectiontext(.Map) => ___printasmout("\n")) ...</k>
    rule <k> (___sectiontext(F:Id |-> ___lambda(Ds:ParamDeclList, B:Block) M:Map) => ___convertfunction(F, Ds, B) ~> ___sectiontext(M)) ...</k>



    // Convert function to assembly code
    syntax KItem ::= "___convertfunction" "(" Id "," ParamDeclList "," Block ")"



    rule <k> (___convertfunction(F:Id, Ds:ParamDeclList, {B}:Block) => ___printasmoutlist(ListItem("global ") ListItem(F) ListItem("\n    ")
                                                                                          ListItem(F) ListItem(":\n")
                                                                                          ListItem("        push rbp\n")
                                                                                          ListItem("        mov  rbp, rsp\n\n"))
                                                                    ~> ___processparameters(-16, Ds)
                                                                    ~> B
                                                                    ~> ___returnfromfunction(0)
                                                                    ~> ___convertfunctionend)
         ...</k>
         <rsp> 0 ~> 0 </rsp>
         <env> Env </env>
         <localenv> .Set </localenv>
         <envstack> (.List => ListItem(___envinfo(0,Env,.Set))) ...</envstack>
         <level> 0 => 1 </level>
         <currfuncname> . => F:Id </currfuncname>

    rule <k> (___convertfunction(F:Id, Ds:ParamDeclList, {}:Block) => ___printasmoutlist(ListItem("global ") ListItem(F) ListItem("\n    ")
                                                                                         ListItem(F) ListItem(":\n")
                                                                                         ListItem("        xor rax, rax\n")
                                                                                         ListItem("        ret\n\n")))
         ...</k>



    // Map parameters to the coresponding offset from rbp
    syntax KItem ::= "___processparameters" "(" Int "," ParamDeclList ")"



    rule <k> (___processparameters(Offset:Int, .ParamDeclList) => .) ...</k>


    rule <k> (___processparameters(Offset:Int, int X:Id, Ds) => ___processparameters(Offset -Int sizeof(int), Ds)) ...</k>
         <env> Env => Env[X <- ___varinfo(int, "[rbp - (" +String Int2String(Offset) +String ")]", Offset)] </env>
         <localenv>... (.Set => SetItem(X)) ...</localenv>



    // Write the code that returns from function
    syntax KItem ::= "___returnfromfunction" "("        ")"
                   | "___returnfromfunction" "(" Id     ")"
                   | "___returnfromfunction" "(" Int    ")"
                   | "___returnfromfunction" "(" String ")"



    rule ___returnfromfunction() => ___returnfromfunction(0)



    rule <k> (___returnfromfunction(X:Id) => ___asmreturn(X) ~> ___printasmout("\n")) ...</k>
         <rsp> SP:Int ~> 0 </rsp>
         <currfuncname> F:Id </currfuncname>
         when SP ==Int 0
    rule <k> (___returnfromfunction(X:Int) => ___asmreturn(X) ~> ___printasmout("\n")) ...</k>
         <rsp> SP:Int ~> 0 </rsp>
         <currfuncname> F:Id </currfuncname>
         when SP ==Int 0
    rule <k> (___returnfromfunction(X:String) => ___asmreturn(X) ~> ___printasmout("\n")) ...</k>
         <rsp> SP:Int ~> 0 </rsp>
         <currfuncname> F:Id </currfuncname>
         when SP ==Int 0



    rule <k> (___returnfromfunction(X:Id) => ___asmsub("rsp", "(-" +String Int2String(SP) +String ")")
                                          ~> ___asmreturn(X) ~> ___printasmout("\n")) ...</k>
         <rsp> SP:Int ~> 0 </rsp>
         <currfuncname> F:Id </currfuncname>
         when SP =/=Int 0
    rule <k> (___returnfromfunction(X:Int) => ___asmsub("rsp", "(-" +String Int2String(SP) +String ")")
                                           ~> ___asmreturn(X) ~> ___printasmout("\n")) ...</k>
         <rsp> SP:Int ~> 0 </rsp>
         <currfuncname> F:Id </currfuncname>
         when SP =/=Int 0
    rule <k> (___returnfromfunction(X:String) => ___asmsub("rsp", "(-" +String Int2String(SP) +String ")")
                                              ~> ___asmreturn(X) ~> ___printasmout("\n")) ...</k>
         <rsp> SP:Int ~> 0 </rsp>
         <currfuncname> F:Id </currfuncname>
         when SP =/=Int 0



    // Clean cells after the function was converted to assembly
    syntax KItem ::= "___convertfunctionend"

    rule <k> (___convertfunctionend => .) ...</k>
         <rsp> (_ => 0) ~> 0 </rsp>
         <env> _ => Env </env>
         <localenv> _ => .Set </localenv>
         <envstack> (ListItem(___envinfo(0,Env,.Set)) => .List) ...</envstack>
         <level> Lvl => 0 </level>
         <currfuncname> F:Id => . </currfuncname>
endmodule



////////////////////////////////////////////////////////////////
/// Rules for converting a function's code to assembly
////////////////////////////////////////////////////////////////
module FUNCTION-SCOPE
    imports FUNCTION-SCOPE-SYNTAX
    imports GLOBAL-SCOPE
    imports SECTION-TEXT
    imports ASMINSTR



    // Stmt
    rule S:Stmt Ss:Stmt => S ~> Ss

    rule ; => .
    rule X:Id; => .
    rule X:Const; => .



    // Block
    rule <k> ({} => .) ...</k>



    rule <k> ({S:Stmt} => S ~> ___restoreenv) ...</k>
         <rsp> SP ~> 0 </rsp>
         <env> Env </env>
         <localenv> LocalEnv => .Set </localenv>
         <envstack> (.List => ListItem(___envinfo(SP,Env,LocalEnv))) ...</envstack>
         <level> Lvl => Lvl +Int 1 </level>
         <currfuncname> F:Id </currfuncname>



    syntax KItem ::= "___restoreenv"

    rule <k> (___restoreenv => ___printasmoutlist(ListItem("        sub  rsp, (") ListItem(SP -Int OldSP) ListItem(")\n"))) ...</k>
         <rsp> (OldSP => SP) ~> 0 </rsp>
         <env> _ => Env </env>
         <localenv> _ => LocalEnv </localenv>
         <envstack> (ListItem(___envinfo(SP,Env,LocalEnv)) => .List) ...</envstack>
         <level> Lvl => Lvl -Int 1 </level>
         <currfuncname> F:Id </currfuncname>



    // Return / Exit
    rule (return;               => ___returnfromfunction()     ) ~> S:Stmt
    rule (return X:Id;          => ___returnfromfunction(X)    ) ~> S:Stmt
    rule (return X:Int;         => ___returnfromfunction(X)    ) ~> S:Stmt
    rule (return LR:LastResult; => ___returnfromfunction("rax")) ~> S:Stmt

    rule (return;               ~> ___returnfromfunction(0) => ___printasmout("\n") ~> ___returnfromfunction()     ) ~> ___convertfunctionend
    rule (return X:Id;          ~> ___returnfromfunction(0) => ___printasmout("\n") ~> ___returnfromfunction(X)    ) ~> ___convertfunctionend
    rule (return X:Int;         ~> ___returnfromfunction(0) => ___printasmout("\n") ~> ___returnfromfunction(X)    ) ~> ___convertfunctionend
    rule (return LR:LastResult; ~> ___returnfromfunction(0) => ___printasmout("\n") ~> ___returnfromfunction("rax")) ~> ___convertfunctionend



    // Variable declaration
    rule <k> int (X:Id, Xs => Xs); ...</k>
         <rsp> (SP:Int ~> B) => (SP +Int sizeof(int) ~> B +Int sizeof(int)) </rsp>
         <env> Env => Env[X <- ___varinfo(int, "[rbp - (" +String Int2String(SP +Int sizeof(int)) +String ")]", SP +Int sizeof(int))] </env>
         <localenv>... (.Set => SetItem(X)) ...</localenv>
         <currfuncname> F:Id </currfuncname>

    rule <k> (T:Type .VarConstructList; => ___printasmoutlist(ListItem("        sub  rsp, (") ListItem(B) ListItem(")\n"))) ...</k>
         <rsp> SP:Int ~> (B:Int => 0) </rsp>
         <currfuncname> F:Id </currfuncname>



    // Assignment
    rule X:Id = Y:Id          => ___asmmov("rax", Y) ~> ___asmmov(X, "rax") ~> X
    rule X:Id = Y:Int         => ___asmmov(X, Y) ~> X
    rule X:Id = LR:LastResult => ___asmmov(X, "rax") ~> X



    // Increment / Decrement
    rule ++ X:Id => ___asminc(X) ~> ___asmmov("rax", X) ~> ___lastresult
    rule X:Id ++ => ___asmmov("rax", X) ~> ___asminc(X) ~> ___lastresult
    rule -- X:Id => ___asmdec(X) ~> ___asmmov("rax", X) ~> ___lastresult
    rule X:Id -- => ___asmmov("rax", X) ~> ___asmdec(X) ~> ___lastresult



    // Arithmetic
    rule X:Int + Y:Int => X +Int Y
    rule X:Int - Y:Int => X -Int Y
    rule X:Int * Y:Int => X *Int Y
    rule X:Int / Y:Int => X /Int Y
    rule X:Int % Y:Int => X %Int Y

    rule X:Id  + Y:Id          => ___asmmov("rax", X) ~> ___asmadd("rax", Y) ~> ___lastresult
    rule X:Id  + Y:Int         => ___asmmov("rax", X) ~> ___asmadd("rax", Y) ~> ___lastresult
    rule X:Id  + LR:LastResult => ___asmadd("rax", X) ~> LR
    rule X:Int + Y:Id          => ___asmmov("rax", Y) ~> ___asmadd("rax", X) ~> ___lastresult
    rule X:Int + LR:LastResult => ___asmadd("rax", X) ~> LR
    rule LR:LastResult + Y:Id  => ___asmadd("rax", Y) ~> LR
    rule LR:LastResult + Y:Int => ___asmadd("rax", Y) ~> LR

    rule X:Id  - Y:Id          => ___asmmov("rax", X) ~> ___asmsub("rax", Y) ~> ___lastresult
    rule X:Id  - Y:Int         => ___asmmov("rax", X) ~> ___asmsub("rax", Y) ~> ___lastresult
    rule X:Id  - LR:LastResult => ___asmsub("rax", X) ~> LR
    rule X:Int - Y:Id          => ___asmmov("rax", Y) ~> ___asmsub("rax", X) ~> ___lastresult
    rule X:Int - LR:LastResult => ___asmsub("rax", X) ~> LR
    rule LR:LastResult - Y:Id  => ___asmsub("rax", Y) ~> LR
    rule LR:LastResult - Y:Int => ___asmsub("rax", Y) ~> LR

    rule X:Id  * Y:Id          => ___asmmov("rax", X) ~> ___asmmul("rax", Y) ~> ___lastresult
    rule X:Id  * Y:Int         => ___asmmov("rax", Y) ~> ___asmmul("rax", X) ~> ___lastresult
    rule X:Id  * LR:LastResult => ___asmmul("rax", X) ~> LR
    rule X:Int * Y:Id          => ___asmmov("rax", X) ~> ___asmmul("rax", Y) ~> ___lastresult
    rule X:Int * LR:LastResult => ___asmmul("rax", X) ~> LR
    rule LR:LastResult * Y:Id  => ___asmmul("rax", Y) ~> LR
    rule LR:LastResult * Y:Int => ___asmmul("rax", Y) ~> LR

    rule X:Id  / Y:Id          => ___asmxor("rdx", "rdx") ~> ___asmmov("rax", X)     ~> ___asmdiv(Y)        ~> ___lastresult
    rule X:Id  / Y:Int         => ___asmxor("rdx", "rdx") ~> ___asmmov("rax", X)     ~> ___asmmov("rbx", Y) ~> ___asmdiv("rbx") ~> ___lastresult
    rule X:Id  / LR:LastResult => ___asmxor("rdx", "rdx") ~> ___asmmov("rbx", "rax") ~> ___asmmov("rax", X) ~> ___asmdiv("rbx") ~> LR
    rule X:Int / Y:Id          => ___asmxor("rdx", "rdx") ~> ___asmmov("rax", X)     ~> ___asmdiv(Y)        ~> ___lastresult
    rule X:Int / LR:LastResult => ___asmxor("rdx", "rdx") ~> ___asmmov("rbx", "rax") ~> ___asmmov("rax", X) ~> ___asmdiv("rbx") ~> LR
    rule LR:LastResult / Y:Id  => ___asmxor("rdx", "rdx") ~> ___asmdiv(Y)            ~> LR
    rule LR:LastResult / Y:Int => ___asmxor("rdx", "rdx") ~> ___asmmov("rbx", Y)     ~> ___asmdiv("rbx")    ~> LR



    // Print
    rule print(.Exps); => .
    rule print(X:Exp, Xs:Exps); => ___print(X) ~> print(Xs);



    syntax KItem ::= "___print" "(" Exp ")" [strict]

    rule ___print(X:Id)          => ___asmmov("rax", X) ~> ___print(___lastresult)
    rule ___print(X:Int)         => ___asmprint(X)
    rule ___print(X:String)      => ___asmprint(X)
    rule ___print(LR:LastResult) => ___asmprint(LR)



    // Read
    rule read() => ___asmread()



    // Function call
    rule F:Id(Xs:Exps) => ___asmfunccall(F, Xs) ~> ___lastresult
endmodule



////////////////////////////////////////////////////////////////
/// Helper functions for assembly instructions
////////////////////////////////////////////////////////////////
module ASMINSTR
    imports CONFIGURATION
    imports GLOBAL-SCOPE



    // Represents the result of the last operation
    syntax LastResult ::= "___lastresult"
    syntax Const ::= LastResult



    // Exit the program
    syntax KItem ::= "___asmexit" "(" Id     ")" [klabel(___asmexit_id)]
                   | "___asmexit" "(" Int    ")" [klabel(___asmexit_int)]
                   | "___asmexit" "(" String ")" [klabel(___asmexit_string)]



    rule <k> (___asmexit(X:Id) => ___asmexit(AccessStr)) ...</k>
         <env>... (X |-> ___varinfo(int, AccessStr:String, _)) ...</env>

    rule <k> (___asmexit(V:Int) => ___asmexit(Int2String(V))) ...</k>


    rule <k> (___asmexit(S:String) => .) ...</k>
         <asmout>... (.List => ListItem("        mov  rax, 60\n")
                               ListItem("        mov  rdi, ") ListItem(S) ListItem("\n")
                               ListItem("        syscall\n"))
         </asmout>
         when S =/=String "rdi"

    rule <k> (___asmexit(S:String) => .) ...</k>
         <asmout>... (.List => ListItem("        mov  rax, 60\n")
                               ListItem("        syscall\n"))
         </asmout>
         when S ==String "rdi"



    // Return from function
    syntax KItem ::= "___asmreturn" "(" Id     ")" [klabel(___asmreturn_id)]
                   | "___asmreturn" "(" Int    ")" [klabel(___asmreturn_int)]
                   | "___asmreturn" "(" String ")" [klabel(___asmreturn_string)]



    rule <k> (___asmreturn(X:Id) => ___asmreturn(AccessStr)) ...</k>
         <env>... (X |-> ___varinfo(int, AccessStr:String, _)) ...</env>

    rule <k> (___asmreturn(V:Int) => ___asmreturn(Int2String(V))) ...</k>


    rule <k> (___asmreturn(S:String) => .) ...</k>
         <asmout>... (.List => ListItem("        pop  rbp\n")
                               ListItem("        mov  rax, ") ListItem(S) ListItem("\n")
                               ListItem("        ret\n"))
         </asmout>
         when S =/=String "rax"

    rule <k> (___asmreturn(S:String) => .) ...</k>
         <asmout>... (.List => ListItem("        pop  rbp\n")
                               ListItem("        ret\n"))
         </asmout>
         when S ==String "rax"



    // Print
    syntax KItem ::= "___asmprint" "(" Exp ")" [klabel(___asmprint), strict]



    rule <k> (___asmprint(X:Id) => ___addstring("%lld") ~> ___asmprint(X)) ...</k>
         <env>... (X |-> ___varinfo(int, _, _)) ...</env>
         <strs> Strs </strs>
         when notBool("%lld" in keys(Strs))
    rule <k> (___asmprint(X:Id) => ___asmmov("rdi", L) ~> ___asmmov("rsi", AccessStr) ~> ___asmxor("rax", "rax") ~> ___printasmout("        call printf\n")) ...</k>
         <env>... (X |-> ___varinfo(int, AccessStr:String, _)) ...</env>
         <strs>... ("%lld" |-> L:Id) ...</strs>



    rule <k> (___asmprint(X:Int) => ___addstring("%lld") ~> ___asmprint(X)) ...</k>
         <env>... (X |-> ___varinfo(int, _, _)) ...</env>
         <strs> Strs </strs>
         when notBool("%lld" in keys(Strs))
    rule <k> (___asmprint(X:Int) => ___asmmov("rdi", L) ~> ___asmmov("rsi", X) ~> ___asmxor("rax", "rax") ~> ___printasmout("        call printf\n")) ...</k>
         <strs>... ("%lld" |-> L:Id) ...</strs>



    rule <k> (___asmprint(S:String) => ___addstring("%s") ~> ___asmprint(S)) ...</k>
         <strs> Strs </strs>
         when notBool("%s" in keys(Strs))
    rule <k> (___asmprint(S:String) => ___addstring(S) ~> ___asmprint(S)) ...</k>
         <strs> Strs </strs>
         when notBool(S in keys(Strs))
    rule <k> (___asmprint(S:String) => ___asmprint_string_fmt("%s") ~> ___asmprint_string_str(S) ~> ___asmxor("rax", "rax") ~> ___printasmout("        call printf\n")) ...</k>
         <strs> Strs </strs>
         when ("%s" in keys(Strs)) andBool (S in keys(Strs))

    syntax KItem ::= "___asmprint_string_fmt" "(" String ")"
                   | "___asmprint_string_str" "(" String ")"
    rule <k> (___asmprint_string_fmt(Fmt:String) => ___asmmov("rdi", X)) ...</k>
         <strs>... (Fmt |-> X:Id) ...</strs>
    rule <k> (___asmprint_string_str(Str:String) => ___asmmov("rsi", X)) ...</k>
         <strs>... (Str |-> X:Id) ...</strs>



    rule <k> (___asmprint(LR:LastResult) => ___addstring("%lld") ~> ___asmprint(LR)) ...</k>
         <strs> Strs </strs>
         when notBool("%lld" in keys(Strs))
    rule <k> (___asmprint(LR:LastResult) => ___asmmov("rdi", L) ~> ___asmmov("rsi", "rax") ~> ___asmxor("rax", "rax") ~> ___printasmout("        call printf\n")) ...</k>
         <strs>... ("%lld" |-> L:Id) ...</strs>



    // Read
    syntax KItem ::= "___asmread" "(" ")" [klabel(___asmread)]

    rule <k> (___asmread() => ___addstring("%lld") ~> ___asmread()) ...</k>
         <strs> Strs </strs>
         when notBool("%lld" in keys(Strs))

    rule <k> (___asmread() => ___asmmov("rdi", L)       ~> ___asmadd("rsp", "(-" +String Int2String(sizeof(int)) +String ")")
                           ~> ___asmmov("rsi", "rsp")   ~> ___asmxor("rax", "rax") ~> ___printasmout("        call scanf\n")
                           ~> ___asmmov("rax", "[rsp]") ~> ___asmadd("rsp", "(" +String Int2String(sizeof(int)) +String ")")
                           ~> ___lastresult) ...</k>
         <strs>... ("%lld" |-> L:Id) ...</strs>



    // Function call
    syntax KItem ::= "___asmcall" "(" Id ")" [klabel(___asmcall)]

    rule <k> (___asmcall(F:Id) => ___printasmoutlist(ListItem("        call ") ListItem(F) ListItem("\n"))) ...</k>
         <text>... (F |-> _) ...</text>



    syntax KItem ::= "___asmfunccall" "(" Id "," Exps ")" [klabel(___asmfunccall)]

    rule <k> (___asmfunccall(F:Id, .Exps) => ___asmcall(F)) ...</k>
         <text>... (F |-> _) ...</text>
         <rsp> SP:Int ~> 0 </rsp>

    rule <k> (___asmfunccall(F:Id, .Exps) => ___asmcall(F) ~> ___asmsub("rsp", "(-" +String Int2String(B) +String")")) ...</k>
         <text>... (F |-> _) ...</text>
         <rsp> SP:Int ~> (B:Int => 0) </rsp>
         when B =/=Int 0

    rule <k> (___asmfunccall(F:Id, Xs:Exps) => ___asmpushparameterlist(Xs) ~> ___asmfunccall(F, .Exps)) ...</k>
         <text>... (F |-> _) ...</text>



    syntax KItem ::= "___asmpushparameterlist" "(" Exps ")" [klabel(___asmpushparameterlist)]

    rule <k> (___asmpushparameterlist(.Exps) => .) ...</k>
    rule <k> (___asmpushparameterlist(X:Exp, Xs:Exps) => ___asmpushparameterlist(Xs) ~> ___asmpushparameter(X)) ...</k>



    syntax KItem ::= "___asmpushparameter" "(" Exp ")" [klabel(___asmpushparameter), strict]

    rule <k> (___asmpushparameter(LR:LastResult) => ___asmpush("rax")) ...</k>
         <rsp> SP:Int ~> (B:Int => B +Int sizeof(int)) </rsp>

    rule <k> (___asmpushparameter(X:Int)         => ___asmpush(X)) ...</k>
         <rsp> SP:Int ~> (B:Int => B +Int sizeof(int)) </rsp>

    rule <k> (___asmpushparameter(X:Id)          => ___asmpush(X)) ...</k>
         <rsp> SP:Int ~> (B:Int => B +Int sizeof(int)) </rsp>



    // Push
    syntax KItem ::= "___asmpush" "(" Id     ")" [klabel(___asmpush_id)]
                   | "___asmpush" "(" Int    ")" [klabel(___asmpush_int)]
                   | "___asmpush" "(" String ")" [klabel(___asmpush_string)]

    rule <k> (___asmpush(X:Id)     => ___printasmout("        push qword " +String AccessStr +String "\n")) ...</k>
         <env>... (X |-> ___varinfo(int, AccessStr:String, _)) ...</env>

    rule <k> (___asmpush(X:Int)    => ___printasmout("        push " +String Int2String(X) +String "\n")) ...</k>

    rule <k> (___asmpush(X:String) => ___printasmout("        push " +String X +String "\n")) ...</k>



    // Mov
    syntax KItem ::= "___asmmov" "(" Id     "," Id      ")"
                   | "___asmmov" "(" Id     "," Int     ")"
                   | "___asmmov" "(" Id     "," String  ")"
                   | "___asmmov" "(" String "," Id      ")"
                   | "___asmmov" "(" String "," Int     ")"
                   | "___asmmov" "(" String "," String  ")"




    rule <k> (___asmmov(X:String, Y:Int) => .) ...</k>
         <asmout>... (.List => ListItem("        mov  " +String X +String ", " +String Int2String(Y) +String "\n")) </asmout>

    rule <k> (___asmmov(X:String, Y:String) => .) ...</k>
         <asmout>... (.List => ListItem("        mov  " +String X +String ", " +String Y +String "\n")) </asmout>
         when (findChar(X, "[", 0) =/=Int 0) orBool (findChar(Y, "[", 0) =/=Int 0) orBool (X ==String Y)
    rule <k> (___asmmov(X:String, Y:String) => ___error("___asmmov: Both operands are memory references")) ...</k>
         when (findChar(X, "[", 0) ==Int 0) andBool (findChar(Y, "[", 0) ==Int 0)

    // 64-bit integer
    rule <k> (___asmmov(X:Id, Y:String) => ___asmmov(AccessStr, Y)) ...</k>
         <env>... (X |-> ___varinfo(int, AccessStr:String, _)) ...</env>
    rule <k> (___asmmov(X:Id, Y:Int)    => ___asmmov("qword " +String AccessStr, Int2String(Y))) ...</k>
         <env>... (X |-> ___varinfo(int, AccessStr:String, _)) ...</env>
    rule <k> (___asmmov(X:Id, Y:Id)     => ___asmmov("qword " +String AccessStr, Y)) ...</k>
         <env>... (X |-> ___varinfo(int, AccessStr:String, _)) ...</env>

    rule <k> (___asmmov(X:String, Y:Id) => .) ...</k>
         <asmout>... (.List => ListItem("        mov  " +String X +String ", " +String AccessStr +String "\n")) </asmout>
         <env>... (Y |-> ___varinfo(int, AccessStr:String, _)) ...</env>

    // char*
    rule <k> (___asmmov(X:Id, Y:String) => ___asmmov(AccessStr, Y)) ...</k>
         <env>... (X |-> ___varinfo(char*, AccessStr:String, _)) ...</env>
    rule <k> (___asmmov(X:Id, Y:Int)    => ___asmmov("qword " +String AccessStr, Int2String(Y))) ...</k>
         <env>... (X |-> ___varinfo(char*, AccessStr:String, _)) ...</env>
    rule <k> (___asmmov(X:Id, Y:Id)     => ___asmmov("qword " +String AccessStr, Y)) ...</k>
         <env>... (X |-> ___varinfo(char*, AccessStr:String, _)) ...</env>

    rule <k> (___asmmov(X:String, Y:Id) => .) ...</k>
         <asmout>... (.List => ListItem("        mov  " +String X +String ", " +String AccessStr +String "\n")) </asmout>
         <env>... (Y |-> ___varinfo(char*, AccessStr:String, _)) ...</env>



    // Inc / Dec
    syntax KItem ::= "___asminc" "(" Id     ")"
                   | "___asminc" "(" String ")"

    rule <k> (___asminc(X:Id) => ___asminc("dword " +String AccessStr)) ...</k>
         <env>... (X |-> ___varinfo(int, AccessStr:String, _)) ...</env>

    rule <k> (___asminc(X:String) => ___printasmout("        inc  " +String X +String "\n")) ...</k>



    syntax KItem ::= "___asmdec" "(" Id     ")"
                   | "___asmdec" "(" String ")"

    rule <k> (___asmdec(X:Id) => ___asmdec("dword " +String AccessStr)) ...</k>
         <env>... (X |-> ___varinfo(int, AccessStr:String, _)) ...</env>

    rule <k> (___asmdec(X:String) => ___printasmout("        inc  " +String X +String "\n")) ...</k>



    // Add
    syntax KItem ::= "___asmadd" "(" Id     "," Id      ")"
                   | "___asmadd" "(" Id     "," Int     ")"
                   | "___asmadd" "(" Id     "," String  ")"
                   | "___asmadd" "(" String "," Id      ")"
                   | "___asmadd" "(" String "," Int     ")"
                   | "___asmadd" "(" String "," String  ")"



    // 64-bit integer
    rule <k> (___asmadd(X:Id, Y:String) => ___asmadd(AccessStr, Y)) ...</k>
         <env>... (X |-> ___varinfo(int, AccessStr:String, _)) ...</env>
    rule <k> (___asmadd(X:Id, Y:Int)    => ___asmadd("qword " +String AccessStr, Int2String(Y))) ...</k>
         <env>... (X |-> ___varinfo(int, AccessStr:String, _)) ...</env>
    rule <k> (___asmadd(X:Id, Y:Id)     => ___asmadd("qword " +String AccessStr, Y)) ...</k>
         <env>... (X |-> ___varinfo(int, AccessStr:String, _)) ...</env>


    rule <k> (___asmadd(X:String, Y:Id) => .) ...</k>
         <asmout>... (.List => ListItem("        add  " +String X +String ", " +String AccessStr +String "\n")) </asmout>
         <env>... (Y |-> ___varinfo(int, AccessStr:String, _)) ...</env>

    rule <k> (___asmadd(X:String, Y:Int) => .) ...</k>
         <asmout>... (.List => ListItem("        add  " +String X +String ", " +String Int2String(Y) +String "\n")) </asmout>

    rule <k> (___asmadd(X:String, Y:String) => .) ...</k>
         <asmout>... (.List => ListItem("        add  " +String X +String ", " +String Y +String "\n")) </asmout>
         when (findChar(X, "[", 0) =/=Int 0) orBool (findChar(Y, "[", 0) =/=Int 0)

    rule <k> (___asmadd(X:String, Y:String) => ___error("___asmadd: Both operands are memory references")) ...</k>
         when (findChar(X, "[", 0) ==Int 0) andBool (findChar(Y, "[", 0) ==Int 0)



    // Sub
    syntax KItem ::= "___asmsub" "(" Id     "," Id      ")"
                   | "___asmsub" "(" Id     "," Int     ")"
                   | "___asmsub" "(" Id     "," String  ")"
                   | "___asmsub" "(" String "," Id      ")"
                   | "___asmsub" "(" String "," Int     ")"
                   | "___asmsub" "(" String "," String  ")"



    // 64-bit integer
    rule <k> (___asmsub(X:Id, Y:String) => ___asmsub(AccessStr, Y)) ...</k>
         <env>... (X |-> ___varinfo(int, AccessStr:String, _)) ...</env>
    rule <k> (___asmsub(X:Id, Y:Int)    => ___asmsub("qword " +String AccessStr, Int2String(Y))) ...</k>
         <env>... (X |-> ___varinfo(int, AccessStr:String, _)) ...</env>
    rule <k> (___asmsub(X:Id, Y:Id)     => ___asmsub("qword " +String AccessStr, Y)) ...</k>
         <env>... (X |-> ___varinfo(int, AccessStr:String, _)) ...</env>


    rule <k> (___asmsub(X:String, Y:Id) => .) ...</k>
         <asmout>... (.List => ListItem("        sub  " +String X +String ", " +String AccessStr +String "\n")) </asmout>
         <env>... (Y |-> ___varinfo(int, AccessStr:String, _)) ...</env>

    rule <k> (___asmsub(X:String, Y:Int) => .) ...</k>
         <asmout>... (.List => ListItem("        sub  " +String X +String ", " +String Int2String(Y) +String "\n")) </asmout>

    rule <k> (___asmsub(X:String, Y:String) => .) ...</k>
         <asmout>... (.List => ListItem("        sub  " +String X +String ", " +String Y +String "\n")) </asmout>
         when (findChar(X, "[", 0) =/=Int 0) orBool (findChar(Y, "[", 0) =/=Int 0)

    rule <k> (___asmsub(X:String, Y:String) => ___error("___asmsub: Both operands are memory references")) ...</k>
         when (findChar(X, "[", 0) ==Int 0) andBool (findChar(Y, "[", 0) ==Int 0)



    // Mul
    syntax KItem ::= "___asmmul" "(" String "," Id     ")"
                   | "___asmmul" "(" String "," Int    ")"
                   | "___asmmul" "(" String "," String ")"



    // 64-bit integer
    rule <k> (___asmmul(X:String, Y:String) => ___error("___asmmul: Left operand is memory reference")) ...</k>
         when (findChar(X, "[", 0) ==Int 0)
    rule <k> (___asmmul(X:String, Y:Int)    => ___error("___asmmul: Left operand is memory reference")) ...</k>
         when (findChar(X, "[", 0) ==Int 0)
    rule <k> (___asmmul(X:String, Y:Id)     => ___error("___asmmul: Left operand is memory reference")) ...</k>
         when (findChar(X, "[", 0) ==Int 0)


    rule <k> (___asmmul(X:String, Y:Id) => .) ...</k>
         <asmout>... (.List => ListItem("        imul " +String X +String ", " +String AccessStr +String "\n")) </asmout>
         <env>... (Y |-> ___varinfo(int, AccessStr:String, _)) ...</env>

    rule <k> (___asmmul(X:String, Y:Int) => .) ...</k>
         <asmout>... (.List => ListItem("        imul " +String X +String ", " +String Int2String(Y) +String "\n")) </asmout>

    rule <k> (___asmmul(X:String, Y:String) => .) ...</k>
         <asmout>... (.List => ListItem("        imul " +String X +String ", " +String Y +String "\n")) </asmout>



    // Div
    syntax KItem ::= "___asmdiv" "(" Id     ")"
                   | "___asmdiv" "(" String ")"



    // 64-bit integer
    rule <k> (___asmdiv(X:Id) => .) ...</k>
         <asmout>... (.List => ListItem("        idiv " +String AccessStr +String "\n")) </asmout>
         <env>... (Y |-> ___varinfo(int, AccessStr:String, _)) ...</env>

    rule <k> (___asmdiv(X:String) => .) ...</k>
         <asmout>... (.List => ListItem("        idiv " +String X +String "\n")) </asmout>



    // Xor
    syntax KItem ::= "___asmxor" "(" Id     "," Id      ")"
                   | "___asmxor" "(" Id     "," Int     ")"
                   | "___asmxor" "(" Id     "," String  ")"
                   | "___asmxor" "(" String "," Id      ")"
                   | "___asmxor" "(" String "," Int     ")"
                   | "___asmxor" "(" String "," String  ")"



    // 64-bit integer
    rule <k> (___asmxor(X:Id, Y:String) => ___asmxor(AccessStr, Y)) ...</k>
         <env>... (X |-> ___varinfo(int, AccessStr:String, _)) ...</env>
    rule <k> (___asmxor(X:Id, Y:Int)    => ___asmxor("qword " +String AccessStr, Int2String(Y))) ...</k>
         <env>... (X |-> ___varinfo(int, AccessStr:String, _)) ...</env>
    rule <k> (___asmxor(X:Id, Y:Id)     => ___asmxor("qword " +String AccessStr, Y)) ...</k>
         <env>... (X |-> ___varinfo(int, AccessStr:String, _)) ...</env>


    rule <k> (___asmxor(X:String, Y:Id) => .) ...</k>
         <asmout>... (.List => ListItem("        xor  " +String X +String ", " +String AccessStr +String "\n")) </asmout>
         <env>... (Y |-> ___varinfo(int, AccessStr:String, _)) ...</env>

    rule <k> (___asmxor(X:String, Y:Int) => .) ...</k>
         <asmout>... (.List => ListItem("        xor  " +String X +String ", " +String Int2String(Y) +String "\n")) </asmout>

    rule <k> (___asmxor(X:String, Y:String) => .) ...</k>
         <asmout>... (.List => ListItem("        xor  " +String X +String ", " +String Y +String "\n")) </asmout>
         when (findChar(X, "[", 0) =/=Int 0) orBool (findChar(Y, "[", 0) =/=Int 0)

    rule <k> (___asmxor(X:String, Y:String) => ___error("___asmxor: Both operands are memory references")) ...</k>
         when (findChar(X, "[", 0) ==Int 0) andBool (findChar(Y, "[", 0) ==Int 0)
endmodule
