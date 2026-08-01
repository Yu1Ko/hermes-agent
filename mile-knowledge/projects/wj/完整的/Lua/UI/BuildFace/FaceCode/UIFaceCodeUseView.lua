-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIFaceCodeUseView
-- Date: 2024-03-19 19:50:36
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIFaceCodeUseView = class("UIFaceCodeUseView")

function UIFaceCodeUseView:OnEnter(nDataType)
    self.nDataType = nDataType
    self.bBody = nDataType and nDataType == SHARE_DATA_TYPE.BODY
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bLoginWeb = true -- 已经不走原来的web登录流程了，这里默认是true
    self.bIsLogin = true
    if PlayerData.GetClientPlayer() then
        self.bIsLogin = false
    end

    local szPlaceHolder = "请输入%s分享码"
    local szTitle = "导入云端%s分享码"
    local szPrint = "导入%s"
    local szDataType = g_tStrings.tShareStationTitle[self.nDataType]
    szPlaceHolder = string.format(szPlaceHolder, szDataType)
    szTitle = string.format(szTitle, szDataType)
    szPrint = string.format(szPrint, szDataType)

    UIHelper.SetPlaceHolder(self.EditBox, szPlaceHolder)
    UIHelper.SetString(self.LabelTitle, szTitle)
    UIHelper.SetString(self.LabelPrint, szPrint)

    -- if self.bBody then
        UIHelper.SetMaxLength(self.EditBox, 26)
    -- else
    --     UIHelper.SetMaxLength(self.EditBox, 16)
    -- end

    ShareCodeData.Init()
    self:UpdateInfo()
end

function UIFaceCodeUseView:OnExit()
    self.bInit = false
    ShareCodeData.UnInit()
end

function UIFaceCodeUseView:BindUIEvent()

    UIHelper.RegisterEditBoxChanged(self.EditBox, function()
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        if self.bBusy then
            local szTips = "正在导入%s，请稍候"
            local szDataType = g_tStrings.tShareStationTitle[self.nDataType]
            szTips = string.format(szTips, szDataType)
            TipsHelper.ShowNormalTip(szTips)
            -- return
        end
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        if self.bBusy then
            local szTips = "正在导入%s，请稍候"
            local szDataType = g_tStrings.tShareStationTitle[self.nDataType]
            szTips = string.format(szTips, szDataType)
            TipsHelper.ShowNormalTip(szTips)
            -- return
        end
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnPrint, EventType.OnClick, function(btn)
        local szCode = UIHelper.GetText(self.EditBox)
        local szTips = "正在导入%s，请稍候"
        local szDataType = g_tStrings.tShareStationTitle[self.nDataType]
        szTips = string.format(szTips, szDataType)
        ShareCodeData.ApplyData(self.bIsLogin, self.nDataType, szCode)

        self.bBusy = true
        TipsHelper.ShowNormalTip(szTips)
        UIHelper.SetButtonState(self.BtnPrint, BTN_STATE.Disable, szTips)
    end)

    UIHelper.BindUIEvent(self.BtnPaste, EventType.OnClick, function(btn)
        local szCode = GetClipboard()
        szCode = string.match(szCode, "[0-9A-Za-z]*")
        if not string.is_nil(szCode) then
            UIHelper.SetText(self.EditBox, szCode)
            self:UpdateInfo()
        end
    end)
end

function UIFaceCodeUseView:RegEvent()
    Event.Reg(self, EventType.OnShareCodeRsp, function (szKey, tInfo)
        if string.match(szKey, "GET_DATA") then
            if tInfo and tInfo.code and tInfo.code ~= 1 then
                self.bBusy = false
                self:UpdateInfo()
            end
        end
    end)

    Event.Reg(self, EventType.OnDownloadShareCodeData, function (bSuccess, szShareCode, szFilePath, nDataType)
        if bSuccess and ShareCodeData.szCurGetShareCode == szShareCode then
            if self.nDataType == nDataType and nDataType == SHARE_DATA_TYPE.EXTERIOR then
                local tData = ShareCodeData.GetShareCodeData(szShareCode)
                if not tData or not tData.tExterior then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_SHARE_STATION_DOWNLOAD_FAIL)
                    self.bBusy = false
                    self:UpdateInfo()
                    return
                end

                if tData and tData.tExterior then
                    UIMgr.Open(VIEW_ID.PaneShareStationImportPop, tData.tExterior)
                    ShareCodeData.AddDataHeat(SHARE_DATA_TYPE.EXTERIOR, szShareCode)
                    Timer.Add(self, 0.1, function ()
                        UIMgr.Close(self)
                    end)
                end
                return
            end
            Timer.AddFrame(self, 1, function ()
                UIMgr.Close(self)
            end)
        else
            self.bBusy = false
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "LOGIN_NOTIFY", function(nEvent)
		if nEvent == LOGIN.REQUEST_LOGIN_GAME_SUCCESS or nEvent == LOGIN.MISS_CONNECTION then
			Timer.Add(self, 0.3, function ()
                UIMgr.Close(self)
            end)
		end
    end)
end

function UIFaceCodeUseView:UpdateInfo()
    if self.bBusy then
        return
    end

    local szCode = UIHelper.GetText(self.EditBox)
    szCode = string.match(szCode, "[0-9A-Za-z]*")
    UIHelper.SetText(self.EditBox, szCode)

    UIHelper.SetButtonState(self.BtnPrint, BTN_STATE.Normal)
    if not self.bLoginWeb then
        UIHelper.SetButtonState(self.BtnPrint, BTN_STATE.Disable, "正在登录云端服务器，请稍候")
    elseif not string.is_nil(szCode) then
        UIHelper.SetButtonState(self.BtnPrint, BTN_STATE.Normal)
    else
        local szTips = "请输入%s分享码"
        local szDataType = g_tStrings.tShareStationTitle[self.nDataType]
        szTips = string.format(szTips, szDataType)

        UIHelper.SetButtonState(self.BtnPrint, BTN_STATE.Disable, szTips)
    end
end

return UIFaceCodeUseView