local value = require("path.other")
print(value)

local number = 0

--[[ (DEBUG)
print(number)
--]]

--[====[ (not DEBUG)
print("running in normal mode")
--]====]

for i=1,10 do
    number = number + i
    --[[ (DEBUG) 
    print(number)
    ]]
end

--[[ (TEST)
assert(number == 55)
print("number passed assertion")
--]]