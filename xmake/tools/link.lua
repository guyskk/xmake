--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        link.lua
--

-- imports
import("core.project.config")

-- init it
function init(shellname)
    
    -- save the shell name
    _g.shellname = shellname or "link.exe"

    -- the architecture
    local arch = config.get("arch")

    -- init flags for architecture
    local flags_arch = ""
    if arch == "x86" then 
        flags_arch = "-machine:x86"
    elseif arch == "x64" or arch == "amd64" or arch == "x86_amd64" then
        flags_arch = "-machine:x64"
    end

    -- init ldflags
    _g.ldflags = { "-nologo", "-dynamicbase", "-nxcompat", flags_arch}

    -- init arflags
    _g.arflags = {"-nologo", flags_arch}

    -- init shflags
    _g.shflags = {"-nologo", flags_arch}

    -- init flags map
    _g.mapflags = 
    {
        -- strip
        ["-s"]                  = ""
    ,   ["-S"]                  = ""
 
        -- others
    ,   ["-ftrapv"]             = ""
    ,   ["-fsanitize=address"]  = ""
    }
end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

-- make the strip flag
function strip(level)
    return ""
end

-- make the symbol flag
function symbol(level, symbolfile)

    -- debug? generate *.pdb file
    local flags = ""
    if level == "debug" then
        if symbolfile then
            flags = "-debug -pdb:" .. symbolfile
        else
            flags = "-debug"
        end
    end

    -- none
    return flags
end

-- make the linklib flag
function linklib(lib)

    -- make it
    return lib .. ".lib"
end

-- make the linkdir flag
function linkdir(dir)

    -- make it
    return "-libpath:" .. dir
end

-- make the link command
function linkcmd(objectfiles, targetfile, flags)

    -- make it
    local cmd = format("%s %s -out:%s %s", _g.shellname, flags, targetfile, objectfiles)

    -- too long?
    if #cmd > 4096 then
        local argfile = targetfile .. ".arg"
        io.printf(argfile, "%s -out:%s %s", flags, targetfile, objectfiles)
        cmd = format("%s @%s", _g.shellname, argfile)
    end

    -- ok?
    return cmd
end

-- link the target file
function link(objectfiles, targetfile, flags)

    -- ensure the target directory
    os.mkdir(path.directory(targetfile))

    -- link it
    os.run(linkcmd(objectfiles, targetfile, flags))
end

-- make the archive command
function archivecmd(objectfiles, targetfile, flags)
    return linkcmd(objectfiles, targetfile, flags)
end

-- archive the library file
function archive(objectfiles, targetfile, flags)
    link(objectfiles, targetfile, flags)
end

-- check the given flags 
function check(flags)

    -- -def:"xxx.def"? pass directly
    if flags and flags:lower():find("def:") then
        return 
    end

    -- make an stub source file
    local binaryfile = os.tmpfile() .. ".exe"
    local objectfile = os.tmpfile() .. ".obj"
    local sourcefile = os.tmpfile() .. ".c"

    -- main entry
    if flags and flags:lower():find("subsystem:windows") then
        io.write(sourcefile, "int WinMain(void* instance, void* previnst, char** argv, int argc)\n{return 0;}")
    else
        io.write(sourcefile, "int main(int argc, char** argv)\n{return 0;}")
    end

    -- check it
    os.run("cl -c -Fo%s %s", objectfile, sourcefile)
    os.run("%s %s -out:%s %s", _g.shellname, ifelse(flags, flags, ""), binaryfile, objectfile)

    -- remove files
    os.rm(objectfile)
    os.rm(sourcefile)
    os.rm(binaryfile)
end

