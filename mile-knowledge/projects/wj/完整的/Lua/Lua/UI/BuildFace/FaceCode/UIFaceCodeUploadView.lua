-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIFaceCodeUploadView
-- Date: 2024-03-19 09:50:44
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIFaceCodeUploadView = class("UIFaceCodeUploadView")

local MAX_NAME_LEN = 8

function UIFaceCodeUploadView:OnEnter(szFileName, bBody)
    self.bBody = bBody
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bIsLogin = true
    if PlayerData.GetClientPlayer() then
        self.bIsLogin = false
    end

    if self.bBody then
        UIHelper.SetPlaceHolder(self.EditBox, "请输入体型名称")
        UIHelper.SetString(self.LabelTitle, "上传体型到云端")

        BodyCodeData.Init()
        BodyCodeData.LoginAccount(self.bIsLogin)
    else
        UIHelper.SetPlaceHolder(self.EditBox, "请输入脸型名称")
        UIHelper.SetString(self.LabelTitle, "上传脸型到云端")

        FaceCodeData.Init()
        FaceCodeData.LoginAccount(self.bIsLogin)
    end

    UIHelper.SetText(self.EditBox, szFileName)
    self:UpdateInfo()
end

function UIFaceCodeUploadView:OnExit()
    self.bInit = false
    FaceCodeData.UnInit()
end

function UIFaceCodeUploadView:BindUIEvent()
    UIHelper.RegisterEditBoxChanged(self.EditBox, function()
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnPrint, EventType.OnClick, function(btn)
        local szFileName = UIHelper.GetText(self.EditBox)
        if not TextFilterCheck(UIHelper.UTF8ToGBK(szFileName)) then --过滤文字
            TipsHelper.ShowNormalTip("您输入的备注名中含有敏感字词。")
            return
        end

        if self.bBody then
            local tBody = BuildBodyData.tNowBodyData
            local bSucc, szMsg
            local bOld = false
            bSucc, szMsg = BuildBodyData.ExportData(szFileName, tBody, BuildFaceData.nRoleType, self.bIsLogin, true)
            if not bSucc and szMsg then
                TipsHelper.ShowNormalTip(szMsg)
            end

            if bSucc then
                BodyCodeData.ReqGetUploadToken(szFileName, szMsg, ".dat")
                self.bBusy = true
                TipsHelper.ShowNormalTip("正在上传体型，请稍候")
                UIHelper.SetButtonState(self.BtnPrint, BTN_STATE.Disable, "正在上传体型，请稍候")
            end
        else
            local tFace = BuildFaceData.tNowFaceData
            local bSucc, szMsg
            local bOld = false
            if tFace.bNewFace then
                bSucc, szMsg = NewFaceData.ExportData(szFileName, tFace, BuildFaceData.nRoleType, self.bIsLogin, true)
            elseif tFace.tFaceData and not tFace.tFaceData.bNewFace then
                bSucc, szMsg = NewFaceData.ExportOldData(szFileName, tFace.tFaceData, BuildFaceData.nRoleType, self.bIsLogin, true)
                bOld = true
            end
            if not bSucc and szMsg then
                TipsHelper.ShowNormalTip(szMsg)
            end

            if bSucc then
                if bOld then
                    FaceCodeData.ReqGetFaceUploadToken(szFileName, szMsg, ".dat")
                else
                    FaceCodeData.ReqGetFaceUploadToken(szFileName, szMsg, ".ini")
                end
                self.bBusy = true
                TipsHelper.ShowNormalTip("正在上传脸型，请稍候")
                UIHelper.SetButtonState(self.BtnPrint, BTN_STATE.Disable, "正在上传脸型，请稍候")
            end
        end
    end)
end

function UIFaceCodeUploadView:RegEvent()
    if self.bBody then
        Event.Reg(self, EventType.OnBodyCodeRsp, function (szKey, tInfo)
            if szKey == "LOGIN_ACCOUNT" then
                if BodyCodeData.szSessionID then
                    self.bLoginWeb = true
                    self:UpdateInfo()
                else
                    TipsHelper.ShowNormalTip("连接云端服务器失败，请稍候重试")
                    UIMgr.Close(self)
                end
            elseif szKey == "GET_UPLOAD_TOKEN" then
                if tInfo and tInfo.code and tInfo.code ~= 1 then
                    Timer.AddFrame(self, 1, function ()
                        local szFileName = UIHelper.GetText(self.EditBox)
                        if tInfo.code == -20104 then
                            local dialog = UIHelper.ShowConfirm("无法上传，云端体型存储已达上限（30/30），请在体型列表清理后尝试", function ()
                                local scriptView = UIMgr.Open(VIEW_ID.PanelBodyCodeList, self.bIsLogin)
                                scriptView:SetCloseCallback(function ()
                                    UIMgr.Open(VIEW_ID.PanelPrintFaceToCloud, szFileName, self.bBody)
                                end)
                            end)
                            dialog:SetButtonContent("Confirm", "去清理")
                        end
                        UIMgr.Close(self)
                    end)
                end
            elseif szKey == "UPLOAD_BODY" then
                Timer.AddFrame(self, 1, function ()
                    UIMgr.Close(self)
                end)
            end
        end)
    else
        Event.Reg(self, EventType.OnFaceCodeRsp, function (szKey, tInfo)
            if szKey == "LOGIN_ACCOUNT" then
                if FaceCodeData.szSessionID then
                    self.bLoginWeb = true
                    FaceCodeData.ReqGetConfig()
                    self:UpdateInfo()
                else
                    TipsHelper.ShowNormalTip("连接云端服务器失败，请稍候重试")
                    UIMgr.Close(self)
                end
            elseif szKey == "GET_UPLOAD_TOKEN" then
                if tInfo and tInfo.code and tInfo.code ~= 1 then
                    Timer.AddFrame(self, 1, function ()
                        local szFileName = UIHelper.GetText(self.EditBox)
                        if tInfo.code == -20104 then
                            local nUploadLimit = 30
                            if FaceCodeData.tbFaceListConfig then
                                nUploadLimit = FaceCodeData.tbFaceListConfig.nUploadLimit
                            end
                            local dialog = UIHelper.ShowConfirm(string.format("无法上传，云端脸型存储已达上限（%d/%d），请在脸型列表清理后尝试", nUploadLimit, nUploadLimit), function ()
                                local scriptView = UIMgr.Open(VIEW_ID.PanelCoinFaceCodeList, self.bIsLogin)
                                scriptView:SetCloseCallback(function ()
                                    UIMgr.Open(VIEW_ID.PanelPrintFaceToCloud, szFileName)
                                end)
                            end)
                            dialog:SetButtonContent("Confirm", "去清理")
                        end
                        UIMgr.Close(self)
                    end)
                end
            elseif szKey == "UPLOAD_FACE" then
                Timer.AddFrame(self, 1, function ()
                    UIMgr.Close(self)
                end)
            end
        end)
    end

    Event.Reg(self, "LOGIN_NOTIFY", function(nEvent)
		if nEvent == LOGIN.REQUEST_LOGIN_GAME_SUCCESS or nEvent == LOGIN.MISS_CONNECTION then
			Timer.Add(self, 0.3, function ()
                UIMgr.Close(self)
            end)
		end
    end)
end

function UIFaceCodeUploadView:UpdateInfo()
    if self.bBusy then
        return
    end

    local szFileName = UIHelper.GetText(self.EditBox)
    szFileName = Lib.FilterSpecString(szFileName)
    UIHelper.SetText(self.EditBox, szFileName)

    UIHelper.SetButtonState(self.BtnPrint, BTN_STATE.Normal)
    if not self.bLoginWeb then
        UIHelper.SetButtonState(self.BtnPrint, BTN_STATE.Disable, "正在登录云端服务器，请稍候")
    elseif not string.is_nil(szFileName) then
        UIHelper.SetButtonState(self.BtnPrint, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnPrint, BTN_STATE.Disable, "请输入脸型名称")
    end

    if string.is_nil(szFileName) then
        UIHelper.SetString(self.LabelLimit, string.format("%d/%d", 0, MAX_NAME_LEN))
    else
        UIHelper.SetString(self.LabelLimit, string.format("%d/%d", string.getCharLen(szFileName), MAX_NAME_LEN))
    end
end

return UIFaceCodeUploadView