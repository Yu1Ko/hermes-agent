local UIRenownUseItemView = class("UIRenownUseItemView")
local RELATION_RANK = {
	HATED = 0, -- 仇恨
	HOSTILE = 1, -- 敌视
	UNFRIENDLY = 2, -- 疏远
	NEUTRAL = 3, -- 中立
	FRIENDLY = 4, -- 友好
	INTIMACY = 5, -- 亲密
	REGARD = 6, -- 敬重
	ESTEEM = 7, -- 尊敬
	HORNORED = 8, -- 钦佩
	RESPECT = 9, -- 显赫
	REVERED = 10, -- 崇敬
	EXALTED = 11, -- 崇拜
	LEGEND = 12, -- 传说
}
local tReputation = {
	[0]  = {12000, "仇恨"}, -- 仇恨
	[1]  = {8400,  "敌视"}, -- 敌视
	[2]  = {3600,  "疏远"}, -- 疏远
	[3]  = {3600,  "中立"}, -- 中立
	[4]  = {8400,  "友好"}, -- 友好
	[5]  = {12000, "亲密"}, -- 亲密
	[6]  = {18000, "敬重"}, -- 敬重
	[7]  = {20000, "尊敬"}, -- 尊敬
	[8]  = {22000, "钦佩"}, -- 钦佩
	[9]  = {24000, "显赫"}, -- 显赫
	[10] = {26000, "崇敬"}, -- 崇敬
	[11] = {28000, "崇拜"}, -- 崇拜
	[12] = {30000, "传说"}, -- 传说
}

-- local tReputeItemMap = {
-- 	[6346]  = {nType = 3, nReputation = 600}, 	-- 科举大声望道具
-- 	[6338]  = {nType = 3, nReputation = 300}, 	-- 科举小声望道具	
-- 	[10821] = {nType = 3, nReputation = 100}, 	-- 金缕玉札
-- 	[38120] = {nType = 2, nReputation = 100}, 	-- 迟来的江湖
-- 	[31379] = {nType = 1, nReputation = 100}, 	-- 迟来的钦佩
-- 	[19886] = {nType = 1, nReputation = 100}, 	-- 遗失的尊敬
-- }

function UIRenownUseItemView:OnEnter(dwForceID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitData(dwForceID)
    self:UpdateInfo()
end

function UIRenownUseItemView:OnExit()
    self.bInit = false
end

function UIRenownUseItemView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnReduce, EventType.OnClick, function ()
        self:ChangeUseCount(self.nUseCount-1)
    end)

    UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function ()
        self:ChangeUseCount(self.nUseCount+1)
    end)

    UIHelper.BindUIEvent(self.BtnMax, EventType.OnClick, function ()
        local nMaxCount = self:GetMaxCount()
        if nMaxCount <= 0 then nMaxCount = 1 end
        self:ChangeUseCount(nMaxCount)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function ()
        RemoteCallToServer("On_Reputation_UseReputeItem", self.dwForceID, self.dwIndex, self.nUseCount)
    end)

    UIHelper.RegisterEditBoxEnded(self.EditPaginate, function ()
        local nUseCount = tonumber(UIHelper.GetText(self.EditPaginate)) or 0
        self:ChangeUseCount(nUseCount)
    end)
end

function UIRenownUseItemView:RegEvent()
    Event.Reg(self, EventType.OnGameNumKeyboardOpen, function(editbox)
        if editbox == self.EditPaginate then
            UIHelper.SetEditBoxGameKeyboardRange(self.EditPaginate, 0, 9999)
        end
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if editbox == self.EditPaginate then
            local nUseCount = tonumber(UIHelper.GetText(self.EditPaginate)) or 0
            self:ChangeUseCount(nUseCount)
        end
    end)

    Event.Reg(self, "BAG_ITEM_UPDATE", function()
        for dwIndex, script in pairs(self.tScriptList) do
            script:UpdateInfo()
            if self.dwIndex == dwIndex then
                Timer.AddFrame(self, 1, function ()
                    self:ChangeUseCount(self.nUseCount)
                    UIHelper.SetSelected(script.TogPartnerUpItem, true, false)
                end)
            end
        end
    end)
end

function UIRenownUseItemView:InitData(dwForceID)
    self.dwForceID = dwForceID
    UIHelper.SetText(self.EditPaginate, "1")
    local nMaxLevel = RELATION_RANK.HORNORED -- 默认到钦佩，部分势力达不到钦佩
	if self.dwForceID == 46 or self.dwForceID == 47 then -- 昆仑和刀宗上限亲密
		nMaxLevel = RELATION_RANK.INTIMACY
	end
	if self.dwForceID == 121 then -- 刹那千年上限尊敬
		nMaxLevel = RELATION_RANK.ESTEEM
	end
	if self.dwForceID == 162 then -- 霸刀塞北营只能友好
		nMaxLevel = RELATION_RANK.FRIENDLY
	end

    self.nMaxLevel = nMaxLevel
end

function UIRenownUseItemView:UpdateInfo()
    self.nUseCount = 1
    self.tScriptList = {}
    local tItemConfigList = {}
    local tReputeItemMap = GetReputeItemMap()
    local tReputeForceMap = GetReputeForceMap()
    for dwIndex, tItemConfig in pairs(tReputeItemMap) do
        tItemConfig.dwIndex = dwIndex
        if tReputeForceMap[tItemConfig.nType][self.dwForceID] then
            table.insert(tItemConfigList, tItemConfig)
        end        
    end
    table.sort(tItemConfigList, function (a, b)
        return a.dwIndex > b.dwIndex
    end)

    for nIndex, tItemConfig in ipairs(tItemConfigList) do
        local script = UIMgr.AddPrefab(PREFAB_ID.WidgetPartnerUpItem, self.ScrollViewContent, ITEM_TABLE_TYPE.OTHER, tItemConfig.dwIndex)
        self.tScriptList[tItemConfig.dwIndex] = script
        UIHelper.BindUIEvent(script.TogPartnerUpItem, EventType.OnClick, function()
            self:OnChooseItem(tItemConfig.dwIndex)
            self:ChangeUseCount(1)
        end)
        if nIndex == 1 then
            self:OnChooseItem(tItemConfig.dwIndex)
            self:ChangeUseCount(1)
            Timer.AddFrame(self, 1, function ()
                UIHelper.SetSelected(script.TogPartnerUpItem, true, false)
            end)
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)

    local tForceUIInfo = Table_GetReputationForceInfo(self.dwForceID)
    UIHelper.SetString(self.LabelTitle, string.format("使用道具增加【%s】的声望", UIHelper.GBKToUTF8(tForceUIInfo.szName)))
end

function UIRenownUseItemView:UpdateStatus()
    local nMaxLevel = self.nMaxLevel
    local player = GetClientPlayer()
    local tReputeItemMap = GetReputeItemMap()
    local tItemConfig = tReputeItemMap[self.dwIndex]
    local nCurLevel = player.GetReputeLevel(self.dwForceID)
	local nCurProgress = player.GetReputation(self.dwForceID)
    local nCurProgressLimit = tReputation[nCurLevel][1]
    local nExtraProgress = self.nUseCount * tItemConfig.nReputation
    local nAddLevel = 0
    local nProgress = nCurProgress + nExtraProgress
    local nLimit = nCurProgressLimit
    for nLevel = nCurLevel, nMaxLevel - 1 do
        local nLimit = tReputation[nLevel][1]
        if nProgress >= nLimit then
            nAddLevel = nAddLevel + 1
            nProgress = nProgress - nLimit
        else
            break
        end
    end

    local szCurLevelName = tReputation[nCurLevel][2]
    local szNextLevelName = tReputation[nCurLevel+nAddLevel][2]
    local szLevelDesc = string.format("<color=#D7f6ff>%s</c><color=#fffaa3>->%s</color>", szCurLevelName, szNextLevelName)

    UIHelper.SetRichText(self.LabelLevelNum, szLevelDesc)
    UIHelper.SetString(self.LabelExpAdd, "+"..Partner_GetSimpleExp(nExtraProgress))
    UIHelper.SetString(self.LabelExp, string.format("%s/%s", Partner_GetSimpleExp(nCurProgress), Partner_GetSimpleExp(nCurProgressLimit)))
    UIHelper.SetProgressBarPercent(self.ProgressBase, nCurProgress/nCurProgressLimit * 100)
    UIHelper.SetProgressBarPercent(self.ProgressAdvance, nProgress/nLimit * 100)
    UIHelper.SetVisible(self.ProgressBase, nAddLevel == 0)
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.LabelExp))

    local nItemCount = player.GetItemAmountInAllPackages(5, self.dwIndex)
    if nItemCount < self.nUseCount then
        UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Disable, "可用道具数量不足")
    else
        UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Normal)
    end
end

function UIRenownUseItemView:GetMaxCount()
    local player = g_pClientPlayer
    local tReputeItemMap = GetReputeItemMap()
    local tItemConfig = tReputeItemMap[self.dwIndex]
    local nCurLevel = player.GetReputeLevel(self.dwForceID)
	local nCurProgress = player.GetReputation(self.dwForceID)
    local nProgressSpace = -nCurProgress
    for nLevel = nCurLevel, self.nMaxLevel - 1 do
        nProgressSpace = nProgressSpace + tReputation[nLevel][1]
    end

    local nMaxCount = math.ceil(nProgressSpace / tItemConfig.nReputation)
    local nItemCount = player.GetItemAmountInAllPackages(5, self.dwIndex)
    if nMaxCount > nItemCount then
        nMaxCount = nItemCount
    end

    return nMaxCount
end

function UIRenownUseItemView:ChangeUseCount(nCount)
    if nCount < 1 then nCount = 1 end

    local nMaxCount = self:GetMaxCount()
    if nMaxCount <= 0 then nMaxCount = 1 end
    if nCount > nMaxCount then nCount = nMaxCount end

    self.nUseCount = nCount
    UIHelper.SetText(self.EditPaginate, self.nUseCount)
    if self.nUseCount == 1 then
        UIHelper.SetButtonState(self.BtnReduce, BTN_STATE.Disable, "至少使用1个道具", true)
    else
        UIHelper.SetButtonState(self.BtnReduce, BTN_STATE.Normal)
    end
    if self.nUseCount == nMaxCount then
        UIHelper.SetButtonState(self.BtnAdd, BTN_STATE.Disable, "无法使用更多道具", true)
    else
        UIHelper.SetButtonState(self.BtnAdd, BTN_STATE.Normal)
    end

    self:UpdateStatus()
end

function UIRenownUseItemView:OnChooseItem(dwIndex)
    self.dwIndex = dwIndex
    local tReputeItemMap = GetReputeItemMap()
    local tItemConfig = tReputeItemMap[self.dwIndex]
    local nMaxLevel = RELATION_RANK.HORNORED -- 默认到钦佩，部分势力达不到钦佩
	if self.dwForceID == 46 or self.dwForceID == 47 then -- 昆仑和刀宗上限亲密
		nMaxLevel = RELATION_RANK.INTIMACY
	end
	if self.dwForceID == 121 then -- 刹那千年上限尊敬
		nMaxLevel = RELATION_RANK.ESTEEM
	end
	if self.dwForceID == 162 then -- 霸刀塞北营只能友好
		nMaxLevel = RELATION_RANK.FRIENDLY
	end
    if tItemConfig.nType == 3 and nMaxLevel > RELATION_RANK.ESTEEM then nMaxLevel = RELATION_RANK.ESTEEM end
    self.nMaxLevel = nMaxLevel
end

return UIRenownUseItemView