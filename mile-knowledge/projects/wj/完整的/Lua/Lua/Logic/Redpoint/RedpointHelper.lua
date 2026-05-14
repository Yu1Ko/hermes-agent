RedpointHelper = RedpointHelper or { className = "RedpointHelper" }
local self = RedpointHelper


self.tbEmotionPackageList = {}


function RedpointHelper.Init()
    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        self.tbEmotionPackageList = g_pClientPlayer.GetEmotionPackageList()
    end)

    Event.Reg(self, "ON_PLAYER_EMOTION_PACKAGE_UPDATE", function()
        local tbNowList = g_pClientPlayer.GetEmotionPackageList()
        for k, v in ipairs(tbNowList or {}) do
            if not table.contain_value(self.tbEmotionPackageList, v) then
                RedpointHelper.ChatEmotion_SetNew(v, true, false)
            end
        end

        Storage.Emotion.Flush()

        Event.Dispatch(EventType.OnChatEmojiAdd)

        self.tbEmotionPackageList = tbNowList
    end)

    Event.Reg(self, EventType.OnChatEmojiGroupSelected, function(nGroupID)
        RedpointHelper.ChatEmotion_SetNew(nGroupID, false, true)
    end)
end


-- -----------------------------------------------------------------------------
-- 角色 挂件
-- -----------------------------------------------------------------------------
function RedpointHelper.Pendant_SetNew(nPendantType, dwItemIndex, bIsNew)
    if not Storage.Character.tbNewPendant[nPendantType] then
        Storage.Character.tbNewPendant[nPendantType] = {}
    end

    if bIsNew then
        Storage.Character.tbNewPendant[nPendantType][dwItemIndex] = true
    else
        Storage.Character.tbNewPendant[nPendantType][dwItemIndex] = nil
        Event.Dispatch(EventType.ON_UPDATE_PENDANT_NEW)
    end

    Storage.Character.Flush()
end

function RedpointHelper.Pendant_HasNewByType(nPendantType)
    local bResult = false

    if Storage.Character.tbNewPendant[nPendantType] then
        local nLen = table.get_len(Storage.Character.tbNewPendant[nPendantType])
        bResult = nLen > 0
    end

    return bResult
end

function RedpointHelper.Pendant_IsNew(nPendantType, dwItemIndex)
    local bResult = false

    if Storage.Character.tbNewPendant[nPendantType] then
        bResult = Storage.Character.tbNewPendant[nPendantType][dwItemIndex]
    end

    return bResult
end

function RedpointHelper.Pendant_ClearByType(nPendantType)
    if Storage.Character.tbNewPendant[nPendantType] then
        Storage.Character.tbNewPendant[nPendantType] = nil
        Storage.Character.Flush()
        Event.Dispatch(EventType.ON_UPDATE_PENDANT_NEW)
    end
end

function RedpointHelper.Pendant_HasRedpoint()
    for nPendantType, tbNewPendant in pairs(Storage.Character.tbNewPendant or {}) do
        for dwItemIndex, bIsNew in pairs(tbNewPendant or {}) do
            if bIsNew then
                return true
            end
        end
    end

    return false
end









-- -----------------------------------------------------------------------------
-- 角色 特效
-- -----------------------------------------------------------------------------
function RedpointHelper.Effect_SetNew(nEffectType, nSFXID, bIsAcquire)
    if not Storage.Character.tbNewEffect[nEffectType] then
        Storage.Character.tbNewEffect[nEffectType] = {}
    end

    if bIsAcquire then
        Storage.Character.tbNewEffect[nEffectType][nSFXID] = true
    else
        if CharacterEffectData.bEffectUIIsShow then
            Storage.Character.tbNewEffect[nEffectType][nSFXID] = nil
        end
    end

    Storage.Character.Flush()
    Event.Dispatch(EventType.ON_UPDATE_EFFECT_NEW)
end

function RedpointHelper.Effect_HasNewByType(nEffectType)
    local bResult = false

    if Storage.Character.tbNewEffect[nEffectType] then
        local nLen = table.get_len(Storage.Character.tbNewEffect[nEffectType])
        bResult = nLen > 0
    end

    return bResult
end

function RedpointHelper.Effect_IsNew(nEffectType, nSFXID)
    local bResult = false

    if Storage.Character.tbNewEffect[nEffectType] then
        bResult = Storage.Character.tbNewEffect[nEffectType][nSFXID]
    end

    return bResult
end

function RedpointHelper.Effect_ClearByType(nEffectType)
    if Storage.Character.tbNewEffect[nEffectType] then
        Storage.Character.tbNewEffect[nEffectType] = nil
        Storage.Character.Flush()
        Event.Dispatch(EventType.ON_UPDATE_EFFECT_NEW)
    end
end

function RedpointHelper.Effect_HasRedpoint()
    for nEffectType, tbNewEffect in pairs(Storage.Character.tbNewEffect or {}) do
        for nSFXID, bIsNew in pairs(tbNewEffect or {}) do
            if bIsNew then
                return true
            end
        end
    end

    return false
end








-- -----------------------------------------------------------------------------
-- 角色 待机动作
-- -----------------------------------------------------------------------------
function RedpointHelper.IdleAction_SetNew(nActID, bIsAcquire)
    if not Storage.Character.tbNewIdleAction then
        Storage.Character.tbNewIdleAction = {}
    end

    if bIsAcquire then
        Storage.Character.tbNewIdleAction[nActID] = true
    else
        Storage.Character.tbNewIdleAction[nActID] = nil
    end

    Storage.Character.Flush()
    Event.Dispatch(EventType.ON_UPDATE_IDLEACTION_NEW)
end

-- function RedpointHelper.IdleAction_HasNewByType(nActionType)
--     local bResult = false

--     if Storage.Character.tbNewIdleAction[nActionType] then
--         local nLen = table.get_len(Storage.Character.tbNewIdleAction[nActionType])
--         bResult = nLen > 0
--     end

--     return bResult
-- end

function RedpointHelper.IdleAction_IsNew(nActID)
    local bResult = false

    if Storage.Character.tbNewIdleAction then
        bResult = Storage.Character.tbNewIdleAction[nActID] or false
    end

    return bResult
end

function RedpointHelper.IdleAction_ClearAll()
    if Storage.Character.tbNewIdleAction then
        Storage.Character.tbNewIdleAction = nil
        Storage.Character.Flush()
        Event.Dispatch(EventType.ON_UPDATE_IDLEACTION_NEW)
    end
end

function RedpointHelper.IdleAction_HasRedpoint()
    for nActID, bIsNew in pairs(Storage.Character.tbNewIdleAction or {}) do
        if bIsNew then
            return true
        end
    end

    return false
end









-- -----------------------------------------------------------------------------
-- 角色 武技殊影
-- -----------------------------------------------------------------------------
function RedpointHelper.SkillSkin_SetNew(dwSkinID, bIsAcquire)
    if not Storage.Character.tbNewSkillSkin then
        Storage.Character.tbNewSkillSkin = {}
    end

    if bIsAcquire then
        Storage.Character.tbNewSkillSkin[dwSkinID] = true
    else
        Storage.Character.tbNewSkillSkin[dwSkinID] = nil
    end

    Storage.Character.Flush()
    Event.Dispatch(EventType.ON_UPDATE_SKILLSKIN_NEW)
end

function RedpointHelper.SkillSkin_IsNew(dwSkinID)
    local bResult = false

    if Storage.Character.tbNewSkillSkin then
        bResult = Storage.Character.tbNewSkillSkin[dwSkinID] or false
    end

    return bResult
end

function RedpointHelper.SkillSkin_ClearAll()
    if Storage.Character.tbNewSkillSkin then
        Storage.Character.tbNewSkillSkin = nil
        Storage.Character.Flush()
        Event.Dispatch(EventType.ON_UPDATE_SKILLSKIN_NEW)
    end
end

function RedpointHelper.SkillSkin_HasRedpoint()
    for nActID, bIsNew in pairs(Storage.Character.tbNewSkillSkin or {}) do
        if bIsNew then
            return true
        end
    end

    return false
end










-- -----------------------------------------------------------------------------
-- 公告
-- -----------------------------------------------------------------------------
function RedpointHelper.Bulletin_Update(szBulletinType)
    local szMD5 = BulletinData.GetBulleintMD5(szBulletinType)
    Storage.Bulletin.tbRedPointBulletin[szBulletinType] = szMD5
    Storage.Bulletin.Flush()
    Event.Dispatch(EventType.OnBulletinRedPointUpdate)
end

function RedpointHelper.Bulletin_HasRedpoint(szBulletinType)
    local _, szBulletin = BulletinData.GetBulletin(szBulletinType)
    if string.is_nil(szBulletin) then
        return false
    end

    if not BulletinData.IsInShowTime(szBulletinType) then
        return false
    end

    --提审版本游戏公告/系统公告不显示红点
    if AppReviewMgr.IsReview() then
        if szBulletinType == BulletinType.Announcement or szBulletinType == BulletinType.System then
            return false
        end
    end

    --游戏公告为默认文本时不显示红点
    if szBulletinType == BulletinType.Announcement and BulletinData.IsDefaultAnnouncement() then
        return false
    end

    -- 蔚领云游戏，不显示红点
    if Channel.Is_WLColud() then
        return false
    end

    local szMD5 = BulletinData.GetBulleintMD5(szBulletinType)
    local bResult = Storage.Bulletin.tbRedPointBulletin[szBulletinType] ~= szMD5
    return bResult
end









-- -----------------------------------------------------------------------------
-- 称号
-- -----------------------------------------------------------------------------
function RedpointHelper.PersonalTitle_SetNew(nPrefix, nPostfix, bGeneration, bIsNew)
    if nPrefix and nPrefix ~= 0 then
        local aDesignation = Table_GetDesignationPrefixByID(nPrefix, UI_GetPlayerForceID())
        if aDesignation then
            Storage.PersonalTitle.tbNewPrefix[nPrefix] = bIsNew or nil
            Storage.PersonalTitle.Flush()
            Event.Dispatch(EventType.OnDesignationNewUpdate)
        end
    end

    if nPostfix and nPostfix ~= 0 then
        local aDesignation = g_tTable.Designation_Postfix:Search(nPostfix)
        if aDesignation then
            Storage.PersonalTitle.tbNewPostfix[nPostfix] = bIsNew or nil
            Storage.PersonalTitle.Flush()
            Event.Dispatch(EventType.OnDesignationNewUpdate)
        end
    end

    if bGeneration then
        Storage.PersonalTitle.dwNewGeneration = nil
        if bIsNew then
            local player = GetClientPlayer()
            local tGen = player and g_tTable.Designation_Generation:Search(player.dwForceID, player.GetDesignationGeneration())
            if tGen then
                Storage.PersonalTitle.dwNewGeneration = tGen.dwGeneration
            end
        end
        Storage.PersonalTitle.Flush()
        Event.Dispatch(EventType.OnDesignationNewUpdate)
    end
end

function RedpointHelper.PersonalTitle_IsNew(aDesignation)
    local bIsNew = false
    if aDesignation then
        if aDesignation.nType == DESIGNATION_TYPE.COURTESY then
            bIsNew = Storage.PersonalTitle.dwNewGeneration == aDesignation.dwID
        elseif aDesignation.nType == DESIGNATION_TYPE.POSTFIX then
            bIsNew = Storage.PersonalTitle.tbNewPostfix[aDesignation.dwID]
        else
            bIsNew = Storage.PersonalTitle.tbNewPrefix[aDesignation.dwID]
        end
    end
    return bIsNew
end

function RedpointHelper.PersonalTitle_ClearAll()
    Storage.PersonalTitle.tbNewPrefix = {}
    Storage.PersonalTitle.tbNewPostfix = {}
    Storage.PersonalTitle.dwNewGeneration = nil
    Storage.PersonalTitle.Flush()
    Event.Dispatch(EventType.OnDesignationNewUpdate)
end

function RedpointHelper.PersonalTitle_HasRedpoint()
    for nPrefix, bValue in pairs(Storage.PersonalTitle.tbNewPrefix or {}) do
        if bValue then
            return true
        end
    end

    for nPostfix, bValue in pairs(Storage.PersonalTitle.tbNewPostfix or {}) do
        if bValue then
            return true
        end
    end

    if Storage.PersonalTitle.dwNewGeneration then
        return true
    end

    return false
end

function RedpointHelper.PersonalTitle_Flush()
    Storage.PersonalTitle.Flush()
end









-- -----------------------------------------------------------------------------
-- 坐骑
-- -----------------------------------------------------------------------------
function RedpointHelper.Horse_SetNew(dwBoxIndex, dwX, bIsNew)
    if bIsNew then
        -- 坐骑
        if dwBoxIndex == INVENTORY_INDEX.HORSE then
            local item = ItemData.GetItemByPos(dwBoxIndex, dwX)
            if item then
                Storage.Horse.tbNewRideHorse = Storage.Horse.tbNewRideHorse or {}
                if Storage.Horse.tbNewRideHorse[item.nGenTime + item.dwIndex] == nil then
                    Storage.Horse.tbNewRideHorse[item.nGenTime + item.dwIndex] = true
                    Storage.Horse.bHasNewHorse = true
                    Storage.Horse.Flush()
                end
            end
            -- 奇趣坐骑
        elseif dwBoxIndex == INVENTORY_INDEX.RARE_HORSE1 or
                dwBoxIndex == INVENTORY_INDEX.RARE_HORSE2 or
                dwBoxIndex == INVENTORY_INDEX.RARE_HORSE3 or
                dwBoxIndex == INVENTORY_INDEX.RARE_HORSE4 or
                dwBoxIndex == INVENTORY_INDEX.RARE_HORSE5 then

            if not Storage.Horse.tbNewQiquHorse[dwBoxIndex] then
                Storage.Horse.tbNewQiquHorse[dwBoxIndex] = {}
            end
            if Storage.Horse.tbNewQiquHorse[dwBoxIndex][dwX] == nil then
                Storage.Horse.tbNewQiquHorse[dwBoxIndex][dwX] = true
                Storage.Horse.Flush()
            end
        end
    else
        if dwBoxIndex == nil or dwBoxIndex == INVENTORY_INDEX.HORSE then
            RedpointHelper.Horse_Ride_ClearAll()
        else
            Storage.Horse.tbNewQiquHorse[dwBoxIndex][dwX] = false
            Event.Dispatch(EventType.OnHorseNewUpdate)
        end
    end
end

function RedpointHelper.Horse_Qiqu_IsNew(dwBoxIndex, dwX)
    return Storage.Horse.tbNewQiquHorse[dwBoxIndex] and Storage.Horse.tbNewQiquHorse[dwBoxIndex][dwX]
end

function RedpointHelper.Horse_Ride_HasRedPoint()
    return Storage.Horse.bHasNewHorse
end

function RedpointHelper.Horse_Qiqu_ClearAll()
    for dwBoxIndex, tbNewQiquHorse in pairs(Storage.Horse.tbNewQiquHorse or {}) do
        for dwX, bIsNew in pairs(tbNewQiquHorse or {}) do
            tbNewQiquHorse[dwX] = false
        end
    end
    RedpointHelper.Horse_Flush()
    Event.Dispatch(EventType.OnHorseNewUpdate)
end

function RedpointHelper.Horse_Ride_ClearAll()
    for dwID, bIsNew in pairs(Storage.Horse.tbNewRideHorse or {}) do
        Storage.Horse.tbNewRideHorse[dwID] = false
    end
    Storage.Horse.bHasNewHorse = false
    RedpointHelper.Horse_Flush()
    Event.Dispatch(EventType.OnHorseNewUpdate)
end

function RedpointHelper.Horse_Flush()
    return Storage.Horse.Flush
end

function RedpointHelper.Horse_Qiqu_HasRedPoint()
    for dwBoxIndex, tbNewQiquHorse in pairs(Storage.Horse.tbNewQiquHorse or {}) do
        for dwX, bIsNew in pairs(tbNewQiquHorse or {}) do
            if bIsNew then
                return true
            end
        end
    end

    return false
end









-- -----------------------------------------------------------------------------
-- 宠物
-- -----------------------------------------------------------------------------
function RedpointHelper.Pet_SetNew(dwPetIndex, bIsNew)
    if bIsNew then
        Storage.Pet.tbNewPet[dwPetIndex] = true
        Storage.Pet.Flush()
    else
        Storage.Pet.tbNewPet[dwPetIndex] = nil
    end
end

function RedpointHelper.Pet_IsNew(dwPetIndex)
    return Storage.Pet.tbNewPet[dwPetIndex]
end

function RedpointHelper.Pet_ClearAll()
    Storage.Pet.tbNewPet = {}
    Storage.Pet.Flush()
    Event.Dispatch(EventType.OnPetNewUpdate)
end

function RedpointHelper.Pet_Flush()
    Storage.Pet.Flush()
    Event.Dispatch(EventType.OnPetNewUpdate)
end

function RedpointHelper.Pet_HasRedPoint()
    for dwPetIndex, bIsNew in pairs(Storage.Pet.tbNewPet or {}) do
        if bIsNew then
            return true
        end
    end

    return false
end









-- -----------------------------------------------------------------------------
-- 玩具箱
-- -----------------------------------------------------------------------------
function RedpointHelper.ToyBox_SetNew(dwID, bIsNew)
    if bIsNew then
        Storage.ToyBox.tbNewToyBox[dwID] = true
        Storage.ToyBox.Flush()
    else
        Storage.ToyBox.tbNewToyBox[dwID] = nil
    end
end

function RedpointHelper.ToyBox_IsNew(dwID)
    return Storage.ToyBox.tbNewToyBox[dwID]
end

function RedpointHelper.ToyBox_ClearAll()
    Storage.ToyBox.tbNewToyBox = {}
    Storage.ToyBox.Flush()
    Event.Dispatch(EventType.OnToyBoxNewUpdate)
end

function RedpointHelper.ToyBox_Flush()
    Storage.ToyBox.Flush()
    Event.Dispatch(EventType.OnToyBoxNewUpdate)
end

function RedpointHelper.ToyBox_HasRedPoint()
    if not (g_pClientPlayer and g_pClientPlayer.nLevel >= 106) then
        return false
    end

    for dwID, bIsNew in pairs(Storage.ToyBox.tbNewToyBox or {}) do
        if bIsNew then
            return true
        end
    end

    return false
end









-- -----------------------------------------------------------------------------
-- 表情动作
-- -----------------------------------------------------------------------------
function RedpointHelper.Emotion_SetNew(dwActionID, bIsNew)
    local emotion = EmotionData.GetEmotionAction(dwActionID)
    if not emotion then
        return
    end

    local nType = emotion.nActionType

    if bIsNew then
        if not Storage.Emotion.tbNewEmotion[nType] then
            Storage.Emotion.tbNewEmotion[nType] = {}
        end
        Storage.Emotion.tbNewEmotion[nType][dwActionID] = true
        Storage.Emotion.Flush()
    else
        if Storage.Emotion.tbNewEmotion[nType] then
            Storage.Emotion.tbNewEmotion[nType][dwActionID] = nil
            Storage.Emotion.Flush()
            Event.Dispatch(EventType.OnEmotionActionNewUpdate)
        end
    end
end

function RedpointHelper.Emotion_IsNew(dwActionID)
    local bResult = false

    local emotion = EmotionData.GetEmotionAction(dwActionID)
    if emotion then
        local nType = emotion.nActionType
        if Storage.Emotion.tbNewEmotion[nType] then
            bResult = Storage.Emotion.tbNewEmotion[nType][dwActionID]
        end
    end

    return bResult
end

function RedpointHelper.Emotion_HasNewByType(nType)
    local bResult = false

    if Storage.Emotion.tbNewEmotion[nType] then
        local nLen = table.get_len(Storage.Emotion.tbNewEmotion[nType])
        bResult = nLen > 0
    end

    return bResult
end

function RedpointHelper.Emotion_ClearByType(nType)
    if Storage.Emotion.tbNewEmotion[nType] then
        Storage.Emotion.tbNewEmotion[nType] = nil
    end
    Storage.Emotion.Flush()
end

function RedpointHelper.Emotion_Flush()
    Storage.Emotion.Flush()
end

function RedpointHelper.Emotion_HasRedPoint()
    if not SystemOpen.IsSystemOpen(SystemOpenDef.BiaoQing) then
        return false
    end

    for nType, tbNewEmotion in pairs(Storage.Emotion.tbNewEmotion or {}) do
        for dwActionID, bValue in pairs(tbNewEmotion) do
            if bValue then
                return true
            end
        end
    end

    return false
end









-- -----------------------------------------------------------------------------
-- 头顶表情
-- -----------------------------------------------------------------------------
function RedpointHelper.BrightMark_SetNew(dwBrightMarkID, bIsNew)
    local emotion = HeadEmotionData.GetHeadEmotion(dwBrightMarkID)
    if not emotion then
        return
    end

    local nType = emotion.nPageID

    if bIsNew then
        if not Storage.BrightMark.tbNewBrightMark[nType] then
            Storage.BrightMark.tbNewBrightMark[nType] = {}
        end
        Storage.BrightMark.tbNewBrightMark[nType][dwBrightMarkID] = true
        Storage.BrightMark.Flush()
    else
        if Storage.BrightMark.tbNewBrightMark[nType] then
            Storage.BrightMark.tbNewBrightMark[nType][dwBrightMarkID] = nil
            Event.Dispatch(EventType.OnBrightMarkNewUpdate)
        end
    end
end

function RedpointHelper.BrightMark_IsNew(dwBrightMarkID)
    local bResult = false

    local emotion = HeadEmotionData.GetHeadEmotion(dwBrightMarkID)
    if emotion then
        local nType = emotion.nPageID
        if Storage.BrightMark.tbNewBrightMark[nType] then
            bResult = Storage.BrightMark.tbNewBrightMark[nType][dwBrightMarkID]
        end
    end

    return bResult
end

function RedpointHelper.BrightMark_HasNewByType(nType)
    local bResult = false

    if Storage.BrightMark.tbNewBrightMark[nType] then
        local nLen = table.get_len(Storage.BrightMark.tbNewBrightMark[nType])
        bResult = nLen > 0
    end

    return bResult
end

function RedpointHelper.BrightMark_ClearByType(nType)
    if Storage.BrightMark.tbNewBrightMark[nType] then
        Storage.BrightMark.tbNewBrightMark[nType] = nil
    end
    Storage.BrightMark.Flush()
end

function RedpointHelper.BrightMark_Flush()
    Storage.BrightMark.Flush()
end

function RedpointHelper.BrightMark_HasRedPoint()
    if not SystemOpen.IsSystemOpen(SystemOpenDef.BiaoQing) then
        return false
    end

    for nType, tbNewBrightMark in pairs(Storage.BrightMark.tbNewBrightMark or {}) do
        for dwBrightMarkID, bValue in pairs(tbNewBrightMark) do
            if bValue then
                return true
            end
        end
    end

    return false
end

Event.Reg(RedpointHelper, "PLAYER_LEVEL_UP", function(dwPlayerID)
    if g_pClientPlayer and g_pClientPlayer.dwID == dwPlayerID then
        if g_pClientPlayer.nLevel >= 108 and Storage.Arena.bLocked then
            --竞技场
            Storage.Arena.bLocked = false
            Storage.Arena.bHaveRedPoint = true
            Storage.Arena.Flush()
        end
        if g_pClientPlayer.nLevel >= 102 and Storage.HuaELou.bNewLevel then
            --花萼楼
            Storage.HuaELou.bNewLevel = false
            Storage.HuaELou.Flush()
            Event.Dispatch("OnPlayerLevelUp")
        end
    end
end)

Event.Reg(RedpointHelper, "PLAYER_LEVEL_UPDATE", function(dwPlayerID)
    local pPlayer = GetClientPlayer()

    if pPlayer and pPlayer.dwID == dwPlayerID then
        if pPlayer.nLevel == 130 and pPlayer.nCamp == 0 then
            --阵营
            Storage.PanelCamp.bNewLevel = true
            Storage.PanelCamp.Flush()
        end
    end
end)

--竞技场
function RedpointHelper.Arena_HasRedPoint()
    return Storage.Arena.bHaveRedPoint
end

local nPanelCampLevelRestriction = 130

function RedpointHelper.PanelCamp_IsLevelNew()
    if not g_pClientPlayer or g_pClientPlayer.nLevel < nPanelCampLevelRestriction then
        return false -- 未到等级限制时不显示红点
    end
    return Storage.PanelCamp.bNewLevel
end

function RedpointHelper.PanelCamp_OnClickLevel()
    if not g_pClientPlayer or g_pClientPlayer.nLevel < nPanelCampLevelRestriction then
        return false -- 未到等级限制时不显示红点
    end

    Storage.PanelCamp.bNewLevel = false
    Storage.PanelCamp.Flush()
end
-- -----------------------------------------------------------------------------
-- 武学面板
-- -----------------------------------------------------------------------------
--function RedpointHelper.PanelSkill_SetNew(dwID, bIsNew)
--    if bIsNew then
--        Storage.ToyBox.tbNewToyBox[dwID] = true
--        Storage.ToyBox.Flush()
--    else
--        Storage.ToyBox.tbNewToyBox[dwID] = nil
--    end
--end
local nDefaultVersion = 0
local nLiuPaiLevelRestriction = 130

function RedpointHelper.PanelSkill_HasRedPoint()
    if SkillData.IsUsingHDKungFu() then
        return false -- DX武学不显示红点
    end
    
    local bNewMiji = false
    if g_pClientPlayer then
        if SystemOpen.IsSystemOpen(SystemOpenDef.Skill) then
            local nCurrentKungFuID = g_pClientPlayer.GetActualKungfuMountID()
            local nCurrentSetID = g_pClientPlayer.GetTalentCurrentSet(g_pClientPlayer.dwForceID, nCurrentKungFuID)
            for i = 1, 5 do
                local nSkillID = SkillData.GetSlotSkillID(i, nCurrentKungFuID, nCurrentSetID)
                local _, bActive = SkillData.GetFinalRecipeList(nSkillID)
                if nSkillID and not bActive then
                    bNewMiji = true
                    break
                end
            end
        end
    end

    return bNewMiji or RedpointHelper.PanelSkill_IsRecommendNew()
end

function RedpointHelper.PanelSkill_ShowApplyButtonRedPoint(bIsPVP)
    local tKungFuRecommendVersion = Storage.PanelSkill.tKungFuRecommendVersion
    if bIsPVP == nil then
        bIsPVP = false
    end

    if g_pClientPlayer then
        local nTargetKungFuID = g_pClientPlayer.GetActualKungfuMountID()
        local nSetID = g_pClientPlayer.GetTalentCurrentSet(g_pClientPlayer.dwForceID, nTargetKungFuID)

        if g_pClientPlayer.dwForceID == 0 then
            return false  -- 大侠号不提示
        end
        
        if not nTargetKungFuID then
            return false  -- 在客户端资源缺失导致无法获取技能时直接返回
        end

        tKungFuRecommendVersion[nTargetKungFuID] = tKungFuRecommendVersion[nTargetKungFuID] or {}
        tKungFuRecommendVersion[nTargetKungFuID][nSetID] = tKungFuRecommendVersion[nTargetKungFuID][nSetID] or {}

        local tRecommendData = UISkillRecommendTab[nTargetKungFuID]
        local tFightData = tRecommendData and (bIsPVP and tRecommendData.PVP or tRecommendData.PVE)
        if tFightData then
            local tData = tKungFuRecommendVersion[nTargetKungFuID][nSetID]
            local nNewVersion = tFightData.Version or nDefaultVersion -- 默认值为0
            local nOldVersion = (bIsPVP and tData.PVP or tData.PVE) or nDefaultVersion
            if nNewVersion > nOldVersion then
                return true
            end
        end
    end

    if not bIsPVP then
        return Storage.PanelSkill.bNewRecommend -- 初始账号默认显示秘境推荐
    else
        return false
    end
end

function RedpointHelper.PanelSkill_IsRecommendNew()
    if g_pClientPlayer and g_pClientPlayer.nLevel >= SKILL_RESTRICTION_LEVEL then
        return RedpointHelper.PanelSkill_ShowApplyButtonRedPoint() or RedpointHelper.PanelSkill_ShowApplyButtonRedPoint(true)
    end
    return false
end

function RedpointHelper.PanelSkill_OnClickApplyRecommend(bIsPVP)
    local tKungFuRecommendVersion = Storage.PanelSkill.tKungFuRecommendVersion
    local nTargetKungFuID = g_pClientPlayer.GetActualKungfuMountID()
    local nSetID = g_pClientPlayer.GetTalentCurrentSet(g_pClientPlayer.dwForceID, nTargetKungFuID)

    tKungFuRecommendVersion[nTargetKungFuID] = tKungFuRecommendVersion[nTargetKungFuID] or {}
    tKungFuRecommendVersion[nTargetKungFuID][nSetID] = tKungFuRecommendVersion[nTargetKungFuID][nSetID] or {}

    local tRecommendData = UISkillRecommendTab[nTargetKungFuID]
    local tFightData = tRecommendData and (bIsPVP and tRecommendData.PVP or tRecommendData.PVE)
    if tFightData then
        local tData = tKungFuRecommendVersion[nTargetKungFuID][nSetID]
        local nNewVersion = tFightData.Version or nDefaultVersion
        if bIsPVP then
            tData.PVP = nNewVersion
        else
            tData.PVE = nNewVersion
        end
    end

    if not bIsPVP then
        Storage.PanelSkill.bNewRecommend = false
    end
    Storage.PanelSkill.Flush()
    Event.Dispatch("SKILL_RED_POINT_UPDATE")
end

function RedpointHelper.PanelSkill_IsLiuPaiKungFuNew()
    if not g_pClientPlayer or g_pClientPlayer.nLevel < nLiuPaiLevelRestriction then
        return false -- 未到等级限制是不显示流派红点
    end
    return Storage.PanelSkill.bNewLiuPai_WuXiang
end

function RedpointHelper.PanelSkill_OnClickLiuPaiKungFu()
    if not g_pClientPlayer or g_pClientPlayer.nLevel < nLiuPaiLevelRestriction then
        return false -- 未到等级限制是不显示流派红点
    end
    
    Storage.PanelSkill.bNewLiuPai_WuXiang = false
    Storage.PanelSkill.Flush()
    Event.Dispatch("SKILL_RED_POINT_UPDATE")
end

function RedpointHelper.CoinShopSchool_HasRedPoint()
    local bResult = false

    local SCHOOL_EXTERIOR = 927
	local bOpen = ActivityData.IsActivityOn(SCHOOL_EXTERIOR) or UI_IsActivityOn(SCHOOL_EXTERIOR)

    if bOpen then
        local nChance = CoinShopData.GetSchoolLeftChance()
        local bClickState = CoinShopData.GetClickSchoolActivityState()
        if bOpen and (nChance > 0 or bClickState == false) then
            bResult = true
        end
    end

    return bResult
end

-- -----------------------------------------------------------------------------
-- 聊天表情
-- -----------------------------------------------------------------------------
function RedpointHelper.ChatEmotion_IsNew(dwGroupID)
    if dwGroupID == nil then return end
    if ChatData.CheckEmojiGroupDisable(dwGroupID) then return end

    local bResult = Storage.Emotion.tbNewChatEmotion[dwGroupID]
    return bResult
end

function RedpointHelper.ChatEmotion_SetNew(dwGroupID, bNew, bFlush)
    if dwGroupID == nil then return end
    if ChatData.CheckEmojiGroupDisable(dwGroupID) then return end

    if bNew then
        Storage.Emotion.tbNewChatEmotion[dwGroupID] = true
        Event.Dispatch(EventType.OnChatEmojiAdd)
    else
        Storage.Emotion.tbNewChatEmotion[dwGroupID] = nil
        Event.Dispatch(EventType.OnChatEmojiRemove)
    end

    if bFlush then
        RedpointHelper.ChatEmotion_Flush()
    end
end

function RedpointHelper.ChatEmotion_Flush()
    Storage.Emotion.Flush()
end

function RedpointHelper.ChatEmotion_HasRedPoint()
    local bResult = false

    for dwGroupID, v in pairs(Storage.Emotion.tbNewChatEmotion or {}) do
        if not ChatData.CheckEmojiGroupDisable(dwGroupID) and v == true then
            bResult = true
            break
        end
    end

    return bResult
end

-- -----------------------------------------------------------------------------
-- 教学盒子
-- -----------------------------------------------------------------------------
function RedpointHelper.TeachBox_IsNew()
    return Storage.TeachBox.bNew
end

function RedpointHelper.TeachBox_ClearAll()
    Storage.TeachBox.bNew = false
    Storage.TeachBox.Flush()
end


-- -----------------------------------------------------------------------------
-- 商城 外装
-- -----------------------------------------------------------------------------
function RedpointHelper.Exterior_SetNew(dwID, bIsNew)
    if bIsNew then
        Storage.CoinShop.tbNewExterior[dwID] = true
    else
        Storage.CoinShop.tbNewExterior[dwID] = nil
    end
    Event.Dispatch(EventType.ON_UPDATE_EXTERIOR_NEW)
    Storage.CoinShop.Flush()
end

function RedpointHelper.Exterior_HasNewByType(nClass)
    local bResult = false
    local hExterior = GetExterior()
    for dwID in pairs(Storage.CoinShop.tbNewExterior) do
        local tExteriorInfo = hExterior.GetExteriorInfo(dwID)
        local tSetInfo = Table_GetExteriorSet(tExteriorInfo.nSet)
        if tSetInfo.nClass == nClass then
            bResult = true
            break
        end
    end
    return bResult
end

function RedpointHelper.Exterior_IsNew(dwID)
    local bResult = false
    bResult = Storage.CoinShop.tbNewExterior[dwID] or false
    return bResult
end

function RedpointHelper.Exterior_HasRedpoint()
    for dwID in pairs(Storage.CoinShop.tbNewExterior) do
        return true
    end
    return false
end

function RedpointHelper.Exterior_ClearByType(nClass)
    local hExterior = GetExterior()
    for dwID in pairs(Storage.CoinShop.tbNewExterior) do
        local tExteriorInfo = hExterior.GetExteriorInfo(dwID)
        local tSetInfo = Table_GetExteriorSet(tExteriorInfo.nSet)
        if tSetInfo.nClass == nClass then
            Storage.CoinShop.tbNewExterior[dwID] = nil
        end
    end
    Storage.CoinShop.Flush()
    Event.Dispatch(EventType.ON_UPDATE_EXTERIOR_NEW)
end

-- -----------------------------------------------------------------------------
-- 商城 武器外装
-- -----------------------------------------------------------------------------
function RedpointHelper.WeaponExterior_SetNew(dwID, bIsNew)
    if bIsNew then
        Storage.CoinShop.tbNewWeaponExterior[dwID] = true
    else
        Storage.CoinShop.tbNewWeaponExterior[dwID] = nil
    end
    Event.Dispatch(EventType.ON_UPDATE_WEAPON_EXTERIOR_NEW)
    Storage.CoinShop.Flush()
end

function RedpointHelper.WeaponExterior_IsNew(dwID)
    local bResult = false
    bResult = Storage.CoinShop.tbNewWeaponExterior[dwID] or false
    return bResult
end

function RedpointHelper.WeaponExterior_HasRedpoint()
    for dwID in pairs(Storage.CoinShop.tbNewWeaponExterior) do
        return true
    end
    return false
end

function RedpointHelper.WeaponExterior_ClearNew()
    Storage.CoinShop.tbNewWeaponExterior = {}
    Storage.CoinShop.Flush()
    Event.Dispatch(EventType.ON_UPDATE_WEAPON_EXTERIOR_NEW)
end

-- -----------------------------------------------------------------------------
-- 商城 发型
-- -----------------------------------------------------------------------------
function RedpointHelper.Hair_SetNew(dwID, bIsNew)
    if bIsNew then
        Storage.CoinShop.tbNewHair[dwID] = true
    else
        Storage.CoinShop.tbNewHair[dwID] = nil
    end
    Event.Dispatch(EventType.ON_UPDATE_HAIR_NEW)
    Storage.CoinShop.Flush()
end

function RedpointHelper.Hair_IsNew(dwID)
    local bResult = false
    bResult = Storage.CoinShop.tbNewHair[dwID] or false
    return bResult
end

function RedpointHelper.Hair_HasRedpoint()
    if not CoinShop_CanChangeHair() then
        return false
    end
    for dwID in pairs(Storage.CoinShop.tbNewHair) do
        return true
    end
    return false
end

function RedpointHelper.Hair_ClearNew()
    Storage.CoinShop.tbNewHair = {}
    Storage.CoinShop.Flush()
    Event.Dispatch(EventType.ON_UPDATE_HAIR_NEW)
end

-- -----------------------------------------------------------------------------
-- 商城 脸型
-- -----------------------------------------------------------------------------
function RedpointHelper.Face_SetNew(nIndex, bIsNew)
    if bIsNew then
        Storage.CoinShop.tbNewFace[nIndex] = true
    else
        Storage.CoinShop.tbNewFace[nIndex] = nil
    end
    Event.Dispatch(EventType.ON_UPDATE_FACE_NEW)
    Storage.CoinShop.Flush()
end

function RedpointHelper.Face_IsNew(dwID)
    local bResult = false
    bResult = Storage.CoinShop.tbNewFace[dwID] or false
    return bResult
end

function RedpointHelper.Face_HasNewByType(bNewFace)
    local hManager = GetFaceLiftManager()
    for nIndex in pairs(Storage.CoinShop.tbNewFace) do
        local bCurrentNew = hManager.CheckNewFace(nIndex)
        bCurrentNew = bCurrentNew == 1 or bCurrentNew == true or false
        if bCurrentNew == bNewFace then
            return true
        end
    end
    return false
end

function RedpointHelper.Face_HasRedpoint()
    for nIndex in pairs(Storage.CoinShop.tbNewFace) do
        return true
    end
    return false
end

function RedpointHelper.Face_ClearNewByType(bNewFace)
    local hManager = GetFaceLiftManager()
    for nIndex in pairs(Storage.CoinShop.tbNewFace) do
        local bCurrentNew = hManager.CheckNewFace(nIndex)
        bCurrentNew = bCurrentNew == 1 or bCurrentNew == true or false
        if bCurrentNew == bNewFace then
           Storage.CoinShop.tbNewFace[nIndex] = nil
        end
    end
    Storage.CoinShop.Flush()
    Event.Dispatch(EventType.ON_UPDATE_FACE_NEW)
end

-- -----------------------------------------------------------------------------
-- 商城 体型
-- -----------------------------------------------------------------------------
function RedpointHelper.Body_SetNew(nIndex, bIsNew)
    if bIsNew then
        Storage.CoinShop.tbNewBody[nIndex] = true
    else
        Storage.CoinShop.tbNewBody[nIndex] = nil
    end
    Event.Dispatch(EventType.ON_UPDATE_BODY_NEW)
    Storage.CoinShop.Flush()
end

function RedpointHelper.Body_IsNew(nIndex)
    local bResult = false
    bResult = Storage.CoinShop.tbNewBody[nIndex] or false
    return bResult
end

function RedpointHelper.Body_HasRedpoint()
    for nIndex in pairs(Storage.CoinShop.tbNewBody) do
        return true
    end
    return false
end

function RedpointHelper.Body_ClearNew()
    Storage.CoinShop.tbNewBody = {}
    Storage.CoinShop.Flush()
    Event.Dispatch(EventType.ON_UPDATE_BODY_NEW)
end

-- -----------------------------------------------------------------------------
-- 商城 挂宠
-- -----------------------------------------------------------------------------
function RedpointHelper.PendantPet_SetNew(dwItemIndex, bIsNew)
    if bIsNew then
        Storage.CoinShop.tbNewPendantPet[dwItemIndex] = true
    else
        Storage.CoinShop.tbNewPendantPet[dwItemIndex] = nil
    end
    Event.Dispatch(EventType.ON_UPDATE_PENDANT_PET_NEW)
    Storage.CoinShop.Flush()
end

function RedpointHelper.PendantPet_IsNew(dwItemIndex)
    local bResult = false
    bResult = Storage.CoinShop.tbNewPendantPet[dwItemIndex] or false
    return bResult
end

function RedpointHelper.PendantPet_HasRedpoint()
    for dwItemIndex in pairs(Storage.CoinShop.tbNewPendantPet) do
        return true
    end
    return false
end

function RedpointHelper.PendantPet_ClearNew()
    Storage.CoinShop.tbNewPendantPet = {}
    Storage.CoinShop.Flush()
    Event.Dispatch(EventType.ON_UPDATE_PENDANT_PET_NEW)
end

-- -----------------------------------------------------------------------------
-- 商城 特判零元购
-- -----------------------------------------------------------------------------
local t0YuanGouDiscoupon = {
    [1] = 181,
    [2] = 182,
    [3] = 183,
}
function RedpointHelper.CoinShop_Has0YuanGou()
    for _, dwID in ipairs(t0YuanGouDiscoupon) do
        if CoinShopData.GetWelfare(dwID) then
            return true
        end
    end
    return false
end

-- -----------------------------------------------------------------------------
-- 界面自定义
-- -----------------------------------------------------------------------------
function RedpointHelper.MainCityCustom_IsNew()
    return Storage.MainCityCustom.bNew
end

function RedpointHelper.MainCityCustom_ClearAll()
    Storage.MainCityCustom.bNew = false
    Storage.MainCityCustom.Flush()
end

-- -----------------------------------------------------------------------------
-- 名剑大会
-- -----------------------------------------------------------------------------
function RedpointHelper.ArenaLevelReward_HasRedPoint(nArenaType)
    if not ArenaData.tbLevelRewardInfo then
        ArenaData.GetLevelAwardInfo()
        return false
    end

    return not not ArenaData.tbLevelRewardInfo[nArenaType]
end

-- -----------------------------------------------------------------------------
-- 绝境战场-寻宝模式
-- -----------------------------------------------------------------------------
function RedpointHelper.ExtractReward_HasRedPoint()
    return PvpExtractData.CanGetBPReward()
end

-- -----------------------------------------------------------------------------
-- 日历活动
-- -----------------------------------------------------------------------------
function RedpointHelper.Activity_HasRedPoint(nType)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.ActivityCalendar) then
        return false
    end

    return ActivityData.CheckNewActivity(nType)
end

-- -----------------------------------------------------------------------------
-- 信息追踪
-- -----------------------------------------------------------------------------
function RedpointHelper.TraceInfo_HasRedPoint(szInfoType)
    return Storage.TraceInfo.tbTraceData[szInfoType]
end

function RedpointHelper.TraceInfo_SetNew(szInfoType, bIsNew)
    Storage.TraceInfo.tbTraceData[szInfoType] = bIsNew
    Storage.TraceInfo.Flush()
    Event.Dispatch(EventType.OnUpdateTraceInfoRedPoint)
end

function RedpointHelper.TraceInfo_ClearAll(szInfoType, bIsNew)
    Storage.TraceInfo.tbTraceData = {}
    Storage.TraceInfo.Flush()
    Event.Dispatch(EventType.OnUpdateTraceInfoRedPoint)
end

-- -----------------------------------------------------------------------------
-- 小头像
-- -----------------------------------------------------------------------------
function RedpointHelper.Avatar_SetNew(dwID, bIsNew)
    local tInfo = Table_GetRoleAvatarInfo(dwID)
    if not tInfo then
        return
    end

    if bIsNew then
        Storage.Avatar.tbNewAvatar[dwID] = true
        Storage.Avatar.Flush()
    else
        Storage.Avatar.tbNewAvatar[dwID] = nil
        Event.Dispatch(EventType.OnAvatarNewUpdate)
    end
end

function RedpointHelper.Avatar_IsNew(dwID)
    local bResult = false

    bResult = Storage.Avatar.tbNewAvatar[dwID]

    return bResult
end

function RedpointHelper.Avatar_HasNew()
    local bResult = false

    local nLen = table.get_len(Storage.Avatar.tbNewAvatar)
    bResult = nLen > 0

    return bResult
end

-- -----------------------------------------------------------------------------
-- 副本相关
-- -----------------------------------------------------------------------------
function RedpointHelper.AuctionLootList_SetNew(dwDoodadID, nLootItemIndex)
    for _, tRedPoint in ipairs(Storage.Auction.tRedPointLootItemList) do
        if tRedPoint.dwDoodadID == dwDoodadID and tRedPoint.nLootItemIndex == nLootItemIndex then
            return
        end
    end
    table.insert(Storage.Auction.tRedPointLootItemList, {
        dwDoodadID = dwDoodadID,
        nLootItemIndex = nLootItemIndex
    })
    Storage.Auction.Flush()
    Event.Dispatch(EventType.OnAuctionLootListRedPointChanged)
end

function RedpointHelper.AuctionLootList_Clear(dwDoodadID, nLootItemIndex)
    if not dwDoodadID then return end
    for nIndex, tRedPoint in ipairs(Storage.Auction.tRedPointLootItemList) do
        if tRedPoint.dwDoodadID == dwDoodadID and (not nLootItemIndex or tRedPoint.nLootItemIndex == nLootItemIndex) then
            table.remove(Storage.Auction.tRedPointLootItemList, nIndex)
            break
        end
    end

    Storage.Auction.Flush()
    Event.Dispatch(EventType.OnAuctionLootListRedPointChanged)
end

function RedpointHelper.AuctionLootList_ClearAll()
    Storage.Auction.tRedPointLootItemList = {}
    Storage.Auction.Flush()
    Event.Dispatch(EventType.OnAuctionLootListRedPointChanged)
end

function RedpointHelper.AuctionLootList_HasRedPoint(dwDoodadID, nLootItemIndex)
    if dwDoodadID == nil then
        return #Storage.Auction.tRedPointLootItemList > 0
    end
    for _, tRedPoint in ipairs(Storage.Auction.tRedPointLootItemList) do
        if tRedPoint.dwDoodadID == dwDoodadID and (nLootItemIndex == nil or tRedPoint.nLootItemIndex == nLootItemIndex) then
            return true
        end
    end

    return false
end

function RedpointHelper.AuctionLootList_HasRedPointWithoutNoPromot()
    for _, tRedPoint in ipairs(Storage.Auction.tRedPointLootItemList) do
        if not CheckIsInTable(Storage.Auction.tNoPromotDoodadList, {tRedPoint.dwDoodadID, tRedPoint.nLootItemIndex}) then
            return true
        end
    end

    return false
end

-- -----------------------------------------------------------------------------
-- 商店相关
-- -----------------------------------------------------------------------------
function RedpointHelper.SystemShop_SetNew(dwShopID, bIsNew)
    if bIsNew == false and not Storage.Shop.tbRedPointShopIDMap[dwShopID] then return end

    Storage.Shop.tbRedPointShopIDMap[dwShopID] = bIsNew

    Storage.Shop.Flush()
    Event.Dispatch(EventType.OnShopRedPointChanged)
end

-- 商店是否有红点，true为有红点，false为红点被清除，nil则不存在红点规则
function RedpointHelper.SystemShop_HasRedPoint(dwShopID)
    if dwShopID == nil then
        for _, bHasRedPoint in pairs(Storage.Shop.tbRedPointShopIDMap) do
            if bHasRedPoint then return true end
        end
        return false
    end
    return Storage.Shop.tbRedPointShopIDMap[dwShopID]
end

-- -----------------------------------------------------------------------------
-- 地图预约
-- -----------------------------------------------------------------------------
function RedpointHelper.MapAppointment_SetNew(dwID, bIsNew)
    Storage.MapAppointment.tbNewAppointment[dwID] = bIsNew
    Storage.MapAppointment.Flush()
    Event.Dispatch(EventType.OnMapAppointmentNewUpdate)
end

function RedpointHelper.MapAppointment_HasRedPoint(dwID)
    -- 2024.8.5 预约不要加红点 大侠之路除了奖励都不要给红点
    -- local nState = AppointmentData.GetMapAppointmentStateByID(dwID)
    -- if nState == MAP_APPOINTMENT_SATE.CAN_BOOK and Storage.MapAppointment.tbNewAppointment[dwID] then
    --     return true
    -- end

    return false
end