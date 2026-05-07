-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIExtractPersetSkillPop
-- Date: 2025-06-10 15:32:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIExtractPersetSkillPop = class("UIExtractPersetSkillPop")

function UIExtractPersetSkillPop:OnEnter(tbSelectWeapon)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbSelectWeapon = tbSelectWeapon or {}
    self.tWeaponTable, self.tWeapon2Range, self.tWeapon2ID = Table_GetDesertWeaponSkill()

    self:UpdateInfo()
end

function UIExtractPersetSkillPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIExtractPersetSkillPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)
end

function UIExtractPersetSkillPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIExtractPersetSkillPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIExtractPersetSkillPop:UpdateInfo()
    local nSelectnDetail
    local tbSelectWeapon = self.tbSelectWeapon
    if tbSelectWeapon then
        -- local iteminfo = ItemData.GetItemInfo(tbSelectWeapon[1], tbSelectWeapon[2])
        nSelectnDetail = self.tWeapon2ID[tostring(tbSelectWeapon[2])]
    end

    UIHelper.RemoveAllChildren(self.ScrollViewOptionList)
    local tbSkillList = self.tWeaponTable
    local scriptSelect = nil
    for k, v in pairs(tbSkillList) do
        local nDetail = k
        local tSkillList = SplitString(v.szSkillID, "|")

        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetXunBaoEquipSkillCell, self.ScrollViewOptionList)
        scriptCell:OnEnter(v.szName, tSkillList, nSelectnDetail and nSelectnDetail == nDetail)
        if nSelectnDetail and nSelectnDetail == nDetail then
            scriptSelect = scriptCell
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewOptionList)

    if scriptSelect then
        Timer.AddFrame(self, 1, function ()
            UIHelper.ScrollLocateToPreviewItem(self.ScrollViewOptionList, scriptSelect._rootNode, Locate.TO_CENTER)
        end)
    end
end


return UIExtractPersetSkillPop