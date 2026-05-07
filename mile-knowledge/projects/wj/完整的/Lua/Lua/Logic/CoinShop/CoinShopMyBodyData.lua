CoinShopMyBodyData = CoinShopMyBodyData or {}

local PAGE_VIEW_COUNT = 6
local DEFAULT_INDEX = 1
local tViewClear =
{
	EQUIPMENT_REPRESENT.FACE_EXTEND,
    EQUIPMENT_REPRESENT.BACK_EXTEND,
    EQUIPMENT_REPRESENT.WAIST_EXTEND,
    EQUIPMENT_REPRESENT.WEAPON_STYLE,
    EQUIPMENT_REPRESENT.BIG_SWORD_STYLE,
    EQUIPMENT_REPRESENT.GLASSES_EXTEND,
    EQUIPMENT_REPRESENT.L_GLOVE_EXTEND,
    EQUIPMENT_REPRESENT.R_GLOVE_EXTEND,
}

function CoinShopMyBodyData.Init()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    CoinShopMyBodyData.nRoleType = hPlayer.nRoleType
    CoinShopMyBodyData.GetCameraData()

    CoinShopMyBodyData.tMyBodyList = nil
    CoinShopMyBodyData.nMyBodyCount = nil
    CoinShopMyBodyData.GetMyBodyList()
    local tRepresentID = hPlayer.GetRepresentID()
    CoinShopMyBodyData.aRepresent = tRepresentID
    for _, nRepresentSub in ipairs(tViewClear) do
        CoinShopMyBodyData.aRepresent[nRepresentSub] = 0
    end
    local bUseLiftedFace = hPlayer.bEquipLiftedFace
    local tFaceData = hPlayer.GetEquipLiftedFaceData()
    CoinShopMyBodyData.aRepresent.bUseLiftedFace = bUseLiftedFace
    CoinShopMyBodyData.aRepresent.tFaceData = tFaceData

    CoinShopMyBodyData.GetMyEquippedBodyBoneIndex()
    CoinShopMyBodyData.GetMyBodyBox()
end

function CoinShopMyBodyData.UnInit()
    CoinShopMyBodyData.nRoleType = nil
    CoinShopMyBodyData.aRepresent = nil
    CoinShopMyBodyData.aCameraData = nil
    CoinShopMyBodyData.tMyBodyList = nil
    CoinShopMyBodyData.nMyBodyCount = nil
    CoinShopMyBodyData.nEquippedIndex = nil
    CoinShopMyBodyData.nMyBodyBoxCount = nil
end

function CoinShopMyBodyData.GetCameraData()
	if CoinShopMyBodyData.aCameraData then
		return CoinShopMyBodyData.aCameraData
	end
	CoinShopMyBodyData.aCameraData = g_tRoleBodyView
end

function CoinShopMyBodyData.GetMyBodyList()
    if not CoinShopMyBodyData.tMyBodyList then
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
        local tBodyBoneList = hPlayer.GetBodyBoneList()
        local nMyCount = hPlayer.GetBodyBoneCount()
        local tMyBodyList = {}
        local nKey = nMyCount
        for k, v in pairs(tBodyBoneList) do
            tMyBodyList[nKey] = v
            tMyBodyList[nKey].nIndex = k
            nKey = nKey - 1
        end
        CoinShopMyBodyData.tMyBodyList = tMyBodyList
        CoinShopMyBodyData.nMyBodyCount = nMyCount
    end

    return CoinShopMyBodyData.tMyBodyList, CoinShopMyBodyData.nMyBodyCount
end

function CoinShopMyBodyData.GetMyEquippedBodyBoneIndex()
    local tRepresentID = ExteriorCharacter.GetRoleRes()
    CoinShopMyBodyData.nEquippedIndex = tRepresentID.nBody
end

function CoinShopMyBodyData.GetMyBodyBox()
    local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
    local nBoxSize = hPlayer.GetBodyBoneBoxSize()
    CoinShopMyBodyData.nMyBodyBoxCount = nBoxSize
end

function CoinShopMyBodyData.SetRename(nIndex, szText)
    if not TextFilterCheck(UIHelper.UTF8ToGBK(szText)) then --过滤文字
        TipsHelper.ShowNormalTip(g_tStrings.STR_BODY_RENAME_ERROR)
        return
    end
    if szText == "" then
        szText = nil
    end

    for k, v in pairs(Storage.Character.tbBodyName) do
        if v == szText then
            TipsHelper.ShowNormalTip(g_tStrings.STR_BODY_RENAME_ERROR2)
            return
        end
    end
    Storage.Character.tbBodyName[nIndex] = szText
    Storage.Character.Flush()

    TipsHelper.ShowNormalTip("已成功修改备注")
end

function CoinShopMyBodyData.GetBodyName(nIndex)
    local szName

    if nIndex == DEFAULT_INDEX then
        szName = g_tStrings.STR_MY_BODY_DEFAULT_NAME
    else
        szName = Storage.Character.tbBodyName[nIndex] or g_tStrings.STR_BODY_DEFAULT_TITLE .. "-" .. nIndex
    end
    return szName
end

Event.Reg(CoinShopMyBodyData, "ON_CHANGE_BODY_BONE_NOTIFY", function()
    local nMethod = arg1
    if nMethod == BODY_RESHAPING_OPERATE_METHOD.ADD or nMethod == BODY_RESHAPING_OPERATE_METHOD.REPLACE then
        RedpointHelper.Body_SetNew(arg0, true)
    end
end)