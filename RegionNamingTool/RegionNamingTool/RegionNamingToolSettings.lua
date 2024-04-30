textEditorExecutable = "notepad.exe"

listBox1ValuesDefault = {
	"",
	"AMB",
	"ENV",
	"OBJ",
	"PLR",
	"ENE",
	"NPC",
	"FX",
	"CINE",
	"UI"
}

listBox2ValuesDefault = {
	"",
	"movement",
	"skill",
	"vocal",
	"physics",
	"kinematic",
	"attack",
	"damage",
	"death",
	"jump",
	"shoot",
	"melee",
	"move",
	"roll",
	"collision",
	"loop",
	"start",
	"end"
	}

-- In following example any project which has projectName in its full path uses rnt_projectName.lua as listbox values instead of defaults
-- For example reaper project with full path c:/reaper_projects/projectName/enemy_test.rpp would use projectName, because it's under projectName folder
projects = {
	"projectName", "C:/reaper_projects/projectName/rnt_projectName.lua"	
	}