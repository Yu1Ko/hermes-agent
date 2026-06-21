-- ---------------------------------------------------------------------------------
-- Author: liuyumin
-- Name: IdentitySkillData
-- Date: 2023-09-26 11:12:44
-- Desc: ?
-- ---------------------------------------------------------------------------------

IdentitySkillData = IdentitySkillData or {className = "IdentitySkillData"}
local self = IdentitySkillData
-------------------------------- 消息定义 --------------------------------
IdentitySkillData.Event = {}
IdentitySkillData.Event.XXX = "IdentitySkillData.Msg.XXX"
local m_tbDynamicSkills = {}
local tbPetSkill = {
    id = 16048,
    level = 1
}

function IdentitySkillData.Init()
	self.bCanCastSkill = true
    self.bCanUserChange = false
	Event.Reg(self, EventType.OnClientPlayerLeave, function()--退出场景自动清空动态技能状态
        self.OnSwitchDynamicSkillStateBySkills()
    end)
end

function IdentitySkillData.UnInit()

end

function IdentitySkillData.OnLogin()

end

function IdentitySkillData.OnFirstLoadEnd()

end

function IdentitySkillData.GetDynamicSkillData(nSlotIndex)
    return m_tbDynamicSkills[nSlotIndex]
end

function IdentitySkillData.GetDynamicSkillCount()
    return #m_tbDynamicSkills
end

function IdentitySkillData.CastFirstSkill()
    if m_tbDynamicSkills and #m_tbDynamicSkills >= 1 then
        OnUseSkill(m_tbDynamicSkills[1].id, 1)
    end
end

--进入身份动态技能组
function IdentitySkillData.OnSwitchDynamicSkillStateBySkills(tbSkills)
    local bEnter = tbSkills ~= nil
    if bEnter then
		self.nCurGroupID = 1
        self._updateDynamicSkillDataBySkills(tbSkills)
    else
		self.nCurGroupID = 0
        self._updateDynamicSkillDataBySkills()
    end
    Event.Dispatch("ON_CHANGE_IDENTITY_SKILL", bEnter)
end

function IdentitySkillData.IsInDynamicSkillState()
	return self.nCurGroupID and self.nCurGroupID ~= 0
end


function IdentitySkillData._updateDynamicSkillDataBySkills(tbSKillInfo)
    Timer.DelAllTimer(self)

    if not tbSKillInfo then
        m_tbDynamicSkills = {}
		self.bCanCastSkill = true
        self.bCanUserChange = false
        return
    end

    m_tbDynamicSkills = {}
    self.bCanCastSkill = tbSKillInfo.CanCastSkill
    self.bCanUserChange = tbSKillInfo.canuserchange--用户是否可以主动退出动态技能


    self._getSkillData(tbSKillInfo.tbSkilllist)
end

function IdentitySkillData._getSkillData(tbSkills)
    local nCount = #tbSkills
    for i = 1, nCount, 1 do
        local tbSkill = tbSkills[i]
        tbSkill.szImgPath = TabHelper.GetSkillIconPathByIDAndLevel(tbSkill.id, tbSkill.level)
        tbSkill.callback = function()
            local player = g_pClientPlayer
            if player then
                SkillData.SetCastPointToTargetPos()
                local nMask = (tbSkill.id * (tbSkill.id % 10 + 1))
                OnUseSkill(tbSkill.id, nMask, nil, nil, self.bCanCastSkill)
            end
        end
        tbSkill.id = tonumber(tbSkill.id)
        tbSkill.level = tonumber(tbSkill.level)
        table.insert(m_tbDynamicSkills, tbSkill)
    end
end