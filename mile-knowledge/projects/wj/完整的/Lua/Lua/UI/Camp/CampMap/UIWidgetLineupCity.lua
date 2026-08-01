-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetLineupCity
-- Date: 2023-07-25 16:27:04
-- Desc: WidgetLineupCity 阵营沙盘-攻防概况
-- ---------------------------------------------------------------------------------

local UIWidgetLineupCity = class("UIWidgetLineupCity")

function UIWidgetLineupCity:OnEnter(dwMapID, szPerson, nCopyIndex, nTipType)
    self.dwMapID = dwMapID
    self.szPerson = szPerson
    self.nCopyIndex = nCopyIndex

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(nTipType)
end

function UIWidgetLineupCity:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetLineupCity:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCityGo, EventType.OnClick, function()
        if self.dwMapID then
            CampData.CampTransfer(self.dwMapID, self.nCopyIndex)
        end
    end)
end

function UIWidgetLineupCity:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetLineupCity:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetLineupCity:UpdateInfo(nTipType)
    local dwMapID = self.dwMapID
    local szPerson = self.szPerson
    local nCopyIndex = self.nCopyIndex
    local hScene      = GetClientScene()
    local dwCurMapID  = hScene.dwMapID
    local nCurCopy    = hScene.nCopyIndex
    if dwCurMapID == 656 then
        dwCurMapID = 216
        nCurCopy = nCurCopy + 1
    end


    local szMapName = UIHelper.GBKToUTF8(Table_GetMapName(dwMapID))
    if nCopyIndex then
        local szName = FormatString(g_tStrings.STR_CAMP_BATTLE_BRANCH_NAME, szMapName, nCopyIndex)
        UIHelper.SetString(self.LabelLineupTitle, szName)
    else
        UIHelper.SetString(self.LabelLineupTitle, szMapName)
    end
    UIHelper.SetVisible(self.ImgTipPerson, nCurCopy and nCopyIndex and nCurCopy == nCopyIndex and dwCurMapID == dwMapID)

    if szPerson and szPerson ~= "" then
        UIHelper.SetVisible(self.LabelLineupTitleNum, true)
        UIHelper.SetRichText(self.LabelLineupTitleNum, szPerson)
    else
        UIHelper.SetVisible(self.LabelLineupTitleNum, false)
    end

    for i, widgetTip in ipairs(self.tWidgetTip or {}) do
        UIHelper.SetVisible(widgetTip, nTipType == i) --1:主战场, 2:奇袭场, 3:分线
    end

    -- self.scriptAppointment = self.scriptAppointment or UIHelper.AddPrefab(PREFAB_ID.WidgetPreBookBtn, self.WidgetPreBookBtn)
    -- self.scriptAppointment:OnInitWithMapID(dwMapID, nCopyIndex)
end

return UIWidgetLineupCity