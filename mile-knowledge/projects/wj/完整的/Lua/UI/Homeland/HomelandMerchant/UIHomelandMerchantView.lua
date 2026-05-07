-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMerchantView
-- Date: 2024-12-31 15:04:38
-- Desc: ?
-- ---------------------------------------------------------------------------------
local RANK_LIST_ID = 266
local UIHomelandMerchantView = class("UIHomelandMerchantView")

function UIHomelandMerchantView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bCollectFilter = false
    self.tbMerchantList = {}
    local player = GetClientPlayer()
    if not player or IsRemotePlayer(player.dwID) then
        return
    end

    ApplyCustomRankList(RANK_LIST_ID)
end

function UIHomelandMerchantView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandMerchantView:BindUIEvent()
    self.scriptScrollViewTree = UIHelper.GetBindScript(self.WidgetScrollTree)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnTips, EventType.OnClick, function(btn)
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnTips, g_tStrings.STR_HOMELAND_QIHUO_TIPS)
    end)

    UIHelper.BindUIEvent(self.TogCollected, EventType.OnSelectChanged, function(btn, bSelected)
        self.bCollectFilter = bSelected
        self:UpdateInfo()
    end)
end

function UIHomelandMerchantView:RegEvent()
    Event.Reg(self, "CUSTOM_RANK_UPDATE", function(nRankListID, nTotalNum)
        if nRankListID == RANK_LIST_ID then
            self.tbMerchantList = GetCustomRankList(RANK_LIST_ID)
            self:InitData()
            self:UpdateInfo()
        end
    end)
end

function UIHomelandMerchantView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIHomelandMerchantView:InitData()
    local tbFilterList = {}
    local player = GetClientPlayer()
    if not player then
        return tbFilterList
    end

    local fnItemInsert = function (tbList, tData)
        table.insert(tbList.tItemList, {tArgs = {
            bMerchant = true, nIndex = tData.community, nCopyIndex = tData.copy, nMapID = tData.scene, nLandIndex = tData.land
        }})
    end

    for _, tData in pairs(self.tbMerchantList) do
        local nAchiID = tData.achi or 0
        local tSetInfo = Table_GetFurnitureSetInfoByID(nAchiID) or {}
        if table.is_empty(tSetInfo) or string.is_nil(tSetInfo.szName) then
            -- 没有套装名的也列进其它家具里面
            nAchiID = 0
        end

        if tbFilterList[nAchiID] then
            fnItemInsert(tbFilterList[nAchiID], tData)
        else
            local tbItem = {}
            tbItem.tItemList = {}

            local tArgs = {}
            tArgs.nAchiID = nAchiID
            tArgs.szSetName = "其它家具"
            tArgs.bFinished = false
            if nAchiID ~= 0 then
                local tSetData = player.GetSetCollection(nAchiID) or {}
                tArgs.szSetName = UIHelper.GBKToUTF8(tSetInfo.szName)
                tArgs.bFinished = tSetData.eType == SET_COLLECTION_STATE_TYPE.COLLECTED or tSetData.eType == SET_COLLECTION_STATE_TYPE.TO_AWARD
            end

            tbItem.tArgs = tArgs
            fnItemInsert(tbItem, tData)
            tbFilterList[nAchiID] = tbItem
        end
    end

    self.tbFilterList = tbFilterList
end

function UIHomelandMerchantView:UpdateInfo()
    self.scriptScrollViewTree:ClearContainer()
    self.scriptScrollViewTree:SetOuterInitSelect()

    local tbFilterList = {}
    if self.bCollectFilter then
        for _, tbInfo in pairs(self.tbFilterList) do
            if tbInfo.tArgs and not tbInfo.tArgs.bFinished then
                table.insert(tbFilterList, tbInfo)
            end
        end
    else
        for _, tbInfo in pairs(self.tbFilterList) do
            if tbInfo.tArgs and not tbInfo.tArgs.bFinished then
                table.insert(tbFilterList, 1, tbInfo)
            else
                table.insert(tbFilterList, tbInfo)
            end
        end
    end

    table.sort(tbFilterList, function (a, b)
        return a.tArgs.nAchiID > b.tArgs.nAchiID
    end)

    local fnInitContainer = function (scriptContainer, tArgs)
        UIHelper.SetString(scriptContainer.LabelTitle02, tArgs.szSetName)
        UIHelper.SetString(scriptContainer.LabelTitle03, tArgs.szSetName)
        UIHelper.SetString(scriptContainer.LabelCollection, tArgs.bFinished and "已收集" or "未收集")
        UIHelper.SetString(scriptContainer.LabelCollection_Select, tArgs.bFinished and "已收集" or "未收集")
        UIHelper.SetVisible(scriptContainer.LabelCollection, tArgs.nAchiID > 0)
        UIHelper.SetVisible(scriptContainer.LabelCollection_Select, tArgs.nAchiID > 0)

        UIHelper.LayoutDoLayout(scriptContainer.LayoutTitle)
        UIHelper.LayoutDoLayout(scriptContainer.LayoutTitle_Select)
    end

    UIHelper.SetupScrollViewTree(self.scriptScrollViewTree,
        PREFAB_ID.WidgetMerchantCell,
        PREFAB_ID.WidgetFlowerCommunityCell,
        fnInitContainer, tbFilterList, false)

    UIHelper.SetVisible(self.WidgetEmpty, table.is_empty(tbFilterList))
end


return UIHomelandMerchantView