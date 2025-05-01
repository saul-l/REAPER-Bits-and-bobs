# Reaper Bits and bobs

ReaPack compatible repository for my random REAPER scripts and jsfx

Raw index url for ReaPack: https://raw.githubusercontent.com/saul-l/REAPER-Bits-and-bobs/refs/heads/master/index.xml
Currently content:

**Next Variation**

Sound design workflow improvement plugin for automatically moving item audio content start position to next variation.

**Region Naming Tool**

Naming tool, which makes it easy to name multiple regions at once and allows using custom word lists

Requires Lokasenna's GUI library v2 for Lua.  
- Use ReaPack to download it from this repo: https://github.com/ReaTeam/ReaScripts/raw/master/index.xml or downloaded directly from here: https://github.com/jalovatt/Lokasenna_GUI  
- After installation you might need to run action Script: Set Lokasenna_GUI v2 library path.lua
  
**Split and Keep Fade Curves**

Does exactly what name implies. I got tired of split not working how I wanted it to work

**Peak Envelope Generator**

Generates envelope based on audio item peaks.
You can think of it as an offline audio source parameter baker.

Requires ReaImGui, but will prompt you to install it and provide ReaPack repo,
if you don't already have it.

Contains built-in documentation in UI.

Only works with FX envelopes at the moment
