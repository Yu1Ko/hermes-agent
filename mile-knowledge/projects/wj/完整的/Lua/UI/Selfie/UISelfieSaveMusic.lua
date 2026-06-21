-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UISelfieSaveMusic
-- Date: 
-- Desc: 
-- ---------------------------------------------------------------------------------
UISelfieSaveMusic = class("UISelfieSaveMusic")
UISelfieSaveMusic.tCustomBGM = {}
function UISelfieSaveMusic.Init()
    CustomData.Register(CustomDataType.Role, "SelfieSaveMusic", UISelfieSaveMusic.tCustomBGM)
end

function UISelfieSaveMusic.UnInit()
    Event.UnRegAll(UISelfieSaveMusic)
    CustomData.Register(CustomDataType.Role, "SelfieSaveMusic", UISelfieSaveMusic.tCustomBGM)
end

function UISelfieSaveMusic.SaveCustomBGM(nBGMID, szName, nStartTime, nEndTime)
    local tBGM = {}
    tBGM.nBGMID = nBGMID
    tBGM.szCustomName = szName
    tBGM.nStartTime = nStartTime
    tBGM.nEndTime = nEndTime
    table.insert(UISelfieSaveMusic.tCustomBGM, tBGM)
end

function UISelfieSaveMusic.GetAllCustomBGM()
    return UISelfieSaveMusic.tCustomBGM
end

function UISelfieSaveMusic.GetCustomBGM(nIndex)
    return UISelfieSaveMusic.tCustomBGM and UISelfieSaveMusic.tCustomBGM[nIndex]
end

function UISelfieSaveMusic.DeleteCustomBGM(nIndex)
    if not UISelfieSaveMusic.tCustomBGM then
        return
    end

    table.remove(UISelfieSaveMusic.tCustomBGM, nIndex)
end
