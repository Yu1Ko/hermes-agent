-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIDungeonPersonalCardSettle
-- Date: 2026-01-09 11:17:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIDungeonPersonalCardSettle = class("UIDungeonPersonalCardSettle")

function UIDungeonPersonalCardSettle:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIDungeonPersonalCardSettle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDungeonPersonalCardSettle:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnLeave, EventType.OnClick, function ()
        UIMgr.Close(VIEW_ID.PanelDungeonPersonalCardSettle)
    end)

    UIHelper.BindUIEvent(self.BtnPraise, EventType.OnClick, function ()
        self:PraiseAll()
    end)

    UIHelper.BindUIEvent(self.BtnGoldLoot, EventType.OnClick, function ()
        AuctionData.SetDirty(true)
        AuctionData.TryOpenAuctionView()
    end)
end

function UIDungeonPersonalCardSettle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDungeonPersonalCardSettle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIDungeonPersonalCardSettle:UpdateInfo(tExcellentList)
    self.tExcellentList = tExcellentList

    self.tbScriptList = {}
    UIHelper.RemoveAllChildren(self.WidegtMvpPersonalCardList)

    for k, v in ipairs(self.tExcellentList) do
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetDungeonPersonalCardList, self.WidegtMvpPersonalCardList)
        scriptCell:OnEnter(v)
        table.insert(self.tbScriptList, scriptCell)
    end

    UIHelper.LayoutDoLayout(self.WidegtMvpPersonalCardList)
    UIHelper.SetButtonState(self.BtnPraise, self.tExcellentList.bPraised and BTN_STATE.Disable or BTN_STATE.Normal)
    self:UpdateLootBtn()
end

function UIDungeonPersonalCardSettle:UpdateLootBtn()
    local bShowLootBtn = DungeonSettleCardData.CheckShowLootBtn()
    UIHelper.SetButtonState(self.BtnGoldLoot, bShowLootBtn and BTN_STATE.Normal or BTN_STATE.Disable, "仅拍团模式下可查看")
end

local REClick_CD = 500
function UIDungeonPersonalCardSettle:PraiseAll()
    local nThisTime = GetTickCount()
    self.nLastPraiseTime = self.nLastPraiseTime or 0
    if nThisTime < self.nLastPraiseTime + REClick_CD then
        OutputMessage("MSG_ANNOUNCE_RED", "你的操作过于频繁，请稍后再试\n")
        return
    end

    local tbCardPraiseList = {}
    for _, scriptCell in ipairs(self.tbScriptList) do
        local tbExcellent = scriptCell.tExcellent
        local dwPlayerID = tbExcellent.dwID
        local szGlobalID = tbExcellent.szGlobalID
        local bSelf = szGlobalID == UI_GetClientPlayerGlobalID()
        if not bSelf then
            tbCardPraiseList[szGlobalID] = dwPlayerID -- 以全局ID作为key，防止重复点赞

            if tbExcellent.dwID == DUNGEON_EXCELLENT_ID.GREAT_LEADER and not scriptCell.bPraised then
                UIHelper.SimulateClick(scriptCell.BtnPriaise)
            end
        end
    end

    for szGlobalID, dwPlayerID in pairs(tbCardPraiseList) do
        RemoteCallToServer("On_ShowCard_AddPraiseRequest", PRAISE_TYPE.PERSONAL_CARD, dwPlayerID, szGlobalID)
    end
    self.nLastPraiseTime = nThisTime
    self.tExcellentList.bPraised = true
    UIHelper.SetButtonState(self.BtnPraise, BTN_STATE.Disable)
end


return UIDungeonPersonalCardSettle