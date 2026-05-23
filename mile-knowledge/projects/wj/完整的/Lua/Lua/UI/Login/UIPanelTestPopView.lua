-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelTestPopView
-- Date: 2023-06-20 11:30:40
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelTestPopView = class("UIPanelTestPopView")

local function RegisterTable()
    if not IsUITableRegister("LoginQuest") then
        local tLoginQuestTable =
        {
            Path = "\\UI\\Scheme\\Case\\LoginQuest.txt",
            Title =
            {
                {f = "i", t = "dwID"},
                {f = "s", t = "szText"},
                {f = "s", t = "szAnswer1"},
                {f = "s", t = "szFitKungfu1"},
                {f = "i", t = "dwNextID1"},
				{f = "s", t = "szAnswer2"},
                {f = "s", t = "szFitKungfu2"},
                {f = "i", t = "dwNextID2"},
				{f = "s", t = "szAnswer3"},
                {f = "s", t = "szFitKungfu3"},
                {f = "i", t = "dwNextID3"},
				{f = "s", t = "szAnswer4"},
                {f = "s", t = "szFitKungfu4"},
                {f = "i", t = "dwNextID4"},
                {f = "s", t = "szAnswer5"},
                {f = "s", t = "szFitKungfu5"},
                {f = "i", t = "dwNextID5"},
            }
        }
        RegisterUITable("LoginQuest", tLoginQuestTable.Path, tLoginQuestTable.Title)
    end
end


local function Table_GetLoginQuest(dwID)
    local tLine = g_tTable.LoginQuest:Search(dwID)
    return tLine
end

function UIPanelTestPopView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        RegisterTable()
        self.bInit = true
    end
    self.nQuestID = 1
    self.tbScriptView = {}
    self:UpdateInfo()
end

function UIPanelTestPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelTestPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnNext, EventType.OnClick, function()
        local nNextID = self.tbCurInfo.nNextID
        if nNextID then
            self.nQuestID = nNextID
            self:UpdateFitKungfuID()
            self:UpdateInfo()
        end
    end)

    UIHelper.BindUIEvent(self.BtnView, EventType.OnClick, function()
        self:UpdateFitKungfuID()
        if #self.tbKunfuID == 0 then
            local tbKunfuID = Table_GetAllKungfuID()
            self.nKungFuID = tbKunfuID[math.random(1, #tbKunfuID)]
        else
            self.nKungFuID = self.tbKunfuID[math.random(1, #self.tbKunfuID)]
        end
        self:UpdateResult()
        UIHelper.SetVisible(self.BtnView, false)
        UIHelper.SetVisible(self.BtnConfirm, true)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        Event.Dispatch(EventType.OnTestSchoolConfirm, self.nKungFuID)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPanelTestPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelTestPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelTestPopView:UpdateInfo()
    local bEnd = true
    local nCellCount = 0
    local tInfo = Table_GetLoginQuest(self.nQuestID)

    UIHelper.SetString(self.LabelChooseTitle, tInfo.szText)
    for nIndex = 1, 5 do
        local szAnswer = tInfo["szAnswer" .. nIndex]
        if szAnswer and szAnswer ~= "" then
            local tbInfo = {}
            tbInfo.szAnswer= UIHelper.GBKToUTF8(szAnswer)
            tbInfo.nNextID = tInfo["dwNextID" .. nIndex]
            tbInfo.szFitKunfu = tInfo["szFitKungfu" .. nIndex]
            tbInfo.bSelect = nIndex == 1

            local scriptView = self.tbScriptView[nIndex]
            if scriptView then
                scriptView:OnEnter(tbInfo, self)
            else
                scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetTestChooseCell, self.ScrollViewContent, tbInfo, self)
                table.insert(self.tbScriptView, scriptView)
            end

            if tInfo["dwNextID" .. nIndex] and tInfo["dwNextID" .. nIndex] ~= 0 then
                bEnd = false
            end
            nCellCount = nCellCount + 1
        end
    end

    for nIndex = nCellCount + 1, #self.tbScriptView do
        self.tbScriptView[nIndex]:OnRecycled()
    end

    UIHelper.SetVisible(self.BtnView, bEnd)
    UIHelper.SetVisible(self.BtnNext, not bEnd)
    UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
    UIHelper.ScrollToTop(self.ScrollViewContent)
end

function UIPanelTestPopView:UpdateResult()
    UIHelper.SetVisible(self.WidgetQuestion, false)
    UIHelper.SetVisible(self.WidgetResult, true)
    UIHelper.SetSpriteFrame(self.ImgSchool, PlayerKungfuID2SchoolImg_2[self.nKungFuID])
    UIHelper.SetSpriteFrame(self.ImgSchoolName, PlayerKungfuID2SchoolImgName[self.nKungFuID])
end

function UIPanelTestPopView:SetCurInfo(tbInfo)
    self.tbCurInfo = tbInfo
    -- self:UpdateFitKungfuID()
end

function UIPanelTestPopView:UpdateFitKungfuID()
    local tKungfu = string.split(self.tbCurInfo.szFitKunfu, "|")
    if not self.tbKunfuID then
        self.tbKunfuID = {}
    end
    if #self.tbKunfuID == 0 then
        for k, v in ipairs(tKungfu) do
            local nKungfuID = tonumber(v)
            table.insert(self.tbKunfuID, nKungfuID)
        end
    else
        local tbNewKungfu = {}
        for k, v in ipairs(tKungfu) do
            local nKungfuID = tonumber(v)
            if table.contain_value(self.tbKunfuID, nKungfuID) then
                table.insert(tbNewKungfu, nKungfuID)
            end
        end
        self.tbKunfuID = tbNewKungfu
    end
end

return UIPanelTestPopView