-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMarkMemberView
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIMarkMemberView = class("UIMarkMemberView")

function UIMarkMemberView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bEditTag = false
    self.scriptMemberMap = {}
    self.tCustomData = Storage.Auction
    if self.tCustomData and table_is_empty(self.tCustomData.TagNameList) then
        for i = 1, AuctionData._MAX_TAG_NUM do
			table.insert(self.tCustomData.TagNameList, g_tStrings.tTeamPlayerDefaultTags[i] or "")
		end
    end
    self:UpdateInfo()
end

function UIMarkMemberView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
    Storage.Auction.Dirty(true)
    Event.Dispatch(EventType.OnAuctionTagChanged)
end

function UIMarkMemberView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function (btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnEdit, EventType.OnClick, function (btn)
        self.bEditTag = true
        UIHelper.SetVisible(self.WidgetChooseTag, not self.bEditTag)
        UIHelper.SetVisible(self.WidgetEditTag, self.bEditTag)
    end)

    UIHelper.BindUIEvent(self.BtnFinish, EventType.OnClick, function (btn)
        self.bEditTag = false
        UIHelper.SetVisible(self.WidgetChooseTag, not self.bEditTag)
        UIHelper.SetVisible(self.WidgetEditTag, self.bEditTag)

        for nIndex, editBox in ipairs(self.tbEditBoxTagList) do
            local szTag = UIHelper.GetText(editBox)
            if szTag == nil or szTag == "" then
                szTag = "*"
            end
            self.tCustomData.TagNameList[nIndex] = szTag
        end

        for nIndex, labelTag in ipairs(self.tbLabelTagList) do
            local szTag = self.tCustomData.TagNameList[nIndex]
            if szTag then
                UIHelper.SetString(labelTag, szTag)
            end
            UIHelper.SetVisible(labelTag, szTag ~= nil)
        end
        Event.Dispatch(EventType.OnAuctionTagChanged)
    end)

    UIHelper.ToggleGroupAddToggle(self.ToggleGroupTag, self.TogTagDefault)
    for nIndex, toggleTag in ipairs(self.tbTogTagList) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupTag, toggleTag)
        UIHelper.BindUIEvent(toggleTag, EventType.OnSelectChanged, function (_, bSelected)
            if not self.dwPlayerID or not bSelected then
                return
            end
            local szTag = self.tCustomData.TagNameList[nIndex]
            AuctionData.SetPlayerTagID(self.dwPlayerID, nIndex)

            local scriptMember = self.scriptMemberMap[self.dwPlayerID]
            if scriptMember then
                local dwPlayerID = self.dwPlayerID
                scriptMember:OnEnter(self.dwPlayerID, function ()
                    self:OnSelectMember(dwPlayerID)
                end)
            end
        end)
    end
end

function UIMarkMemberView:RegEvent()

end

function UIMarkMemberView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMarkMemberView:UpdateInfo()
    local clientTeam = GetClientTeam()

    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupMember)
    UIHelper.RemoveAllChildren(self.ScrollViewMemberPlayer)
    local firstScriptRecord = nil
    local totalCount = 0
    local curCount = 0
    local aPartyMember = AuctionData.GetAllOnlineTeamMemberInfo()
	for nIndex, tMemberInfo in ipairs(aPartyMember) do
        local dwPlayerID = tMemberInfo.dwPlayerID
        totalCount = totalCount + 1
        local scriptRecord = UIHelper.AddPrefab(PREFAB_ID.WidgetDistriRecordPlayerItem, self.ScrollViewMemberPlayer)
        local szTag = AuctionData.GetPlayerTag(dwPlayerID)

        if szTag then curCount = curCount + 1 end

        scriptRecord:OnEnter(dwPlayerID, function (bSelected)
            if bSelected then self:OnSelectMember(dwPlayerID) end
        end)
        if not firstScriptRecord then
            firstScriptRecord = scriptRecord
            UIHelper.SetSelected(firstScriptRecord.ToggleSelect, true)
        end
        self.scriptMemberMap[dwPlayerID] = scriptRecord
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupMember, scriptRecord.ToggleSelect)
        UIHelper.SetTouchDownHideTips(scriptRecord.ToggleSelect, false)
	end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewMemberPlayer)

    for nIndex, labelTag in ipairs(self.tbLabelTagList) do
        local szTag = self.tCustomData.TagNameList[nIndex]
        if szTag then
            UIHelper.SetString(labelTag, szTag)
        end
        UIHelper.SetVisible(labelTag, szTag ~= nil)
    end
    
    for nIndex, editBox in ipairs(self.tbEditBoxTagList) do
        local szTag = self.tCustomData.TagNameList[nIndex]
        if szTag then
            UIHelper.SetText(editBox, szTag) 
        end
    end

    local szTitle = string.format("标记常用队员（%d/%d）", curCount, totalCount)
    UIHelper.SetString(self.LabelTitle, szTitle)
end

function UIMarkMemberView:OnSelectMember(dwPlayerID)
    self.dwPlayerID = dwPlayerID
    UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupTag, self.TogTagDefault)
end

return UIMarkMemberView