local tSkillTabs = UISkillTab

TabHelper = TabHelper or {}

function TabHelper.GetUIViewTab(nViewID)
    if not nViewID then
        LOG.ERROR("TabHelper.GetUIViewTab nViewID is nil")
        return
    end

    local tbConfig = UIViewTab[nViewID]
    if not tbConfig then
        LOG.ERROR(string.format("TabHelper.GetUIViewTab nViewID is not config! nViewID:%d", nViewID))
        return
    end

    return tbConfig
end

function TabHelper.GetUIPrefabTab(nPrefabID)
    if not nPrefabID then
        LOG.ERROR("TabHelper.GetUIPrefabTab nPrefabID is nil")
        return
    end

    local tbConfig = UIPrefabTab[nPrefabID]
    if not tbConfig then
        LOG.ERROR(string.format("TabHelper.GetUIPrefabTab nPrefabID is not config! nPrefabID:%d", nPrefabID))
        return
    end

    return tbConfig
end

function TabHelper.GetUICharacterInfoAttribTab(nID)
    if not nID then
        LOG.ERROR("TabHelper.GetUICharacterInfoAttribTab nID is nil")
        return
    end

    local tbConfig = UICharacterInfoAttribTab[nID]
    return tbConfig or {}
end

function TabHelper.GetUICharacterInfoMainAttribShowTab(nID)
    if not nID then
        LOG.ERROR("TabHelper.GetUICharacterInfoMainAttribShowTab nID is nil")
        return
    end

    local tbConfig = UICharacterInfoMainAttribShowTab[nID]
    return Lib.copyTab(tbConfig or {})
end

local skillStorageCustomType = CustomDataType.Role

function TabHelper.GetUISkillSocket(nForceID)
    if not nForceID then
        LOG.ERROR("TabHelper.GetUISkillSocket 传入空的 nForceID(配置表名： UISkillSocketTab)")
        return
    end

    if not UISkillSocketTab[nForceID] then
        LOG.ERROR("TabHelper.GetUISkillSocket 找不到 %d 对应的配置(配置表名: UISkillSocketTab)", nForceID)
    end

    return UISkillSocketTab[nForceID]
end

function TabHelper.GetUISkillSkinInfo(nSkillID, nSkinID)
    if not nSkillID then
        return
    end

    if not UISkillSkinTab[nSkillID] or not UISkillSkinTab[nSkillID][nSkinID] then
        return
    end

    return UISkillSkinTab[nSkillID][nSkinID]
end

---comment 获取技能槽位信息
---@param nForceID number 角色门派
---@param nSlot number 槽位
---@return UISkillDefaultSlot 槽位配置
function TabHelper.GetUISkillSlotInfo(nForceID, nSlot)
    local tForceCfg = UISkillSocketTab[nForceID]
    if not tForceCfg then
        LOG.ERROR("TabHelper.GetUISkillSocket 找不到 %d 对应的配置(配置表名: UISkillSocketTab)", nForceID)
        return UISkillDefaultSlot
    end

    return tForceCfg[nSlot] or UISkillDefaultSlot
end


---comment 获取技能UI配置
---@param nID integer 技能ID
---@return _SkillTab
function TabHelper.GetUISkillMap(nID)
    return tSkillTabs[nID]
end

---comment 获取技能UI配置
---@param nID integer 技能ID
---@return _SkillTab
function TabHelper.GetUISkill(nID)
    return tSkillTabs[nID]
    -- if not nID then
    --     LOG.ERROR("TabHelper.GetUISkill 传入空的 ID (配置表名: UISkillTab)")
    --     return
    -- end

    -- local tTab = tSkillTabs[nID]
    -- if not tTab then
    --     --[[LOG.ERROR("TabHelper.GetUISkill 找不到 {0} ID 对应的配置 (配置表名: UISkillTab)", nID)]]
    --     return tSkillTabs[100003]
    -- end
    -- return tTab
end

function TabHelper.GetDisplaySkill(nID)
    local tSkill = TabHelper.GetUISkill(nID)
    if tSkill and tSkill.nDamageParentID and tSkill.nDamageParentID ~= 0 then
        tSkill = TabHelper.GetUISkill(tSkill.nDamageParentID)
    end
    return tSkill
end

function TabHelper.GetUIBeforeSkillTab(skillID)
    return nil
end

function TabHelper.GetEquipRecommend(nRecommendID)
    if not nRecommendID then
        LOG.ERROR("TabHelper.GetEquipRecommend nRecommendID is nil")
        return
    end

    local tbConfig = g_tTable.EquipRecommend:Search(nRecommendID)
    if not tbConfig then
        return
    end

    local tb = {}
    tb.dwID = tbConfig.dwID
    tb.desc = UIHelper.GBKToUTF8(tbConfig.szDesc)
    tb.kungfu_ids = tbConfig.kungfu_ids

    return tb
end

function TabHelper.GetUISkillRecipeInfo(nRecipeID)
    if not nRecipeID then
        LOG.ERROR("TabHelper.GetUISkillRecipeInfo nRecipeID is nil")
        return
    end

    local tbConfig = UISkillRecipeTab[nRecipeID]
    if not tbConfig then
        return
    end

    return tbConfig
end

function TabHelper.GetSkillIconPath(nSkillID)
    if nSkillID == nil then
        return nil
    end

    local skillInfo = TabHelper.GetUISkillMap(nSkillID)
    if not skillInfo then
        return nil
    end

    local nIconID = skillInfo.nIconID
    if not nIconID or nIconID == 0 then
        local sorceSkillInfo = skillInfo.nSourceSkillID and TabHelper.GetUISkillMap(skillInfo.nSourceSkillID)
        nIconID = sorceSkillInfo and sorceSkillInfo.nIconID or 0
    end

    local iconTab = Table_GetItemIconInfo(nIconID)
    local path = nil
    if iconTab == nil then
        LOG.ERROR("GetSkillIconPath Failed, nSkillID is %d", nSkillID or -10000000)
    else
        path = iconTab.FileName
    end
    return path
end

function TabHelper.GetSkillIconPathByIDAndLevel(nSkillID, dwSkillLevel)
    if nSkillID == nil or dwSkillLevel == nil then
        return nil
    end
    local dwSkillIconID = Table_GetSkillIconID(nSkillID, dwSkillLevel)
    local iconTab = Table_GetItemIconInfo(dwSkillIconID)
    local path = nil
    if iconTab == nil then
        LOG.ERROR("GetSkillIconPath Failed, nSkillID is %d", nSkillID or -10000000)
    else
        path = iconTab.FileName
        if not string.find(path, "Resource/icon/") then
            path = "Resource/icon/" .. path
        end
    end
    return path
end


function TabHelper.GetBuffIconPath(nBuffID, nLevel)
    local nBuffIcon = Table_GetBuffIconID(nBuffID, nLevel)
    if not nBuffIcon then
        return
    end
    local iconTab = Table_GetItemIconInfo(nBuffIcon)
    if not iconTab then
        LOG.ERROR("GetBuffIconPath Failed, nBuffID is %d, nLevel is %d", nBuffID, nLevel)
    end
    return iconTab and iconTab.FileName or ""
end

function TabHelper.GetUIArenaRankLevelTab(nID)
    if not nID then
        LOG.ERROR("TabHelper.GetUIArenaRankLevelTab nID is nil")
        return
    end

    local tbConfig = UIArenaRankLevelTab[nID]
    return tbConfig
end

function TabHelper.GetUIRuleTab(nID)
    if not nID then
        LOG.ERROR("TabHelper.GetUIRuleTab nID is nil")
        return
    end

    local tbConfig = UIRuleTab[nID]
    if not tbConfig then
        LOG.ERROR(string.format("TabHelper.GetUIRuleTab nID is not config! nID:%d", nID))
        return
    end

    return tbConfig
end

function TabHelper.GetUICameraConfigTab(szType, nID)
    if not szType or not nID then
        LOG.ERROR("TabHelper.GetUICameraConfigTab szType:%s, nID:%s", tostring(szType), tostring(nID))
        return
    end
    return UICameraConfigTab[szType][nID]
end

function TabHelper.GetUIRewardsCameraTab(nCameraID, nRoleType)
    if not nCameraID then
        LOG.ERROR("TabHelper.GetUIRewardsCameraTab nCameraID is nil")
        return
    end

    if not nRoleType then
        LOG.ERROR("TabHelper.GetUIRewardsCameraTab nRoleType is nil")
        return
    end

    local tbConfig = {}
    for key, val in pairs(UIRewardsCameraTab) do
        if val["nCameraID"] == nCameraID and val["nRoleType"] == nRoleType then
            tbConfig = val
            break
        end
    end

    return tbConfig
end

function TabHelper.GetUISelfieFilterTab(nIndex)
    if not nIndex then
        LOG.ERROR("TabHelper.GetUISelfieFilterTab nIndex is nil")
        return
    end
    return UISelfieFilterTab[nIndex]
end

function TabHelper.IsHDKungfuID(dwKungfuID)
    if not dwKungfuID then
        LOG.ERROR("TabHelper.IsHDKungfuID dwKungfuID is nil")
        return
    end
    -- 目前GetMobileKungfuID接口会有以下几种情况
    -- 1. 传入端游心法ID，将会返回手游的心法ID
    -- 2. 传入手游的心法ID，将会返回该值本身
    -- 3. 其他情况则返回0
    -- 所以目前这个判定条件要增加判断不等于传入的值本身
    local dwResult = GetMobileKungfuID(dwKungfuID)
    return dwResult ~= 0 and dwResult ~= dwKungfuID
end

function TabHelper.GetHDKungfuID(dwMobileKungfuID)
    if not dwMobileKungfuID then
        LOG.ERROR("TabHelper.GetHDKungfuID dwMobileKungfuID is nil")
        return
    end

    return GetHDKungfuID(dwMobileKungfuID)
end

function TabHelper.GetMobileKungfuID(dwHDKungfuID)
    if not dwHDKungfuID then
        LOG.ERROR("TabHelper.GetMobileKungfuID dwHDKungfuID is nil")
        return
    end

    return GetMobileKungfuID(dwHDKungfuID)
end

function TabHelper.GetUITeachBoxTab(nIndex)
    if not nIndex then
        LOG.ERROR("TabHelper.GetUITeachBoxTab nIndex is nil")
        return
    end
    return UITeachBoxTab[nIndex]
end

function TabHelper.GetUIPrivateHomeSkinTab(nMapID, nSkinID, nAreaID)
    if not nMapID then
        LOG.ERROR("TabHelper.GetUIPrivateHomeSkinTab nMapID is nil")
        return
    end

    if not nSkinID then
        LOG.ERROR("TabHelper.GetUIPrivateHomeSkinTab nSkinID is nil")
        return
    end

    if not nAreaID then
        LOG.ERROR("TabHelper.GetUIPrivateHomeSkinTab nAreaID is nil")
        return
    end

    if not UIPrivateHomeSkinTab[nMapID] or not UIPrivateHomeSkinTab[nMapID][nSkinID] or not UIPrivateHomeSkinTab[nMapID][nSkinID][nAreaID] then

    end

    return UIPrivateHomeSkinTab[nMapID][nSkinID][nAreaID]
end

function TabHelper.GetUILoginScenePresetEffectTab(szPresetName)
    local tbEffect = {}
    for k, v in pairs(UILoginScenePresetEffectTab) do
        if v.szPresetName == szPresetName then
            table.insert(tbEffect , v)
        end
    end
    return tbEffect
end


function TabHelper.GetUILoginSchoolBodyClothTab(nRoleType , nForceID)
    local tbBodyCloth = {}
    for k, v in ipairs(UILoginSchoolBodyClothTab) do
        if v.nForceID == nForceID and v.nRoleType == nRoleType then
            table.insert(tbBodyCloth , v)
        end
    end
    return tbBodyCloth
end

function TabHelper.GetUIFontSizeTab(szDevice, nMode)
    local tbSize
    for k, v in pairs(UIFontSizeTab) do
        if v.szDevice == szDevice and v.nMode == nMode then
            tbSize = v
        end
    end
    return tbSize
end

function TabHelper.GetTipsScaleTab(szName, bPanel)
    local tbScaleInfo = {}
    for k, v in pairs(UITipsSizeTab) do
        if bPanel and szName == v.szPanelParentName then
            tbScaleInfo = v
        elseif v.szPrefabName == szName then    --预制
            tbScaleInfo = v
        end
    end
    return tbScaleInfo
end

function TabHelper.GetBaiZhanDbmInfo(nGroupID)
    return Table_GetBaizhanDbmByGroupID(nGroupID)
end

function TabHelper.GetBaiZhanDbmInfoBynID(nID)
    return Table_GetBaizhanDbmByID(nID)
end

local tOperationActivityMap = nil
function TabHelper.GetHuaELouActivityByOperationID(nOperationID)
    if not tOperationActivityMap then
        tOperationActivityMap = {}
        for _, v in pairs(UIHuaELouActivityTab) do
            tOperationActivityMap[v.dwOperatActID] = v
        end
    end
    return tOperationActivityMap[nOperationID]
end