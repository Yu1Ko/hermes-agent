-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetTaskTeamSubtitle
-- Date: 2023-02-28 10:55:22
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetTaskTeamSubtitle = class("UIWidgetTaskTeamSubtitle")

function UIWidgetTaskTeamSubtitle:OnEnter(szText, nFrame)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szText = szText
    self.nFrame = nFrame
    self.szImagePath = self.nFrame and UI_PQ_MainTile[self.nFrame] or nil
    self:UpdateInfo()
end

function UIWidgetTaskTeamSubtitle:OnExit()
    self.bInit = false
    self:SetBtnHintVis(false)
    self:SetDetailBtnVis(false)
    self:SetClickCallBack(nil)
    self:SetDetailClickCallBack(nil)
    self:UnRegEvent()
end

function UIWidgetTaskTeamSubtitle:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnHint, EventType.OnClick, function()
        if self.funcClick then
            self.funcClick()
        end
    end)
    UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function()
        if self.funcDetailClick then
            self.funcDetailClick()
        end
    end)
    UIHelper.BindUIEvent(self.BtnWeather, EventType.OnClick, function()
        if self.funcWeatherClick then
            self.funcWeatherClick()
        end
    end)
end

function UIWidgetTaskTeamSubtitle:RegEvent()
    
end

function UIWidgetTaskTeamSubtitle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTaskTeamSubtitle:UpdateInfo()
    UIHelper.SetString(self.LabelOtherSubtitle, self.szText)
    if self.szImagePath then
        UIHelper.SetSpriteFrame(self.ImgTaskMark,  self.szImagePath)
    end

    UIHelper.SetVisible(self.ImgTaskMark, self.szImagePath ~= nil)
    -- UIHelper.SetHeight(self._rootNode, 32)
    UIHelper.LayoutDoLayout(self._rootNode)
end

function UIWidgetTaskTeamSubtitle:SetFontSize(nFontSize)
    UIHelper.SetFontSize(self.LabelOtherSubtitle, nFontSize)
end

function UIWidgetTaskTeamSubtitle:CheckIsValid()
    return self.bInit
end

function UIWidgetTaskTeamSubtitle:SetBtnHintVis(bShow)
    UIHelper.SetVisible(self.BtnHint, bShow)
    UIHelper.LayoutDoLayout(self._rootNode)
end

function UIWidgetTaskTeamSubtitle:SetClickCallBack(funcClick)
    self.funcClick = funcClick
end

function UIWidgetTaskTeamSubtitle:SetDetailBtnVis(bShow)
    UIHelper.SetVisible(self.BtnDetail, bShow)
    UIHelper.LayoutDoLayout(self._rootNode)
end

function UIWidgetTaskTeamSubtitle:SetDetailClickCallBack(funcClick)
    self.funcDetailClick = funcClick
end

function UIWidgetTaskTeamSubtitle:SetWeatherBtnVis(bShow)
    UIHelper.SetVisible(self.BtnWeather, bShow)
    UIHelper.LayoutDoLayout(self._rootNode)
end

function UIWidgetTaskTeamSubtitle:SetWeatherIcon(szIconPath)
    UIHelper.SetSpriteFrame(self.ImgWeather, szIconPath)
end

function UIWidgetTaskTeamSubtitle:SetWeatherClickCallBack(funcClick)
    self.funcWeatherClick = funcClick
end


return UIWidgetTaskTeamSubtitle