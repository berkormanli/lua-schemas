--local json = require "json"

----------------------
luaschemasObject = {
    index = {},
    optional = function(self)
        self.__optional = true
        return self
    end
}

LSArray = {}
LSArray.index = {}
setmetatable(LSArray, {
    __call = function(instance, elements)
        local obj = setmetatable({
            __type = "array",
            __arrayType = type(elements[1]),
            __data = {},
            length = 0,
            push = function(instance, ...)
                local args = {...}
                for i, j in ipairs(args) do
                    table.insert(instance.__data, j)
                    instance.length = instance.length + 1
                end
            end,
            pop = function(instance)
                if instance.length == 0 then return false end
                local removed = table.remove(instance.__data)
                instance.length = instance.length - 1
                return removed
            end,
            shift = function(instance)
                local removed = table.remove(instance.__data, 1)
                instance.length = instance.length - 1
                local removed
            end,
            unshift = function(instance, value)
                table.insert(instance.__data, 1, value)
                instance.length = instance.length + 1
            end,
            includes = function(instance, value)
                for _, v in ipairs(instance.__data) do
                    if v == value then
                        return true
                    end
                end
                return false
            end,
            join = function(instance, separator)
                return table.concat(instance.__data, separator)
            end,
            fill = function(instance, newValue, startIndex, endIndex)
                if (startIndex and startIndex < 1) or (endIndex and endIndex > instance.length) then return false end
                if not startIndex then startIndex = 1 end
                if not endIndex then endIndex = instance.length end
                for i = startIndex, endIndex, 1 do
                    instance.__data[i] = newValue
                end
            end,
            map = function(instance, mapCB)
                local resultArray = LSArray()
                for i, v in ipairs(instance.__data) do
                    resultArray:push(mapCB(v, i, instance.__data))
                end
                return resultArray
            end,
            filter = function(instance, predicateCB)
                local resultArray = LSArray()
                for i, v in ipairs(instance.__data) do
                    if predicateCB(v, i, instance.__data) then
                        resultArray:push(v)
                    end
                end
                return resultArray
            end,
            find = function(predicateCB)
                for i, v in ipairs(instance.__data) do
                    if predicateCB(v, i, instance.__data) then
                        return v
                    end
                end
                return false
            end,
            every = function(predicateCB)
                for i, v in ipairs(instance.__data) do
                    if not predicateCB(v, i, instance.__data) then
                        return false
                    end
                end
                return true
            end,
            some = function(predicateCB)
                for i, v in ipairs(instance.__data) do
                    if predicateCB(v, i, instance.__data) then
                        return true
                    end
                end
                return false
            end,
            findIndex = function(predicateCB)
                for i, v in ipairs(instance.__data) do
                    if predicateCB(v, i, instance.__data) then
                        return i
                    end
                end
                return false
            end,
            findLast = function(predicateCB)
                for i, v in ipairs(instance.__data) do
                    if predicateCB(v, i, instance.__data) then
                        return v
                    end
                end
                return false
            end,
            findLastIndex = function(predicateCB)
                for i = #instance.__data, 1, -1 do
                    if predicateCB(v, i, instance.__data) then
                        return i
                    end
                end
                return false
            end,
            reduce = function(accumulator, initialValue)
                local result = initialValue
                for _, value in ipairs(instance.__data) do
                    result = accumulator(result, value)
                end
                return result
            end
        }, {
            __len = function(instance)
                return instance.length
            end,
            __index = luaschemasObject
        })
        -- @desc It inserts all elements if it's a predefined Array.
        if elements then
            for i, j in ipairs(elements) do
                table.insert(obj.__data, j)
                obj.length = obj.length + 1
            end
        end
        return obj
    end,
    __index = LSArray.index
})
----------------------
l = {}

local _type = type

---@param arg any
---@return LType
-- Primitive types are: nil, boolean, number, string, userdata, function, thread, and table
type = function(arg)
    if _type(arg) ~= "table" then
        return _type(arg)
    else
        return arg.__type and arg.__type or "table"
    end
end

local _error = error
---@param errMsg string
error = function(errMsg)
    local currentLineErr = debug.getinfo(3)
    local infosFunc = debug.getinfo(2)

    print(string.format('An error occured around %d while using function %q (defined at %s)\nWarning: %s',
        currentLineErr.currentline,
        infosFunc.name,
        infosFunc.short_src.."@"..infosFunc.linedefined,
        errMsg
    ))
end

---@class l.string
---@field private __type string
---@field _min table
---@field _max table
---@field _length table
---@field _email table
---@field min function
---@field max function
---@field length function
---@field email function
---@field parse function
---@field wrongTypeError string
l.string = {}
l.string.index = {}
setmetatable(l.string, {
    ---LString constuctor
    ---@param instance any
    ---@param errMsgs table<LError, string>
    ---@return l.string
    __call = function(instance, errMsgs)
        local obj = setmetatable({
            __type = "string",
            ---Set string minimum length.
            ---@param self l.string
            ---@param minLength number
            ---@param errMsg LError
            ---@return l.string
            min = function(self, minLength, errMsg)
                if type(minLength) == "number" and not self._min then
                    self._min = {
                        minLength = minLength,
                        message = errMsg and errMsg or "Must be "..minLength.." or more characters long"
                    }
                end
                return self
            end,
            ---Set string maximum length.
            ---@param self l.string
            ---@param maxLength number
            ---@param errMsg LError
            ---@return l.string
            max = function(self, maxLength, errMsg)
                if type(maxLength) == "number" and not self._max then
                    self._max = {
                        maxLength = maxLength,
                        message = errMsg or "Must be "..maxLength.." or less characters long"
                    }
                end
                return self
            end,
            ---Set string exact length.
            ---@param self l.string
            ---@param exactLength number
            ---@param errMsg LError
            ---@return l.string
            length = function(self, exactLength, errMsg)
                if type(exactLength) == "number" and not self._length then
                    self._length = {
                        exactLength = exactLength,
                        message = errMsg or "Must be exactly "..exactLength.." characters long"
                    }
                end
                return self
            end,
            ---Set string as email.
            ---@param self l.string
            ---@param errMsg LError
            ---@return l.string
            email = function(self, errMsg)
                if not self._email then
                    self._email = {
                        emailPattern = '^[%w_-%.]+[@]([%w-]+%.)([%w-][%w-]+)$',
                        message = errMsg or "This string should be in an e-mail format"
                    }
                end
                return self
            end,
            ---Parse the argument to check if it suits the string schema.
            ---@param self l.string
            ---@param argToBeTested any
            ---@return boolean success
            ---@return LString | LError returnVal
            parse = function(self, argToBeTested)
                if type(argToBeTested) ~= "string" then
                    if self.wrongTypeError then
                        error(self.wrongTypeError)
                        return false, self.wrongTypeError
                    else
                        error("Variable is not a string")
                        return false, 'Variable is not a string'
                    end
                end
                if self._min and string.len(argToBeTested) < self._min.minLength then
                    if self._min.message then
                        error(self._min.message)
                        return false, self._min.message
                    else
                        error("Variable is not long enough")
                        return false, 'Variable is not long enough'
                    end
                end
                if self._max and string.len(argToBeTested) > self._max.maxLength then
                    if self._max.message then
                        error(self._max.message)
                        return false, self._max.message
                    else
                        error("Variable is not short enough")
                        return false, 'Variable is not short enough'
                    end
                end
                if self._length and string.len(argToBeTested) ~= self._length.exactLength then
                    if self._length.message then
                        error(self._length.message)
                        return false, self._length.message
                    else
                        error("Variable is not exactly long as defined")
                        return false, 'Variable is not exactly long as defined'
                    end
                end
                return true, {
                    __type = 'string',
                    __value = argToBeTested
                }
            end
        },{
            __index = luaschemasObject,
            __pairs = instance.__ipairs
        })
        if errMsgs then
            for errorType, errorMessage in pairs(errMsgs) do
                obj[errorType] = errorMessage
            end
        end
        return obj
    end
})

local stringSchema = l.string({
    wrongTypeError = "string değil aq"
})
local stringSchemaMin = l.string():min(3)
local stringSchemaMax = l.string():max(10)
local stringSchemaBoth = l.string():min(3):max(10)
local stringSchemaExact = l.string():length(11):optional()
local testString = "12345678901"
local testNumber = 2

--stringSchemaExact:parse(testString)
stringSchemaMin:parse(testString)
--stringSchema:parse(testNumber)

---@class l.number
---@field private __type string
---@field _min table
---@field _minNE table
---@field _max table
---@field _maxNE table
---@field _integer LError
---@field _positive LError
---@field _nonnegative LError
---@field _negative LError
---@field _nonpositive LError
---@field _multipleOf table
---@field _finite LError
---@field min function
---@field gt function
---@field gte function
---@field max function
---@field lt function
---@field lte function
---@field int function
---@field positive function
---@field nonnegative function
---@field negative function
---@field nonpositive function
---@field multipleOf function
---@field finite function
---@field parse function
---@field wrongTypeError string
l.number = {}
l.number.index = {}
setmetatable(l.number, {
    __call = function(instance, errMsgs)
        local minFunc = function(obj, minValue, errMsg)
            if type(minValue) == "number" and not obj._min then
                obj._min = {
                    minValue = minValue,
                    message = errMsg and errMsg or "Must be greater than or equal to "..minValue
                }
            end
            return obj
        end
        local maxFunc = function(obj, maxValue, errMsg)
            if type(maxValue) == "number" and not obj._max then
                obj._max = {
                    maxValue = maxValue,
                    message = errMsg and errMsg or "Must be less than or equal to "..maxValue
                }
            end
            return obj
        end
        local obj = setmetatable({
            __type = "number",
            min = minFunc,
            gte = minFunc,
            gt = function(self, minValue, errMsg)
                if type(minValue) == "number" and not self._minNE then
                    self._minNE = {
                        minValue = minValue,
                        message = errMsg and errMsg or "Must be greater than "..minValue
                    }
                end
                return self
            end,
            max = maxFunc,
            lte = maxFunc,
            lt = function(self, maxValue, errMsg)
                if type(maxValue) == "number" and not self._maxNE then
                    self._maxNE = {
                        maxValue = maxValue,
                        message = errMsg and errMsg or "Must be less than "..maxValue
                    }
                end
                return self
            end,

            int = function(self, errMsg)
                self._integer = errMsg and errMsg or "Must be an integer"
                return self
            end,

            positive = function(self, errMsg)
                if not self._negative and not self._nonpositive then
                    self._positive = errMsg and errMsg or "Must be greater than 0"
                end
                return self
            end,
            nonnegative = function(self, errMsg)
                if not self._negative and not self._nonpositive and not self._positive then
                    self._nonnegative = errMsg and errMsg or "Must be greater than or equal to 0"
                end
                return self
            end,
            negative = function(self, errMsg)
                if not self._positive and not self._nonnegative then
                    self._negative = errMsg and errMsg or "Must be less than 0"
                end
                return self
            end,
            nonpositive = function(self, errMsg)
                if not self._positive and not self._nonnegative and not self._negative then
                    self._nonpositive = errMsg and errMsg or "Must be less than or equal to 0"
                end
                return self
            end,

            multipleOf = function(self, modulus, errMsg)
                self._multipleOf = {
                    multipleOf = modulus,
                    message = errMsg and errMsg or "Must be a multiple of "..modulus
                }
                return self
            end,

            finite = function(self, errMsg)
                self._finite = errMsg and errMsg or "Must be between math.huge and -math.huge"
                return self
            end,

            ---comment
            ---@param self l.number
            ---@param argToBeTested any
            ---@return boolean success
            ---@return LInteger | LNumber | LError
            parse = function(self, argToBeTested)
                if type(argToBeTested) ~= "number" then
                    if self.wrongTypeError then
                        error(self.wrongTypeError)
                        return false, self.wrongTypeError
                    else
                        error("Variable is not a number")
                        return false, 'Variable is not a number'
                    end
                end
                if self._min and argToBeTested < self._min.minValue then
                    if self._min.message then
                        error(self._min.message)
                        return false, self._min.message
                    else
                        error("Variable is not greater than or equal to "..self._min.minValue)
                        return false, 'Variable is not greater than or equal to '..self._min.minValue
                    end
                end
                if self._minNE and argToBeTested <= self._minNE.minValue then
                    if self._minNE.message then
                        error(self._minNE.message)
                        return false, self._minNE.message
                    else
                        error("Variable is not greater than "..self._minNE.minValue)
                        return false, 'Variable is not greater than '..self._minNE.message
                    end
                end
                if self._max and argToBeTested < self._max.maxValue then
                    if self._max.message then
                        error(self._max.message)
                        return false, self._max.message
                    else
                        error("Variable is not lower than or equal to "..self._max.maxValue)
                        return false, 'Variable is not lower than or equal to '..self._max.maxValue
                    end
                end
                if self._maxNE and argToBeTested <= self._maxNE.maxValue then
                    if self._maxNE.message then
                        error(self._maxNE.message)
                        return false, self._maxNE.message
                    else
                        error("Variable is not lower than "..self._maxNE.maxValue)
                        return false, 'Variable is not lower than '..self._maxNE.message
                    end
                end
                if self._integer and tostring(argToBeTested):find('.') then
                    error(self._integer)
                    return false, self._integer
                end
                if self._finite and not (argToBeTested < math.huge and argToBeTested > -math.huge) then
                    error(self._finite)
                    return false, self._finite
                end

                return true, {
                    __type = self._integer and 'integer' or 'number',
                    __value = argToBeTested
                }
            end
        },{
            __index = luaschemasObject,
            --__pairs = instance.__ipairs
        })
        if errMsgs then
            for errorType, errorMessage in pairs(errMsgs) do
                obj[errorType] = errorMessage
            end
        end
        return obj
    end
})

local numberSchemaMin = l.number():min(3)
local numberSchemaGte = l.number():gte(3)
local numberSchemaGt = l.number():finite()

--numberSchemaMin:parse(3)
--numberSchemaGte:parse(2)
--numberSchemaGt:parse(math.huge)

l.Object = {}
l.Object.index = {}
setmetatable(l.Object, {
    __call = function(instance, fields, errMsgs)
        instance.__type = "object"
        instance.__fields = fields
        local obj = {
            shape = function(self, key)
                return type(self.fields[key])
            end,
            extend = function(self, additionalFields)
                -- implement a deep copy function for l.Object
                local tmpCopy = deepCopy(self)
                for key, value in pairs(additionalFields) do
                    tmpCopy.fields[key] = value
                end
                return tmpCopy
            end,
            merge = function(self, object)
                -- implement a deep copy function for l.Object
                local tmpCopy = deepCopy(self)
                for key, value in pairs(object.__fields) do
                    tmpCopy.fields[key] = value
                end
                return tmpCopy
            end,
            pick = function(self, keys)
                local tmpCopy = {}
                if type(keys[1]) == 'boolean' then
                    for key, value in pairs(keys) do
                        tmpCopy[key] = self[key] or nil
                    end
                    return tmpCopy
                else
                    for _, value in ipairs(keys) do
                        tmpCopy[value] = self[value] or nil
                    end
                    return tmpCopy
                end
            end,
            omit = function(self, keys)
                -- implement a deep copy function for l.Object
                local tmpCopy = deepCopy(self)
                if type(keys[1]) == 'boolean' then
                    for key, value in pairs(keys) do
                        tmpCopy[key] = nil
                    end
                    return tmpCopy
                else
                    for _, value in ipairs(keys) do
                        tmpCopy[value] = nil
                    end
                    return tmpCopy
                end
            end,
            --- This method will make the parser to NOT strip the unknown keys.
            passthrough = function(self)
                if self.__strict then return self
                else
                    self.__passthrough = true
                    return self
                end
            end,

            --- This method will make parser to throw an LError if there is an unknown key.
            strict = function(self)
                if self.__passthrough then return self
                else
                    self.__strict = true
                    return self
                end
            end,

            --- This method will make parser validate all unknown keys according to the schema provided.
            catchall = function(self, schema)
                self.__catchallSchema = schema
                return self
            end,

            parse = function(self)
            end
        }
        return obj
    end
})

l.Array = {}
l.Array.index = {}
setmetatable(l.Array, {
    __call = function(instance, arrayType)
        local obj = {
            __type = "array",
            __fieldType = type(arrayType),
            element = type(arrayType),
            nonempty = function(self, errMsg)
                if type(errMsg) == 'table' then
                    self._nonempty = {
                        message = errMsg.message
                    }
                elseif type(errMsg) == 'string' then
                    self._nonempty = errMsg
                else
                    self._nonempty = true
                end
                return self
            end,
            min = function(self, minLength, errMsg)
                if type(minLength) == "number" and not self._min then
                    self._min = {
                        minLength = minLength,
                        message = errMsg or "Must contain "..minLength.." or more items"
                    }
                end
                return self
            end,
            max = function(self, maxLength, errMsg)
                if type(maxLength) == "number" and not self._max then
                    self._max = {
                        maxLength = maxLength,
                        message = errMsg or "Must contain "..maxLength.." or less items"
                    }
                end
                return self
            end,
            length = function(self, exactLength, errMsg)
                if type(exactLength) == "number" and not self._exactLength then
                    self._exactLength = {
                        exactLength = exactLength,
                        message = errMsg or "Must contain exactly "..exactLength.." items"
                    }
                end
                return self
            end,
            parse = function(self, argToBeTested, errMsgs)
                local count = 0
                local isHashMap = false
                for _idx, _value in pairs(argToBeTested) do
                    if type(_idx) == 'string' then
                        isHashMap = true
                        return
                    end
                    count = count + 1
                end
                if isHashMap then
                    if self._errMsgs then
                        error(self._errMsgs.hashMapError)
                    else
                        error("Arg should be an array but fed Hash Map")
                    end
                end
                if count == 0 and self._nonempty then
                    if type(self._nonempty) == 'table' then
                        error(self._nonempty.message)
                    elseif type(self._nonempty) == 'string' then
                        error(self._nonempty)
                    else
                        error("Array should not be empty")
                    end
                end
                if self._min and count < self._min.minLength then
                    if self._min.message then
                        error(self._min.message)
                    else
                        error("Variable is not long enough")
                    end
                end
                if self._max and count > self._max.maxLength then
                    if self._max.message then
                        error(self._max.message)
                    else
                        error("Variable is not short enough")
                    end
                end
                if self._exactLength and count ~= self._exactLength.exactLength then
                    if self._exactLength.message then
                        error(self._exactLength.message)
                    else
                        error("Variable is not exactly long as defined")
                    end
                end
            end
        }
        return obj
    end
})

--[[local minThreeArray = l.Array(l.string()):min(3)
local nonEmptyArray = l.Array(l.string()):nonempty()
minThreeArray:parse({"a", "b", "c", "d"})
minThreeArray:parse({"a", "b", "c"})
print(nonEmptyArray.element)]]

---@class l.boolean
---@field __type string
---@field parse function
---@field wrongTypeError string
l.boolean = {}
l.boolean.index = {}
setmetatable(l.boolean, {
    __call = function (instance, errMsgs)
        local obj = {
            __type = 'boolean',
            ---comment
            ---@param self l.boolean
            ---@param argToBeTested any
            ---@return boolean success
            ---@return LBoolean | LError returnVal
            parse = function(self, argToBeTested)
                if type(argToBeTested) ~= 'boolean' then
                    if self.wrongTypeError then
                        error(self.wrongTypeError)
                        return false, self.wrongTypeError
                    else
                        error("Variable is not a boolean")
                        return false, 'Variable is not a boolean'
                    end
                end
                return true, {
                    __type = 'boolean',
                    __value = argToBeTested
                }
            end
        }
        if errMsgs then
            for errorType, errorMessage in pairs(errMsgs) do
                obj[errorType] = errorMessage
            end
        end
        return obj
    end
})