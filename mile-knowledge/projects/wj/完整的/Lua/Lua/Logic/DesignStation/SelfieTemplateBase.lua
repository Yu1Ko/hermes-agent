-- ---------------------------------------------------------------------------------
-- Author: yuminqian
-- Name: SelfieTemplateBase
-- Date: 2025-09-25 15:28:47
-- Desc: 幻境云图照片数据导出本地及导入后数据使用相关接口，dx对应脚本同名。
-- ---------------------------------------------------------------------------------
SelfieTemplateBase = SelfieTemplateBase or {className = "SelfieTemplateBase"}
local self = SelfieTemplateBase

local _SELFIE_PHOTO_DATA_VERSION = 2

local m_ImportState = false
local m_ExportState = false
local m_tData = {}
local bUsedAction = false -- 处于成功使用动作状态
local bPlayAction = false -- 动作使用的类型是播放动作
local bOnGuild = false    -- 处于追踪状态
local bArrive = false

local bSelfieFreeze = false -- 幻境云图定格标记
local bApplyAction = false  -- 导出申请动作等回调中
local bPlayActionFile = false -- id调用失败后用路径调用一次
local tFreezeAction = {}

local nPrivateVisitMap = 572 -- 私宅参观地图（不会被IsPrivateHomeMap和IsHomelandCommunityMap识别到）

local tDefaultExteriorData = {
    [EQUIPMENT_REPRESENT.HAIR_STYLE] = 0,            -- 发型 1
    [EQUIPMENT_REPRESENT.HELM_STYLE] = 0,            -- 外装收集-帽子 2
    [EQUIPMENT_REPRESENT.CHEST_STYLE] = 0,           -- 【成衣】或【外装收集-上衣】 5
    [EQUIPMENT_REPRESENT.WAIST_STYLE] = 0,           -- 外装收集-腰带 8
    [EQUIPMENT_REPRESENT.BANGLE_STYLE] = 0,          -- 外装收集-护腕 11
    [EQUIPMENT_REPRESENT.BOOTS_STYLE] = 0,           -- 外装收集-鞋子 14
    [EQUIPMENT_REPRESENT.WEAPON_STYLE] = 0,          -- 武器收集/藏剑轻剑 16
    [EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] = 0,       -- 武器收集-重剑 20
    [EQUIPMENT_REPRESENT.BACK_EXTEND] = 0,           -- 背部挂件 24
    [EQUIPMENT_REPRESENT.WAIST_EXTEND] = 0,          -- 腰部挂件 25
    [EQUIPMENT_REPRESENT.FACE_EXTEND] = 0,           -- 面部挂件 31
    [EQUIPMENT_REPRESENT.L_SHOULDER_EXTEND] = 0,     -- 左肩饰 32
    [EQUIPMENT_REPRESENT.R_SHOULDER_EXTEND] = 0,     -- 右肩饰 33
    [EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND] = 0,     -- 披风 34
    [EQUIPMENT_REPRESENT.BAG_EXTEND] = 0,            -- 佩囊 40
    [EQUIPMENT_REPRESENT.PENDENT_PET_STYLE] = 0,     -- 挂宠 41
    [EQUIPMENT_REPRESENT.GLASSES_EXTEND] = 0,        -- 眼饰 43
    [EQUIPMENT_REPRESENT.L_GLOVE_EXTEND] = 0,        -- 左手饰 44
    [EQUIPMENT_REPRESENT.R_GLOVE_EXTEND] = 0,        -- 右手饰 45
    [EQUIPMENT_REPRESENT.HEAD_EXTEND] = 0,           -- 1号头饰 46
    [EQUIPMENT_REPRESENT.HEAD_EXTEND1] = 0,          -- 2号头饰 51
    [EQUIPMENT_REPRESENT.HEAD_EXTEND2] = 0,          -- 3号头饰 52

    ["Footprint"] = 0,                               -- 脚印特效
    ["CircleBody"] = 0,                              -- 环身特效
    ["LHand"] = 0,                                   -- 左手特效
    ["RHand"] = 0,                                   -- 右手特效
}

local tPendantList = -- tRepresentSubToItemSub
{
	[EQUIPMENT_REPRESENT.WAIST_EXTEND] = EQUIPMENT_SUB.WAIST_EXTEND,          -- 腰部挂件
	[EQUIPMENT_REPRESENT.BACK_EXTEND] = EQUIPMENT_SUB.BACK_EXTEND, -- 背部挂件
	[EQUIPMENT_REPRESENT.FACE_EXTEND] = EQUIPMENT_SUB.FACE_EXTEND,    -- 面部挂件
	[EQUIPMENT_REPRESENT.L_SHOULDER_EXTEND] = EQUIPMENT_SUB.L_SHOULDER_EXTEND,-- 左肩饰
	[EQUIPMENT_REPRESENT.R_SHOULDER_EXTEND] = EQUIPMENT_SUB.R_SHOULDER_EXTEND,-- 右肩饰
	[EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND] = EQUIPMENT_SUB.BACK_CLOAK_EXTEND,-- 披风
	[EQUIPMENT_REPRESENT.BAG_EXTEND] = EQUIPMENT_SUB.BAG_EXTEND,      -- 佩囊
	[EQUIPMENT_REPRESENT.GLASSES_EXTEND] = EQUIPMENT_SUB.GLASSES_EXTEND,    -- 眼饰
	[EQUIPMENT_REPRESENT.L_GLOVE_EXTEND] = EQUIPMENT_SUB.L_GLOVE_EXTEND,   -- 左手饰
	[EQUIPMENT_REPRESENT.R_GLOVE_EXTEND] = EQUIPMENT_SUB.R_GLOVE_EXTEND,   -- 右手饰
    [EQUIPMENT_REPRESENT.HEAD_EXTEND] = EQUIPMENT_SUB.HEAD_EXTEND, -- 1号头饰
    [EQUIPMENT_REPRESENT.HEAD_EXTEND1] = EQUIPMENT_SUB.HEAD_EXTEND, -- 2号头饰
    [EQUIPMENT_REPRESENT.HEAD_EXTEND2] = EQUIPMENT_SUB.HEAD_EXTEND, -- 3号头饰
}

function SelfieTemplateBase.CancelPhotoActionDataUse()
    Player_EndApplyLocalPauseAnimation()
    bPlayAction = false
    if not bUsedAction then
        return
    end
    bUsedAction = false
    Event.Dispatch(EventType.OnActionDataUseState, false)
end

function SelfieTemplateBase.CancelFaceActionUse()
    rlcmd("pause face animation 0")
end

function SelfieTemplateBase.GetPhotoActionUseState()
    return bUsedAction
end

function SelfieTemplateBase.GetPhotoActionPlayState()
    return bPlayAction
end

function SelfieTemplateBase.SetPhotoActionFreezeState(bUsed)
    bUsedAction = bUsed
end

function SelfieTemplateBase.GetPhotoActionFreezeState()
    return bUsedAction
end

function SelfieTemplateBase.CheckPendantChangeCustomData(nRepresentSub, tDetails)
    if not tDetails then
        return
    end
    
    local tInfo = tDetails[nRepresentSub]
    if not tInfo or not tInfo.tCustomData then
        return
    end
    
    return true
end

function SelfieTemplateBase.CheckExteriorChangeColor(nRepresentSub, tDetails)
    if not tDetails then
        return
    end
    
    local tInfo = tDetails[nRepresentSub]
    if not tInfo or not tInfo.tColorID then
        return
    end
    
    return true
end

local tSFXPendant = {
    ["Footprint"] = 0,                               -- 脚印特效
    ["CircleBody"] = 0,                              -- 环身特效
    ["LHand"] = 0,                                   -- 左手特效
    ["RHand"] = 0,                                   -- 右手特效
}

local DEFAULT_CUSTOM_DATA = {
    fScale = 1,
    nOffsetX = 0, nOffsetY = 0, nOffsetZ = 0,
    fRotationX = 0, fRotationY = 0, fRotationZ = 0,
}

local EXPORT_CD_TIME = 5 * 1000
local nLastExportTime = nil
local nMajorVersion = 1 --代表现行版，也有部分老玩家是没有这个变量的，但是怀旧版玩家一定是2
local tRoleName =
{
    [1] = "standardmale",
    [2] = "standardfemale",
    [5] = "littleboy",
    [6] = "littlegirl",
}

local SELFIE_STUDIO_MAP_LIST    = {705}

local function AdjustDataPath(szPath, bCanReName)
	local szSuffix = ".dat"
	local szAdjust = szPath .. szSuffix
    if Platform.IsWindows() then
        if not Lib.IsFileExist(UIHelper.UTF8ToGBK(szAdjust), false) then
            return szAdjust
        end
    else
        if not Lib.IsFileExist(szAdjust, false) then
            return szAdjust
        end
	end

	if bCanReName == nil or bCanReName then
		for i = 1, 100 do
			local szAdjust = szPath .. "(" .. i.. ")" .. szSuffix
			if not Lib.IsFileExist(szAdjust) then
				return szAdjust
			end
		end

		local nTickCount = GetTickCount()
		szAdjust = szPath .. "(" .. nTickCount.. ")" .. szSuffix
	end

	return szAdjust
end


function SelfieTemplateBase.ExportedFolder()
	local szPath = UIHelper.GBKToUTF8(GetStreamAdaptiveDirPath(GetFullPath("selfiedata") .. "\\PhotoSettings_Mobile\\"))
    CPath.MakeDir(szPath)
    return szPath
end

local function ToggleFaceDecorationShowAndHide(tFaceData)
    local bShow = (tFaceData.nDecorationID and tFaceData.nDecorationID ~= 0)
    GetFaceLiftManager().SetDecorationShowFlag(bShow)
end

function SelfieTemplateBase.SavePhotoData(szFileName, tPhotoData, nRoleType, bIsVertical)
	local tPhotoData = clone(tPhotoData)
	tPhotoData.nVersion = _SELFIE_PHOTO_DATA_VERSION
	tPhotoData.bVertical = bIsVertical or false
    tPhotoData.szName = szFileName or "照片模板"

	local szPhotoDir = GetFullPath("selfiedata") .. "/PhotoSettings_Mobile/"

	CPath.MakeDir(szPhotoDir)

	if Platform.IsWindows() then
		szPhotoDir = UIHelper.GBKToUTF8(szPhotoDir)
	end

    local szSuffix = tRoleName[nRoleType]
	local nTime = GetCurrentTime()
	local time = TimeToDate(nTime)
	local szTime = string.format("%d%02d%02d-%02d%02d%02d", time.year, time.month, time.day, time.hour, time.minute, time.second)
    local szFileName = "PhotoSettings_Mobile_" .. szSuffix .. "_" .. szTime

	local szPath = szPhotoDir .. szFileName
	szPath = AdjustDataPath(szPath)
	szPath = string.gsub(szPath, "\\", "/")
	SaveLUAData(szPath, tPhotoData)

	return szPath, _SELFIE_PHOTO_DATA_VERSION
end

function SelfieTemplateBase.ExportData(szFileName, tPhotoData, nRoleType, bIsVertical, bUploadData)
	local nTime = GetTickCount()
	if SM_IsEnable() and nLastExportTime and nTime - nLastExportTime < EXPORT_CD_TIME then
		return false, g_tStrings.STR_PHOTO_DATA_EXPORT_CD
	end
	local szPath = SelfieTemplateBase.SavePhotoData(szFileName, tPhotoData, nRoleType, bIsVertical)
	nLastExportTime = nTime
	local szMsg = FormatString( g_tStrings.STR_PHOTO_DATA_EXPORT, szPath)

	if szPath then
		if not bUploadData then -- 是否就单纯导出到本地，不做提示
			if Platform.IsWindows() then
				local dialog = UIHelper.ShowConfirm(szMsg, function ()
					local i, folder, file = 0, GetStreamAdaptiveDirPath(GetFullPath("selfiedata") .. "/PhotoSettings_Mobile/")
					CPath.MakeDir(folder)
					OpenFolder(folder)
				end)
				dialog:SetButtonContent("Confirm", g_tStrings.FACE_OPEN_FLODER)
			else
				local scriptView = UIHelper.ShowConfirm(szMsg)
				scriptView:HideButton("Cancel")
			end
		end
		return true, szPath
	end

	return false, g_tStrings.PHOTO_DATA_EXPORT_FAIL
end

function SelfieTemplateBase.LoadPhotoData(szFile)
	if Platform.IsWindows() and not Lib.IsFileExist(szFile) then
		return
	end

	local tPhotoData = LoadLUAData(szFile, false, true, nil, true)
	if not tPhotoData or
		not tPhotoData.tSelfieParam or
		not tPhotoData.tPlayerParam then
		return
	end

	if not tPhotoData.nVersion then
		return
	end

    bPlayActionFile = false
	-- if tPhotoData.nMajorVersion and tPhotoData.nMajorVersion ~= nMajorVersion then --客户端不一致
    --     return nil, g_tStrings.COIN_PHOTODATA_ERROR
	-- end

    m_tData = tPhotoData
	return tPhotoData
end

function SelfieTemplateBase.GetPhotoData(bIsCardPhoto, bIsVertical)
    local tPhotoData = {
        nVersion = _SELFIE_PHOTO_DATA_VERSION,
        bVertical = bIsVertical or false,
        szName = "",
        bIsMobile = true,
        bIsCardPhoto = bIsCardPhoto or false,
        tSelfieParam = {},
        tPlayerParam = {},
    }
    m_tData.tSelfieParam = {}
    m_tData.tPlayerParam = {}
    m_tData.tPlayerParam.tAction = {dwAnimationID = -1, szAnimationFile = "", nAniOffset = 0}
    m_tData.tPlayerParam.tFaceAction = {dwFaceMotionID = -1, fFacePersent = 0,}
    SelfieTemplateBase.ApplyActionInfo(nil, true)
    tPhotoData.tSelfieParam = clone(SelfieTemplateBase.GetSelfieData())
    tPhotoData.tPlayerParam = clone(SelfieTemplateBase.GetPlayerData())

    return tPhotoData
end

function SelfieTemplateBase.ApplyActionInfo(bFreezeApply, bExportApply)
    if bFreezeApply then -- 幻境云图冻结时，apply并存一次动作信息
        bSelfieFreeze = bFreezeApply
    end
    if bExportApply then
        bApplyAction = bExportApply
    end
    rlcmd("GetLocalAnimationInfo") -- 人物、表情动作申请
end

function SelfieTemplateBase.ResertFreezeActionInfo()
    bSelfieFreeze = false
    tFreezeAction = {}
end

function SelfieTemplateBase.OnExitActionAccident()
    SelfieTemplateBase.CancelPhotoActionDataUse()
    OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_SELFIE_PHOTO_BE_EXIT_ACTION)
end

function SelfieTemplateBase.OnGetLocalAnimationInfoResult(dwAnimationID, szAnimationPath, bAnimationIDMatchFilePath, nAniOffset, nFrame, dwFaceMotionID, fFacePersent)
    local tResult = {
        dwAnimationID = dwAnimationID, 
        szAnimationFile = szAnimationPath, 
        bAnimationIDMatchFilePath = bAnimationIDMatchFilePath,
        nAniOffset = nAniOffset, 
        nFrame = nFrame,
        dwFaceMotionID = dwFaceMotionID,
        fFacePersent = fFacePersent,
    }
    -- fFacePersent 后续数值改成了nOffset，但由于网页校验规则已确定，因此此处参数名字不做修改
    if bSelfieFreeze then -- 定格时申请的动作数据记在tFreezeAction里
        tFreezeAction = clone(tResult)
        bSelfieFreeze = false
    end

    if bApplyAction and m_tData.tPlayerParam and m_tData.tPlayerParam.tAction and m_tData.tPlayerParam.tFaceAction then
        local tTrueAction = tResult
        m_tData.tPlayerParam.tAction = {dwAnimationID = 0, szAnimationFile = "", nAniOffset = 0}
        if SelfieData.IsInFreeAnimation() then
            tTrueAction = clone(tFreezeAction)
        end

        m_tData.tPlayerParam.tFaceAction = {
            dwFaceMotionID  = tTrueAction.dwFaceMotionID,
            fFacePersent = tTrueAction.fFacePersent,
        }

        local tInfo = SelfieTemplateBase.GetActionInfo(tTrueAction.dwAnimationID)
        if tInfo then
            if tTrueAction.bAnimationIDMatchFilePath == 1 or tInfo.bSkillSkin then -- 匹配路径或者是技能皮肤
                m_tData.tPlayerParam.tAction = {
                    dwAnimationID   = tTrueAction.dwAnimationID,
                    szAnimationFile = tTrueAction.szAnimationFile,
                    nAniOffset      = tTrueAction.nAniOffset,
                    nFrame          = tTrueAction.nFrame,
                }
                OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_SELFIE_PHOTO_ACTION_EXPORT_SUCCESS)
            end
        end
        if tTrueAction.dwAnimationID == 0 then
            OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_SELFIE_PHOTO_ACTION_EXPORT_FALILED)
        end
        bApplyAction = false
        Event.Dispatch(EventType.OnSelfieGetLocalAnimationSuccess, m_tData.tPlayerParam.tAction, m_tData.tPlayerParam.tFaceAction)
    end
end

function SelfieTemplateBase.OnGetLocalAnimationApplyResult(bSuccess)
    local bSuccess = 1 and true or false
    if bSuccess then
        OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_SELFIE_PHOTO_ACTION_USE_SUCCESS)
        bUsedAction = true
        Event.Dispatch(EventType.OnActionDataUseState, true)
    else
        if not bPlayActionFile then
            bPlayActionFile = true
            Event.Dispatch("OnApplyToSetActionByFile")
        else
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_SELFIE_PHOTO_ACTION_USE_FAILED)
        end
    end
end

function SelfieTemplateBase.OnGetLocalFaceActionApplyResult(bSuccess)
    local bSuccess = 1 and true or false
    if bSuccess then
        OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_SELFIE_PHOTO_FACEACTION_USE_SUCCESS)
    else
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_SELFIE_PHOTO_FACEACTION_USE_FAILED)
    end
end

-- function SelfieTemplateBase.RegEvent()
    Event.Reg(self, "EXIT_APPLY_PAUSE_ANIMATSION", function()
        SelfieTemplateBase.OnExitActionAccident()
    end)
    Event.Reg(self, "GET_LOCAL_ANIMATION_INFO_RESULT", function(dwAnimationID, szAnimationPath, bAnimationIDMatchFilePath, nAniOffset, nFrame, dwFaceMotionID, fFacePersent)
        SelfieTemplateBase.OnGetLocalAnimationInfoResult(dwAnimationID, szAnimationPath, bAnimationIDMatchFilePath, nAniOffset, nFrame, dwFaceMotionID, fFacePersent)
    end)
    Event.Reg(self, "APPLY_LOCAL_PAUSE_ANIMATION_RES", function(bSuccess)
        SelfieTemplateBase.OnGetLocalAnimationApplyResult(bSuccess)
    end)
    Event.Reg(self, EventType.OnSelfieFrameFreezeState, function(bIsFreeze)
        if bIsFreeze then
            SelfieTemplateBase.ApplyActionInfo(true) -- 此举是记录定格此刻的动作数据
        else
            SelfieTemplateBase.ResertFreezeActionInfo()
        end
    end)
    Event.Reg(self, "APPLY_FACE_PAUSE_ANIMATION_RES", function(bSuccess)
        SelfieTemplateBase.OnGetLocalFaceActionApplyResult(bSuccess)
    end)
    Event.Reg(self, "OnMapUpdateNpcTrace", function(bNearAutoClear)
        if bNearAutoClear == true and bOnGuild then
            bArrive = true
        end
    end)
-- end

function SelfieTemplateBase.GetSelfieData()
    local tSelfieParam = {
        tBase = SelfieTemplateBase.UpdateBaseData(),
        tWind = SelfieTemplateBase.UpdateWindData(),
        tLight = SelfieTemplateBase.UpdateLightData(),
        tFilter = SelfieTemplateBase.UpdateFilterData(),
    }
    m_tData.tSelfieParam = tSelfieParam
    return tSelfieParam
end

local function CheckFaceDecoration(tFaceData)
    local hManager = GetFaceLiftManager()
    if not hManager then
        return
    end
    local bShow = hManager.GetDecorationShowFlag()
    if tFaceData and tFaceData.nDecorationID and not bShow then -- 有装饰物数据，但不显示
        tFaceData.nDecorationID = 0
    end
end

function SelfieTemplateBase.GetPlayerData()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return 
    end
    m_tData.tPlayerParam = m_tData.tPlayerParam or {}
    m_tData.tPlayerParam.dwForceID = hPlayer.dwForceID
    m_tData.tPlayerParam.dwKungFu = UI_GetPlayerMountKungfuID()
    m_tData.tPlayerParam.nRoleType = Player_GetRoleType(hPlayer)  -- 体型（男、女、萝、太）
    m_tData.tPlayerParam.tAction = {dwAnimationID = -1, szAnimationFile = "", nAniOffset = 0} -- 动作
    m_tData.tPlayerParam.tFaceAction = {dwFaceMotionID = -1, fFacePersent = 0,}               -- 面部表情
    m_tData.tPlayerParam.bNewFace = ExteriorCharacter.IsNewFace()
    m_tData.tPlayerParam.tFace = hPlayer.GetEquipLiftedFaceData()
    CheckFaceDecoration(m_tData.tPlayerParam.tFace)
    m_tData.tPlayerParam.tBody = hPlayer.GetEquippedBodyBoneData()
    m_tData.tPlayerParam.tPlace = SelfieTemplateBase.GetPlayerPlaceData(hPlayer)
    m_tData.tPlayerParam.tExterior = SelfieTemplateBase.GetPlayerExteriorData(hPlayer, true)-- 搭配
    return m_tData.tPlayerParam
end

function SelfieTemplateBase.GetActionInfo(dwAnimationID)
    return Table_GetSelfieActionInfo(dwAnimationID)
end

function SelfieTemplateBase.GetActionType(dwAnimationID, tExteriorList)
    local tInfo = SelfieTemplateBase.GetActionInfo(dwAnimationID)
    if not tInfo or IsTableEmpty(tInfo) then
        return
    end

    local nPendantType = 4

    local dwTabType_Toy = 5
    local nToyType = 6

    local tFlag = {}
    if tExteriorList then
        for _, dwID in pairs(tExteriorList) do
            tFlag[dwID] = true
        end
    end

    local GetActionTypeAndID = function ()
        local nType, dwLogicID
        if tInfo.tLogicID and not IsTableEmpty(tInfo.tLogicID) then
            for nActionType, tLogic in pairs(tInfo.tLogicID) do
                for _, dwActionLogicID in ipairs(tLogic) do
                    if not nType or not dwLogicID then
                        nType, dwLogicID = nActionType, dwActionLogicID 
                    elseif nType == nPendantType and tFlag and tFlag[dwActionLogicID] then 
                        nType, dwLogicID = nActionType, dwActionLogicID
                    elseif nType == nToyType and ItemData.IsItemCollected(dwTabType_Toy, dwActionLogicID) then 
                        nType, dwLogicID = nActionType, dwActionLogicID
                    end
                end
            end
        end
        if nType and dwLogicID then
            return nType, dwLogicID
        end
    
        if tInfo.tAndLogic and not IsTableEmpty(tInfo.tAndLogic) then
            for _, tGroup in ipairs(tInfo.tAndLogic) do
                for nActionType, tLogic in pairs(tGroup) do
                    for _, dwActionLogicID in ipairs(tLogic) do
                        if not nType or not dwLogicID then
                            nType, dwLogicID = nActionType, dwActionLogicID 
                        elseif nType == nPendantType and tFlag and tFlag[dwActionLogicID] then 
                            nType, dwLogicID = nActionType, dwActionLogicID
                        elseif nType == nToyType and ItemData.IsItemCollected(dwTabType_Toy, dwActionLogicID) then 
                            nType, dwLogicID = nActionType, dwActionLogicID
                        end
                    end
                end
            end
        end
        return nType, dwLogicID
    end
    local nType, dwLogicID = GetActionTypeAndID()
    if not nType or not dwLogicID then
        return
    end
    
    return nType, dwLogicID
end

function SelfieTemplateBase.UpdateActionBoxInfo(dwAnimationID, itemScript, tExteriorList)
    local tInfo = SelfieTemplateBase.GetActionInfo(dwAnimationID)
    if not tInfo or IsTableEmpty(tInfo) then
        return
    end

    local nType, dwLogicID = SelfieTemplateBase.GetActionType(dwAnimationID, tExteriorList)
    local szDsc = g_tStrings.tActionType[nType]
    local szName = szDsc

    local tUpdateActionInfo = {
        [1] = {fnUpdate = function()
            return false
        end},
        [2] = {fnUpdate = function()
            local tInfo = EmotionData.GetEmotionAction(dwLogicID)
            if not tInfo then
                return false
            end
            itemScript:OnInitWithIconID(tInfo.nIconID)
            return UIHelper.GBKToUTF8(tInfo.szName)
        end},
        [3] = {fnUpdate = function()
            local tInfo = Table_GetIdleAction(dwLogicID)
            if not tInfo then
                return false
            end
            itemScript:OnInitWithTabID(tInfo.dwItemType, tInfo.dwItemID)
            return UIHelper.GBKToUTF8(tInfo.szActionName)
        end},
        [4] = {fnUpdate = function()
            local hItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwLogicID)
            itemScript:OnInitWithTabID(ITEM_TABLE_TYPE.CUST_TRINKET, dwLogicID)
            return UIHelper.GBKToUTF8(hItemInfo.szName)
        end},
        [5] = {fnUpdate = function()
            local szName = CoinShop_GetGoodsName(COIN_SHOP_GOODS_TYPE.EXTERIOR, dwLogicID) or szDsc
            local szName
            local bCollect = CoinShop_GetCollectInfo(COIN_SHOP_GOODS_TYPE.EXTERIOR, dwLogicID)
            if not bCollect then
                szName = CoinShop_GetGoodsName(COIN_SHOP_GOODS_TYPE.EXTERIOR, dwLogicID)
                szName = UIHelper.GBKToUTF8(szName)
            else
                local hExteriorClient = GetExterior()
                if not hExteriorClient then
                    return
                end
                local tExteriorInfo = hExteriorClient.GetExteriorInfo(dwLogicID)
                local tbSet = Table_GetExteriorSet(tExteriorInfo.nSet)
                local szSub = g_tStrings.tExteriorSubNameGBK[tExteriorInfo.nSubType]
                szName = UIHelper.GBKToUTF8(tbSet.szSetName .. g_tStrings.STR_CONNECT_GBK .. szSub)
            end
            local tInfo = {}
            tInfo.dwGoodsID = dwLogicID
            tInfo.eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR
            CoinShopPreview.InitItemIcon(itemScript, tInfo, nil, nil)
            return szName
        end},
        [6] = {fnUpdate = function()
            local tToy = Table_GetToyBoxByItem(dwLogicID)
            if not tToy or not tToy.dwID then
                return false, false
            end
            itemScript:OnInitWithTabID(5, dwLogicID)
            return UIHelper.GBKToUTF8(tToy.szName)
        end}
    }

    local bHaveBox = false
    if tUpdateActionInfo[nType] then
        szName = tUpdateActionInfo[nType].fnUpdate()
        if szName then
            bHaveBox = true
        end
    end
    if not szName then
        szName = szDsc
    end

    return szName, szDsc, bHaveBox
end

function SelfieTemplateBase.GetPlayerPlaceData(hPlayer)
    local tPlace = {
        nX = hPlayer.nX, 
        nY = hPlayer.nY, 
        nZ = hPlayer.nZ,
        dwMapID = hPlayer.GetMapID(),
        nFaceDirection = hPlayer.nFaceDirection   -- 朝向
    }     
    -- tPlace.tStudio = {dwID = 0, nPreset = 0, nWeather = 0,}  -- 万景阁预设

    if SelfieData.IsInStudioMap(tPlace.dwMapID) then
        tPlace.tStudio = {
            dwID = GDAPI_GetPhotoStudioInfo(hPlayer, tPlace.dwMapID) or 0,
            nPreset = SelfieData.nPresetIndex or 0,
            nWeather = SelfieData.GetDynamicWeather() or 0,
        }
    end
    return tPlace
end

function SelfieTemplateBase.GetMapParams()
    local szEnvPreset
    local nMapID = g_pClientPlayer.GetMapID()
    local tAtmosphere = Table_GetFilterAtmosphere(nMapID)
    local tMapParam = Storage.FilterParam.tbMapParams[nMapID]

    if tAtmosphere and tMapParam then
        local szTime = tMapParam.szTime
        local szWeather = tMapParam.szWeather
        szEnvPreset = tAtmosphere[szTime] and tAtmosphere[szTime][szWeather]
	end
end

function SelfieTemplateBase.GetPlayerExteriorData(hPlayer, bSelfiePhoto)
    if not hPlayer then
        return
    end

    local tExterior = {}
    local tRepresentID = hPlayer.GetRepresentID()
    local tShowRes = Player_GetEquipHideParam(
        Player_GetRoleType(hPlayer),
        EQUIPMENT_REPRESENT.TOTAL,
        tRepresentID,
        tRepresentID.bHideHat
    )
    if bSelfiePhoto then                    -- 处理幻境云图中的各个部位显示和隐藏
        local tShowSelfie = m_tData.tSelfieParam.tBase.tShowHide.tRoleBoxCheck
        for k, _ in pairs(tShowSelfie) do
            if not tShowSelfie[k] then
                tShowRes[k] = 0
            end
        end
    end
    
    tExterior.tExteriorID = SelfieTemplateBase.GetExteriortLogicIndex(hPlayer, tShowRes)
    tExterior.tDetail = SelfieTemplateBase.GetExteriortDetailInfo(hPlayer, tExterior.tExteriorID, tRepresentID)
    SelfieTemplateBase.UpdatePendantInfo(hPlayer, tExterior.tExteriorID, tExterior.tDetail, tShowRes)
    SelfieTemplateBase.UpdateSFXPendantInfo(hPlayer, tExterior.tExteriorID, tExterior.tDetail)
    return tExterior
end

function SelfieTemplateBase.GetExteriortLogicIndex(hPlayer, tShowRes)
    local hExteriorClient = GetExterior()
    if not hExteriorClient then
		return
	end

    local tData = clone(tDefaultExteriorData)
    local nCurrentSetID = hPlayer.GetCurrentSetID()
    local bShowExtrior = hPlayer.IsApplyExterior()

    if bShowExtrior then
        local tExteriorSet = hPlayer.GetExteriorSet(nCurrentSetID)
        for i = 1, EXTERIOR_SUB_NUMBER do
            local nExteriorSub  = Exterior_BoxIndexToExteriorSub(i)
            local nRepresentSub = Exterior_BoxIndexToRepresentSub(i)
            if tShowRes[nRepresentSub] ~= 0 then
                local dwExteriorID = tExteriorSet[nExteriorSub]
                tData[nRepresentSub] = dwExteriorID
            end
        end

        local tWeaponExterior = hPlayer.GetWeaponExteriorSet(nCurrentSetID)
        local tWeaponBox = CoinShop_GetWeaponIndexArray()
        for nBoxIndex, nWeaponSub in pairs(tWeaponBox) do
            local dwWeaponID = tWeaponExterior[nWeaponSub]
            local nRepresentSub = Exterior_BoxIndexToRepresentSub(nBoxIndex)
            if tShowRes[nRepresentSub] ~= 0 then
                tData[nRepresentSub] = dwWeaponID
                local tExteriorInfo = hExteriorClient.GetExteriorInfo(dwWeaponID)
            end
        end
    end

    for nRepresentSub, _ in pairs(tDefaultExteriorData) do
        local nEquipSub = Exterior_RepresentSubToEquipSub(nRepresentSub)
        if nEquipSub and tShowRes[nRepresentSub] ~= 0 and tData[nRepresentSub] == 0 then -- 表现有外观，但没取到外观，取装备外观
            local item = GetPlayerItem(hPlayer, INVENTORY_INDEX.EQUIP, nEquipSub)
            if item and item.dwTabType and item.dwIndex then
                local dwTabType, dwIndex = item.dwTabType, item.dwIndex
                local tItemInfo = GetItemInfo(dwTabType, dwIndex)
                local dwExteriorID
                if nRepresentSub == EQUIPMENT_REPRESENT.WEAPON_STYLE or nRepresentSub == EQUIPMENT_REPRESENT.BIG_SWORD_STYLE then
                    dwExteriorID = CoinShop_GetWeaponIDByItemInfo(tItemInfo)
                else
                    dwExteriorID = CoinShop_GetExteriorID(dwTabType, dwIndex) or -1
                end
                tData[nRepresentSub] = dwExteriorID or -1
            end
        end
    end

    -- 帽子不一定盖住了发型
    if tShowRes[EQUIPMENT_REPRESENT.HAIR_STYLE] ~= 0 then -- 发型外观
        tData[EQUIPMENT_REPRESENT.HAIR_STYLE] = tShowRes[EQUIPMENT_REPRESENT.HAIR_STYLE]
    end

    return tData
end

function SelfieTemplateBase.GetExteriortDetailInfo(hPlayer, tExteriorID, tRepresentID)
    local tRepresentID = tRepresentID or hPlayer.GetRepresentID()
    local tDetail = {}
    for nRepresentSub, dwID in pairs(tExteriorID) do
        local tInfo
        if nRepresentSub == EQUIPMENT_REPRESENT.HAIR_STYLE then
            tInfo = {nFlag = -1, tDyeingData = {}}
            if dwID ~= tDefaultExteriorData[nRepresentSub] then
                local hHairShop = GetHairShop()
                if hHairShop then
                    local nCount = hHairShop.GetSubsetCanHideCount(Player_GetRoleType(hPlayer), dwID)
                    if nCount > 0 then
                        tInfo.nFlag = hPlayer.GetHairSubsetHideFlag(dwID) -- 发型裁剪部位（8位）
                    end

                    local tDyeing = hPlayer.GetEquippedHairCustomDyeingData(dwID)
                    if tDyeing then
                        tInfo.tDyeingData = tDyeing 
                    end
                end
            end
        elseif nRepresentSub == EQUIPMENT_REPRESENT.CHEST_STYLE then
            tInfo = {nFlag = -1, bViewReplace = false, bMingJiaoCap = false,}
            if dwID ~= tDefaultExteriorData[nRepresentSub] then
                local hExterior = GetExterior()
                if hExterior then
                    local nCount = hExterior.GetSubsetCanHideCount(dwID)
                    if nCount > 0 then
                        tInfo.nFlag = hPlayer.GetExteriorSubsetHideFlag(dwID) -- 衣服裁剪部位（8位）
                    end
                end
                local _, bViewReplace = ShareExteriorData.GetViewReplaceState(tRepresentID)
                tInfo.bViewReplace = bViewReplace
                tInfo.bMingJiaoCap = ShareExteriorData.GetMingJiaoHatState()
            end
        elseif nRepresentSub == EQUIPMENT_REPRESENT.HELM_STYLE then
            tInfo = {nNowDyeingID = 0}
            if dwID ~= tDefaultExteriorData[nRepresentSub] then
                tInfo.nNowDyeingID = hPlayer.GetExteriorDyeingID(dwID)
            end
        end
        tDetail[nRepresentSub] = tInfo
    end
    return tDetail
end

function SelfieTemplateBase.GetPendantPosNew(nPendantType, nRepresentSub)
    local nPos = GetPendentPos(nPendantType)
    if nRepresentSub == EQUIPMENT_REPRESENT.HEAD_EXTEND1 then
        nPos = PENDENT_SELECTED_POS.HEAD1
    elseif nRepresentSub == EQUIPMENT_REPRESENT.HEAD_EXTEND2 then
        nPos = PENDENT_SELECTED_POS.HEAD2
    end
    return nPos
end

local function SelfiePhoto_IsCustomPendantType(nRepresentSub)
    if IsCustomPendantType(nRepresentSub) and nRepresentSub ~= EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND then
        return true
    end
    return false
end

local function SelfiePhoto_IsCustomBackCloak(hPlayer, dwID)
    if not hPlayer then
        return
    end

    local iteminfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwID)
    if iteminfo and IsCustomPendantRepresentID(EQUIPMENT_SUB.BACK_CLOAK_EXTEND, iteminfo.nRepresentID, hPlayer.nRoleType) then
        return true
    end
    return false
end

function SelfieTemplateBase.UpdatePendantInfo(hPlayer, tData, tDetail, tShowRes)
    local tCustomPendant = GetEquipCustomRepresentData(hPlayer)
    for nRepresentSub, _ in pairs(tData) do
        if (tPendantList[nRepresentSub] and tShowRes[nRepresentSub] ~= 0) or nRepresentSub == PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL then
            local nEquipSub = tPendantList[nRepresentSub]
            local nPendantType = GetPendantTypeByEquipSub(nEquipSub)
            local nPendantPos = SelfieTemplateBase.GetPendantPosNew(nPendantType, nRepresentSub)
            tData[nRepresentSub] = hPlayer.GetSelectPendent(nPendantPos) or 0
            if SelfiePhoto_IsCustomPendantType(nRepresentSub) then 
                if not tDetail[nRepresentSub] then  -- 挂件的细节只有自定义数据(披风只有部分可自定义)
                    tDetail[nRepresentSub] = {}
                end
               tDetail[nRepresentSub].tCustomData = tCustomPendant[nRepresentSub] or DEFAULT_CUSTOM_DATA
            end

            if nRepresentSub == EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND then
                local dwID = tData[nRepresentSub]
                local tInfo = {bVisible = false, tColorID = nil, tCustomData = nil}
                if dwID and dwID ~= 0 then
                    tInfo.bVisible = not hPlayer.GetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL)

                    local bColor = GetCloakChangeColorInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwID)
                    if bColor then
                        tInfo.tColorID = GetPendantColor(ITEM_TABLE_TYPE.CUST_TRINKET, dwID) or {0, 0, 0}
                    end

                    local tDefaultPendant = ShareExteriorData.GetDefaultPendantCustomData(nRepresentSub, dwID)
                    if SelfiePhoto_IsCustomBackCloak(hPlayer, dwID) then
                        tInfo.tCustomData = tCustomPendant[nRepresentSub] or tDefaultPendant
                    end
                end
                tDetail[nRepresentSub] = tInfo
            end
        end

        if nRepresentSub == EQUIPMENT_REPRESENT.PENDENT_PET_STYLE then -- 挂宠
            local nIndex, nPos = hPlayer.GetEquippedPendentPet()
            tData[nRepresentSub] = nIndex
            tDetail[nRepresentSub] = {nPetPos = nPos}
        end
    end
end

function SelfieTemplateBase.UpdateSFXPendantInfo(hPlayer, tData, tDetail)
    for szType, _ in pairs(tSFXPendant) do
        local dwEffectID = CharacterEffectData.GetEffectEquipByType(szType)
        if dwEffectID and dwEffectID ~= 0 then
            tData[szType] = dwEffectID
            if szType == "CircleBody" then
                tDetail[szType] = {}
                local tCustomData = hPlayer.GetEquipCustomSFXData(PLAYER_SFX_REPRESENT.SURROUND_BODY) or DEFAULT_CUSTOM_DATA
                tDetail[szType].tCustomData = tCustomData
            end 
        end
    end
end

function SelfieTemplateBase.GetSelfiePhotoTemplateVersion()
    return _SELFIE_PHOTO_DATA_VERSION
end

function SelfieTemplateBase.GetPhotoMapTypeAndID(tPhotoData)
    if tPhotoData and tPhotoData.tPlayerParam and tPhotoData.tPlayerParam.tPlace then
        local tPlace = tPhotoData.tPlayerParam.tPlace
        local bInStudio = SelfieData.IsStudioMap(tPlace.dwMapID)

        local nMapType  = bInStudio and SHARE_PHOTO_MAP_TYPE.SELFIE_STUDIO or SHARE_PHOTO_MAP_TYPE.NORMAL
        local dwPlaceID = bInStudio and clone(tPlace.tStudio.dwID) or clone(tPlace.dwMapID)
        return nMapType, dwPlaceID
    end
    return
end

function SelfieTemplateBase.IsHomelandMap(dwMapID)
    if IsHomelandCommunityMap(dwMapID) then
        return true
    end
    return false
end

function SelfieTemplateBase.GetPhotoMapName(nMapType, dwPlaceID)
    local szType, szMapName
    if nMapType == SHARE_PHOTO_MAP_TYPE.SELFIE_STUDIO then  -- 万景阁
        local dwID  = dwPlaceID
        local tInfo = Table_GetSelfieStudioInfo(dwID)
        szMapName = UIHelper.GBKToUTF8(tInfo.szName)
        szType    = g_tStrings.STR_SELFIE_STUDIO
    else                                              -- 家园及大世界
        local dwMapID  = dwPlaceID
        local bHomeMap = SelfieTemplateBase.IsHomelandMap(dwMapID)
        szMapName = UIHelper.GBKToUTF8(Table_GetMapName(dwMapID))
        szType    = bHomeMap and g_tStrings.STR_FURNITURE_TIP_NAME or g_tStrings.STR_SELFIE_PLACE_BIG_WORLD
    end
    return FormatString(g_tStrings.STR_ARENA_V_L, szType, szMapName)
end

function SelfieTemplateBase.GetPartPhotoDataByType(tPhotoData, nDataType)
    if nDataType == SHARE_DATA_TYPE.FACE then
        if tPhotoData and tPhotoData.tPlayerParam and tPhotoData.tPlayerParam.tFace then
            return tPhotoData.tPlayerParam.tFace
        end
    elseif nDataType == SHARE_DATA_TYPE.BODY then
        if tPhotoData and tPhotoData.tPlayerParam and tPhotoData.tPlayerParam.tBody then
            return tPhotoData.tPlayerParam.tBody
        end
    elseif nDataType == SHARE_DATA_TYPE.EXTERIOR then
        if tPhotoData and tPhotoData.tPlayerParam and tPhotoData.tPlayerParam.tExterior then
            return tPhotoData.tPlayerParam.tExterior
        end
    elseif nDataType == SHARE_DATA_TYPE.PHOTO then
        if tPhotoData then
            return tPhotoData
        end
    end
    return false
end
---------------------------------------------------------------------------------------------
function SelfieTemplateBase.SetAllPhotoData(tData)
    m_tData = tData
    if IsTableEmpty(m_tData) or SelfieData.nEnter == 0 then
        return 
    end
    m_ImportState = true
    SelfieTemplateBase.SetPhotoSelfieData(tData.tSelfieParam)
    SelfieTemplateBase.SetPhotoPlayerData(tData.tPlayerParam)
end

function SelfieTemplateBase.SetPhotoSelfieData(tSelfieData)
    local tSelfieParam = tSelfieData or clone(m_tData.tSelfieParam)
    if m_tData.bIsMobile then
        SelfieTemplateBase.SetWindData(tSelfieParam.tWind)
        SelfieTemplateBase.SetBaseData(tSelfieParam.tBase)
        SelfieTemplateBase.SetLightData(tSelfieParam.tLight)
        SelfieTemplateBase.SetFilterData(tSelfieParam.tFilter)
    end
end

function SelfieTemplateBase.SetPhotoPlayerData(tPlayerParam)
    local hPlayer = GetClientPlayer()
    if not hPlayer or m_tData.tPlayerParam.nRoleType ~= Player_GetRoleType(hPlayer) then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_SELFIE_IMPORT_PLAYER_DATA_FAILED)
        return
    end

    local tExterior = tPlayerParam or m_tData.tPlayerParam.tExterior

    SelfieTemplateBase.SetFaceData(m_tData.tPlayerParam.tFace)
    SelfieTemplateBase.SetBodyData(m_tData.tPlayerParam.tBody, hPlayer)
    SelfieTemplateBase.SetActionData(m_tData.tPlayerParam.tAction)
    SelfieTemplateBase.SetPlayerExteriorRes(tExterior)
    SelfieTemplateBase.SetPlayerPendantRes(tExterior) 
    SelfieTemplateBase.SetPlayerSFXPendantRes(tExterior)
    SelfieTemplateBase.SetPlayerDirection()
end

function SelfieTemplateBase.CancelGuildSelfiePlace()
    -- TrackingTip.Close()
    BubbleMsgData.RemoveMsg("CameraTrace") -- 气泡
    bOnGuild = false
    bArrive = false
end

function SelfieTemplateBase.SetPlaceGuild(tPlace, bForbidOpenMap)
    SelfieTemplateBase.CancelGuildSelfiePlace() -- 默认取消掉上一个模板的追踪
    local tPlace = tPlace or m_tData.tPlayerParam.tPlace
    if not tPlace then
        return
    end
    bArrive = false
    bOnGuild = true
    local tPoint = { tPlace.nX, tPlace.nY, tPlace.nZ }
    UIMgr.Close(VIEW_ID.PanelCamera)
    MapMgr.SetTracePoint("幻境云图追踪", tPlace.dwMapID, tPoint)
    if not bForbidOpenMap then
        UIMgr.Open(VIEW_ID.PanelMiddleMap, tPlace.dwMapID, 0)
    end
    BubbleMsgData.PushMsgWithType("CameraTrace",{
        szType = "CameraTrace",
        nBarTime = 0,
        bShowAdventureBar = true,
        szAction = function ()
            local szMsg = bArrive and "已到达模板拍摄点，可打开幻境云图或者名片拍摄，应用拍照模板" or "正在追踪模板拍摄点，可打开幻境云图或者名片拍摄，应用拍照模板"
            local script = UIHelper.ShowConfirm(szMsg, function() -- confirm
                UIMgr.Open(VIEW_ID.PanelCamera)
                SelfieTemplateBase.CancelGuildSelfiePlace()
            end, 
            function() -- cancel
                SelfieTemplateBase.CancelGuildSelfiePlace()
            end)
            script:SetButtonContent("Cancel", "取消追踪")
            script:SetButtonContent("Confirm", "幻境云图")

            script:ShowOtherButton()
            script:SetOtherButtonClickedCallback(function()
                UIMgr.Open(VIEW_ID.PanelCamera, true)
                SelfieTemplateBase.CancelGuildSelfiePlace()
            end)  
            script:SetButtonContent("Other", "名片拍照")
        end,
    })

end

function SelfieTemplateBase.PhotoStudioMapTeleport(dwID, nCopy)
    if not PakDownloadMgr.UserCheckDownloadMapRes(SELFIE_STUDIO_MAP_LIST, function ()
        RemoteCallToServer("On_PhotoStudio_Apply", dwID, nCopy) 
    end, "万景阁地图资源文件下载完成，是否前往？") then
        return
    end
    RemoteCallToServer("On_PhotoStudio_Apply", dwID, nCopy) 
end

function SelfieTemplateBase.GuildToStudio(tPlace, dwSelectLine, bGuildOutSide)
    SelfieTemplateBase.CancelGuildSelfiePlace()-- 默认取消掉上一个模板的追踪
    bArrive = false
    bOnGuild = true
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return 
    end
    local tInfo = tPlace.tStudio
    if not tInfo or not tInfo.dwID then 
        return 
    end
    local dwNowMapID = hPlayer.GetMapID()
    local dwTargetMapID = tPlace.dwMapID
    local nInitPhotoStudioID, dwInitLine = GDAPI_GetPhotoStudioInfo(hPlayer, SelfieData.GetCurrentMapID())
    local dwTargetLine = dwSelectLine or dwInitLine

    if dwTargetMapID == dwNowMapID and (not dwTargetLine or dwInitLine == dwTargetLine) then --直接传，不用过图
        SelfieTemplateBase.PhotoStudioMapTeleport(tInfo.dwID, dwTargetLine)
        -- bOnGuild = false
    else
        local dialog = UIHelper.ShowConfirm(g_tStrings.STR_SELFIE_STUDIO_MSG, function()
            -- SelfieData.bOpenAgain = true
            SelfieTemplateBase.PhotoStudioMapTeleport(tInfo.dwID, dwTargetLine)
            SelfieTemplateBase.SetPlaceGuild(tPlace, true)
            -- bOnGuild = false
        end)
        dialog:SetButtonContent("Confirm", g_tStrings.STR_HOTKEY_SURE)
        dialog:SetButtonContent("Cancel", g_tStrings.STR_HOTKEY_CANCEL)
    end
end

function SelfieTemplateBase.SetBodyData(tBody, pPlayer)
    local tBodyData = tBody or m_tData.tPlayerParam.tBody
    local pPlayer = pPlayer or GetClientPlayer()
    local hManager = GetBodyReshapingManager()
    if not tBodyData or not hManager or not pPlayer then
        return
    end
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local nRoleType = Player_GetRoleType(hPlayer)
    local nRetCode = GetBodyReshapingManager().CheckValid(nRoleType, tBodyData)
    if nRetCode ~= BODY_RESHAPING_ERROR_CODE.SUCCESS then
        local szMsg = g_tStrings.tBodyCheckNotify[nRetCode]
        OutputMessage("MSG_ANNOUNCE_RED", szMsg)
		return
	end

    local bHave, nIndex = hManager.IsAlreadyHave(tBodyData)
    local nEquippedIndex = pPlayer.GetEquippedBodyBoneIndex()
    if nEquippedIndex == nIndex then
        OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_SELFIE_PHOTO_ALREADY_EQUIP_BODY)
        -- 已装备了对应的体型
        return
    end
    if bHave and nIndex then -- 直接帮忙应用上去
        local nRetCode = hManager.Equip(nIndex)
        if nRetCode ~= BODY_RESHAPING_ERROR_CODE.SUCCESS then
            OutputMessage("MSG_ANNOUNCE_RED",g_tStrings.tBodyEquipNotify[nRetCode])
        end
    else  -- 预览体型，跳转到商城购买处
        UIMgr.Close(VIEW_ID.PanelCamera)
        FireUIEvent("EVENT_LINK_NOTIFY", "CoinShopTitle/" .. UI_COIN_SHOP_GOODS_TYPE_OTHER .. "/1")
    end 
end

function SelfieTemplateBase.SetPlayerExteriorRes(tExterior)
    local pPlayer = GetClientPlayer()
	if not pPlayer then
		return 
	end
    local tExteriorID = tExterior.tExteriorID or m_tData.tPlayerParam.tExterior.tExteriorID
    local tDetail     = tExterior.tDetail or m_tData.tPlayerParam.tExterior.tDetail

    local tSaveData = {}
	for nRepresentSub, _ in pairs(tExteriorID) do
        local tItem = {}
        local dwExterior = tExteriorID[nRepresentSub]
        if nRepresentSub == EQUIPMENT_REPRESENT.HAIR_STYLE then
            tItem.dwGoodsID  = dwExterior
            tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.HAIR
        elseif nRepresentSub == EQUIPMENT_REPRESENT.WEAPON_STYLE or nRepresentSub == EQUIPMENT_REPRESENT.BIG_SWORD_STYLE then
            tItem.dwGoodsID  = dwExterior
            tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR
            tItem.nEquipPos  = Exterior_RepresentSubToEquipSub(nRepresentSub)
        elseif Exterior_RepresentSubToEquipSub(nRepresentSub) then
            tItem.dwGoodsID  = dwExterior
            tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR
            tItem.nSubType   = Exterior_RepresentToBoxIndex(nRepresentSub)
        end
        if tItem.dwGoodsID and tItem.dwGoodsID ~= 0 then
            table.insert(tSaveData, tItem)
        end

        local bShow = (dwExterior and dwExterior ~= 0)
        SelfieTemplateBase.ToggleExteriorShowAndHide(pPlayer, nRepresentSub, bShow)
    end

    local nRetCode = COIN_SHOP_ERROR_CODE.FAILED
    if not IsTableEmpty(tSaveData) then
        nRetCode = GetCoinShopClient().Save(tSaveData)
        local msg = nRetCode and g_tStrings.tCoinShopNotify[nRetCode]
        if msg then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tCoinShopNotify[nRetCode])
        end
    end

    if nRetCode == COIN_SHOP_ERROR_CODE.SUCCESS then
        SelfieTemplateBase.UpdateExteriorDetail(pPlayer, tExteriorID, tDetail)
    end
end

function SelfieTemplateBase.UpdateExteriorDetail(pPlayer, tExteriorID, tDetail)
    local nClothType = EQUIPMENT_REPRESENT.CHEST_STYLE
    local nHairType  = EQUIPMENT_REPRESENT.HAIR_STYLE

    if pPlayer.dwForceID == FORCE_TYPE.MING_JIAO then                  -- 明教戴帽
        local bTargetState = tDetail[nClothType].bMingJiaoCap
        SelfieTemplateBase.ChangeMingJiaoCapState(pPlayer, bTargetState)
    end

    local nChestSubset = tDetail[nClothType].nFlag -- 衣服Subset
    if nChestSubset and nChestSubset ~= -1 then
        SelfieTemplateBase.ChangeChestSubset(tExteriorID[nClothType], nChestSubset)
    end

    local nHairSubset = tDetail[nHairType].nFlag  -- 头发Subset
    if nHairSubset and nHairSubset ~= -1 then
        SelfieTemplateBase.ChangeHairSubset(tExteriorID[nHairType], nHairSubset)
    end

    local hManager = GetHairCustomDyeingManager()
	if not hManager then
		return
	end
    local tDyeingData = tDetail[nHairType].tDyeingData -- 头发染色
    if tDyeingData and not IsTableEmpty(tDyeingData) then
        local bUsed = false
        local nCode
        local dwID = tExteriorID[nHairType]
        local tList = pPlayer.GetHairCustomDyeingList(dwID)
        if tList and not IsTableEmpty(tList) then
            for nIndex, tInfo in pairs(tList) do
                if IsTableEqual(tInfo, tDyeingData) then
                    bUsed = true
                    nCode = hManager.Equip(dwID, nIndex)
                end
            end
        end
        if not bUsed then
            local szMsg = g_tStrings.STR_SELFIE_PHOTO_NOT_HAVE_DYEINGDATA
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
        elseif bUsed and nCode and nCode ~= HAIR_CUSTOM_DYEING_ERROR_CODE.SUCCESS then
            local szChannel = "MSG_ANNOUNCE_RED"
            local szMsg = g_tStrings.tHairDyeingEquipNotify[nCode]
            OutputMessage(szChannel, szMsg)
            return
        end
    end
end

function SelfieTemplateBase.ChangeChestSubset(dwExteriorID, nSubset)
    local pPlayer = GetClientPlayer()
	if not pPlayer then
		return 
	end
    if not dwExteriorID or dwExteriorID <= 0 then
        return 
    end
    pPlayer.SetExteriorSubsetHideFlag(dwExteriorID, nSubset)
end

function SelfieTemplateBase.ChangeHairSubset(dwHairID, nSubset)
    local pPlayer = GetClientPlayer()
	if not pPlayer then
		return 
	end
    if not dwHairID or dwHairID <= 0 then
        return 
    end
    pPlayer.SetHairSubsetHideFlag(dwHairID, nSubset)
end

function SelfieTemplateBase.ChangeMingJiaoCapState(pPlayer, bTargetState)
    local bCurState = ExteriorData.GetMingJiaoHatState()
    if not bTargetState or bCurState ~= bTargetState then
        local dwMiniAvatarID = pPlayer.dwMiniAvatarID
        PlayerData.UpdateMJMiniAvatar(dwMiniAvatarID)
        PlayerData.MingJiaoDoAction(dwMiniAvatarID)
    end
end

function SelfieTemplateBase.SetPlayerPendantRes(tExterior)
    local pPlayer = GetClientPlayer()
	if not pPlayer then
		return 
	end
    local tHeadMore = {
        [EQUIPMENT_REPRESENT.HEAD_EXTEND] = PENDENT_SELECTED_POS.HEAD,
        [EQUIPMENT_REPRESENT.HEAD_EXTEND1] = PENDENT_SELECTED_POS.HEAD1,
        [EQUIPMENT_REPRESENT.HEAD_EXTEND2] = PENDENT_SELECTED_POS.HEAD2,
    }

    local tExteriorID = tExterior.tExteriorID or m_tData.tPlayerParam.tExterior.tExteriorID
    local tDetail = tExterior.tDetail or m_tData.tPlayerParam.tExterior.tDetail
	for nRepresentSub, _ in pairs(tExteriorID) do
        local nEquipSub = tPendantList[nRepresentSub]
        local dwIndex = tExteriorID[nRepresentSub]
        if SelfieTemplateBase.IsSelfiePendant(nRepresentSub) then
            if dwIndex and dwIndex ~= 0 then
                    local tColorID = tDetail[nRepresentSub] and tDetail[nRepresentSub].tColorID
                    local bColor = GetCloakChangeColorInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex)
                    if tColorID and (tColorID[1] ~= 0 or tColorID[2] ~= 0 or tColorID[3] ~= 0) and bColor then
                        pPlayer.SelectColorPendent(nEquipSub, dwIndex or 0, tColorID[1] or 0, tColorID[2] or 0, tColorID[3] or 0)
                    elseif tHeadMore[nRepresentSub] then
                        pPlayer.SelectPendent(nEquipSub, dwIndex or 0, tHeadMore[nRepresentSub])
                    else
                        pPlayer.SelectPendent(nEquipSub, dwIndex or 0)
                    end
                    if tDetail[nRepresentSub] and (SelfieTemplateBase.IsCustomPendantType(nRepresentSub) or SelfieTemplateBase.IsCustomBackCloak(pPlayer, dwIndex)) then
                        if tDetail[nRepresentSub].tCustomData then
                            local hItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex)
                            local nRepresentID = hItemInfo.nRepresentID
                            local nRetCode = pPlayer.SetEquipCustomRepresentData(nRepresentSub, nRepresentID, tDetail[nRepresentSub].tCustomData)
                        end
                    end
            end

            local bShow = (dwIndex and dwIndex ~= 0)
            SelfieTemplateBase.ToggleExteriorShowAndHide(pPlayer, nRepresentSub, bShow)
        end  
	end

    local dwPetIndex = tExteriorID[EQUIPMENT_REPRESENT.PENDENT_PET_STYLE]
    local nPetPos = tDetail[EQUIPMENT_REPRESENT.PENDENT_PET_STYLE] and tDetail[EQUIPMENT_REPRESENT.PENDENT_PET_STYLE].nPetPos
    if dwPetIndex and nPetPos and pPlayer.IsHavePendentPet(dwPetIndex) then
        pPlayer.EquipPendentPet(dwPetIndex or 0)
        pPlayer.ChangePendentPetPos(dwPetIndex, nPetPos)
    else
        pPlayer.EquipPendentPet(0)
    end
end

function SelfieTemplateBase.SetPlayerSFXPendantRes(tExterior)
    local pPlayer = GetClientPlayer()
	if not pPlayer then
		return 
	end
    local tExteriorID = tExterior.tExteriorID or m_tData.tPlayerParam.tExterior.tExteriorID
    local tDetail = tExterior.tDetail or m_tData.tPlayerParam.tExterior.tDetail
    for szType, _ in pairs(tExteriorID) do
		local dwEffectID = tExteriorID[szType]
        if SelfieTemplateBase.IsSelfieSFXPendant(szType) then
            if dwEffectID and dwEffectID ~= 0 then
                if szType == "CircleBody" then
                    if tDetail[szType] and tDetail[szType].tCustomData then
                        pPlayer.SetEquipCustomSFXData(PLAYER_SFX_REPRESENT.SURROUND_BODY, tDetail[szType].tCustomData)
                    end
                end
                if not pPlayer.IsEquipSFX(dwEffectID)  then
                    pPlayer.SetCurrentSFX(dwEffectID or 0)
                end
            elseif dwEffectID and dwEffectID == 0 then 
                local dwEffectID = CharacterEffectData.GetEffectEquipByType(szType)
                if dwEffectID and dwEffectID ~= 0 then
                    pPlayer.SetCurrentSFX(dwEffectID)
                end
            end
        end
    end
end

function SelfieTemplateBase.ToggleExteriorShowAndHide(pPlayer, nRepresentSub, bShow)
    if not pPlayer then
        return
    end

    if nRepresentSub == EQUIPMENT_REPRESENT.FACE_EXTEND then
        pPlayer.SetFacePendentHideFlag(not bShow)
    elseif nRepresentSub == EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND then
        pPlayer.SetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL, not bShow)
    elseif nRepresentSub == EQUIPMENT_REPRESENT.HELM_STYLE then
        pPlayer.HideHat(not bShow)
    elseif nRepresentSub == EQUIPMENT_REPRESENT.CHEST_STYLE then
        RemoteCallToServer("OnApplyExterior")
    end
end

function SelfieTemplateBase.IsSelfiePendant(nRepresentSub)
    return tPendantList[nRepresentSub] ~= nil
end

function SelfieTemplateBase.IsSelfieSFXPendant(szType)
    return tSFXPendant[szType] ~= nil
end

function SelfieTemplateBase.IsCustomPendantType(nRepresentSub)
    if IsCustomPendantType(nRepresentSub) and nRepresentSub ~= EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND then
        return true
    end
    return false
end

function SelfieTemplateBase.IsCustomBackCloak(hPlayer, dwID)
    if not hPlayer then
        return
    end

    local iteminfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwID)
    if iteminfo and IsCustomPendantRepresentID(EQUIPMENT_SUB.BACK_CLOAK_EXTEND, iteminfo.nRepresentID, hPlayer.nRoleType) then
        return true
    end
    return false
end

function SelfieTemplateBase.SetPlayerDirection(tPlace)
    local tPlace = tPlace or (m_tData.tPlayerParam and m_tData.tPlayerParam.tPlace)
    if not tPlace or not tPlace.nFaceDirection then
        return
    end
    TurnTo(tPlace.nFaceDirection)
    OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_SELFIE_PHOTO_USED_DIRECTION)
end

function SelfieTemplateBase.SetPlayActionAgainState(bPlayAgain)
    bPlayActionFile = bPlayAgain
end

function SelfieTemplateBase.SetActionData(tAction, nDelayFreeze)
    if bUsedAction then
        return 
    end
    local tAction = tAction or m_tData.tPlayerParam.tAction
    local dwAnimationID = tAction.dwAnimationID
    local szAnimationFile = tAction.szAnimationFile
    local nAniOffset = tAction.nAniOffset 
    local nFrame = tAction.nFrame or 0
    local nDelayFreeze = nDelayFreeze or 0
    local tInfo = SelfieTemplateBase.GetActionInfo(dwAnimationID)
    local bCanUse = SelfieTemplateBase.CheckActionCanUse(tInfo)
    if (tInfo and bCanUse) or bPlayActionFile then
        if nDelayFreeze and nDelayFreeze ~= 0 then
            bPlayAction = true
        end
        Player_ApplyLocalPauseAnimation(dwAnimationID, szAnimationFile, nAniOffset, nDelayFreeze, nFrame)
    end

end

function SelfieTemplateBase.SetFaceActionData(tFaceAction)
    local tFaceAction = tFaceAction or m_tData.tPlayerParam.tFaceAction
    if bUsedAction and bPlayAction then
        return 
    end
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    if not SelfieTemplateBase.CheckFaceActionData(tFaceAction) then
        return
    end

    rlcmd(string.format("apply face pause animation %d %d", tFaceAction.dwFaceMotionID, tFaceAction.fFacePersent))
end

function SelfieTemplateBase.CheckFaceActionData(tFaceAction)
    if not tFaceAction.dwFaceMotionID or not tFaceAction.fFacePersent then
        return
    end
    if tFaceAction.dwFaceMotionID == 0 then 
        return false
    end

    local tFaceMotion = EmotionData.GetFaceMotion(tFaceAction.dwFaceMotionID)
	if not tFaceMotion then
		return false
	end

    return true
end

function SelfieTemplateBase.CheckActionCanUse(tInfo)
    local hPlayer = GetClientPlayer()
    if not hPlayer or not tInfo then
        return
    end

    local tActionCanUse = {
        [1] = {fnCanUse = function(dwLogicID) return true end},        -- 基础动作
        [2] = {fnCanUse = function(dwLogicID) return EmotionData.IsEmotionActionCollected(dwLogicID) end},   -- 表情动作
        [3] = {fnCanUse = function(dwLogicID) return hPlayer.IsHaveIdleAction(dwLogicID) end},   -- 站姿待机
        [4] = {fnCanUse = function(dwLogicID) return hPlayer.IsPendentExist(dwLogicID) end},     -- 挂件动作
        [5] = {fnCanUse = function(dwLogicID) return hPlayer.IsHaveExterior(dwLogicID) end},     -- 外装动作
        [6] = {fnCanUse = function(dwLogicID)                                                    -- 玩具动作
            local tToy = Table_GetToyBoxByItem(dwLogicID)
            return (tToy and GDAPI_IsToyHave(hPlayer, tToy.dwID, tToy.nCountDataIndex))
        end}, 
        [7] = {fnCanUse = function(dwLogicID)                                                    -- 持门派武器动作
            local tExteriorID = m_tData.tPlayerParam.tExterior.tExteriorID
            local dwWeaponID = tExteriorID[EQUIPMENT_REPRESENT.WEAPON_STYLE]
            local dwSwordID = tExteriorID[EQUIPMENT_REPRESENT.BIG_SWORD_STYLE]                                            

            local tItemInfo1 = GetPlayerItem(hPlayer, INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.MELEE_WEAPON) -- 角色身上装备的武器类型
            local tItemInfo2 = GetPlayerItem(hPlayer, INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.BIG_SWORD)
            local bCanUse = false
            if dwWeaponID and dwWeaponID ~= 0 then
                bCanUse =  (tItemInfo1 and tItemInfo1.nDetail == dwLogicID)
            end
            if dwSwordID and dwSwordID ~= 0 then
                bCanUse = (tItemInfo2 and tItemInfo2.nDetail == dwLogicID)
            end
            return bCanUse
        end}, 
        [8] = {fnCanUse = function(dwLogicID)                                                    -- 门派专属技能动作
            return hPlayer.dwForceID == dwLogicID
            -- 判门派是不是和传来的门派数据一致
        end}, 
    }

    local bCanUse = false
    if tInfo.tLogicID and not IsTableEmpty(tInfo.tLogicID) then
        for nType, tLogic in pairs(tInfo.tLogicID) do
            for _, dwLogicID in ipairs(tLogic) do
                bCanUse = tActionCanUse[nType].fnCanUse(dwLogicID)
                if bCanUse then
                    return bCanUse
                end
            end
        end
    end

    if tInfo.tAndLogic and not IsTableEmpty(tInfo.tAndLogic) then
        for _, tGroup in ipairs(tInfo.tAndLogic) do
            local tGroupHave = true
            for nType, tLogic in pairs(tGroup) do
                for _, dwLogicID in ipairs(tLogic) do
                    if not tActionCanUse[nType].fnCanUse(dwLogicID) then
                        tGroupHave = false
                    end
                end
            end
            if tGroupHave then
                return tGroupHave
            end
        end
    end

    return bCanUse
end

function SelfieTemplateBase.SetFaceData(tFace)
    local tFaceData = tFace or m_tData.tPlayerParam.tFace
    local hManager = GetFaceLiftManager()
    if not tFaceData or not hManager then
        return
    end
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local nRoleType = Player_GetRoleType(hPlayer)
    local nRetCode = hManager.CheckValid(nRoleType, tFaceData)
	if nRetCode ~= FACE_LIFT_ERROR_CODE.SUCCESS then
		local szMsg = tFaceData.bNewFace and g_tStrings.tNewFaceLiftNotify[nRetCode] or g_tStrings.tFaceLiftNotify[nRetCode]
        OutputMessage("MSG_ANNOUNCE_RED", szMsg)
		return
	end

    local bHave, nIndex = hManager.IsAlreadyHave(tFaceData) -- 新老脸型兼容
    local nEquippedIndex = hManager.GetEquipedIndex()
    if nEquippedIndex == nIndex then
        ToggleFaceDecorationShowAndHide(tFaceData)
        OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_SELFIE_PHOTO_ALREADY_EQUIP_FACE)
        -- 已装备了对应的脸型
        return
    end
    if bHave and nIndex then  -- 直接帮忙应用上去
        local nRetCode = hManager.Equip(nIndex)
        if nRetCode ~= FACE_LIFT_ERROR_CODE.SUCCESS then
            local szMsg = g_tStrings.tFaceLiftNotify[nRetCode]
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
        elseif nRetCode == FACE_LIFT_ERROR_CODE.SUCCESS then
            ToggleFaceDecorationShowAndHide(tFaceData)
        end

    else -- 预览脸型，跳转到商城购买处
        -- Selfie.Close()
        FireUIEvent("EVENT_LINK_NOTIFY", "CoinShopTitle/" .. UI_COIN_SHOP_GOODS_TYPE_OTHER .. "/2")
        -- CoinShop_NewFaceShop.ImportData(tFaceData) -- 来不及，等事件预览
    end
end

function SelfieTemplateBase.SetMapParams(dwID)
    SelfieData.SetEnvPreset(dwID)
end
-------------------- 幻境云图 -------------------------------
function SelfieTemplateBase.UpdateWindData()
    local tWind = clone(SelfieData.GetClothWind())
    tWind.bImportPhotoData = nil
    return tWind
end

function SelfieTemplateBase.UpdateBaseData()
    local tBase = clone(SelfieData.GetBaseData())
    return tBase
end

function SelfieTemplateBase.UpdateLightData()
    local tLight = clone(SelfieData.GetLightData())
    tLight.bImportPhotoData = nil
    return tLight
end

function SelfieTemplateBase.UpdateFilterData()
    local tFilter = clone(SelfieData.GetFilterData()) or {}
    tFilter.bImportPhotoData = nil
    return tFilter
end

function SelfieTemplateBase.SetTemplateImportState(bImport) -- 取消/完成导入后，清除所有数据
    m_ImportState = bImport
    if not bImport and not bOnGuild then
        m_tData = {}
        -- Selfie.UpdateImportTemplateBtn(false) -- 模板按钮隐藏
    end
end

function SelfieTemplateBase.SavePhotoDataByCloud(tCloudData)
    m_tData = tCloudData
end

function SelfieTemplateBase.GetTemplateGuildState() -- 看是否处在追踪过程中
    return bOnGuild
end

function SelfieTemplateBase.GetTemplateData()
    local tData = clone(m_tData)
    return tData
end

function SelfieTemplateBase.GetTemplateSelfieData()
    local tData = clone(m_tData)
    return tData.tSelfieParam
end

function SelfieTemplateBase.GetTemplatePlayerData()
    local tData = clone(m_tData)
    return tData.tPlayerParam
end

function SelfieTemplateBase.SetWindData(tWind)
    Event.Dispatch(EventType.OnSetWindData, tWind)
end

function SelfieTemplateBase.SetBaseData(tBase)
    Event.Dispatch(EventType.OnSetBaseData, tBase)
end

function SelfieTemplateBase.SetLightData(tLight)
    Event.Dispatch(EventType.OnSetLightData, tLight)
end

function SelfieTemplateBase.SetFilterData(tFilter)
    Event.Dispatch(EventType.OnSetFilterData, tFilter)
end


function SelfieTemplateBase.SetPhotoTemplateName(szText)
    if szText and szText ~= "" then
        m_tData.szName = szText
    end
end