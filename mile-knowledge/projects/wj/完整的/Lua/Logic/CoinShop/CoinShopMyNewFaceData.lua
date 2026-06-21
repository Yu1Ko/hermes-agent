CoinShopMyNewFaceData = CoinShopMyNewFaceData or {}

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

function CoinShopMyNewFaceData.Init()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    CoinShopMyNewFaceData.nRoleType = hPlayer.nRoleType

    CoinShopMyNewFaceData.tMyFaceList = nil
    CoinShopMyNewFaceData.nMyFaceCount = nil
    CoinShopMyNewFaceData.GetMyFaceList()
    local tRepresentID = hPlayer.GetRepresentID()
    CoinShopMyNewFaceData.aRepresent = tRepresentID
    for _, nRepresentSub in ipairs(tViewClear) do
        CoinShopMyNewFaceData.aRepresent[nRepresentSub] = 0
    end
    local tBodyData = hPlayer.GetEquippedBodyBoneData()
    CoinShopMyNewFaceData.aRepresent.tBody = tBodyData

    CoinShopMyNewFaceData.GetEquippedFaceIndex()
end

function CoinShopMyNewFaceData.UnInit()
    CoinShopMyNewFaceData.nRoleType = nil
    CoinShopMyNewFaceData.aRepresent = nil
    CoinShopMyNewFaceData.tMyFaceList = nil
    CoinShopMyNewFaceData.nMyFaceCount = nil
    CoinShopMyNewFaceData.nEquippedIndex = nil
end

function CoinShopMyNewFaceData.GetMyFaceList()
    if not CoinShopMyNewFaceData.tMyFaceList then
        local hManager = GetFaceLiftManager()
        if not hManager then
            return
        end
        local tLifedFaceList = hManager.GetLiftedFaceList()
        local nCount = #tLifedFaceList
        local tMyFaceList = {}

        for i = nCount, 1, -1 do
            if tLifedFaceList[i].tFaceData.bNewFace then
                table.insert(tMyFaceList, tLifedFaceList[i])
            end
        end

        local nMyCount = #tMyFaceList
        CoinShopMyNewFaceData.tMyFaceList = tMyFaceList
        CoinShopMyNewFaceData.nMyFaceCount = nMyCount
    end

    return CoinShopMyNewFaceData.tMyFaceList, CoinShopMyNewFaceData.nMyFaceCount
end

function CoinShopMyNewFaceData.GetEquippedFaceIndex()
    _, CoinShopMyNewFaceData.nEquippedIndex = ExteriorCharacter.GetPreviewNewFace()
end

function CoinShopMyNewFaceData.SetRename(nIndex, szText)
    if not TextFilterCheck(UIHelper.UTF8ToGBK(szText)) then --过滤文字
        TipsHelper.ShowNormalTip(g_tStrings.STR_FACE_RENAME_ERROR)
        return
    end
    if szText == "" then
        szText = nil
    end

    for k, v in pairs(Storage.Character.tbNewFaceName) do
        if v == szText then
            TipsHelper.ShowNormalTip(g_tStrings.STR_FACE_RENAME_ERROR2)
            return
        end
    end
    Storage.Character.tbNewFaceName[nIndex] = szText
    Storage.Character.Flush()

    TipsHelper.ShowNormalTip("已成功修改备注")
end

function CoinShopMyNewFaceData.GetFaceNameByIndex(nIndex, nUIIndex)
    if not nUIIndex then
		nUIIndex = GetFaceLiftManager().GetUIIndex(nIndex)
	end
    return Storage.Character.tbNewFaceName[nUIIndex] or (g_tStrings.STR_MY_NEW_FACE_DEFAULT_NAME .. "-" .. nUIIndex)
end

Event.Reg(CoinShopMyNewFaceData, "LIFTED_FACE_ADD_V2", function()
    RedpointHelper.Face_SetNew(arg0, true)
end)

Event.Reg(CoinShopMyNewFaceData, "LIFTED_FACE_CHANGE_V2", function ()
    RedpointHelper.Face_SetNew(arg0, true)
end)