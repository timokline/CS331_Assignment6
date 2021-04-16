-- FNAM: interpit.lua
-- DESC: Interpret AST from parseit.parse
--       Solution to Assignment 6, Exercise 2
-- AUTH: Timothy Albert Kline
--       Glenn G. Chappell
-- CRSE: CS F331 - Programming Languages
-- PROF: Glenn G. Chappell
-- STRT: 31 March 2021
-- UPDT: 07 April 2021
-- VERS: 1.0


-- *** To run a Caracal program, use caracal.lua, which uses this file.


-- *********************************************************************
-- Module Table Initialization
-- *********************************************************************


local interpit = {}  -- Our module


-- *********************************************************************
-- Symbolic Constants for AST
-- *********************************************************************


local STMT_LIST    = 1
local WRITE_STMT   = 2
local RETURN_STMT  = 3
local ASSN_STMT    = 4
local FUNC_CALL    = 5
local FUNC_DEF     = 6
local IF_STMT      = 7
local FOR_LOOP     = 8
local STRLIT_OUT   = 9
local CR_OUT       = 10
local DQ_OUT       = 11
local CHAR_CALL    = 12
local BIN_OP       = 13
local UN_OP        = 14
local NUMLIT_VAL   = 15
local BOOLLIT_VAL  = 16
local READNUM_CALL = 17
local SIMPLE_VAR   = 18
local ARRAY_VAR    = 19


-- *********************************************************************
-- Utility Functions
-- *********************************************************************


-- numToInt
-- Given a number, return the number rounded toward zero.
local function numToInt(n)
    assert(type(n) == "number")

    if n >= 0 then
        return math.floor(n)
    else
        return math.ceil(n)
    end
end


-- strToNum
-- Given a string, attempt to interpret it as an integer. If this
-- succeeds, return the integer. Otherwise, return 0.
local function strToNum(s)
    assert(type(s) == "string")

    -- Try to do string -> number conversion; make protected call
    -- (pcall), so we can handle errors.
    local success, value = pcall(function() return tonumber(s) end)

    -- Return integer value, or 0 on error.
    if success then
        if value == nil then
            return 0
        else
            return numToInt(value)
        end
    else
        return 0
    end
end


-- numToStr
-- Given a number, return its string form.
local function numToStr(n)
    assert(type(n) == "number")

    return tostring(n)
end


-- boolToInt
-- Given a boolean, return 1 if it is true, 0 if it is false.
local function boolToInt(b)
    assert(type(b) == "boolean")

    if b then
        return 1
    else
        return 0
    end
end


-- astToStr
-- Given an AST, produce a string holding the AST in (roughly) Lua form,
-- with numbers replaced by names of symbolic constants used in parseit.
-- A table is assumed to represent an array.
-- See the Assignment 4 description for the AST Specification.
--
-- THIS FUNCTION IS INTENDED FOR USE IN DEBUGGING ONLY!
-- IT SHOULD NOT BE CALLED IN THE FINAL VERSION OF THE CODE.
function astToStr(x)
    local symbolNames = {
        "STMT_LIST", "WRITE_STMT", "RETURN_STMT", "ASSN_STMT",
        "FUNC_CALL", "FUNC_DEF", "IF_STMT", "FOR_LOOP", "STRLIT_OUT",
        "CR_OUT", "DQ_OUT", "CHAR_CALL", "BIN_OP", "UN_OP",
        "NUMLIT_VAL", "BOOLLIT_VAL", "READNUM_CALL", "SIMPLE_VAR",
        "ARRAY_VAR"
    }
    if type(x) == "number" then
        local name = symbolNames[x]
        if name == nil then
            return "<Unknown numerical constant: "..x..">"
        else
            return name
        end
    elseif type(x) == "string" then
        return '"'..x..'"'
    elseif type(x) == "boolean" then
        if x then
            return "true"
        else
            return "false"
        end
    elseif type(x) == "table" then
        local first = true
        local result = "{"
        for k = 1, #x do
            if not first then
                result = result .. ","
            end
            result = result .. astToStr(x[k])
            first = false
        end
        result = result .. "}"
        return result
    elseif type(x) == "nil" then
        return "nil"
    else
        return "<"..type(x)..">"
    end
end


-- *********************************************************************
-- Primary Function for Client Code
-- *********************************************************************


-- interp
-- Interpreter, given AST returned by parseit.parse.
-- Parameters:
--   ast     - AST constructed by parseit.parse
--   state   - Table holding Caracal variables & functions
--             - AST for function xyz is in state.f["xyz"]
--             - Value of simple variable xyz is in state.v["xyz"]
--             - Value of array item xyz[42] is in state.a["xyz"][42]
--   incall  - Function to call for line input
--             - incall() inputs line, returns string with no newline
--   outcall - Function to call for string output
--             - outcall(str) outputs str with no added newline
--             - To print a newline, do outcall("\n")
-- Return Value:
--   state, updated with changed variable values
function interpit.interp(ast, state, incall, outcall)
    -- Each local interpretation function is given the AST for the
    -- portion of the code it is interpreting. The function-wide
    -- versions of state, incall, and outcall may be used. The
    -- function-wide version of state may be modified as appropriate.


    -- Forward declare local functions
    local interp_stmt_list
    local interp_stmt
    local eval_expr
    local get_lval
    local set_lval


    -- interp_stmt_list
    -- Given the ast for a statement list, execute it.
    function interp_stmt_list(ast)
        for i = 2, #ast do
            interp_stmt(ast[i])
        end
    end


    -- interp_stmt
    -- Given the ast for a statement, execute it.
    function interp_stmt(ast)
        if ast[1] == WRITE_STMT then
            for i = 2, #ast do
                if ast[i][1] == STRLIT_OUT then
                    local str = ast[i][2]
                    outcall(str:sub(2, str:len()-1))
                elseif ast[i][1] == CR_OUT then
                    outcall("\n")
                elseif ast[i][1] == DQ_OUT then -- DOUBLE QUOTE
                    outcall("\"")
                elseif ast[i][1] == CHAR_CALL then
                    local n = eval_expr(ast[i][2])
                    if n < 0 or n > 255 then
                        n = 0
                    end
                    outcall(string.char(n))
                else  -- Expression
                    local val = eval_expr(ast[i])
                    outcall(numToStr(val))
                end
            end
        elseif ast[1] == RETURN_STMT then
            outcall(astToStr(ast))
            state.v["return"] = eval_expr(ast[2])
        elseif ast[1] == FUNC_CALL then
            local funcname = ast[2]
            local funcbody = state.f[funcname]
            if funcbody == nil then
                funcbody = { STMT_LIST }
            end
            interp_stmt_list(funcbody)
        elseif ast[1] == ASSN_STMT then

        elseif ast[1] == FUNC_DEF then
            local funcname = ast[2]
            local funcbody = ast[3]
            state.f[funcname] = funcbody
        elseif ast[1] == IF_STMT then
            print ("IF_STATEMENT UNIMPLEMENTED")
        elseif ast[1] == FOR_LOOP then
    
            print ("FOR_LOOP UNIMPLEMENTED")
        end
    end

    local function equal(x,y) return x==y end
    local function lthan(x,y) return x<y end
    local function lethan(x,y) return x<=y end

    local bin_oper = {
        ["and"] =
            function (x,y)
                if x == 0 or y == 0 then
                    return 0
                else
                    return 1
                end
            end,
        ["or"] =
            function (x,y)
                if x == 0 and y == 0 then
                        return 0
                    else
                        return 1
                    end
                end,
        ["=="] = function (x,y)
                    return boolToInt(equal(x,y))
                 end,
        ["!="] = function (x,y) return boolToInt(not equal(x,y)) end,
        ["<"] = function (x,y) return boolToInt(lthan(x,y)) end,
        ["<="] = function (x,y) return boolToInt(lethan(x,y)) end,
        [">"] = function (x,y) return boolToInt(not lethan(x,y)) end,
        [">="] = function (x,y) return boolToInt(not lthan(x,y)) end,
        ["+"] = function (x,y) return x + y  end,
        ["-"] = function (x,y) return x - y end,
        ["*"] = function (x,y) return x * y end,
        ["/"] =
            function (x,y)
                if y == 0 then
                    return 0
                else
                    return x / y
                end
            end,
        ["%"] =
            function (x,y)
                if y == 0 then
                    return 0
                else
                    return x % y
                end
            end
    }

    local uni_oper = {
        ["-"] = function (x) return (-x) end;
        ["+"] = function (x) return x end;
        ["not"] = function (x) return equal(x,0) end;
    }

    local boolean = {
        ["true"] = 1,
        ["false"] = 0
    }

    -- eval_expr
    -- Given the AST for an expression, evaluate it and return the
    -- value.
    function eval_expr(ast)
        local result
        --outcall(astToStr(ast[1]))
        if ast[1] == NUMLIT_VAL then
            result = strToNum(ast[2])
        elseif ast[1] == BOOLLIT_VAL then
            result = boolean[ast[2]]
        -- Skully: https://stackoverflow.com/questions/65746996/using-a-variable-as-arithmetic-operator-in-lua
        elseif ast[1] == READNUM_CALL then
            local input = incall()
            result = strToNum(input)
        elseif ast[1] == SIMPLE_VAR then
            local varname = ast[2]
            local varval = state.v[varname]
            if varval == nil then
                varval = 0
            end
            result = varval
        elseif ast[1] == ARRAY_VAR then
            local arrname = ast[2]
            local index = eval_expr(ast[3])
            local arrval = state.a[arrname][index]
            if not arrval then
                arrval = 0
            end
            result = arrval
        elseif ast[1] == FUNC_CALL then
            interp_stmt_list(ast)
            local funcval = state.v["return"]
            if not funcval then
                funcval = 0
            end
            result = funcval
        elseif ast [1][1] == BIN_OP then
            local op = ast[1][2]
            local lterm = eval_expr(ast[2])
            local rterm = eval_expr(ast[3])
            result = numToInt(bin_oper[op](lterm, rterm))
        elseif ast [1][1] == UN_OP then
            local sign = ast[1][2]
            local factor = eval_expr(ast[2])
            result = uni_oper[sign](factor)
        end

        return result
    end

    -- get_lval
    -- Retrieves an previously defined Lvalue.
    function get_lval(ast)
        local val

        return val
    end

    -- set_lval
    -- Assigns an Lvalue to a value.
    function set_lval(ast)
        local var

        return var
    end

    -- Body of function interp
    interp_stmt_list(ast)
    return state
end


-- *********************************************************************
-- Module Table Return
-- *********************************************************************


return interpit

