-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeIdentityFishNoteView
-- Date: 2024-01-25 10:37:00
-- Desc: ?
-- ---------------------------------------------------------------------------------
local RANK_LIST_ID = 290
local PerFrameToCreatCell = 40
local UIHomeIdentityFishNoteView = class("UIHomeIdentityFishNoteView")
local DataModel = {}

function DataModel.Init()
    DataModel.tBagData    = GDAPI_GetMyFishRecordBook()
    DataModel.tFliterData = {}
    DataModel.SeletFish   = {}
    DataModel.tFishInfo   = Table_GetAllFishInfo()
    DataModel.tBagData    = DataModel.SorttFish()
    DataModel.nFliterMode = 0
    DataModel.SeletModeBg = nil
    DataModel.bIsHaveRankList = false
end

function DataModel.SorttFish()
    local tNewData = {}
    for i = 1,#DataModel.tBagData do
        local tInfo = DataModel.GetFishInfo(DataModel.tBagData[i].nFishIndex, DataModel.tFishInfo)
        if tInfo and not tInfo.bHideBook then
            table.insert(tNewData, DataModel.tBagData[i])
        end
    end 
    local tFish = {}
    for _, v in pairs(tNewData) do
        if v.nWeight > 0 then 
            table.insert(tFish, v)
        end
    end
    for _, v in pairs(tNewData) do
        if v.nWeight == 0 then 
            table.insert(tFish, v)
        end
    end
    return tFish
end

function DataModel.GetFishInfo(dwID, tFish)
    for _, v in pairs(tFish) do
        if v.dwID == dwID then
            return v
        end
    end
end

function DataModel.Update()
    DataModel.tBagData = GDAPI_GetMyFishRecordBook()
end

function DataModel.UnInit()
    DataModel.tData = {}
end

function UIHomeIdentityFishNoteView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        DataModel.Init()
        ApplyCustomRankList(RANK_LIST_ID)
        self.bInit = true
    end
    self:Init()
end

function UIHomeIdentityFishNoteView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomeIdentityFishNoteView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSelect, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnSelect, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.IdentityFishNote)
    end)

    UIHelper.BindUIEvent(self.BtnRank, EventType.OnClick, function()
        if not DataModel.bIsHaveRankList then
            TipsHelper.ShowNormalTip("暂无数据")
            return
        end
        local tbInfo = {}
        local tRankList = GetCustomRankList(RANK_LIST_ID)
        for i, tRankInfo in ipairs(tRankList) do
            local tFish = DataModel.GetFishInfo(tRankInfo.dwID, DataModel.tFishInfo)
            if not tFish.bHideBook then
                local szPlayerName = UIHelper.GBKToUTF8(tRankInfo.name)
                local szFishName = UIHelper.GBKToUTF8(tFish.szName)
                local szWeight   = FormatString(g_tStrings.STR_HOMELAND_FISHWEIGHT, string.format("%.2f",(tRankInfo.nKey / 100)))
                table.insert(tbInfo, {szPlayerName = szPlayerName, szFishName = szFishName, szWeight = szWeight})
            end
        end

        if table.is_empty(tbInfo) then
            TipsHelper.ShowNormalTip("暂无数据")
            return
        end
        self.scriptRightPop:OpenFishRankList(tbInfo)
    end)
end

function UIHomeIdentityFishNoteView:RegEvent()
    Event.Reg(self, EventType.OnFishNoteOpenDetailPop, function (nIndex, tInfo)
        if not DataModel.tFliterData or #DataModel.tFliterData == 0 then
            return
        end
        local nWeight = DataModel.tFliterData[nIndex].nWeight
        local nStar = DataModel.tFliterData[nIndex].nStar
        self.scriptRightPop:OpenFishDetails(tInfo, nWeight, nStar)
        RemoteCallToServer("On_HomeLand_CheckFishRC", DataModel.tFliterData[nIndex].nFishIndex, 0)
    end)

    Event.Reg(self, EventType.OnUpdateFishNoteHolderInfo, function (tHolder)
        if tHolder and not table_is_empty(tHolder) then
            self.scriptRightPop:UpdateHolderInfo(tHolder)
        end
    end)

    Event.Reg(self, EventType.OnFilter, function (szKey, tbSelected)
        if szKey == FilterDef.IdentityFishNote.Key then
            DataModel.nFliterMode = tbSelected[1][1] - 1 or 0
            if DataModel.nFliterMode == 0 then
                UIHelper.SetSpriteFrame(self.ImgSelect, ShopData.szScreenImgDefault)
            else
                UIHelper.SetSpriteFrame(self.ImgSelect, ShopData.szScreenImgActiving)
            end
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "CUSTOM_RANK_UPDATE", function (szKey, tbSelected)
        if arg0 == RANK_LIST_ID then
            DataModel.bIsHaveRankList = true
        end
    end)
end

function UIHomeIdentityFishNoteView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIHomeIdentityFishNoteView:Init()
    self.scriptRightPop = UIHelper.GetBindScript(self.WidgetAniRight)
    self.scriptRightPop:OnEnter()
    self.scriptRightPop:SetOpenAni(function ()
        UIHelper.PlayAni(self, self.AniAll, "AniRightShow")
    end)
    self.scriptRightPop:SetCloseAni(function ()
        UIHelper.PlayAni(self, self.AniAll, "AniRightHide", function ()
            UIHelper.SetVisible(self.scriptRightPop._rootNode, false)
        end)
    end)
    self:UpdateInfo()
end

function UIHomeIdentityFishNoteView:UpdateInfo()
    local nIndex = 0
    DataModel.tFliterData = self:UpdatetFishTable(DataModel.tBagData)

    UIHelper.ScrollToPercent(self.ScrollViewFishNote, 0)
    UIHelper.RemoveAllChildren(self.ScrollViewFishNote)
    self.nUpdateTimerID = self.nUpdateTimerID or Timer.AddFrameCycle(self, 1, function ()
        local nStart    = (nIndex * PerFrameToCreatCell) + 1
        local nEnd      = (nIndex + 1) * PerFrameToCreatCell
        for i = nStart, nEnd, 1 do
            local tInfo = DataModel.GetFishInfo(DataModel.tFliterData[i].nFishIndex, DataModel.tFishInfo)
            local nPrefabID = tInfo.nFishType == 1 and PREFAB_ID.WidgetFishNoteCell or PREFAB_ID.WidgetFishNoteCell_Big
            local nWeight = DataModel.tFliterData[i].nWeight
            local nStar = DataModel.tFliterData[i].nStar
            local scriptCell = UIHelper.AddPrefab(nPrefabID, self.ScrollViewFishNote)
            scriptCell:OnEnter(i, tInfo, nWeight, nStar)
            if i >= #DataModel.tFliterData then
                UIHelper.ScrollViewDoLayout(self.ScrollViewFishNote)
                UIHelper.ScrollToPercent(self.ScrollViewFishNote, 0)
                Timer.DelTimer(self, self.nUpdateTimerID)
                self.nUpdateTimerID = nil
                break
            end
        end
        nIndex = nIndex + 1
    end)
end

function UIHomeIdentityFishNoteView:UpdatetFishTable(tFish)
    if DataModel.nFliterMode == 0 then
        return tFish
    elseif DataModel.nFliterMode == 1 or DataModel.nFliterMode == 2 then
        local tBodyFish = {}
        for _, v in pairs(DataModel.tBagData) do
            local tInfo = DataModel.GetFishInfo(v.nFishIndex, DataModel.tFishInfo)
            if tInfo.nFishType == DataModel.nFliterMode then
                table.insert(tBodyFish, v)
            end
        end
        return tBodyFish
    else
        local tLevelFish = {}
        for _, v in pairs(DataModel.tBagData) do
            local tInfo = DataModel.GetFishInfo(v.nFishIndex, DataModel.tFishInfo)
            if tInfo.nQuality == DataModel.nFliterMode - 2 then
                table.insert(tLevelFish, v)
            end
        end
        return tLevelFish
    end
end

return UIHomeIdentityFishNoteView