-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetTaskBuff
-- Date: 2023-05-08 16:17:22
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetTaskBuff = class("UIWidgetTaskBuff")

function UIWidgetTaskBuff:OnEnter(tbBuffList)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbBuffList = tbBuffList
    self:UpdateInfo()
end

function UIWidgetTaskBuff:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetTaskBuff:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBuff, EventType.OnClick, function()
        self:OpenBuffTip()
    end)
end

function UIWidgetTaskBuff:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetTaskBuff:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTaskBuff:UpdateInfo()
    for index, WidgetBuff in ipairs(self.tbWidgetBuff) do
        local tbInfo = self.tbBuffList[index]
        if tbInfo then
            local scriptView = UIHelper.GetBindScript(WidgetBuff)
            scriptView:OnEnter(tbInfo)
        end
        UIHelper.SetVisible(WidgetBuff, tbInfo ~= nil)
    end
    UIHelper.LayoutDoLayout(self.LayoutBuff)
end


function UIWidgetTaskBuff:OpenBuffTip()
    -- self.tipsView = 

    local tbBuffList = {}
    for index, tbBuffInfo in ipairs(self.tbBuffList) do
        local tbInfo = {}
        tbInfo.dwID = tbBuffInfo.nBuffID
        tbInfo.nLevel = tbBuffInfo.nBuffLevel
        tbInfo.nStackNum = tbBuffInfo.nStackNum
        tbInfo.nLeftTime = tbBuffInfo.nLeftTime
        tbInfo.bShowTime = true
        table.insert(tbBuffList, tbInfo)
    end

    local nX = UIHelper.GetWorldPositionX(self.BtnBuff)
    local nY = UIHelper.GetWorldPositionY(self.BtnBuff)
    if #tbBuffList > 0 then
        local _, script = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetMainCityBuffContentTip, nX, nY)
        script:UpdatePlayerInfo(g_pClientPlayer.dwID, tbBuffList)
    end
end



return UIWidgetTaskBuff