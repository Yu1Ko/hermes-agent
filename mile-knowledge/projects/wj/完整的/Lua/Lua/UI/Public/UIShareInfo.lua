-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIShareInfo
-- Date: 2024-11-11 15:58:08
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIShareInfo = class("UIShareInfo")

-- bNormalMode 为true时，表示只截一张图，为false时截两张图，一张带信息，一张不带信息，信息在tbShowWidget节点下
function UIShareInfo:OnEnter(nViewID, bNormalMode)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.prepareCaptureCallback = nil
    self.closeCaptureCallback = nil

    self.nViewID = nViewID
    self.bNormalMode = bNormalMode
    self:UpdateInfo()
end

function UIShareInfo:OnExit()
    self.bInit = false
end

function UIShareInfo:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnShare, EventType.OnClick, function(btn)
        if self.prepareCaptureCallback then
            self.prepareCaptureCallback()
        end

        if self.bNormalMode then
            for _, widget in ipairs(self.tbHideWidget) do
                UIHelper.SetVisible(widget, false)
            end

            self:CaptureScreenNoMessage()
        else
            for _, widget in ipairs(self.tbHideWidget) do
                UIHelper.SetVisible(widget, false)
            end

            for _, widget in ipairs(self.tbShowWidget) do
                UIHelper.SetVisible(widget, true)
            end

            self:CaptureScreenByMessage()
        end
    end)

end

function UIShareInfo:RegEvent()
    Event.Reg(self, EventType.OnPhotoShareWidgetShow, function (bShow)
        for _, widget in ipairs(self.tbHideWidget) do
            UIHelper.SetVisible(widget, bShow)
        end
    end)
end

function UIShareInfo:UpdateInfo()
    UIHelper.SetString(self.LabelSharePlayerName, UIHelper.GBKToUTF8(PlayerData.GetPlayerName()))

    local _, szUserSever = WebUrl.GetServerName()
    UIHelper.SetString(self.LabelShareServer, szUserSever)

    local nPlayerID = PlayerData.GetPlayerID()
    self.scriptHead = self.scriptHead or UIHelper.GetBindScript(self.WidgetShareHead)
    self.scriptHead:OnEnter(nPlayerID)

    UIHelper.SetVisible(self.ImgCode, AppReviewMgr.IsOpenShaderCode())
end

function UIShareInfo:CaptureScreenByMessage()
    -- 此时在截一张带信息的全屏图
    UIHelper.SetVisible(self.WidgetInfo, true)
    Timer.Add(self , 0.2 , function ()
        UIHelper.CaptureScreen(function (pRetTexture , pImage)
            if safe_check(pRetTexture) then
                pRetTexture:retain()
            end
            self.pMessageTexture = pRetTexture
            self.pMessageImage = pImage
            UIHelper.SetVisible(self.WidgetInfo , false)
            self:CaptureScreenNoMessage()
        end, 1 , true)
    end)
end

function UIShareInfo:CaptureScreenNoMessage()
    -- 此时在截一张不带信息的全屏图
    Timer.AddFrame(self , 2 , function ()
        local folder = GetFullPath("dcim/")
        local dt = TimeToDate(GetCurrentTime())
        CPath.MakeDir(folder)
        local fileName = string.format("%04d%02d%02d%02d%02d%02d.png",dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second)
        UIHelper.CaptureScreen(function (pRetTexture , pImage)
            self.nPhotoshareViewID = VIEW_ID.PanelCameraPhotoShare
            if not UIMgr.GetView(self.nPhotoshareViewID) then
                local shareScript = UIMgr.Open(self.nPhotoshareViewID, pRetTexture, pImage, folder, fileName, function ()
                    if self.closeCaptureCallback then
                        self.closeCaptureCallback()
                    end

                    if self.bNormalMode then
                        for _, widget in ipairs(self.tbHideWidget) do
                            UIHelper.SetVisible(widget, true)
                        end
                    else
                        for _, widget in ipairs(self.tbHideWidget) do
                            UIHelper.SetVisible(widget, true)
                        end

                        for _, widget in ipairs(self.tbShowWidget) do
                            UIHelper.SetVisible(widget, false)
                        end
                    end

                    if self.nViewID then
                        UIMgr.Close(self.nViewID)
                    end
                end, self.pMessageImage, not self.bNormalMode)

                if self.bNormalMode then
                    shareScript:SetLogoNotHide(false)
                    shareScript:EnableScaleSave(true)
                else
                    shareScript:SetChangeTexture(self.pMessageTexture)
                    shareScript:HidePlayerInfoToggle()
                    shareScript:EnableScaleSave(false)
                end
            end
        end, 1 , true)
    end)
end

function UIShareInfo:SetPrepareCaptureCallback(cb)
    self.prepareCaptureCallback = cb
end

function UIShareInfo:SetCloseCaptureCallback(cb)
    self.closeCaptureCallback = cb
end

return UIShareInfo