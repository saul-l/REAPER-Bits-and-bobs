-- @description Next Variation
-- @author saul-l / Sauli
-- @version 1.02
-- @about
--   # Next Variation
--
--   Sets content of selected audio item to next variation found. Perfect for sound designers working with recordings containing multiple variations in single file.
--   Uses built-in transient detection, which can be configured action "Transient detection sensitivity/threshold: Adjust..."
--
--   Usage:
--   - Add audio file containing multiple sounds into timeline
--   - Trim first sound variation from the audio item
--   - Select audio item and run the script
--   - It should now contain the second variation in audio file
--   - If results are not satisfactory configure the transient detection through action "Transient detection sensitivity/threshold: Adjust..."
--
--   Features:
--   - Supports multiple selected items
--   - Uses separate tracks for item manipulation, so shouldn't mess with unselected track content
--   - Loops through item content, if Loop source is enabled
--   - Preserves item fade information
--   
--   Known issues and workaround:
--     - Built-in transient detection is not content aware and therefor you often have to choose between getting false positives or not finding the next variation. False positives are not really a big issue, since you can just run the script again (using keyboard shortcut strongly recommended). Sensitivity 35%, Threshold -24db settings seem to work fine (= a bit too false positive happy, but not missing anything) with most audio content. 

newLength = 1000
newItemList = {}

-- Save item selection
function SaveItems(t)
   local t = t or {}
   for i = 0, reaper.CountSelectedMediaItems(0)-1 do
      t[i+1] = reaper.GetSelectedMediaItem(0, i)
   end
   return t
 end
 
-- restore item selection  
function RestoreItems( items )
   for i, item in ipairs( newItemList ) do
      reaper.SetMediaItemSelected( item, true )
   end
end

-- Main function
function Main()
   for i, item in ipairs(selectedItems) do
      
      reaper.SelectAllMediaItems(0, false) 
  
      -- Save original item values   
      itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH" )
      itemPosition = reaper.GetMediaItemInfo_Value(item, "D_POSITION" )
      itemFadeInCurve = reaper.GetMediaItemInfo_Value(item, "C_FADEINSHAPE" )
      itemFadeInLength = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN" )
      itemTrack = reaper.GetMediaItemTrack(item)

      reaper.SetMediaItemSelected(item, 1 )
      reaper.SetOnlyTrackSelected(itemTrack)
      reaper.SetMediaItemInfo_Value(item, "D_LENGTH", newLength)
       
      -- Move item to new empty track to prevent other items messing up the process
      reaper.Main_OnCommand(40001,0) -- insert track
      newTrack=reaper.GetSelectedTrack(0, 0) 
      reaper.MoveMediaItemToTrack(item,newTrack)
      reaper.SetEditCurPos(itemPosition,0,0)
      
      reaper.Main_OnCommand(40375,0) -- Move cursor to next transient
      reaper.Main_OnCommand(40012,0) -- Split. Fade in lost.
 
      newItem=reaper.GetSelectedMediaItem(0,0)
 
      -- Restore values from original item
      reaper.SetMediaItemInfo_Value(newItem, "D_LENGTH", itemLength)
      reaper.SetMediaItemInfo_Value(newItem, "D_POSITION", itemPosition)
      reaper.SetMediaItemInfo_Value(newItem, "C_FADEINSHAPE", itemFadeInCurve)
      reaper.SetMediaItemInfo_Value(newItem, "D_FADEINLEN", itemFadeInLength)
       
      reaper.MoveMediaItemToTrack(newItem,itemTrack)
      reaper.DeleteTrack(newTrack)
 
      -- Add new item to item list
      table.insert(newItemList, reaper.GetSelectedMediaItem(0, 0)) 
 
   end
end
 
 
-- INIT
function Init()
 
   -- Are there selected items
   countSelectedItems = reaper.CountSelectedMediaItems(0)
   if countSelectedItems == 0 then return false end
   
   -- Save item selection and cursor and screen position
   cursorPosition= reaper.GetCursorPosition()
   a,b = reaper.GetSet_ArrangeView2(0, false, 0, 0)
   reaper.PreventUIRefresh(1) 
   selectedItems = SaveItems()
  
   reaper.Undo_BeginBlock()
   Main()
   reaper.Undo_EndBlock("NextVariation", -1)

   -- Restore original item selection and screen position
   RestoreItems(selectedItems)
   reaper.SetEditCurPos(cursorPosition,0,0)
   reaper.GetSet_ArrangeView2(0, 1, 0, 0, a, b)
   reaper.PreventUIRefresh(-1)
   reaper.UpdateArrange()
end

--

Init() 
