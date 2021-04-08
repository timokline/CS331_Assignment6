# [Assignment6](https://www.cs.uaf.edu/users/chappell/public_html/class/2021_spr/cs331/docs/p-assn06d.html)
## Exercise A: Running a Prolog Program
Test to execute Prolog code (not included in repo).

## Exercise B: Interpreter in Lua
Write a Lua module that implements an interpreter for ASTs resulting from parsing the Caracal programming language. The interpreter will not directly use the Caracal parser written previously. Instead, the interpreter will be given the AST of a Caracal program. When the interpreter is combined with a parser for Caracal (`lexit.lua` & `parseit.lua`) and an application that glues them all together (`caracal.lua`), the result will be a complete interpreter than can take Caracal source code and execute it.

### Instructions
* Name your module `interpit`, and implement it in the file `interpit.lua`.
* The interface of module `interpit` consists of a single function `interp`.
  * Function `interp` takes the following four parameters.
  : `ast`. The AST of a Caracal program, as returned by parseit.parse.
  : `state`. A Lua table holding the initial state of the Caracal program: values of all variables: simple variables, array items, and functions. See *[State](#state)*, below.
  : `incall`. A Lua function that inputs (or acts like it inputs) a line of text from the user. This function takes no parameters. It returns the input line as a string with no trailing newline.
  : `outcall`. A Lua function that outputs (or acts like it outputs) a string. This function takes one parameter: the string to output. It returns nothing. You may assume that this function outputs the string in the manner of `io.write`: output goes to the standard output, and no newline is added.
  * Function `interp` returns the `state` parameter, modified as appropriate by the execution of the Caracal program. See *[State](#state)*, below.
  * Function `interp` should execute the given AST based on the semantics of the Caracal programming language. See *[Semantics](#semantics)*, below.
  * All I/O performed by function `interp` must be done via calls to the passed functions `incall` and `outcall`.
  * Function `interp` does not need to do any error checking. You may assume that the given AST is correctly formatted. Further, as explained in *[Semantics](#semantics)*, below, the semantics of Caracal includes no fatal runtime errors. Thus, a Caracal program never terminates abnormally; function `interp` does not need to do any error reporting.

### State
* __Caracal Variables__ : The Caracal programming language stores only integer values and functions. Integers can be stored in simple variables or in array items.

Arrays do not have specified dimensions; every integer is a legal index for every array. This includes negative integers.

* __The `state` Table__ : Values of all *defined* Caracal variables and functions are stored in a Lua table named `state`. This table has three members: `f`, a table that holds functions, `v`, a table that holds simple variables, and `a`, a table that holds arrays.

  * A Caracal function is stored as a key-value pair in the `state.f` table. The key is a string holding the name of the function. The associated value is a Lua table holding the AST of the function body, in the same form as the AST returned by `parseit.parse`.

  * A Caracal simple variable is stored as a key-value pair in the `state.v` table. The key is a string holding the name of the variable. The associated value is a number equal to the variable’s numeric value.

  * A Caracal array is stored as a key-value pair in the `state.a` table. The key is a string holding the name of the array. The associated value is a Lua table holding the array items. In this table, each defined item is stored as a key-value pair. The key is a number equal to the index of the item. The associated value is a number equal to the variable’s numeric value.

Below are examples of where values are stored.
| Kind of Variable | Example   | Where the Value is Stored |
|------------------|-----------|---------------------------|
| Function         | `xyz`     | `state.f["xyz"]`          |
| Simple Variable  | `xyz`     | `state.v["xyz"]`          |
|                  | `xyz[5]`  | `state.a["xyz"][5]`       |
| Array Item       | `xyz[0]`  | `state.a["xyz"][0]`       |
|                  | `xyz[-2]` | `state.a["xyz"][-2]`      |

* __Passing and Return__ : A `state` table is passed to function `interp`. This will always contain members `f`, `v`, and `a`. It may or may not include defined variables/functions. Variables that already have values in `state` should be treated exactly as if their values were set by previous *Assignment* statements.

The `state` table, as modified by the execution of the Caracal program, should be returned by function `interp`. All variables given in the initial table should still be defined in the returned state table; Caracal variables are never deleted. If a variable was set by the Caracal program, then its value in the returned table should be its final value in the program. Otherwise, it should be the same as it was initially.

* __Justification__ : The above may seem a bit mysterious. Why would variables be given values before the execution of a program? The reason for this is to allow a Caracal program to be entered interactively, as a series of statements, each of which is parsed and executed separately. Maintaining the state from one program to the next allows such statements to have the same effect as they would if they were parsed and executed as a single program.

* * *

### Semantics

The semantics of Caracal is specified here, using informal methods. A formal syntax of Caracal and the format of an AST were covered in [Assignment 4](https://www.cs.uaf.edu/~chappell/class/2021_spr/cs331/docs/p-assn04d.html#syntax).

* __General__ : Caracal is a very small programming language with simple imperative semantics. Statements are executed in order, first to last, as modified by the three flow-of-control structures: *If statement*, *For loop*, and *Function call*. The current statement must be executed completely, with all side effects completed, before execution of the next statement begins. When the last statement has executed, program execution terminates, with the current state being returned to the execution environment.

Caracal has no fatal runtime errors. Caracal programs never crash or terminate abnormally.

Caracal programs have two kinds of side effects: variable modification and I/O. Values of variables—including functions—may be specified by the execution environment when a Caracal program begins. Variable values are returned to the execution environment by the Caracal program for later use. I/O is described next.

* __I/O__ : A Caracal program may do text input and output.

A Caracal program does text input by reading a line of text from the standard input and interpreting this as an integer value. If the input does not represent an integer, then it is interpreted as zero. Input is done by an `readnum()` call in an expression.

A Caracal program does text output by printing a string, or integer value converted to a string, to the standard output. Output is done by a *Write statement*.

__!!__ *For information on how to perform text input and output, see [Implementation Notes](#implementation-notes), below.* __!!__

* __Variables__ : Caracal has three kinds of variables: functions, simple variables, and arrays. These are always named. Distinct identifiers never refer to the same variable. Identifiers for functions, identifiers for simple variables and identifiers for arrays lie in three separate namespaces.

A simple variable holds an integer value.

An array holds zero or more items, each indexed by an integer, that may have any integer value: positive, negative, or zero. Array dimensions are not specified; every integer index is usable with every array. Each array item holds an integer value. The legal values for a Caracal integer are implementation-defined.

__!!__ *For information on the legal values of a Caracal integer, see [Implementation Notes](#implementation-notes), below.* __!!__

A function holds the AST for its body.

All variables in Caracal are global. The scope of every identifier is the entire program, along with every program executed later, based on the state returned by the current program.

The value of a Caracal simple variable or array item may be set by an Assignment statement or passed in by the execution environment in the initial state.

A function variable may be set by a *Function definition*, or passed in by the execution environment in the initial state.

A variable is *defined* if it has ever been set, or if it had a value in the initial state specified by the execution environment. The value of a *defined* variable is its most recently set value.

The value of a variable that is not defined is its default value, as indicated below.
| Kind of Variable | Default Value   |
|------------------|-----------------|
| Simple Variable  | 0 (`zero`)      |
| Array Item       | 0 (`zero`)      |
| Function         | `{ STMT_LIST }` |

* __Expressions__ :  Caracal expressions are evaluated *eagerly*; that is, expressions are evaluated when they are encountered (as opposed to lazy evaluation).

The various parts of an expression may be evaluated in any order. The only parts of an expression that may have side effects are function calls and `readnum()` calls; other parts of an expression have no side effects. In particular, the fact that the value of a variable is used in an expression, does not cause the variable to become *defined*.

When a NumericLiteral is encountered in an expression, it is evaluated by converting its string form to a number.

__!!__ *For information on integer conversions, and the method for evaluating a NumericLiteral, see [Implementation Notes](#implementation-notes), below.* __!!__

When a variable is encountered in an expression, it is evaluated to its current value in the program state, or its default value (zero) if it is not *defined*.

A function call inside an expression executes the AST that is the value bound to the given function identifier, or the default AST if the function identifier is not *defined*: `{ STMT_LIST }`. The value of the expression is the value of the simple variable `return` after the AST has been executed—or its default value (zero) if this variable is not *defined*.

An `readnum()` call in an expression results in a line being read. The value of the `readnum()` call is the result of converting the string read to an integer.

__!!__ *For information on reading a line and converting a string to an integer, see [Implementation Notes](#implementation-notes), below.* __!!__

The result of evaluating an expression involving a Caracal operator is the same as for the Lua operator with the same name, followed by conversion to an integer, with the following exceptions.

  * Division by zero. If the second operand of a division (`/`) or modulus (`%`) operator is zero, then the operator should return zero.
  * Caracal has no separate Boolean type. Caracal comparison operators return `1` on true and `0` on false.
  * The Caracal `!=` operator corresponds to the Lua inequality operator (`~=`).
  * Caracal has a unary `+` operator, but Lua does not. The Caracal unary `+` operator simply returns its operand unchanged. So, for example, in Caracal, `+x` has the same value as `x`.
  * To evaluate an array item in an expression, first evaluate the expression between brackets; use the result as the index for an item in the array with the given name. The value is the value of this array item, or its default value (zero) if it is not *defined*.

* __Statements__ : Caracal has seven kinds of statements: *Write statement*, *Return statement*, *Function call*, *Assignment statement*, *Function definition*, *If statement*, and *For loop*. We discuss the semantics of each of these.

A *Write statement* outputs one or more strings to the standard output. For each *write argument*, one string is output.

  * If the *write argument* is a StringLiteral lexeme, then the string printed is the StringLiteral with its leading and trailing quote marks removed.
  * If the *write argument* is a `char` call, then a number is passed to `char`; call this number `n`. If `n` is not in the range 0 to 255, then set `n` to zero. The string printed is the string created by the following Lua code: “`string.char(n)`”.
  * If the argument of `write` is an expression, then the string printed is the string form of the number resulting from evaluating the expression.

__!!__ *For information on converting the numeric value of an expression to a string, see [Implementation Notes](#implementation-notes), below.* __!!__

When a *Return statement* is executed, the expression after the `return` is evaluated. The simple variable named `return` is set to this value. Note that this is the only way to set the value of this variable. Since “`return`” is a *reserved word, the value of this variable cannot be set in an Assignment statement*. __Executing a *Return statement* does not terminate a function; it only sets the value of a variable.__

A *Function call* executes the AST that is the value bound to the given function identifier, or the default AST if the function identifier is not defined: `{ STMT_LIST }`.

An *Assignment statement* evaluates the expression on the right-hand side of the assignment operator (`=`) and sets the Lvalue on the left-hand side to that value. If the Lvalue was not previously *defined*, then its status is defined after the *Assignment statement* is executed. If the Lvalue is an array item, then the expression representing its index must be evaluated before the Lvalue is set, in order to determine which item to set.

A *Function definition* binds the given function identifier to the AST for the given function body (statement list).

When an *If statement* is executed, the expression in parentheses after the `if`, along with any expressions after `elseif` that are part of the same statement, are evaluated, in order. If any of these expressions evaluates to a nonzero value, then no more such expressions are evaluated; the corresponding statement list is executed. If none of the expressions evaluates to a nonzero value, and there is an `else`, then its statement list is executed. If no expression evaluates to a nonzero value, and there is no `else`, then the *If statement* has no effect.

__!!__ *For information on determining whether the value of an expression is nonzero, see [Implementation Notes](#implementation-notes), below.* __!!__

A *For loop* has a “`for`” followed by three things in parentheses. Let us call these three the *initialization*, the *condition*, and the *increment*, respectively.

When a *For loop* is executed, the *initialization* is executed (or nothing is done if the *initialization* is omitted). Then the following actions are executed repetitively. The *condition* is evaluated (unless it is omitted). If this value is zero, then execution of the *For loop* terminates. If this vaue is nonzero, or if the *condition* is omitted, then the statement list is executed, followed by the *increment* (or nothing is done, if the *increment* it is omitted). The execution of the repetitive portion then begins again.

__!!__ *For information on determining whether the value of an expression is nonzero, see [Implementation Notes](#implementation), below.* __!!__

### Implementation Notes

All text input and output in a Caracal program should be done by calling the passed functions `incall` and `outcall`. The former inputs a line of text and returns it, without the newline. The latter outputs the given string; no newline is added.

The legal values for a Caracal simple variable or array item are all the integers that may be represented as a Lua number.

When executing an *If statement* or *For loop*, to determine whether a Caracal expression has a nonzero value, use a Lua expression of the form *VALUE* `~= 0`, where *VALUE* is the numeric value of the Caracal expression.

In the file `interpit.lua`, provided are five utility functions: `numToInt`, `strToNum`, `numToStr`, `boolToInt`, and `astToStr`. __Do not modify these functions!__ They should be used as follows:

* `numToInt`
  : When evaluating an expression involving one of the arithmetic operators (`+ - * / %`), the number returned by the Lua operator should be passed to this function; the return value of numToInt is the actual result of the Caracal computation. For example, the result of evaluating the Caracal expression `42/10` can be computing in Lua using `numToInt(strToNum("42")/strToNum("10"))`.
* `strToNum`
  : This should be used for all string → number conversions. In particular, it should be used when executing a `readnum()` call, to convert the entered string to a number. And it should be used when evaluating NumericLiteral lexemes.
* `numToStr`
  : This should be used for all number → string conversions. In particular, it should be used when executing a *Print statement* whose argument is an expression, to convert the result of evaluating the expression into a string to be output.
* `boolToInt`
  : This should be used for all Boolean → number conversions. In particular, it should be used when evaluating an expression involving one of the comparison or logical operators (`== != < <= > >= && || !`), to convert the Boolean returned by the Lua operator to the integer that Caracal requires.
* `astToStr`
  : This is provided for use in __debugging only__; it should never be called in the final version of your code. This function takes a Caracal AST. It returns a human-readable string form of the AST, suitable for printing.

### Provided Code

I have provided a partially written version of file `interpit.lua`. This includes the five utility functions mentioned above: `numToInt`, `strToNum`, `numToStr`, `boolToInt`, and `astToStr`. Please use these functions in your code, exactly as I have written them.

I have also written a Lua application that uses the `lexit`, `parseit`, and `interpit` modules, forming a complete Caracal source-code interpreter: `caracal.lua`. When `caracal.lua` is executed, it displays a prompt (“`>>>`”). At this prompt, type either Caracal code or a command beginning with “`:`” (these are listed when the program starts up). In particular, typing “`:r` *FILENAME*”, where *FILENAME* is the filename of a Caracal program (source file), will execute the program.

  * If the Caracal code forms the beginning of a correct program, but it is not a complete program, then another prompt is given (“`...`”), and more Caracal code may be entered.
  * If a syntax error is found in the entered code, then an error message is printed, and input restarts.
  * If a complete Caracal program has been entered, then it is executed. Any I/O it performs takes place on the console. When execution completes, input restarts, but the Caracal state is not reset; it is the state returned by the program that was executed.

If you have access to a Unix-like command line, then you may also pass the source filename to `caracal.lua` as a command-line parameter.

&nbsp;&nbsp;&nbsp;&nbsp;\[\*ix command line\]

&nbsp;&nbsp;&nbsp;&nbsp;`caracal.lua myprog.cara`

Because of the above, the shebang convention may be used with `caracal.lua`, if the system supports this convention. To make a Caracal source file into an executable program, set the file’s execute permission, and make the first line of the file something like the following.

&nbsp;&nbsp;&nbsp;&nbsp;`#!./caracal.lua`

The resulting file should be executed with `caracal.lua` in the same directory. Note that, since Caracal comments begin with the pound sign (`#`), the shebang line will be ignored when the Caracal source file is parsed. 
