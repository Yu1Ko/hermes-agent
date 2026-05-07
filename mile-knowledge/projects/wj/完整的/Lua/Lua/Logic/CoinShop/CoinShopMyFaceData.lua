CoinShopMyFaceData = CoinShopMyFaceData or {}

local PAGE_VIEW_COUNT = 9
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
    EQUIPMENT_REPRESENT.HELM_STYLE,
    EQUIPMENT_REPRESENT.CHEST_STYLE,
    EQUIPMENT_REPRESENT.HEAD_EXTEND,
    EQUIPMENT_REPRESENT.HEAD_EXTEND1,
    EQUIPMENT_REPRESENT.HEAD_EXTEND2,
}

function CoinShopMyFaceData.Init()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    CoinShopMyFaceData.nRoleType = hPlayer.nRoleType

    CoinShopMyFaceData.tMyFaceList = nil
    CoinShopMyFaceData.nMyFaceCount = nil
    CoinShopMyFaceData.GetMyFaceList()
    local tRepresentID = hPlayer.GetRepresentID()
    CoinShopMyFaceData.aRepresent = tRepresentID
    for _, nRepresentSub in ipairs(tViewClear) do
        CoinShopMyFaceData.aRepresent[nRepresentSub] = 0
    end
    local tBodyData = hPlayer.GetEquippedBodyBoneData()
    CoinShopMyFaceData.aRepresent.tBody = tBodyData

    CoinShopMyFaceData.GetEquippedFaceIndex()
end

function CoinShopMyFaceData.UnInit()
    CoinShopMyFaceData.nRoleType = nil
    CoinShopMyFaceData.aRepresent = nil
    CoinShopMyFaceData.tMyFaceList = nil
    CoinShopMyFaceData.nMyFaceCount = nil
    CoinShopMyFaceData.nEquippedIndex = nil
end

function CoinShopMyFaceData.GetMyFaceList()
    if not CoinShopMyFaceData.tMyFaceList then
        local player = PlayerData.GetClientPlayer()
        if not player then
            return
        end

        local hManager = GetFaceLiftManager()
        if not hManager then
            return
        end
        local tLifedFaceList = hManager.GetLiftedFaceList()
        local nCount = #tLifedFaceList
        local tMyFaceList = {}

        for i = nCount, 1, -1 do
            if not tLifedFaceList[i].tFaceData.bNewFace then
                table.insert(tMyFaceList, tLifedFaceList[i])
            end
        end

        local tFaceList = player.GetAllHair(HAIR_STYLE.FACE)
        nCount = #tFaceList
        for i = nCount, 1, -1 do
            table.insert(tMyFaceList, tFaceList[i].dwID)
        end

        local nMyCount = #tMyFaceList
        CoinShopMyFaceData.tMyFaceList = tMyFaceList
        CoinShopMyFaceData.nMyFaceCount = nMyCount
    end

    return CoinShopMyFaceData.tMyFaceList, CoinShopMyFaceData.nMyFaceCount
end

function CoinShopMyFaceData.GetEquippedFaceIndex()
    _, CoinShopMyFaceData.nEquippedIndex = ExteriorCharacter.GetPreviewNewFace()
end

function CoinShopMyFaceData.SetUseLifeRename(nIndex, szText)
    if not TextFilterCheck(UIHelper.UTF8ToGBK(szText)) then --过滤文字
        TipsHelper.ShowNormalTip(g_tStrings.STR_FACE_RENAME_ERROR)
        return
    end
    if szText == "" then
        szText = nil
    end

    for k, v in pairs(Storage.Character.tUseLifeFaceName) do
        if v == szText then
            TipsHelper.ShowNormalTip(g_tStrings.STR_FACE_RENAME_ERROR2)
            return
        end
    end
    Storage.Character.tUseLifeFaceName[nIndex] = szText
    Storage.Character.Flush()

    TipsHelper.ShowNormalTip("已成功修改备注")
end

function CoinShopMyFaceData.GetUseLifeFaceNameByIndex(nIndex, nUIIndex)
    if not nUIIndex then
		nUIIndex = GetFaceLiftManager().GetUIIndex(nIndex)
	end
    return Storage.Character.tUseLifeFaceName[nUIIndex] or ("写意脸型-" .. nUIIndex)
end

function CoinShopMyFaceData.SetRename(nIndex, szText)
    if not TextFilterCheck(UIHelper.UTF8ToGBK(szText)) then --过滤文字
        TipsHelper.ShowNormalTip(g_tStrings.STR_FACE_RENAME_ERROR)
        return
    end
    if szText == "" then
        szText = nil
    end

    for k, v in pairs(Storage.Character.tbFaceName) do
        if v == szText then
            TipsHelper.ShowNormalTip(g_tStrings.STR_FACE_RENAME_ERROR2)
            return
        end
    end
    Storage.Character.tbFaceName[nIndex] = szText
    Storage.Character.Flush()

    TipsHelper.ShowNormalTip("已成功修改备注")
end

function CoinShopMyFaceData.GetFaceNameByIndex(nIndex)
    local nUIIndex = CoinShopHair.GetHairUIID("Face", nIndex)
    return Storage.Character.tbFaceName[nIndex] or ("成品脸型-" .. nUIIndex)
end

Event.Reg(CoinShopMyFaceData, "LIFTED_FACE_ADD", function()
    RedpointHelper.Face_SetNew(arg0, true)
end)

Event.Reg(CoinShopMyFaceData, "LIFTED_FACE_CHANGE", function ()
    RedpointHelper.Face_SetNew(arg0, true)
end)