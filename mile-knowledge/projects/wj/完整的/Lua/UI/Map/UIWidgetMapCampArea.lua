-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetMapCampArea
-- Date: 2025-03-19 16:57:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetMapCampArea = class("UIWidgetMapCampArea")

function UIWidgetMapCampArea:OnEnter(tbInfo, nWidth, nHeight)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetMapCampArea:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMapCampArea:BindUIEvent()
    
end

function UIWidgetMapCampArea:RegEvent()
    Event.Reg(self, "ON_MIDDLE_MAP_SCALE_CHANGE", function()
        if not self.nLogicX or not self.nLogicY then
            return
        end

        Event.Dispatch("ON_MIDDLE_UPDATE_SIGN_BUTTON_POS", self, self.nLogicX, self.nLogicY)
    end)

    Event.Reg(self, "FIGHT_HINT", function()
        UIHelper.SetVisible(self.ImgCampArea_Fight, g_pClientPlayer.bFightState)
    end)
end

function UIWidgetMapCampArea:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end




function UIWidgetMapCampArea:SetPosition(nX, nY, nLogicX, nLogicY, nScale)
    self.nX, self.nY, self.nLogicX, self.nLogicY = nX, nY, nLogicX, nLogicY
    self._rootNode:setPosition(nX, nY)
    if nScale then
        UIHelper.SetScale(self._rootNode, nScale, nScale)
    end
end

function UIWidgetMapCampArea:UpdateCampAreaHighLight(nPQID)
    UIHelper.SetVisible(self.ImgCampArea_Light, nPQID == self.tbInfo.nPQID)
end

function UIWidgetMapCampArea:OnShow(tbInfo, nScale)
    if nScale then
        UIHelper.SetScale(self._rootNode, nScale, nScale)
    end
    self.tbInfo = tbInfo
    self:UpdateInfo()
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMapCampArea:UpdateInfo()
    if not self.tbInfo then return end
    local nWidth, nHeight = CELL_LENGTH, CELL_LENGTH
    nWidth, nHeight = nWidth * self.tbInfo.nRegionW, nHeight * self.tbInfo.nRegionH
    UIHelper.SetContentSize(self._rootNode, nWidth, nHeight)
    UIHelper.SetContentSize(self.ImgCampArea_Normal, nWidth, nHeight)
    UIHelper.SetContentSize(self.ImgCampArea_Fight, nWidth, nHeight)
    UIHelper.SetContentSize(self.ImgCampArea_Light, nWidth, nHeight)
    UIHelper.SetPosition(self.ImgCampArea_Normal, 0, 0)
    UIHelper.SetPosition(self.ImgCampArea_Fight, 0, 0)
    UIHelper.SetPosition(self.ImgCampArea_Light, 0, 0)
    UIHelper.SetVisible(self.ImgCampArea_Fight, g_pClientPlayer.bFightState)
end


return UIWidgetMapCampArea