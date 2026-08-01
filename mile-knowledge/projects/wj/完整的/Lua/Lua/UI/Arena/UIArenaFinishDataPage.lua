-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaFinishDataPage
-- Date: 2022-12-15 10:33:37
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaFinishDataPage = class("UIArenaFinishDataPage")

function UIArenaFinishDataPage:OnEnter(tbData)
    self.tbData = tbData
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIArenaFinishDataPage:OnExit()
    self.bInit = false
end

function UIArenaFinishDataPage:BindUIEvent()

end

function UIArenaFinishDataPage:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIArenaFinishDataPage:UpdateInfo()
    self:UpdateSelfInfo()
    self:UpdateEnemyInfo()
end

function UIArenaFinishDataPage:UpdateSelfInfo()
    local tbSelfPlayerInfo = self.tbData.tbPlayerInfo[self.tbData.nSelfSide] or {}
    local tbScriptPlayer = self.tbScriptPlayerL
    if self.tbData.nSelfSide == 1 then
        tbScriptPlayer = self.tbScriptPlayerR
    end
    for i, cell in ipairs(tbScriptPlayer) do
        local scriptCell = UIHelper.GetBindScript(cell)
        local tbInfo = tbSelfPlayerInfo[i]
        if tbInfo then
            UIHelper.SetVisible(cell, true)
            scriptCell:OnEnter(tbInfo)
            if  self.tbData.nSelfSide == 1 then
                scriptCell:SetWidgetPersonalCard(self.WidgetPersonalCardRight)
            else
                scriptCell:SetWidgetPersonalCard(self.WidgetPersonalCardLeft)
            end
        else
            UIHelper.SetVisible(cell, false)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutPlayerLeft)
end

function UIArenaFinishDataPage:UpdateEnemyInfo()
    local tbSelfPlayerInfo = self.tbData.tbPlayerInfo[self.tbData.nEnemySide] or {}
    local tbScriptPlayer = self.tbScriptPlayerL
    if self.tbData.nEnemySide == 1 then
        tbScriptPlayer = self.tbScriptPlayerR
    end
    for i, cell in ipairs(tbScriptPlayer) do
        local scriptCell = UIHelper.GetBindScript(cell)
        local tbInfo = tbSelfPlayerInfo[i]
        if tbInfo then
            UIHelper.SetVisible(cell, true)
            scriptCell:OnEnter(tbInfo)
            if self.tbData.nEnemySide == 1 then
                scriptCell:SetWidgetPersonalCard(self.WidgetPersonalCardRight)
            else
                scriptCell:SetWidgetPersonalCard(self.WidgetPersonalCardLeft)
            end
        else
            UIHelper.SetVisible(cell, false)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutPlayerRight)
end


return UIArenaFinishDataPage