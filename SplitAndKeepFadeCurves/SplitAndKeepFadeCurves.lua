-- @description Split and Keep Fade Curves
-- @author saul-l / Sauli
-- @version 1.00
-- @about
--
-- Splits and keeps fade curves
  worthUndoing = false
  prevsel_items = {}
  init_sel_items = {}
  
  previously_existing_items = {}
  function SaveSelectedItems(t)
    local t = t or {}
    for i = 0, reaper.CountSelectedMediaItems(0)-1 do
      t[i+1] = reaper.GetSelectedMediaItem(0, i)
    end
    return t
  end
  
  function RestoreSelectedItems( items )
        reaper.SelectAllMediaItems(0, false)
    for i, item in ipairs( init_sel_items ) do
      reaper.SetMediaItemSelected( item, true )
    end
  end
  
  function Main()
  
    for i, rightItem in ipairs(init_sel_items) do
      reaper.SelectAllMediaItems(0, false)
      reaper.SetMediaItemSelected( rightItem, true )
    
      itemChanged = true
      for i2, item in ipairs(prevsel_items) do
        if(reaper.GetMediaItemInfo_Value(item, "D_LENGTH") == reaper.GetMediaItemInfo_Value(rightItem, "D_LENGTH")
        and reaper.GetMediaItemInfo_Value(item, "D_POSITION") == reaper.GetMediaItemInfo_Value(rightItem, "D_POSITION"))
        then itemChanged = false
        end
      end      
      
      if (itemChanged) then
        fadeOutLen = reaper.GetMediaItemInfo_Value(rightItem, "D_FADEOUTLEN")
        fadeOutCurve = reaper.GetMediaItemInfo_Value(rightItem, "C_FADEOUTSHAPE")
        fadeOutDir = reaper.GetMediaItemInfo_Value(rightItem, "D_FADEOUTDIR") 
          
        reaper.Main_OnCommand(41128,0) -- Select previous non-overlapping item
        leftItem=reaper.GetSelectedMediaItem(0,0)
            
        if(reaper.CountSelectedMediaItems(0)) ~= 0 then
            
          fadeInLen = reaper.GetMediaItemInfo_Value(leftItem, "D_FADEINLEN")
          fadeInCurve = reaper.GetMediaItemInfo_Value(leftItem, "C_FADEINSHAPE")
          fadeInDir = reaper.GetMediaItemInfo_Value(leftItem, "D_FADEINDIR")     
              
          reaper.SetMediaItemInfo_Value(rightItem, "C_FADEINSHAPE", fadeInCurve)
          reaper.SetMediaItemInfo_Value(leftItem, "C_FADEOUTSHAPE", fadeOutCurve)   
        
          reaper.SetMediaItemInfo_Value(rightItem, "D_FADEINDIR", fadeInDir)    
          reaper.SetMediaItemInfo_Value(leftItem, "D_FADEOUTDIR", fadeOutDir)
              
          worthUndoing = true
        end
      end
    end
  end

  
  function Init()
    reaper.PreventUIRefresh(1) 
    reaper.Undo_BeginBlock()
    
    -- Get already selected media items
    count_sel_items = reaper.CountSelectedMediaItems(0)
    
    if count_sel_items ~= 0 then
     prevsel_items = SaveSelectedItems()
    end
    
    
    reaper.Main_OnCommand(40012,0) -- Split and select right
    -- See if there is items selected
    count_sel_items = reaper.CountSelectedMediaItems(0)
    
    if count_sel_items == 0 then
        reaper.Undo_EndBlock("SplitAndKeepFadeCurves", 0)
    return false end
    
    init_sel_items = SaveSelectedItems()
    
    Main()
    
    RestoreSelectedItems(init_sel_items)
    
    if(worthUndoing) then
      reaper.Undo_EndBlock("SplitAndKeepFadeCurves", -1)
    else
      reaper.Undo_EndBlock("SplitAndKeepFadeCurves", 0)
    end
    
    
    reaper.PreventUIRefresh(-1) 
    reaper.UpdateArrange()
  end
  
  Init() 
  
