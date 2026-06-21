-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMyHomeRightPopLogPage
-- Date: 2023-09-25 16:08:05
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandMyHomeRightPopLogPage = class("UIHomelandMyHomeRightPopLogPage")

local tLogFilterFunc = {
    {
        function(szLog) return true end,
        function(szLog) return string.match(szLog, g_tStrings.STR_LAND_LOG_TYPE_SEARCH[1]) end,
        function(szLog) return string.match(szLog, g_tStrings.STR_LAND_LOG_TYPE_SEARCH[2]) end,
    },
    {
        function(szLog) return true end,
        function(szLog) return string.match(szLog, g_tStrings.STR_LAND_LOG_DEFAULT_SEARCH[1]) end,
        function(szLog) return string.match(szLog, g_tStrings.STR_LAND_LOG_DEFAULT_SEARCH[2]) end,
        function(szLog) return string.match(szLog, g_tStrings.STR_LAND_LOG_DEFAULT_SEARCH[3]) end,
        function(szLog) return string.match(szLog, g_tStrings.STR_LAND_LOG_DEFAULT_SEARCH[4]) end,
    },
}
function UIHomelandMyHomeRightPopLogPage:OnEnter(nMapID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if FilterDef.HomeLandLogFilter and FilterDef.HomeLandLogFilter.Reset then
        FilterDef.HomeLandLogFilter.Reset()
    end
    self.tbFilter = {}

    self.nMapID = nMapID
    self:InitFilter()
    self:UpdateInfo()

    -- 家园红点
    if HomelandData.IsNewHomelandLog then
        HomelandData.SetHomelandLogMsg()
        Event.Dispatch("OnUpdateHomelandRedPoint")
    end
end

function UIHomelandMyHomeRightPopLogPage:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandMyHomeRightPopLogPage:BindUIEvent()
    UIHelper.RegisterEditBoxEnded(self.EditKindSearch, function()
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnScreen, EventType.OnClick, function ()
        self.scriptFilter = self.scriptFilter or UIHelper.AddPrefab(PREFAB_ID.WidgetFiltrateTip, self.WidgetTip, FilterDef.HomeLandLogFilter)
    end)
end

function UIHomelandMyHomeRightPopLogPage:RegEvent()
    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        UIMgr.Close(self)
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey ~= "HomeLandLogFilter" then
            return
        end

        local nFilterIndex1 = tbSelected[1][1]
        local nFilterIndex2 = tbSelected[2][1]
        self.tbFilter[1] = tLogFilterFunc[1][nFilterIndex1]
        self.tbFilter[2] = tLogFilterFunc[2][nFilterIndex2]

        if nFilterIndex1 == 1 and nFilterIndex2 == 1 then
            UIHelper.SetSpriteFrame(self.ImgIconScreen, ShopData.szScreenImgDefault)
        else
            UIHelper.SetSpriteFrame(self.ImgIconScreen, ShopData.szScreenImgActiving)
        end
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        self.scriptFilter = nil
        UIHelper.RemoveAllChildren(self.WidgetTip)
    end)
end

function UIHomelandMyHomeRightPopLogPage:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandMyHomeRightPopLogPage:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewHomeJournal)
    self.tbScript = {}
    local szSearchKey = UIHelper.GetString(self.EditKindSearch) or ""
    local bMatchMod = false
    if not string.is_nil(szSearchKey) then
        bMatchMod = true
    end

    local nCount = GetChatManager().GetSystemNoticeCount(SYSTEM_NOTIFY_TYPE.HOMELAND)
    for i = nCount, 1, -1 do
        local tLog = GetChatManager().GetSystemNotice(SYSTEM_NOTIFY_TYPE.HOMELAND, i)
        tLog[1].text = string.pure_text(UIHelper.GBKToUTF8(tLog[1].text))
        if bMatchMod then
            if string.match(tLog[1].text, szSearchKey) then
                self:UpdateLogsInfo(tLog[1].text)
            end
        else
            self:UpdateLogsInfo(tLog[1].text)
        end
    end
	-- for i = 1, nCount do
	-- 	local tLog = GetChatManager().GetSystemNotice(SYSTEM_NOTIFY_TYPE.HOMELAND, i)
    --     tLog[1].text = string.pure_text(UIHelper.GBKToUTF8(tLog[1].text))
    --     if bMatchMod then
    --         if string.match(tLog[1].text, szSearchKey) then
    --             self:UpdateLogsInfo(tLog[1].text)
    --         end
    --     else
    --         self:UpdateLogsInfo(tLog[1].text)
    --     end
    -- end

    if table.is_empty(self.tbScript) then
        UIHelper.SetVisible(self.WidgetEmpty, true)
    else
        UIHelper.SetVisible(self.WidgetEmpty, false)
        UIHelper.SetVisible(self.tbScript[#self.tbScript].WidgetLine, false)
        UIHelper.LayoutDoLayout(self.tbScript[#self.tbScript]._rootNode)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewHomeJournal)
end

function UIHomelandMyHomeRightPopLogPage:UpdateLogsInfo(szLoginfo)
    if not szLoginfo then
        return
    end
    for _, funcFilter in ipairs(self.tbFilter) do
        if not funcFilter(szLoginfo) then
            return
        end
    end

    local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetHomeJournalPopCell, self.ScrollViewHomeJournal)
    local tbInfo = string.split(szLoginfo, "\n")
    local szContent = ""
    table.insert(self.tbScript, scriptCell)
    szContent = "<color=#ffcf65>"..tbInfo[1].."</c>\n<color=#e2f6fb>"..tbInfo[2].."</color>"
    UIHelper.SetRichText(scriptCell.LabelCentont, szContent)
    UIHelper.LayoutDoLayout(scriptCell._rootNode)
end

function UIHomelandMyHomeRightPopLogPage:InitFilter()
    for index, tbFilter in ipairs(tLogFilterFunc) do
        local func = tbFilter[1]
        self.tbFilter[index] = func
    end
end

return UIHomelandMyHomeRightPopLogPage