-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAutoShoutMainView
-- Date: 2025-03-04 16:43:27
-- Desc: ?
-- ---------------------------------------------------------------------------------
local MAX_SHOW_SKILL_COUNT = 11
local tbAutoShotList = {
    [1] = "Other",
    [2] = "Death",
    [3] = "Skill",
    [4] = "Forbid",
}
local UIAutoShoutMainView = class("UIAutoShoutMainView")

function UIAutoShoutMainView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:InitRuntimeMap()
    self:UpdateInfo()
end

function UIAutoShoutMainView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAutoShoutMainView:BindUIEvent()
    UIHelper.SetScrollViewCombinedBatchEnabled(self.ScrollViewRightList)
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        self:OnClose()
    end)

    UIHelper.BindUIEvent(self.BtnRecover_Forbid, EventType.OnClick, function(btn)
        for key, v in pairs(self.tbRuntimeMap.Forbid) do
            self.tbRuntimeMap.Forbid[key] = {}
        end
        self:UpdateInfo_Forbid()
    end)

    UIHelper.BindUIEvent(self.BtnRecover, EventType.OnClick, function(btn)
        local szMainType = self.szType
        if self["RecoverAutoShoutSetting_"..szMainType] then
            self["RecoverAutoShoutSetting_"..szMainType](self)
        end
    end)

    UIHelper.BindUIEvent(self.BtnAddSkillShout, EventType.OnClick, function(btn)
        local tbBtnParams = {
            {
                szName = "旗舰",
                OnClick = function ()
                    self:OnChangeSkillList(true)
                end
            },
            {
                szName = "无界",
                OnClick = function()
                    self:OnChangeSkillList(false)
                end
            },
        }
        local nSizeW,nSizeH = UIHelper.GetContentSize(self.BtnAddSkillShout)
        APIHelper.ShowMoreOperTips(self.BtnAddSkillShout, tbBtnParams, -nSizeW/2, 300)
    end)

    UIHelper.BindUIEvent(self.BtnForbiddenSetting, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelShoutForbidden)
    end)

    UIHelper.BindUIEvent(self.BtnEditSkill, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelSkillShoutSetting)
    end)

    UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick, function()
        local tbData = self.tbRuntimeMap.Other
        local tbCustomData = Storage.Chat_AutoShout

        if self.szType == "Death" then
            tbData = self.tbRuntimeMap.Death
            tbCustomData = Storage.Chat_DeathShout
        end

        for key, v in pairs(tbData) do
            tbCustomData[key] = v
        end

        tbCustomData.Dirty()
        TipsHelper.ShowNormalTip("保存成功")
    end)

    UIHelper.BindUIEvent(self.BtnSave_Skill, EventType.OnClick, function()
        local tbData = self.tbRuntimeMap.Skill
        for key, v in pairs(tbData) do
            Storage.Chat_SkillShout[key] = v
        end

        Storage.Chat_SkillShout.Dirty()
        ChatAutoShout.InitSkillShoutData()
        TipsHelper.ShowNormalTip("保存成功")
    end)

    UIHelper.BindUIEvent(self.BtnSave_Forbid, EventType.OnClick, function()
        AutoShoutForbidData.SaveShoutFilter(self.tbRuntimeMap.Forbid)
        TipsHelper.ShowNormalTip("保存成功")
    end)
end

function UIAutoShoutMainView:RegEvent()
    Event.Reg(self, EventType.OnTouchViewBackGround, function(script)
        if script == self then
            self:OnClose()
        end
    end)

    Event.Reg(self, EventType.OpenAutoShoutSettingView, function(szType)
        local tbConf = ChatAutoShout.GetConfigList(self.szType)
        local tbSettingData = self:_getSettingData(szType)
        local tbRuntimeMap = self.tbRuntimeMap[self.szType]

        UIMgr.OpenSingle(false, VIEW_ID.PanelChatShoutSetting, szType, tbConf, tbSettingData, tbRuntimeMap)
    end)

    Event.Reg(self, EventType.OnChatAutoShoutSettingUpdate, function(tbRuntimeMap)
        if self.szType == "Other" then
            self.tbRuntimeMap.Other = tbRuntimeMap
            self:UpdateInfo_Group()
        elseif self.szType == "Death" then
            self.tbRuntimeMap.Death = tbRuntimeMap
            self:UpdateInfo_Group()
        end
    end)

    Event.Reg(self, EventType.OnSkillShoutSaved, function(szSaveType)
        if self.szType ~= "Skill" then
            return
        end

        if szSaveType == "tbSkillList" then
            self.tbRuntimeMap.Skill[szSaveType] = clone(Storage.Chat_SkillShout[szSaveType])
            self:UpdateInfo_SkillShout()
        end
    end)
end

function UIAutoShoutMainView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAutoShoutMainView:InitRuntimeMap()
    self.tbRuntimeMap = {}
    self.tbRuntimeMap.Other = clone(Storage.Chat_AutoShout) or {}
    self.tbRuntimeMap.Death = clone(Storage.Chat_DeathShout) or {}
    self.tbRuntimeMap.Skill = clone(Storage.Chat_SkillShout) or {}
    self.tbRuntimeMap.Forbid = clone(Storage.ShoutFilter, true) or {}
end

function UIAutoShoutMainView:UpdateInfo()
    self:UpdateInfo_LeftList()
end

function UIAutoShoutMainView:UpdateInfo_LeftList()
    UIHelper.RemoveAllChildren(self.ScrollViewLeftList)

    local szSelectType = self.szType or "Other"
    local tbConf = ChatAutoShout.GetConfigList()
    for index, szType in ipairs(tbAutoShotList) do
        local tbInfo = tbConf[szType]
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetShoutSettingToggle, self.ScrollViewLeftList)
        script:OnEnter(szType, tbInfo.szTitleName, szSelectType == szType, function() self:Select(szType) end)
        UIHelper.SetToggleGroupIndex(script._rootNode, ToggleGroupIndex.ChatAutoShoutSetting)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewLeftList)
    UIHelper.ScrollToTop(self.ScrollViewLeftList)
end

function UIAutoShoutMainView:UpdateInfo_Group()
    UIHelper.RemoveAllChildren(self.ScrollViewRightList)

    local tbConf = ChatAutoShout.GetConfigList(self.szType)
    local bEmpty = true
    if tbConf then
        for _, v in ipairs(tbConf.tbGroupList) do
            local szType = v.szType
            local nPrefabID = PREFAB_ID.WidgetChatShoutTittle
            local tbSettingData = self:_getSettingData(szType)
            local script = UIHelper.AddPrefab(nPrefabID, self.ScrollViewRightList)
            if script["OnEnter_"..self.szType] then
                script["OnEnter_"..self.szType](script, szType, tbConf, v, tbSettingData)
            end
            bEmpty = false
        end
    end

    UIHelper.SetVisible(self.WidgetEmpty, bEmpty)
    UIHelper.ScrollViewDoLayout(self.ScrollViewRightList)
    UIHelper.ScrollToTop(self.ScrollViewRightList)
end

function UIAutoShoutMainView:UpdateInfo_SkillShout()
    UIHelper.RemoveAllChildren(self.ScrollViewRightList)

    local bEmpty = table.is_empty(self.tbRuntimeMap.Skill) or table.is_empty(self.tbRuntimeMap.Skill.tbSkillList)
    if not bEmpty then
        self:UpdateSkillShoutList()
        self:UpdateSkillShoutChannel()
        self:UpdateSkillShoutMap()
    end

    UIHelper.SetVisible(self.WidgetEmpty, bEmpty)
    UIHelper.SetVisible(self.BtnSave_Skill, not bEmpty)
    UIHelper.SetVisible(self.BtnEditSkill, not bEmpty)
    UIHelper.SetVisible(self.LayoutSkillShoutBtnRight, not bEmpty)

    UIHelper.LayoutDoLayout(self.LayoutAutoShoutBtn)
    UIHelper.LayoutDoLayout(self.LayoutSkillShoutBtnRight)
    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewRightList, true, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRightList)
end

function UIAutoShoutMainView:UpdateSkillShoutList()
    local tbSkillList = self.tbRuntimeMap.Skill.tbSkillList
    local scriptContent = UIHelper.AddPrefab(PREFAB_ID.WidgetChatShoutTittle, self.ScrollViewRightList)
    scriptContent:OnInitWithTitle("技能喊话", true, #tbSkillList > MAX_SHOW_SKILL_COUNT)
    -- scriptContent:ShowBtnSetting(true)
    for index, tSkill in ipairs(tbSkillList) do
        local tbInfo = {szTitle = tSkill.szSkillName}
        local scriptCell = scriptContent:AddTag(index)
        self:InitSkillCell(index, tbInfo, scriptCell, function (bSelected)
            tbSkillList[index].bApplied = bSelected
        end, true)
        scriptCell:SetSelected(tbSkillList[index].bApplied, false)
    end
end

local fnApplyChannelTable = function(tbApplyList, tbChannelList, bSelected)
    for k, v in pairs(tbApplyList) do
        tbApplyList[k] = nil
    end

    if not bSelected then
        return
    end

    for index, nID in ipairs(tbChannelList) do
        if not table.contain_value(tbApplyList, nID) then
            table.insert(tbApplyList, nID)
        end
    end
end

function UIAutoShoutMainView:UpdateSkillShoutChannel()
    local scriptContent = UIHelper.AddPrefab(PREFAB_ID.WidgetChatShoutTittle, self.ScrollViewRightList)
    scriptContent:OnInitWithTitle("发布频道", true)

    local bApplied = false
    local tbChannelList = ChatAutoShout.GetChannelList()
    local tbApplyChannelList = self.tbRuntimeMap.Skill.tbChannelList
    for i = 0, 3, 1 do
        local tbInfo = tbChannelList[i]
        local tbChannelID = tbInfo.tbChannelID
        local scriptCell = scriptContent:AddTag(i)
        self:InitSkillCell(i, tbInfo, scriptCell, function (bSelected)
            local tbScript = scriptContent:GetTagScriptList()
            fnApplyChannelTable(tbApplyChannelList, tbChannelID, bSelected)

            for index, tog in pairs(tbScript) do
                tog:SetSelected(index == i, false)
            end
            Timer.AddFrame(self, 1, function()
                tbScript[0]:SetSelected(table.is_empty(tbApplyChannelList), false)
            end)
        end, bToggle)

        for _, nID in ipairs(tbChannelID) do
            if table.contain_value(tbApplyChannelList, nID) then
                bApplied = true
                scriptCell:SetSelected(true, false)
                break
            end
        end
    end

    if table.is_empty(self.tbRuntimeMap.Skill.tbChannelList) then
        local tbScript = scriptContent:GetTagScriptList()
        tbScript[0]:SetSelected(not bApplied, false)
    end
end

local fnApplyMapTable = function(tbApplyList, nType, bSelected)
    if bSelected then
        tbApplyList[nType] = true
    else
        tbApplyList[nType] = nil
    end
end

function UIAutoShoutMainView:UpdateSkillShoutMap()
    local scriptContent = UIHelper.AddPrefab(PREFAB_ID.WidgetChatShoutTittle, self.ScrollViewRightList)
    scriptContent:OnInitWithTitle("不生效地图", true)

    local tbFobidMapList = ChatAutoShout.GetForbidMapList()
    local tbApplyList = self.tbRuntimeMap.Skill.tbForbidMapList
    for nIndex = 1, #tbFobidMapList, 1 do
        local tbInfo = tbFobidMapList[nIndex]
        local scriptCell = scriptContent:AddTag(nIndex)
        self:InitSkillCell(nIndex, tbInfo, scriptCell, function (bSelected)
            fnApplyMapTable(tbApplyList, nIndex, bSelected)
        end, true)

        if tbApplyList[nIndex] then
            scriptCell:SetSelected(true, false)
        end
    end
end

function UIAutoShoutMainView:UpdateInfo_Forbid()
    UIHelper.RemoveAllChildren(self.ScrollViewRightList)

    self:UpdateForbShoutChannel()
    self:UpdateForbShoutType()
    self:UpdateForbWhiteListMap()

    UIHelper.SetVisible(self.WidgetEmpty, false)
    UIHelper.LayoutDoLayout(self.LayoutAutoShoutBtn)
    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewRightList, true, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRightList)
end

local fnApplyForbChannelTable = function(tbApplyList, tbChannelList, bSelected)
    for index, nID in ipairs(tbChannelList) do
        if bSelected and not table.contain_value(tbApplyList, nID) then
            table.insert(tbApplyList, nID)
        elseif not bSelected then
            table.remove_value(tbApplyList, nID)
        end
    end
    return tbApplyList
end

function UIAutoShoutMainView:UpdateForbShoutChannel()
    local scriptContent = UIHelper.AddPrefab(PREFAB_ID.WidgetChatShoutTittle, self.ScrollViewRightList)
    scriptContent:OnInitWithTitle("屏蔽的频道", true)

    local tbChannelList = AutoShoutForbidData.GetChannelConfig()
    local tbApplyChannelList = self.tbRuntimeMap.Forbid.tbForbidChannel
    for i = 1, #tbChannelList, 1 do
        local tbInfo = tbChannelList[i]
        local tbChannelID = tbInfo.tbChannelID
        local scriptCell = scriptContent:AddTag(i)
        self:InitCell(i, tbInfo, scriptCell, function (bSelected)
            fnApplyForbChannelTable(tbApplyChannelList, tbChannelID, bSelected)
        end)

        for _, nID in ipairs(tbChannelID) do
            if table.contain_value(tbApplyChannelList, nID) then
                scriptCell:SetSelected(true, false)
                break
            end
        end
    end
end

local fnApplyForbTypeTable = function(tbApplyList, nType, bSelected)
    if bSelected then
        tbApplyList[nType] = true
    else
        tbApplyList[nType] = nil
    end
end

function UIAutoShoutMainView:UpdateForbShoutType()
    local scriptContent = UIHelper.AddPrefab(PREFAB_ID.WidgetChatShoutTittle, self.ScrollViewRightList)
    scriptContent:OnInitWithTitle("屏蔽的喊话类型", true)

    local tbShoutTypeList = AutoShoutForbidData.GetShoutTypeConfig()
    local tbApplyList = self.tbRuntimeMap.Forbid.tbForbidType
    for nIndex = 1, #tbShoutTypeList, 1 do
        local tbInfo = tbShoutTypeList[nIndex]
        local scriptCell = scriptContent:AddTag(nIndex)
        self:InitCell(nIndex, tbInfo, scriptCell, function (bSelected)
            fnApplyForbTypeTable(tbApplyList, nIndex, bSelected)
        end)

        if tbApplyList[nIndex] then
            scriptCell:SetSelected(true, false)
        end
    end
end

function UIAutoShoutMainView:UpdateForbWhiteListMap()
    local scriptContent = UIHelper.AddPrefab(PREFAB_ID.WidgetChatShoutTittle, self.ScrollViewRightList)
    scriptContent:OnInitWithTitle("以下地图不屏蔽", true)

    local tbWhiteListConfig = AutoShoutForbidData.GetWhiteListConfig()
    local tbApplyList = self.tbRuntimeMap.Forbid.tbForbidMap
    for nIndex = 1, #tbWhiteListConfig, 1 do
        local tbInfo = tbWhiteListConfig[nIndex]
        local scriptCell = scriptContent:AddTag(nIndex)
        self:InitCell(nIndex, tbInfo, scriptCell, function (bSelected)
            fnApplyForbTypeTable(tbApplyList, nIndex, bSelected)
        end)

        if tbApplyList[nIndex] then
            scriptCell:SetSelected(true, false)
        end
    end
end

function UIAutoShoutMainView:InitCell(nIndex, tbInfo, scriptCell, fnOnSelectChanged)
    local szTitle = tbInfo.szTitle
    scriptCell:OnEnter(true)
    scriptCell:SetTitle(szTitle)
    scriptCell:BindOnSelectChanged(fnOnSelectChanged)
end

function UIAutoShoutMainView:UpdateInfo_State()
    UIHelper.SetVisible(self.LayoutAutoShoutBtn, self.szType == "Other" or self.szType == "Death")
    UIHelper.SetVisible(self.WidgetSkillShoutBtn, self.szType == "Skill")
    UIHelper.SetVisible(self.LayoutForbidBtn, self.szType == "Forbid")
end

function UIAutoShoutMainView:Select(szType)
    self.szType = szType
    if self.szType == "Other" then
        self:UpdateInfo_Group()
    elseif self.szType == "Death" then
        self:UpdateInfo_Group()
    elseif self.szType == "Skill" then
        self:UpdateInfo_SkillShout()
    elseif self.szType == "Forbid" then
        self:UpdateInfo_Forbid()
    end

    self:UpdateInfo_State()
end

function UIAutoShoutMainView:RecoverAutoShoutSetting_Other()
    if self.szType ~= "Other" then
        return
    end

    local tbConf = ChatAutoShout.GetConfigList(self.szType)
    if tbConf then
        for n, v in pairs(tbConf.tbGroupList) do
            self.tbRuntimeMap.Other[v.szType][1] = v.szDefaultText
            self.tbRuntimeMap.Other[v.szType][2] = {}
        end
    end
    self:UpdateInfo_Group()
end

function UIAutoShoutMainView:RecoverAutoShoutSetting_Death()
    if self.szType ~= "Death" then
        return
    end

    local tbConf = ChatAutoShout.GetConfigList(self.szType)
    if tbConf then
        for n, v in pairs(tbConf.tbGroupList) do
            self.tbRuntimeMap.Death[v.szType][1] = v.szDefaultText
            self.tbRuntimeMap.Death[v.szType][2] = {}
        end
    end
    self:UpdateInfo_Group()
end

function UIAutoShoutMainView:_getSettingData(szType)
    local tbInfo = self.tbRuntimeMap[self.szType]
    if szType and tbInfo[szType] then
        return tbInfo[szType]
    end

    return {}
end

function UIAutoShoutMainView:InitSkillCell(nIndex, tbInfo, scriptCell, fnOnSelectChanged, bToggle)
    local szTitle = tbInfo.szTitle
    szTitle = UIHelper.LimitUtf8Len(szTitle, 5)

    scriptCell:OnEnter(true, not bToggle)
    scriptCell:SetTitle(szTitle)
    scriptCell:BindOnSelectChanged(fnOnSelectChanged)
end

function UIAutoShoutMainView:CheckHaveChange()
    local bHaveChange = false
    if not table.deepCompare(Storage.Chat_AutoShout, self.tbRuntimeMap.Other)
        or not table.deepCompare(Storage.Chat_DeathShout, self.tbRuntimeMap.Death)
        or not table.deepCompare(Storage.Chat_SkillShout, self.tbRuntimeMap.Skill)
        or not table.deepCompare(Storage.ShoutFilter, self.tbRuntimeMap.Forbid) then
            bHaveChange = true
    end

    return bHaveChange
end

function UIAutoShoutMainView:OnClose()
    local funcConfirm = function()
        for key, v in pairs(self.tbRuntimeMap.Other) do
            Storage.Chat_AutoShout[key] = v
        end

        for key, v in pairs(self.tbRuntimeMap.Death) do
            Storage.Chat_DeathShout[key] = v
        end

        for key, v in pairs(self.tbRuntimeMap.Skill) do
            Storage.Chat_SkillShout[key] = v
        end

        AutoShoutForbidData.SaveShoutFilter(self.tbRuntimeMap.Forbid)
        Storage.Chat_AutoShout.Dirty()
        Storage.Chat_DeathShout.Dirty()
        Storage.Chat_SkillShout.Dirty()
        ChatAutoShout.InitSkillShoutData()
        UIMgr.Close(self)
    end

    local funcCancel = function()
        UIMgr.Close(self)
    end

    if self:CheckHaveChange() then
        local scriptTips = UIHelper.ShowConfirm("当前内容发生修改，是否保存并退出？", funcConfirm, funcCancel)
        scriptTips:SetCancelButtonContent("取消并退出")
        scriptTips:SetConfirmButtonContent("保存")
        return
    end
    UIMgr.Close(self)
end

function UIAutoShoutMainView:OnChangeSkillList(bDxSkill)
    local bDiff = false
    if not table.deepCompare(Storage.Chat_SkillShout, self.tbRuntimeMap.Skill) then
        bDiff = true
    end

    local function _SaveSkill()
        for key, v in pairs(self.tbRuntimeMap.Skill) do
            Storage.Chat_SkillShout[key] = v
        end
        Storage.Chat_SkillShout.Dirty()
    end

    local funcConfirm = function()
        _SaveSkill()
        UIMgr.Open(VIEW_ID.PanelSkillList, bDxSkill)
    end

    if bDiff then
        local scriptTips = UIHelper.ShowConfirm("当前内容发生修改，是否保存？", funcConfirm)
        scriptTips:SetConfirmButtonContent("保存")
        return
    end
    funcConfirm()
end

return UIAutoShoutMainView