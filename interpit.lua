-- FNAM: interpit.lua
-- DESC: Interpret AST from parseit.parse
--       Solution to Assignment 6, Exercise 2
-- AUTH: Timothy Albert Kline
--       Glenn G. Chappell
-- CRSE: CS F331 - Programming Languages
-- PROF: Glenn G. Chappell
-- STRT: 31 March 2021
-- UPDT: 24 April 2021
-- VERS: 1.0

-- *** To run a Caracal program, use caracal.lua, which uses this file.

-- *********************************************************************
-- Module Table Initialization
-- *********************************************************************

local interpit = {} -- Our module

-- *********************************************************************
-- Symbolic Constants for AST
-- *********************************************************************

local STMT_LIST = 1
local WRITE_STMT = 2
local RETURN_STMT = 3
local ASSN_STMT = 4
local FUNC_CALL = 5
local FUNC_DEF = 6
local IF_STMT = 7
local FOR_LOOP = 8
local STRLIT_OUT = 9
local CR_OUT = 10
local DQ_OUT = 11
local CHAR_CALL = 12
local BIN_OP = 13
local UN_OP = 14
local NUMLIT_VAL = 15
local BOOLLIT_VAL = 16
local READNUM_CALL = 17
local SIMPLE_VAR = 18
local ARRAY_VAR = 19

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
    local success, value =
        pcall(
        function()
            return tonumber(s)
        end
    )

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
                    outcall(str:sub(2, str:len() - 1))
                elseif ast[i][1] == CR_OUT then
                    outcall("\n")
                elseif ast[i][1] == DQ_OUT then -- DOUBLE QUOTE
                    outcall('"')
                elseif ast[i][1] == CHAR_CALL then
                    local n = eval_expr(ast[i][2])
                    if n < 0 or n > 255 then
                        n = 0
                    end
                    outcall(string.char(n))
                else -- Expression
                    local val = eval_expr(ast[i])
                    outcall(numToStr(val))
                end
            end
        elseif ast[1] == RETURN_STMT then
            local val = eval_expr(ast[2])
            state.v["return"] = val
        elseif ast[1] == FUNC_CALL then
            local func_name = ast[2]
            local func_body = state.f[func_name]
            if not func_body then
                func_body = {STMT_LIST}
            end
            interp_stmt_list(func_body)
        elseif ast[1] == ASSN_STMT then
            local rhs = eval_expr(ast[3])
            local name = ast[2][2]
            local lhs
            if ast[2][1] == SIMPLE_VAR then
                lhs = state.v[name]
                if not lhs then 
                    set_lval(ast[2])
                end
                state.v[name] = rhs
            elseif ast[2][1] == ARRAY_VAR then
                local index = eval_expr(ast[2][3])
                lhs = state.a[name]
                if not lhs then
                    set_lval(ast[2])
                end
                state.a[name][index] = rhs
            end
        elseif ast[1] == FUNC_DEF then
            local func_name = ast[2]
            local func_body = ast[3]
            state.f[func_name] = func_body
        elseif ast[1] == IF_STMT then
            local value
            value = eval_expr(ast[2])
            if value ~= 0 then
                interp_stmt_list(ast[3])
                return
            end

            for i = 4, #ast, 2 do
                if ast[i][1] == STMT_LIST then
                    interp_stmt_list(ast[i])
                    return
                end
                value = eval_expr(ast[i])
                if value ~= 0 then
                    interp_stmt_list(ast[i+1])
                    return
                end
            end
        elseif ast[1] == FOR_LOOP then
            local init = ast[2]
            local cond = ast[3]
            local incr = ast[4]
            local body = ast[5]
            local value

            if init ~= {} then
                interp_stmt(init)
            end

            if cond ~= {} then
                value = eval_expr(cond)
            end

            while value ~= 0 or value == {} do
                if incr == {} then
                    break
                end
                interp_stmt_list(body)
                interp_stmt(incr)
                value = eval_expr(cond)
            end
        end
    end

    -- set_lval
    -- Defines an undefined lval
    function set_lval(ast)
        local id = ast[2]
        if ast[1] == SIMPLE_VAR then
            state.v[id] = 0
        elseif ast[1] == ARRAY_VAR then
            state.a[id] = {}
        end
    end

    -- is_equal
    -- Helper function for evaluating whether
    -- lhs == rhs
    local function is_equal(x, y)
        return x == y
    end

    -- is_less_than
    -- Helper function for evaluating whether
    -- lhs < rhs
    local function is_less_than(x, y)
        return x < y
    end

    -- is_lt_or_eql_to
    -- Helper function for evaluating whether
    -- lhs <= rhs
    local function is_lt_or_eql_to(x, y)
        return x <= y
    end

    -- bin_opers
    -- Key-pair list of keyword binary operators
    -- Evaluates a binary expression given the
    -- string version of the operator and
    -- the lh/rhs of the expression
    local bin_opers = {
        ["and"] = function(x, y)
                if x == 0 or y == 0 then
                    return 0
                else
                    return 1
                end
            end,
        ["or"] = function(x, y)
                if x == 0 and y == 0 then
                        return 0
                    else
                        return 1
                    end
                end,
        ["=="] = function(x, y)
            return boolToInt(is_equal(x, y))
        end,
        ["!="] = function(x, y)
            return boolToInt(not is_equal(x, y))
        end,
        ["<"] = function(x, y)
            return boolToInt(is_less_than(x, y))
        end,
        ["<="] = function(x, y)
            return boolToInt(is_lt_or_eql_to(x, y))
        end,
        [">"] = function(x, y)
            return boolToInt(not is_lt_or_eql_to(x, y))
        end,
        [">="] = function(x, y)
            return boolToInt(not is_less_than(x, y))
        end,
        ["+"] = function(x, y)
            return x + y
        end,
        ["-"] = function(x, y)
            return x - y
        end,
        ["*"] = function(x, y)
            return x * y
                 end,
        ["/"] = function(x, y)
                if y == 0 then
                    return y
                else
                    return x / y
                end
            end,
        ["%"] = function(x, y)
                if y == 0 then
                    return y
                else
                    return x % y
                end
            end
    }

    -- uni_opers
    -- Key-pair list of keyword unary operators
    -- Evaluates a unary expression given the
    -- string version of the operator and
    -- the literal
    local un_opers = {
        ["-"] = function(x)
            return (-x)
        end,
        ["+"] = function(x)
            return x
        end,
        ["not"] = function(x)
            return bin_opers["=="](x, 0)
        end
    }

    -- boolean
    -- Converts the string literal of a boolean
    -- to its binary equivalent
    local boolean = {
        ["true"] = 1,
        ["false"] = 0
    }

    -- eval_expr
    -- Given the AST for an expression, evaluate it and return the
    -- value.
    function eval_expr(ast)
        local result
        if ast[1] == NUMLIT_VAL then
            result = strToNum(ast[2])
        elseif ast[1] == BOOLLIT_VAL then
        -- Skully: https://stackoverflow.com/questions/65746996/using-a-variable-as-arithmetic-operator-in-lua
            result = boolean[ast[2]]
        elseif ast[1] == READNUM_CALL then
            local input = incall()
            result = strToNum(input)
        elseif ast[1] == SIMPLE_VAR
                or ast[1] == ARRAY_VAR
                or ast[1] == FUNC_CALL then
            result = get_lval(ast)
        -- Interpreter will crash here if none of the above are caught
        elseif ast[1][1] == BIN_OP then
            local op = ast[1][2]
            local l_term = eval_expr(ast[2])
            local r_term = eval_expr(ast[3])
            result = numToInt(bin_opers[op](l_term, r_term))
        elseif ast[1][1] == UN_OP then
            local sign = ast[1][2]
            local factor = eval_expr(ast[2])
            result = un_opers[sign](factor)
        end
        return result
    end

    -- get_lval
    -- Retrieves the Lvalue of an expression.
    -- Returns 0 if nil
    function get_lval(ast)
        local val
        local name = ast[2]
        if ast[1] == SIMPLE_VAR then
            val = state.v[name]
        elseif ast[1] == ARRAY_VAR then
            local index = eval_expr(ast[3])
            if not state.a[name] then
                return 0
            end
            val = state.a[name][index]
        elseif ast[1] == FUNC_CALL then
            interp_stmt(ast)
            val = state.v["return"]
        end

        if not val then
            return 0
        end

        return val
    end


    -- Body of function interp
    interp_stmt_list(ast)
    return state
end

-- *********************************************************************
-- Module Table Return
-- *********************************************************************

return interpit
