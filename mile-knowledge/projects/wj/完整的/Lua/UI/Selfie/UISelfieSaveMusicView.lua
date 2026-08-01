-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UISelfieSaveMusicView
-- Date: 
-- Desc: 
-- ---------------------------------------------------------------------------------
local UISelfieSaveMusicView = class("UISelfieSaveMusicView")

function UISelfieSaveMusicView:OnEnter(nBGMID, nStartTime, nEndTime, fnSaveCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nBGMID = nBGMID
    self.nStartTime = nStartTime
    self.nEndTime = nEndTime
    self.fnSaveCallback = fnSaveCallback
    self:UpdateInfo()
end

function UISelfieSaveMusicView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieSaveMusicView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnRelease, EventType.OnClick, function()
        local szEditContent = UIHelper.GetText(self.EditBox)
        if string.is_nil(szEditContent) then
            TipsHelper.ShowNormalTip(g_tStrings.STR_SELFIE_BGM_SAVE_NULL1)
            return 
        end
        if string.find(szEditContent, " ", 1, true) ~= nil then
            TipsHelper.ShowNormalTip(g_tStrings.STR_SELFIE_BGM_SAVE_NULL2)
			return 
		end
        
        if not TextFilterCheck(UIHelper.UTF8ToGBK(szEditContent)) then
            OutputMessage("MSG_ANNOUNCE_RED", string.format(g_tStrings.STR_SELFIE_AI_SAVE_ILLEGAL, ""))
            return false
        end
        local tCustomGM = SelfieMusicData.GetAllCustomBGM()
        for _, v in ipairs(tCustomGM) do
            if v.szCustomName == szEditContent then
                local szMsg = string.format(g_tStrings.STR_SELFIE_AI_SAVE_REPEAT_FAILED, g_tStrings.STR_SELFIE_BGM_CUSTOM)
                OutputMessage("MSG_ANNOUNCE_RED", szMsg)
                return
            end
        end
    
        if table.get_len(tCustomGM) >= SelfieMusicData.nCustomMaxCount then
            OutputMessage("MSG_SYS", g_tStrings.STR_SELFIE_BGM_CUSTOM_COUNT_LIMIT)
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_SELFIE_BGM_CUSTOM_COUNT_LIMIT)
            return
        end

        SelfieMusicData.SaveCustomBGM(self.nBGMID, szEditContent, self.nStartTime, self.nEndTime)
        if self.fnSaveCallback then
            self.fnSaveCallback()
        end
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnRefuse, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UISelfieSaveMusicView:RegEvent()

end

function UISelfieSaveMusicView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UISelfieSaveMusicView:UpdateInfo()
    local tBGMInfo = Table_GetSelfieBGMInfo(self.nBGMID)
    UIHelper.SetString(self.LabelSongName, UIHelper.GBKToUTF8(tBGMInfo.szName))
    UIHelper.SetString(self.LabelSongTime, Timer.FormatMilliseconds(self.nEndTime - self.nStartTime, nil, true))

    UIHelper.SetText(self.EditBox, "")
end


return UISelfieSaveMusicView