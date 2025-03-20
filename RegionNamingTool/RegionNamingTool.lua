-- @description Region Naming Tool
-- @author saul-l / Sauli
-- @version 1.03
-- @provides
--   RegionNamingTool/*.lua
--   [main] RegionNamingTool.lua
--  # Region naming tool
--  
--  Requires Lokasenna's GUI library v2 for Lua.
--  RegionNamingTool should automatically help installing it, but in case that doesn't work:  
--  Use ReaPack to download it from this repo: https://github.com/ReaTeam/ReaScripts/raw/master/index.xml  
--  or downloaded directly from here: https://github.com/jalovatt/Lokasenna_GUI  
--  After installation you might need to run action Script: Set Lokasenna_GUI v2 library path.lua  
--  
--  **Basic usage:**  
--   - Create regions in Reaper  
--   - Create timeline selection which has the regions inside it  
--   - Run the script  
--   - Select and/or type words to fields. (For example select PLR, empty field, footstep and type "dirt" into last textbox)  
--   - Press **rename**-button. All regions inside timeline selection are renamed to specified word combination. (PLR_footstep_dirt in example)  
--   - Second list box supports multiselection with both control and shift. Items are always processed in order from top to bottom.  
--  
--  **Settings:**  
--   - Press **global**-button. Settings file should open in text editor.  
--   - textEditorExecutable is path of text editor which opens settings files. notepad.exe is used by default.  
--   - ListBox1ValuesDefault and listBox2ValuesDefault contain word list of two list boxes in RegionNamingTool UI. These are used when no project settings file is found.  
--   - projects contains paths to project-specific word lists. First value is project name and second name is path of project word list.  
--   - project-specific word list is used if project name is found in reaper project path. 
--   - **project**-button opens project word list in text editor.  
--  
--  **Project word list usage example:**  
--   - Project name is "test_project" and path is "C:\regionNamingToolSettings\foobar.lua"  
--   - Current reaper project is C:\reaper_project\test_project\ENE_Megamonster.rpp"  
--   - RegionNamingTool uses list box values defined in C:\regionNamingToolSettings\foobar.lua, because word test_project was found in project path name.  
--   - RegionNamingTool-folder contains rnt_example.lua, which can be used as a base for project specific word list  
--  
--  **Additional info:**  
--   Previously used values are automatically saved inside reaper project file.
-- @changelog
--   - Settings will survive updates after this update.
--   - Your settings have been nuked. Sorry for that.
--   - Empty values clear region name
--   - Console message displayed, if project settings are not found, instead of opening empty text editor.
--   - Possibly works on Mac now. 100% untested blind coding.

-- Check Lokasenna_GUI library availability --
-- Originally by Amagalma https://github.com/amagalma

local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" or not reaper.file_exists(lib_path .. "Core.lua") then
  local not_installed = false
  local Core_library = {reaper.GetResourcePath(), "Scripts", "ReaTeam Scripts", "Development", "Lokasenna_GUI v2", "Library", "Core.lua"}
  local sep = reaper.GetOS():find("Win") and "\\" or "/"
  Core_library = table.concat(Core_library, sep)
  if reaper.file_exists(Core_library) then
    local cmdID = reaper.NamedCommandLookup( "_RS1c6ad1164e1d29bb4b1f2c1acf82f5853ce77875" )
    if cmdID > 0 then
          reaper.MB("Lokasenna's GUI path will be set now. Please, re-run the script", "Lokasenna GUI v2 Installation", 0)
      -- Set Lokasenna_GUI v2 library path.lua
      reaper.Main_OnCommand(cmdID, 0)
      return reaper.defer(function() end)
    else
      not_installed = true
    end
  else
    not_installed = true
  end
  if not_installed then
    reaper.MB("Please, right-click and install 'Lokasenna's GUI library v2 for Lua' in the next window. Then run the 'Set Lokasenna_GUI v2 library path.lua' script in your Action List. After all is set, you can run this script again. Thanks!", "Install Lokasenna GUI v2", 0)
    reaper.ReaPack_BrowsePackages( "Lokasenna GUI library v2 for Lua" )
    return reaper.defer(function() end)
  end
end

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
  local info = debug.getinfo(1,'S')
  local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
  return script_path
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

-- get_line from stackoverflow user cyclaminist
function get_line(filename, line_number)
  local i = 0
  for line in io.lines(filename) do
    i = i + 1
    if i == line_number then
      return line
    end
  end
  return nil -- line not found
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
      if newRegionName == "" then
        reaper.SetProjectMarker4(0, marker[6], marker[2], marker[3], marker[4], newRegionName, 0, 1)
      else
        reaper.SetProjectMarker(marker[6], marker[2], marker[3], marker[4], newRegionName)
      end
    end
  end
  
end

function globalConfig()
  if reaper.GetOS() == "Win32" or reaper.GetOS() == "Win64" then
    os.execute("start " .. winTextEditorExecutable .. " " .. script_path .. "/RegionNamingTool/RegionNamingToolSettings.lua")
  else
    os.execute("open -a " .. macTextEditorExecutable .. " " .. script_path .. "/RegionNamingTool/RegionNamingToolSettings.lua")
  end
end

function projectConfig()
  if reaper.file_exists(activeProjectSettings) then
    if reaper.GetOS() == "Win32" or reaper.GetOS() == "Win64" then
      os.execute("start " .. winTextEditorExecutable .. " " .. activeProjectSettings)
    else
      os.execute("open -a " .. macTextEditorExecutable .. " " .. activeprojectSettings)
    end
  else
    reaper.ShowConsoleMsg("No project settings found!\n")
  end
  
end

function updateSettings(currentSettings, newSettings, newVersion)
  local tempFile = script_path .. "/RegionNamingTool/tempSettings.lua"
  local file = io.open(currentSettings, "r")
  local settingsFileContent = {}
  local i = 0
  
  for line in file:lines() do
    i = i + 1
    if i == 2 then
      table.insert(settingsFileContent, "versionNumber = " .. newVersion .."\n")
    else
      table.insert(settingsFileContent, line .. "\n")
    end
  end
  file:close()
  
  file = io.open(newSettings, "r")
  i = 0
  for line in file:lines() do
    i = i + 1
    if i ~= 1 then
      table.insert(settingsFileContent, line .. "\n")
    end
  end
  file:close()
  
  if reaper.file_exists(tempFile) then
    os.remove(tempFile)
  end
    
  file = io.open(tempFile, "a")
  for _, line in ipairs(settingsFileContent) do
   file:write(line)
  end
  file:close()
  
  os.remove(currentSettings)
  os.rename(tempFile, currentSettings)
  
end

function defaultSettings(localSettings)
  defaultSettingsLocation = script_path .. "/RegionNamingTool/RegionNamingToolSettings.lua"

  local file = io.open(defaultSettingsLocation, "r")
  local defaultSettingsContent = {}
  for line in file:lines() do
      table.insert(defaultSettingsContent, line .. "\n")
  end
  
  file:close()
  
  local tempFile = script_path .. "/RegionNamingTool/tempSettings.lua"
  if reaper.file_exists(tempFile) then
    os.remove(tempFile)
  end 
  
  file = io.open(tempFile, "a")
  for _, line in ipairs(defaultSettingsContent) do
   file:write(line)
  end
  file:close()
  
  os.rename(tempFile, localSettings)
  
end

-- functions end here


script_path = get_script_path()

localSettingsLocation = script_path .. "/RegionNamingTool/UserSettings.lua"
newSettingsLocation = script_path .. "/RegionNamingTool/NewSettings.lua"
if reaper.file_exists(localSettingsLocation) then
  if reaper.file_exists(newSettingsLocation) then
    assert(pcall(load(get_line(localSettingsLocation, 2))),"invalid user settings file! " .. localSettingsLocation .. "\n")
    pcall(load(get_line(newSettingsLocation, 1)))
    if versionNumber<newVersionNumber then
      updateSettings(localSettingsLocation, newSettingsLocation, newVersionNumber)
    end
  end
else
  defaultSettings(localSettingsLocation)
end

  dofile(localSettingsLocation)
  
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


