--local json = require "json"

l = {}

local _type = type
-- Primitive types are: nil, boolean, number, string, userdata, function, thread, and table
l.type = function(arg)
    if _type(arg) ~= "table" then
        return _type(arg)
    else
        return arg.__type and arg.__type or "table"
    end
end

local _error = error
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

l.string = {}
l.string.index = {}
setmetatable(l.string, {
    __call = function(instance, errMsgs)
        instance.__type = "string"
        local obj = {
            min = function(self, minLength, errMsg)
                if type(minLength) == "number" and not self._min then
                    self._min = {
                        minLength = minLength,
                        message = errMsg or "Must be "..minLength.." or more characters long"
                    }
                end
                return self
            end,
            max = function(self, maxLength, errMsg)
                if type(maxLength) == "number" and not self._max then
                    self._max = {
                        maxLength = maxLength,
                        message = errMsg or "Must be "..maxLength.." or less characters long"
                    }
                end
                return self
            end,
            length = function(self, exactLength, errMsg)
                if type(exactLength) == "number" and not self._length then
                    self._length = {
                        exactLength = exactLength,
                        message = errMsg or "Must be exactly "..exactLength.." characters long"
                    }
                end
                return self
            end,
            email = function(self, errMsg)
                if not self._email then
                    self._email = {
                        emailPattern = '^[%w_-%.]+[@]([%w-]+%.)([%w-][%w-]+)$',
                        message = errMsg or "This string should be in an e-mail format"
                    }
                end
                return self
            end,
            parse = function(self, argToBeTested)
                if type(argToBeTested) ~= "string" then
                    if self.wrongTypeError then
                        error(self.wrongTypeError)
                    else
                        error("Variable is not a string")
                    end
                end
                if self._min and string.len(argToBeTested) < self._min.minLength then
                    if self._min.message then
                        error(self._min.message)
                    else
                        error("Variable is not long enough")
                    end
                end
                if self._max and string.len(argToBeTested) > self._max.maxLength then
                    if self._max.message then
                        error(self._max.message)
                    else
                        error("Variable is not short enough")
                    end
                end
                if self._length and string.len(argToBeTested) ~= self._length.exactLength then
                    if self._length.message then
                        error(self._length.message)
                    else
                        error("Variable is not exactly long as defined")
                    end
                end
                print("you did it mk")
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

local stringSchema = l.string({
    wrongTypeError = "string değil aq"
})
local stringSchemaMin = l.string():min(3)
local stringSchemaMax = l.string():max(10)
local stringSchemaBoth = l.string():min(3):max(10)
local stringSchemaExact = l.string():length(11)

local testString = "12345678901"
local testNumber = 2

--stringSchemaExact:parse(testString)
--stringSchema:parse(testNumber)

l.number = {}
l.number.index = {}
setmetatable(l.number, {
    __call = function(instance, errMsgs)
        instance.__type = "number"
        local minFunc = function(obj, minValue, errMsg)
            if type(minValue) == "number" and not obj._min then
                obj._min = {
                    minValue = minValue,
                    message = errMsg or "Must be greater than or equal to "..minValue
                }
            end
            return obj
        end
        local maxFunc = function(obj, maxValue, errMsg)
            if type(maxValue) == "number" and not obj._max then
                obj._max = {
                    maxValue = maxValue,
                    message = errMsg or "Must be less than or equal to "..maxValue
                }
            end
            return obj
        end
        local obj = {
            min = minFunc,
            gte = minFunc,
            gt = function(self, minValue, errMsg)
                if type(minValue) == "number" and not self._minNE then
                    self._minNE = {
                        minValue = minValue,
                        message = errMsg or "Must be greater than "..minValue
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
                        message = errMsg or "Must be less than "..maxValue
                    }
                end
                return self
            end,

            int = function(self, errMsg)
                self._integer = errMsg or "Must be an integer"
                return self
            end,

            positive = function(self, errMsg)
                if not self._negative and not self._nonpositive then
                    self._positive = errMsg or "Must be greater than 0"
                end
                return self
            end,
            nonnegative = function(self, errMsg)
                if not self._negative and not self._nonpositive and not self._positive then
                    self._nonnegative = errMsg or "Must be greater than or equal to 0"
                end
                return self
            end,
            negative = function(self, errMsg)
                if not self._positive and not self._nonnegative then
                    self._negative = errMsg or "Must be less than 0"
                end
                return self
            end,
            nonpositive = function(self, errMsg)
                if not self._positive and not self._nonnegative and not self._negative then
                    self._nonpositive = errMsg or "Must be less than or equal to 0"
                end
                return self
            end,

            multipleOf = function(self, modulus, errMsg)
                self._multipleOf = errMsg or "Must be a multiple of "..modulus
                return self
            end,

            finite = function(self, errMsg)
                self._finite = errMsg or "Must be between math.huge and -math.huge"
                return self
            end,

            parse = function(self, argToBeTested)
                if type(argToBeTested) ~= "number" then
                    if self.wrongTypeError then
                        error(self.wrongTypeError)
                    else
                        error("Variable is not a number")
                    end
                end
                if self._min and argToBeTested < self._min.minValue then
                    if self._min.message then
                        error(self._min.message)
                    else
                        error("Variable is not greater than or equal to "..self._min.minValue)
                    end
                end
                if self._minNE and argToBeTested <= self._minNE.minValue then
                    if self._minNE.message then
                        error(self._minNE.message)
                    else
                        error("Variable is not greater than or equal to "..self._minNE.minValue)
                    end
                end


                if self._finite and not (argToBeTested < math.huge and argToBeTested > -math.huge) then
                    error(self._finite)
                end
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

local numberSchemaMin = l.number():min(3)
local numberSchemaGte = l.number():gte(3)
local numberSchemaGt = l.number():finite()

--numberSchemaMin:parse(3)
--numberSchemaGte:parse(2)
numberSchemaGt:parse(math.huge)

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
