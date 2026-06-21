-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSkillChooseOne
-- Date: 2023-04-11 20:05:01
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetSkillChooseOne = class("UIWidgetSkillChooseOne")

function UIWidgetSkillChooseOne:OnEnter(tbSkillInfo, ToggleGroup, bSelect, scriptReward)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbSkillInfo = tbSkillInfo
    self.ToggleGroup = ToggleGroup
    self.bSelect = bSelect
    self.scriptReward = scriptReward
    self:UpdateInfo()
end

function UIWidgetSkillChooseOne:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSkillChooseOne:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self.scriptReward:SetItemInfo(self.tbSkillInfo)
        end
    end)
end

function UIWidgetSkillChooseOne:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetSkillChooseOne:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSkillChooseOne:UpdateInfo()
    UIHelper.SetString(self.NodeSKillName, UIHelper.GBKToUTF8(Table_GetBuffName(self.tbSkillInfo.nID, self.tbSkillInfo.nLevel)))
    UIHelper.SetString(self.NodeSkillInfo, ParseTextHelper.ParseNormalText(UIHelper.GetBuffTip(self.tbSkillInfo.nID, self.tbSkillInfo.nLevel)))

    local szState = UIHelper.GBKToUTF8(self.tbSkillInfo.szState)
    szState = string.gsub(szState, "<%w+", "")
    szState = string.gsub(szState, ">", "")
    UIHelper.SetString(self.NodeSkillTips, szState)

    self.scriptViewPropIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.RewardGoods)

    local tbBuff = Table_GetBuff(self.tbSkillInfo.nID, self.tbSkillInfo.nLevel)
    self.scriptViewPropIcon:OnInitWithIconID(tbBuff.dwIconID)
    self.scriptViewPropIcon:HideButton()

    UIHelper.ToggleGroupAddToggle(self.ToggleGroup, self._rootNode)

    if self.bSelect then
        self.scriptReward:SetItemInfo(self.tbSkillInfo)
    end
end



return UIWidgetSkillChooseOne