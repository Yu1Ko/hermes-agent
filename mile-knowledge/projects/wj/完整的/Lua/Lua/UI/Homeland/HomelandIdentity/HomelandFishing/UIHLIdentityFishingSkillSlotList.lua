-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHLIdentityFishingSkillSlotList
-- Date: 2024-03-01 11:10:57
-- Desc: ?
-- ---------------------------------------------------------------------------------
local FISH_BAG_SKILL_ID = 35967
local BOSS_FISH_SKILL_ID = 35962
local FISHING_SKILL_ID = 27477
local UIHLIdentityFishingSkillSlotList = class("UIHLIdentityFishingSkillSlotList")

function UIHLIdentityFishingSkillSlotList:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:Init()
end

function UIHLIdentityFishingSkillSlotList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHLIdentityFishingSkillSlotList:BindUIEvent()

end

function UIHLIdentityFishingSkillSlotList:RegEvent()
    Event.Reg(self, "BUFF_UPDATE", function()
        local owner, bdelete, index, cancancel, id, stacknum, endframe, binit, level, srcid, isvalid, leftframe = arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11
        if id == FISHING_SKILL_ID then
            UIHelper.SetString(self.scriptSlot[1].LabelName, bdelete and "抛竿" or "收竿")
        end
    end)
end

function UIHLIdentityFishingSkillSlotList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHLIdentityFishingSkillSlotList:Init()
    self.tbSlotData = {}
    self.scriptSlot = {}

    for i = 1, QTEMgr.GetDynamicSkillCount(), 1 do
        local tbSkillInfo = QTEMgr.GetDynamicSkillData(i)
        if tbSkillInfo.id ~= FISH_BAG_SKILL_ID and tbSkillInfo.id ~= BOSS_FISH_SKILL_ID then
            table.insert(self.tbSlotData, tbSkillInfo)
        end
    end

    for index, slot in ipairs(self.tbSkillSlotList) do
        self.scriptSlot[index] = UIHelper.GetBindScript(slot)
        self.scriptSlot[index]:OnEnter(self.tbSlotData[index], index)
    end
end

function UIHLIdentityFishingSkillSlotList:UpdateInfo()
    
end


return UIHLIdentityFishingSkillSlotList