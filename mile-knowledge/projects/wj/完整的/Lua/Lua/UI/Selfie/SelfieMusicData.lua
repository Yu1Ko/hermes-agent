SelfieMusicData = class("SelfieMusicData")
local self = SelfieMusicData

SelfieMusicData.nCustomMaxCount = 20
local tMusicDataModel = {}
function SelfieMusicData.Init()
    
end

function SelfieMusicData.UnInit()
    if self.tCustomBGM then
		CustomData.Register(CustomDataType.Role, "SelfieSaveMusic", self.tCustomBGM)
	end
    Event.UnRegAll(SelfieMusicData)
end

function SelfieMusicData.CheckCustomBGMData()
	if not self.tCustomBGM then
		self.tCustomBGM = CustomData.GetData(CustomDataType.Role, "SelfieSaveMusic") or {}
	end
end

function SelfieMusicData.Clear()
    self.tCustomBGM = nil
end

function SelfieMusicData.SaveCustomBGM(nBGMID, szName, nStartTime, nEndTime)
    self.CheckCustomBGMData()
    local tBGM = {}
    tBGM.nBGMID = nBGMID
    tBGM.szCustomName = szName
    tBGM.nStartTime = nStartTime
    tBGM.nEndTime = nEndTime
    table.insert(self.tCustomBGM, tBGM)
    CustomData.Register(CustomDataType.Role, "SelfieSaveMusic", self.tCustomBGM)
end

function SelfieMusicData.GetAllCustomBGM()
    self.CheckCustomBGMData()
    return self.tCustomBGM
end

function SelfieMusicData.GetCustomBGM(nIndex)
    self.CheckCustomBGMData()
    return self.tCustomBGM and self.tCustomBGM[nIndex]
end

function SelfieMusicData.DeleteCustomBGM(nIndex)
    if not self.tCustomBGM then
        return
    end
    table.remove(self.tCustomBGM, nIndex)
    CustomData.Register(CustomDataType.Role, "SelfieSaveMusic", self.tCustomBGM)
end


function SelfieMusicData.SetDataModel(dataModel)
    tMusicDataModel = dataModel
end

function SelfieMusicData.GetDataModel()
    return tMusicDataModel
end

SelfieMusicData.MIN_BGM_CUT_TIME = 5000
function SelfieMusicData.GetMusicClipStartTime(nStartTime, nTotalTime, nEndTime)
    local nResultTime = nStartTime
    local nMinStartTime = 0
    local nMaxStartTime = math.max(math.min(nTotalTime, nEndTime), self.MIN_BGM_CUT_TIME)
    if nResultTime < nMinStartTime then
        nResultTime = nMinStartTime
    end
    if nResultTime > nMaxStartTime - self.MIN_BGM_CUT_TIME then
        nResultTime = nMaxStartTime - self.MIN_BGM_CUT_TIME
    end
    return nResultTime
end

function SelfieMusicData.GetMusicClipEndTime(nEndTime, nTotalTime, nStartTime)
    local nResultTime = nEndTime
    local nMinEndTime = math.max(0, nStartTime)
    local nMaxEndTime = nTotalTime
    if nResultTime < nMinEndTime + self.MIN_BGM_CUT_TIME then
        nResultTime = nMinEndTime + self.MIN_BGM_CUT_TIME
    end

    if nResultTime > nMaxEndTime then
        nResultTime = nMaxEndTime
    end
    return nResultTime
end
-------------------------- 更新帧 ----------------------------------
local m_fnProgress = nil
local m_fnPlayStop = nil
function SelfieMusicData.SetProgressCallback(fnCallback)
    m_fnProgress = fnCallback
end

function SelfieMusicData.SetPlayStopCallback(fnCallback)
    m_fnPlayStop = fnCallback
end

function SelfieMusicData.OnRePlayBGM(nStartTime, nEndTime)
    local nBGMID = tMusicDataModel.nSelBGMID
  
    self.OnStopBgMusic() 
    local tBGMInfo = Table_GetSelfieBGMInfo(nBGMID)
    local nRelStartTime = nStartTime or 0
    local nRelEndtime = nEndTime or tBGMInfo.nTime
    local nRelTotalTime = nRelEndtime - nRelStartTime
    local nRelPlayStartTime = 0
    if tMusicDataModel.nTagType == SELFIE_CAMERA_RIGHT_TAG.CUSTOM then
        local tCustom = self.GetCustomBGM(tMusicDataModel.nSelCustomBGMID)
        nBGMID = tCustom.nBGMID
        nRelStartTime = tCustom.nStartTime
        nRelEndtime = tCustom.nEndTime
        nRelTotalTime = nRelEndtime - nRelStartTime
        nRelPlayStartTime = nRelStartTime
    end
   
    local szBgmEvent = tBGMInfo.szBgmEvent
    tMusicDataModel.szPlayBgmEvent = szBgmEvent

    tMusicDataModel.nBgmStartTime = 0
    tMusicDataModel.nBgmEndTime = tBGMInfo.nTime
    tMusicDataModel.nTotalBgmTime = tBGMInfo.nTime

    tMusicDataModel.nPlayEndTime = nRelEndtime
    tMusicDataModel.nPlayStartTime = nRelPlayStartTime
    tMusicDataModel.nPlayTotalBgmTime = nRelEndtime - nRelPlayStartTime
    LOG.INFO(" SelfieMusicData.OnRePlayBGM  Name:%s,nStartTime:%s,EndTime:%s,TotalTime:%s",tostring(szBgmEvent),tostring(nRelStartTime),tostring(nRelEndtime),tostring(nRelTotalTime))
    self.PlayBgMusicWithPos(nBGMID, nRelStartTime)
    tMusicDataModel.nPlayState = BGM_PLAY_STATUS.PLAYING
end

function SelfieMusicData.ActiviteProgressTimer(bActivite)
    if bActivite then
        if self.nProgressTimeID then
            Timer.DelTimer(self, self.nProgressTimeID)
            self.nProgressTimeID = nil
        end
        self.nProgressTimeID = Timer.AddFrameCycle(self, 2, function ()
            self.RefreshBGMTime()
        end)
    else
        if self.nProgressTimeID then
            Timer.DelTimer(self, self.nProgressTimeID)
            self.nProgressTimeID = nil
        end
    end
end

function SelfieMusicData.OnStopBgMusic(bTryPlayLast)
    self.ActiviteProgressTimer(false)
    tMusicDataModel.nPlayState = BGM_PLAY_STATUS.STOP
    local szBgmEvent = tMusicDataModel.szPlayBgmEvent
    if szBgmEvent then
        SoundMgr.StopBgMusic(true)
        SoundMgr.StopUIBgMusic(szBgmEvent, bTryPlayLast)
        tMusicDataModel.szPlayBgmEvent = nil
    end
    if m_fnPlayStop then
        m_fnPlayStop()
    end
end

function SelfieMusicData.RefreshBGMTime()
    if tMusicDataModel.nBgmPlayTickCount and tMusicDataModel.nBgmPlayTime and tMusicDataModel.nPlayStartTime and tMusicDataModel.nPlayEndTime then
        local nBgmPlayTime = tMusicDataModel.nBgmPlayTime
        local nTime = GetTickCount() - tMusicDataModel.nBgmPlayTickCount + nBgmPlayTime 
        local nTrueEndTime = tMusicDataModel.nPlayEndTime
        if tMusicDataModel.nSelBGMID and nBgmPlayTime > tMusicDataModel.nPlayEndTime then
            nTrueEndTime = tMusicDataModel.nPlayTotalBgmTime
        end

        if nTime > nTrueEndTime then
            tMusicDataModel.nBgmPlayTickCount = nil
            tMusicDataModel.nBgmPlayTime = nil
            self.OnStopBgMusic(tMusicDataModel.bStopTryPlayLast)
            tMusicDataModel.bStopTryPlayLast = false
            if tMusicDataModel.nSelBGMID then
                if m_fnProgress then
                    m_fnProgress(1)
                end
            end
            return
        else
            tMusicDataModel.nBgmCurTime = nTime
        end
        
        if tMusicDataModel.nSelBGMID then
            local fProgress = (nTime - (tMusicDataModel.nPlayStartTime or 0))  / tMusicDataModel.nPlayTotalBgmTime
            if m_fnProgress then
                m_fnProgress(fProgress)
            end
            
        end
    end
end

function SelfieMusicData.PlayBgMusicWithPos(nBGMID, nStartTime, bStopTryPlayLast)
    local szBgmEvent = Table_GetSelfieBGMEvent(nBGMID)
    SoundMgr.PlayUIBgMusic(szBgmEvent)
    SetBgMusicStartPos(nStartTime)
    tMusicDataModel.bStopTryPlayLast = bStopTryPlayLast and true or false
    tMusicDataModel.szPlayBgmEvent = szBgmEvent
    tMusicDataModel.nBgmPlayTickCount = GetTickCount()
    tMusicDataModel.nBgmPlayTime = nStartTime
    tMusicDataModel.nPlayState = BGM_PLAY_STATUS.PLAYING
    SelfieMusicData.ActiviteProgressTimer(true)
end


function SelfieMusicData.IsCanSaveCustom()
    SelfieMusicData.CheckCustomBGMData()
    local nCustomCount = table.get_len(self.tCustomBGM or {})
    return nCustomCount <= SelfieMusicData.nCustomMaxCount
end

function SelfieMusicData.GetCustomCountDesc()
    SelfieMusicData.CheckCustomBGMData()
    local nCustomCount = table.get_len(self.tCustomBGM or {})
    return string.format("%d/%d",nCustomCount,SelfieMusicData.nCustomMaxCount)
end
--------------------------------------------------------------------
