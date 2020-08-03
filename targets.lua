local lfs = require('lfs')


local function checkForCommentBlockStart(text)
    local block = ""
    local closer = ""
    local condition = ""

    local s, e = 0, 0
    local found = false

    -- gets the start of the comment section
    for i=1, #text-2 do
        local set = text:sub(i,i+2)
        
        if set == "--[" then 
            s = i
            break
        end
    end

    -- gets the end of the start of the comment section
    if s ~= 0 then for i=s+3, #text do
        local char = text:sub(i,i)
        if char == "[" then
            e = i
            break
        end
    end end

    -- gets the block start and closer strings so we know what
    -- stop at in the future.
    if e ~= 0 then
        block = text:sub(s,e)
        closer = block:gsub("%[","%]"):sub(3)
    end

    -- finds the conditional statement, that we need in order
    -- to remove the comment blocks
    if #closer > 0 then
        local inCondition = false
        for i=e,#text do
            local char = text:sub(i,i)
            if char == "(" then
                inCondition = true
            elseif char == ")" then
                break
            elseif inCondition then
                condition = condition .. char
            end
        end
    end

    if condition then
        if #closer == 0 then closer = nil end
        if #condition == 0 then condition = nil end
        return condition, closer
    end
end

local function checkForCommentBlockEnd(text, closer)
    for i=1,#text-#closer+1 do
        local set = text:sub(i,i+#closer)
        if set == closer then
            return true
        end
    end
end

local function processCondition(conditional)
    local positive = true
    local working = ""
    for i=1,#conditional do
        local char = conditional:sub(i,i)
        if char == " " then
            if working == "not" then
                positive = false
                break
            end
        else
            working = working .. char
        end
    end

    if #working ~= #conditional then
        return conditional:sub(#working + 2), positive
    else
        return conditional, positive
    end
end

--- returns the string of the file.
local function processFile(path, environment)
    environment = environment or { }

    local file = io.open(path,"r")
    local content = ""

    local closer;
    local condition;
    local isPositive;
    for line in file:lines() do

        local addline = true

        if not closer then
            local con, clos = checkForCommentBlockStart(line)
            if con and clos then 
                closer = clos 
                condition, isPositive = processCondition(con)
                addline = false
            end

        elseif condition and isPositive then
            addline = environment[condition]
        elseif condition then
            addline = environment[condition] == nil
        end
        
        if closer then
            if checkForCommentBlockEnd(line, closer) then
                closer = nil
                addline = false
            end
        end

        if addline then
            content = content .. line .. "\n"
        end
    end

    file:close()
    return content
end

local function printText(content)
    local line = ""
    local linePrefix = "    | "
    for i=1,#content do
        local char = content:sub(i,i)
        if char == "\n" or char == "\r" then
            print(linePrefix .. line)
            line = ""
        else
            line = line .. char
        end
    end

    if #line > 0 then
        print(linePrefix .. line)
    end
end

local function getAllSourceFiles(folder)
    local files = { }

    for file in lfs.dir(folder) do if file ~= "." and file ~= ".." then
        local mode = lfs.attributes(folder .. "/" .. file, "mode")
        if mode == "directory" then
            local subfiles = getAllSourceFiles(folder .. "/" .. file)
            for i=1,#subfiles do
                table.insert(files, subfiles[i])
            end
        elseif mode == "file" then
            if #file > 4 then if file:sub(#file-3) == ".lua" then
                table.insert(files, folder .. "/" .. file)
            end end
        end
    end end

    return files
end

local function makeAllFolders(newRoot, oldRoot)
    if lfs.attributes(newRoot,"mode") ~= "directory" then
        lfs.mkdir(newRoot)
    end

    for file in lfs.dir(oldRoot) do
        local oldPath = oldRoot .. "/" .. file
        if file ~= "." and file ~= ".." then
            if lfs.attributes(oldPath,"mode") == "directory" then
                local newPath = newRoot .. "/" .. file
                lfs.mkdir(newPath)
                makeAllFolders(newPath, oldPath)
            end
        end
    end

end

local function runAndProcess(file, env)
    local root = file:match(".*[\\|/]")
    local old_require = require
    require = function(path)
        local filepath = root .. path:gsub("%.","/") .. ".lua"
        if lfs.attributes(filepath,"mode") == "file" then
            return loadstring(processFile(filepath, env))()
        else
            return old_require(path)
        end
    end

    local content = processFile(file, env)
    local f = loadstring(content)
    f()

    require = old_require
end

--- processes the arguments and actually runs the compiler.
local function main(...)
    local n = select('#',...)

    local params = { }
    local env = { }

    local i = 1; while true do
        local c = select(i,...)
        if not c then break end
        if c == "-o" then
            i = i + 1
            params.output = select(i,...)
        elseif params.folder or params.file then
            env[c] = true
        else
            local mode = lfs.attributes(c,"mode")
            if mode == "file" then
                params.file = c
            elseif mode == "folder" then
                params.folder = c
            else assert(false, "'" .. tostring(c) .. "' is not a file or a folder") end
        end

        i = i + 1
    end

    -- with a folder and an output we scan that folder and
    -- process all the source files we find in there.
    if params.folder and params.output then 

        makeAllFolders(params.output, params.folder)

        for _, file in pairs(getAllSourceFiles(params.folder)) do
            local newPath; do
                local localPath = file:sub(#params.folder+2)
                newPath = params.output .. "/" .. localPath
            end
            
            local newContent = processFile(file, env)
            local file = assert(io.open(newPath, "w"))
            file:write(newContent)
            file:close()

        end

    -- with just a folder??
    elseif params.folder then
        print('not implemented')

    -- with a file and an output we will process just that one file, and
    -- all the local files that it depends on (if the option is enabled)
    elseif params.file and params.output then
        print('not implemented')

    -- with only a file we will run that file.
    elseif params.file then
        runAndProcess(params.file, env)

    end
end

main(...)