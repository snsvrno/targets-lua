# Targets!

A simple example of a preprocessing transpiler that uses lua compatable files to pick and choose sections to "compile" to specific case lua files.

The original intent of this is to be able to have `debug` and `assert` sections in code to create a "debug target" that can be ran with extra information and checks. Then a "release target" can be made that will strip these sections out.

The other intent is that all code should be lua compatable code, so the original source can be run and this `targets.lua` can be completely ignored if desired.

## Usage

```
lua targets.lua [source folder/file] -o [output folder] [conditionals] 
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

Now you get a debug and test version by running `lua compile.lua file.lua -o bin\ DEBUG TEST` 

```lua
local number = 0

print(number)

for i=1,#10 do
    number = number + i

    print(number)
end

assert(number == 55)
print("number passed assertion")

```

Or just get the release version by running `lua target.lua file.lua -o bin\`

```lua
local number = 0

print("running in normal mode")

for i=1,#10 do
    number = number + i
end
```

or you can run it directly from the command line with `lua target.lua file.lua DEBUG`