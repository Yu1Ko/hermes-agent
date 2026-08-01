-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: SystemOpen
-- Date: 2023-12-03 11:24:12
-- Desc: ?
-- ---------------------------------------------------------------------------------

SystemOpen = SystemOpen or {}
local self = SystemOpen


function SystemOpen.IsSystemOpen(nSystemOpenID, bWithTips)
    local bResult = true

    local tCfg = self.GetSystemOpenCfg(nSystemOpenID)
    if tCfg then
        local nOpenLevel = tCfg.nOpenLevel
        local nOpenQuestID = tCfg.nOpenQuestID
        local nOpenAchievementID = tCfg.nOpenAchievementID
        local tbOtherCheckFunc = tCfg.tbOtherCheckFunc or {}

        -- 等级
        if nOpenLevel > 0 then
            local nPlayerLevel = g_pClientPlayer and g_pClientPlayer.nLevel or 1
            bResult = nPlayerLevel >= nOpenLevel
        end

        -- 任务
        if not bResult and nOpenQuestID > 0 then
            bResult = QuestData.IsFinished(nOpenQuestID)
        end

        -- 成就
        if not bResult and nOpenAchievementID > 0 then
            local aAchievement = Table_GetAchievement(nOpenAchievementID)
            bResult = AchievementData.IsAchievementAcquired(nOpenAchievementID, aAchievement)
        end

        -- 其他检查条件
        if bResult and #tbOtherCheckFunc > 0 then
            for i, szCondition in ipairs(tbOtherCheckFunc) do
                if not string.execute(szCondition) then
                    bResult = false
                    break
                end
            end
        end
    end

    if bWithTips and not bResult then
        TipsHelper.ShowNormalTip(tCfg.szDesc)
    end

    return bResult
end

function SystemOpen.IsViewOpen(nViewID, bWithTips)
    local bResult = true

    local nSystemOpenID = UISystemOpenViewIDTab[nViewID]
    if nSystemOpenID then
        bResult = SystemOpen.IsSystemOpen(nSystemOpenID, bWithTips)
    end

    return bResult
end


function SystemOpen.GetSystemOpenCfg(nSystemOpenID)
    return nSystemOpenID and UISystemOpenTab[nSystemOpenID]
end

function SystemOpen.GetSystemOpenDesc(nSystemOpenID)
    local tbCfg = SystemOpen.GetSystemOpenCfg(nSystemOpenID)
    return tbCfg and tbCfg.szDesc or ""
end

function SystemOpen.GetSystemOpenTitle(nSystemOpenID)
    local tbCfg = SystemOpen.GetSystemOpenCfg(nSystemOpenID)
    return tbCfg and tbCfg.szTitle or ""
end

