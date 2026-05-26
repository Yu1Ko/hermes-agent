--**********************************************************************************
-- 脚本名称: UIBattleSkillSlot
-- 创建时间: 12/14/2016 4:33:34 PM
-- 功能概述: Introduction
--**********************************************************************************

UIBattleSkillSlot = UIBattleSkillSlot or {}

function UIBattleSkillSlot.Init()
end

function UIBattleSkillSlot.UnInit()

end

function UIBattleSkillSlot.GetShowUI_Ver2(slotID)
    local nResult = nil
    local player = g_pClientPlayer

    if not player or not slotID then
        return nResult
    end

    local nKungFuID = player.GetActualKungfuMountID()
    local nSetID = player.GetTalentCurrentSet(player.dwForceID, nKungFuID)

    local tbSkill
    if slotID == UI_SKILL_UNIQUE_SLOT_ID then
        local nUniqueSkillID = SkillData.GetUniqueSkillID(nKungFuID, nSetID)
        if nUniqueSkillID == nil then
            return nResult
        end
        tbSkill = { nUniqueSkillID }
    elseif slotID == UI_SKILL_DOUQI_SLOT_ID then
        local nDouqiSkillID = SkillData.GetDouqiSkillID(nKungFuID, nSetID)
        if nDouqiSkillID == nil then
            return nResult
        end
        tbSkill = { nDouqiSkillID }
    else
        tbSkill = SkillData.GetSlotSkillTable(slotID, nKungFuID, nSetID)
    end

    for _, nSkillID in ipairs(tbSkill) do
        if SkillData.CanUIShow(player, nSkillID) then
            local tbSkillGroup = UISkillGroup[nSkillID]
            if tbSkillGroup then
                --用于debug
                for _, nRelevantSkillID in ipairs(tbSkillGroup) do
                    local pSkill = SkillData.GetSkill(player, nRelevantSkillID)
                    if not pSkill then
                        return
                    end
                    --print(nRelevantSkillID,pSkill.UITestCast(player.dwID, IsSkillCastMyself(pSkill)))
                end

                local nResult
                for _, nRelevantSkillID in ipairs(tbSkillGroup) do
                    local pSkill = SkillData.GetSkill(player, nRelevantSkillID)
                    if not pSkill then
                        return
                    end

                    local nRes = pSkill.UITestCast(player.dwID, IsSkillCastMyself(pSkill))
                    if nRes ~= SKILL_RESULT_CODE.BUFF_ERROR and nRes ~= SKILL_RESULT_CODE.FAILED and nResult == nil then
                        -- 在各种特殊状态错误码下，如骑马状态，则记录下第一个技能
                        nResult = nRelevantSkillID
                    end

                    if nRes == SKILL_RESULT_CODE.SUCCESS then
                        return nRelevantSkillID  --遇到SUCCESS状态则直接返回
                    end

                end
                return nResult or nSkillID
            else
                return nSkillID
            end
        end
    end

    return nResult
end

function UIBattleSkillSlot.OnReload()

end
