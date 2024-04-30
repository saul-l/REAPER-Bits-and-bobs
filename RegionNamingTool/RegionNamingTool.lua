-- @description Region Naming Tool
-- @author saul-l / Sauli
-- @version 1.00
-- @provides:
--   RegionNamingTool/*
--   [main] RegionNamingTool.lua
-- @about
--  # Region naming tool
--
--  Requires Lokasenna's GUI library v2 for Lua.
--  ReaTeam Scripts has it. Use ReaPack to download it from this repo: https://github.com/ReaTeam/ReaScripts/raw/master/index.xml
--  or downloaded directly from here: https://github.com/jalovatt/Lokasenna_GUI
--  After you have installed it you might need to run action Script: Set Lokasenna_GUI v2 library path.lua
--  
--  Basic usage:
--   Create regions in reaper
--   Create timeline selection which has the regions inside
--   Run the script
--   Select and/or type words to fields. (For example select PLR, empty field, footstep and type "dirt" into last textbox)
--   press rename-button. All regions inside timeline selection are renamed to specified word combination. (PLR_footstep_dirt in example)
--   Second list box supports multiselection with both control and shift. Items are always processed in order from top to bottom.
--  
--  Settings:
--   Press global-button. Settings file should open in text editor.
--   textEditorExecutable is path of text editor which opens settings files. notepad.exe is used by default.
--   ListBox1ValuesDefault and listBox2ValuesDefault contain word list of two list boxes in RegionNamingTool UI. These are used when no project settings file is found.
--   projects contains paths to project-specific word lists. First value is project name and second name is path of project word list.
--   project-specific word list is used if project name is found in reaper project path.
--  
--  Project word list usage example:
--   Project name is "test_project" and path is "C:\regionNamingToolSettings\foobar.lua"
--   Current reaper project is C:\reaper_project\test_project\ENE_Megamonster.rpp"
--   RegionNamingTool uses list box values defined in C:\regionNamingToolSettings\foobar.lua, because word test_project was found in project path name.
--  
--  projects-button opens project word list in text editor.
--   RegionNamingTool-folder contains rnt_example.lua, which can be used as a base for project specific word list
--  
--  Additional info:
--   Previously used values are automatically saved inside reaper project file.

function reaperDoFile(file) local info = debug.getinfo(1,'S'); script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(script_path .. file); end

local regionNamingToolActionName = "Custom: RegionNamingTool.lua"

namingToolName = "REGIONNAMINGTOOL"

projectName = reaper.GetProjectName(0)
projectName = string.upper(string.sub(projectName, 1, string.len(projectName)-4))

retval, path = reaper.EnumProjects(-1, "")
projectSettings = 0
listBox1StringSave = ""
listBox2StringSave = {""}
textEditor1StringSave = ""
textEditor2StringSave = ""
listBox1Values = {}
listBox2Values = {}
script_path = ""
activeProjectSettings = ""

-- This looks if current project folder has any of the project names in it's path.
-- For example if we are currently opening D:/reaper_projects/projectA/enemy/evil_asteroid.rpp
-- it will find that projectA exists in full path and opens lua file listed after "projectA"

-- later separated loading section over

local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
loadfile(lib_path .. "Core.lua")()
GUI.req("Classes/Class - Listbox.lua")()
GUI.req("Classes/Class - Label.lua")()
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - TextEditor.lua")()

if missing_lib then return 0 end

GUI.name = "Region Naming Tool"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 300, 640
GUI.anchor, GUI.corner = "mouse", "C"

function get_script_path()
  local path_line = nil
  local kb_ini_path = reaper.GetResourcePath() .. "\\" .. "reaper-kb.ini"
  if reaper.file_exists(kb_ini_path) then
    for line in io.lines(kb_ini_path) do
      if string.find(line, regionNamingToolActionName) then
        path_line = line
      end   
    end
  end
  
  if path_line == nil then
    reaper.ShowConsoleMsg(regionNamingToolActionName .. " not found! \n")
  else
    path_line = string.reverse(path_line)
    path_line = string.match(path_line, "(.-)\"")
    path_line = string.reverse(path_line)
  end
   
  path_line = path_line:sub(2)
 
  if string.find(path_line, ":") then
    path_line = path_line:gsub("RegionNamingTool.lua", "")
  else
    path_line = path_line:gsub("RegionNamingTool.lua", "")
    path_line = reaper.GetResourcePath() .. "\\Scripts\\" .. path_line
  end
  
  path_line = path_line:gsub("\\", "/")
    
  return path_line
end

function writeSettingsFile(path)
  os.execute("cd /d " .. path .. " & mkdir RegionNamingTool")
  file = io.open(path .. "/RegionNamingTool/RegionNamingToolSettings.lua", "w")
  io.output(file)
  io.write("textEditorExecutable = \"notepad.exe\"\n")
  io.write("listBox1ValuesDefault = {\"\", \"AMB\", \"ENV\", \"OBJ\", \"PLR\", \"ENE\", \"NPC\", \"FX\", \"CINE\", \"UI\"}\n")
  io.write("listBox2ValuesDefault = {\"\", \"movement\", \"skill\", \"vocal\", \"physics\", \"kinematic\", \"attack\", \"damage\", \"death\", \"jump\", \"shoot\", \"melee\", \"angular\", \"linear\", \"move\", \"roll\", \"collision\", \"loop\", \"start\", \"end\"}\n")
  io.close(file)
end

-- serializeTable from stack overflow user Henrik Ilgen
-- usage example:
-- s = serializeTable({a = "foo", b = {c = 123, d = "foo"}})
-- print(s)
-- a = loads(s)()

function serializeTable(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0

    local tmp = string.rep(" ", depth)

    if name then tmp = tmp .. name .. " = " end
  
    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")
  
        for k, v in pairs(val) do
            tmp =  tmp .. serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end
  
        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end
  
    return tmp
end

function saveData()
  -- horrible copypaste mess. Should just loop through couple of arrays containing save strings
  
  local listBox2StringSaveSerialized = serializeTable(listBox2StringSave, "listBox2StringSave")
  
  -- this is saved next time project is saved
  reaper.SetProjExtState(0, namingToolName, "LISTBOX1STRINGSAVE", listBox1StringSave)
  reaper.SetProjExtState(0, namingToolName, "LISTBOX2STRINGSAVE", listBox2StringSaveSerialized)
  reaper.SetProjExtState(0, namingToolName, "TEXTEDITOR1STRINGSAVE", textEditor1StringSave)
  reaper.SetProjExtState(0, namingToolName, "TEXTEDITOR2STRINGSAVE", textEditor2StringSave)

  -- this is saved to memory, but doesn't persist.
  reaper.SetExtState(projectName .. namingToolName, "ALREADYLOADED", "1", false)
  reaper.SetExtState(projectName .. namingToolName, "LISTBOX1STRINGSAVE", listBox1StringSave, false)
  reaper.SetExtState(projectName .. namingToolName, "LISTBOX2STRINGSAVE", listBox2StringSaveSerialized, false)
  reaper.SetExtState(projectName .. namingToolName, "TEXTEDITOR1STRINGSAVE", textEditor1StringSave, false)
  reaper.SetExtState(projectName .. namingToolName, "TEXTEDITOR2STRINGSAVE", textEditor2StringSave, false)
end

function loadData()

  local listBox2StringSaveSerialized = ""
  
  if(reaper.GetExtState(projectName .. namingToolName, "ALREADYLOADED") == "1") then
    listBox1StringSave = reaper.GetExtState(projectName .. namingToolName, "LISTBOX1STRINGSAVE")
    listBox2StringSaveSerialized = reaper.GetExtState(projectName .. namingToolName, "LISTBOX2STRINGSAVE")
    textEditor1StringSave = reaper.GetExtState(projectName .. namingToolName, "TEXTEDITOR1STRINGSAVE")
    textEditor2StringSave = reaper.GetExtState(projectName .. namingToolName, "TEXTEDITOR2STRINGSAVE")
  else
    ret1, listBox1StringSave = reaper.GetProjExtState(0, namingToolName, "LISTBOX1STRINGSAVE")
    ret2, listBox2StringSaveSerialized = reaper.GetProjExtState(0, namingToolName, "LISTBOX2STRINGSAVE")
    ret3, textEditor1StringSave = reaper.GetProjExtState(0, namingToolName, "TEXTEDITOR1STRINGSAVE")
    ret4, textEditor2StringSave = reaper.GetProjExtState(0, namingToolName, "TEXTEDITOR2STRINGSAVE")
  end
  
  load(listBox2StringSaveSerialized)()
  
   postLoadInit()
   
end

function postLoadInit()
   singleSelectListboxSet(listBox1StringSave, listBox1Values, "Listbox1")
   multiSelectListboxSet(listBox2StringSave, listBox2Values, "Listbox2")
  GUI.Val("TextEditor1", textEditor1StringSave)
  GUI.Val("TextEditor2", textEditor2StringSave)
end

function multiSelectListboxSet(inputTable1, inputTable2, listBoxName)
 local selection = {}
 for key1, value1 in pairs(inputTable1) do
    for key2, value2 in pairs(inputTable2) do
     if inputTable1[key1] == inputTable2[key2] then 
        selection[key2] = true
      end
    end
  end
  GUI.Val(listBoxName, selection)
  
end

function singleSelectListboxSet(inputString, inputTable, listBoxName)
 local selection = {}
  for key, value in pairs(inputTable) do
    if inputString == inputTable[key] then
      selection[key] = true
      GUI.Val(listBoxName, selection)
    end
  end
end

  --
function addToMarkerName()

  listBox1StringSave = ""
  listBox2StringSave = {}
  textEditor1StringSave = ""
  textEditor2StringSave = ""
    
  -- Check if Listbox 1 has value
  local listBox1String = ""
  local listBox1GuiVal
  listBox1GuiVal = GUI.Val("Listbox1")
  
  if (listBox1GuiVal ~= nil and listBox1Values[listBox1GuiVal] ~= "") then
    listBox1StringSave = listBox1Values[listBox1GuiVal]
    listBox1String = listBox1Values[listBox1GuiVal] .. "_"
  end

  --
  
  local listBox2String = ""
  local listBox2GuiVal = nil
  listBox2GuiVal = {}
  local listBox2GuiSelection = GUI.Val("Listbox2")
  
  if listBox2GuiSelection ~= nil then

    if type(listBox2GuiSelection) == "number" then listBox2GuiSelection = {[listBox2GuiSelection] = true} end
   
    for k, v in pairs(listBox2GuiSelection) do
      if listBox2GuiSelection[k] == true then
        table.insert(listBox2GuiVal, k)
      end
    end
    
    table.sort(listBox2GuiVal)
    
    for k, v in pairs(listBox2GuiVal) do
      if listBox2Values[listBox2GuiVal[k]] ~= "" then
        listBox2String = listBox2String .. listBox2Values[listBox2GuiVal[k]] .. "_"
        table.insert(listBox2StringSave, listBox2Values[listBox2GuiVal[k]])
      end
    end
  end

  --
  local textEditor1String = ""
  if GUI.Val("TextEditor1") ~= "" then
    textEditor1String = GUI.Val("TextEditor1") .. "_"
    textEditor1StringSave = GUI.Val("TextEditor1")
  end
    
    textEditor2StringSave = GUI.Val("TextEditor2")
  
  saveData()
    
  newRegionName = listBox1String  .. textEditor1String .. listBox2String ..   GUI.Val("TextEditor2")
  if string.sub(newRegionName, -1) == "_" then 
   newRegionName = string.sub(newRegionName, 1, string.len(newRegionName)-1)
  end
  
  local timeSelectionStart, timeSelectionEnd = reaper.GetSet_LoopTimeRange(false ,false, 0,0, false)
  local indexPosition = 0
  
  while true do
    local marker = {reaper.EnumProjectMarkers(indexPosition)}
    indexPosition = marker[1]
    if indexPosition == 0 then break end
    if (marker[2]) and (marker[3] >= timeSelectionStart) and (marker[3] <= timeSelectionEnd) then
        reaper.SetProjectMarker(marker[6], marker[2], marker[3], marker[4], newRegionName)
      end
  end
  
end

function globalConfig()
  os.execute("start " .. textEditorExecutable .. " " .. script_path .. "/RegionNamingTool/RegionNamingToolSettings.lua")
end

function projectConfig()
  os.execute("start " .. textEditorExecutable .. " " .. activeProjectSettings)
end
-- functions end here


script_path = get_script_path()

if reaper.file_exists(script_path .. "/RegionNamingTool/RegionNamingToolSettings.lua") then
  dofile(script_path .. "/RegionNamingTool/RegionNamingToolSettings.lua")
else
   writeSettingsFile(script_path)  
end


for i = 1, #projects, 2
do
  if string.find(path, projects[i]) then
    dofile (projects[i+1])
    activeProjectSettings = projects[i+1]
    projectSettings = projectSettings + 1    
  end
end

if (projectSettings == 0) then
  listBox1Values = listBox1ValuesDefault
  listBox2Values = listBox2ValuesDefault
end

if (projectSettings > 1) then
  reaper.ShowConsoleMsg("Multiple matching project settings files! \n")
  return 0 
end


GUI.New("Listbox1", "Listbox", {
    z = 11,
    x = 16,
    y = 16,
    w = 256,
    h = 148,
    list = listBox1Values,
    multi = false,
    caption = "",
    font_a = 3,
    font_b = 4,
    color = "txt",
    col_fill = "elm_fill",
    bg = "elm_bg",
    cap_bg = "wnd_bg",
    shadow = true,
    pad = 6

})

GUI.New("TextEditor1", "TextEditor", {
    z = 11,
    x = 16,
    y = 172,
    w = 256,
    h = 32,
    caption = "",
    font_a = 3,
    font_b = "monospace",
    color = "txt",
    col_fill = "elm_fill",
    cap_bg = "wnd_bg",
    bg = "elm_bg",
    shadow = true,
    pad = 4,
    undo_limit = 20
})

GUI.New("Listbox2", "Listbox", {
    z = 11,
    x = 16,
    y = 212,
    w = 256,
    h = 320,
    list = listBox2Values,
    multi = true,
    caption = "",
    font_a = 3,
    font_b = 4,
    color = "txt",
    col_fill = "elm_fill",
    bg = "elm_bg",
    cap_bg = "wnd_bg",
    shadow = true,
    pad = 6,
    undo_limit = 20
})

GUI.New("TextEditor2", "TextEditor", {
    z = 11,
    x = 16,
    y = 540,
    w = 256,
    h = 32,
    caption = "",
    font_a = 3,
    font_b = "monospace",
    color = "txt",
    col_fill = "elm_fill",
    cap_bg = "wnd_bg",
    bg = "elm_bg",
    shadow = true,
    pad = 4,
    undo_limit = 20
})

GUI.New("Button1", "Button", {
    z = 11,
    x = 16,
    y = 580,
    w = 48,
    h = 24,
    caption = "Rename",
    font = 3,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = addToMarkerName
})

GUI.New("Button2", "Button", {
    z = 11,
    x = 162,
    y = 580,
    w = 48,
    h = 24,
    caption = "global",
    font = 3,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = globalConfig
})

GUI.New("Button3", "Button", {
    z = 11,
    x = 222,
    y = 580,
    w = 48,
    h = 24,
    caption = "project",
    font = 3,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = projectConfig
})

GUI.Init()
loadData()
GUI.Main()


