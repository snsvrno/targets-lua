# Targets!

A simple example of a preprocessing transpiler that uses lua compatable files to pick and choose sections to "compile" to specific case lua files.

The original intent of this is to be able to have `debug` and `assert` sections in code to create a "debug target" that can be ran with extra information and checks. Then a "release target" can be made that will strip these sections out.

THe other intent is that all code should be lua compatable code, so the original source can be run and this `targets.lua` can be completely ignored if desired.

## Usage

```
lua compile.lua [source folder] -o [output folder] [conditionals] 
```

## Getting Started

Create comment blocks in your code where you want a conditional compilation.

```lua
local number = 0

--[[ (DEBUG)
print(number)
--]]

--[====[ (not DEBUG)
print("running in normal mode")
--]====]

for i=1,#10 do
    number = number + i
    --[[ (DEBUG) 
    print(number)
    ]]
end

--[[ (TEST)
assert(number == 55)
print("number passed assertion")
--]]
```

Now you can run a debug and test version by running `lua compile.lua file.lua DEBUG TEST` or you can 'compile' it to a new file with `lua compile.lua file.lua -o bin\ DEBUG TEST`

Compile.lua will process all local require files with the same environmental flags as the first file run when running an individual file.