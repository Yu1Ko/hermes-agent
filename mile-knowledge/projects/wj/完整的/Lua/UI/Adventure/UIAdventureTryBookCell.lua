-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAdventureTryBookCell
-- Date: 2023-07-28 10:53:02
-- Desc: ?
-- ---------------------------------------------------------------------------------

local function SimpleDate(nData)
	local szData = ""
	if nData >= 10000 then
		if nData % 10000 == 0 then
			szData = nData / 10000 .. g_tStrings.DIGTABLE.tCharDiH[2]
		else
			szData = string.format("%.1f", nData / 10000) .. g_tStrings.DIGTABLE.tCharDiH[2]
		end
	else
		szData = tostring(nData)
	end
	return szData
end

local UIAdventureTryBookCell = class("UIAdventureTryBookCell")

local NAME_FONT_SIZE = 24
local NAME_WIDTH = 160

function UIAdventureTryBookCell:OnEnter()
    -- if not self.bInit then
    --     self:RegEvent()
    --     self:BindUIEvent()
    --     self.bInit = true
    -- end
end

function UIAdventureTryBookCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAdventureTryBookCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnNote, EventType.OnClick, function()
        Event.Dispatch(EventType.OnSelectAdventureTryBookCell, self.tAdv, self.bZhenQi)
    end)

    UIHelper.BindUIEvent(self.BtnNote, EventType.OnTouchBegan, function(btn, nX, nY)
        UIHelper.SetMultiTouch(self.BtnNote, true)
    end)

    UIHelper.BindUIEvent(self.BtnNote, EventType.OnTouchEnded, function(btn, nX, nY)
        UIHelper.SetMultiTouch(self.BtnNote, false)
    end)

    UIHelper.BindUIEvent(self.BtnNote, EventType.OnTouchCanceled, function(btn, nX, nY)
        UIHelper.SetMultiTouch(self.BtnNote, false)
    end)
end

function UIAdventureTryBookCell:RegEvent()
    Event.Reg(self, EventType.OnSelectAdventureTryBookCell, function(tInfo)
        local bSelected = self.tAdv.dwID == tInfo.dwID
        UIHelper.SetVisible(self.ImgSelected, bSelected)
    end)
end

function UIAdventureTryBookCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAdventureTryBookCell:UpdateInfo()

end

function UIAdventureTryBookCell:UpdateZhenQi(tZQ, bSelected)
    self.tAdv = tZQ
    self.bZhenQi = true

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local tShowTry = tZQ.tTryBook[1] --珍奇只有一条
    local tPet = tZQ.tPet
    local szMapName = Table_GetMapName(tPet.nMapID)

    UIHelper.SetVisible(self.ImgToday, tZQ.bUpBuff)
    UIHelper.SetVisible(self.ImgNoChance, false)
    UIHelper.SetVisible(self.ImgDoing, false)
    UIHelper.SetVisible(self.ImgNoResources, false)
    UIHelper.SetVisible(self.ImgSpecial, false)
    UIHelper.SetVisible(self.ImgTried, false)
    UIHelper.SetVisible(self.LabelPetName, false)
    UIHelper.SetVisible(self.LabelTrade, false)
    UIHelper.SetVisible(self.LabelState, false)
    UIHelper.SetVisible(self.ImgSelected, bSelected)

    if tZQ.bTrigger then
        UIHelper.SetVisible(self.ImgDoing, true)
        UIHelper.SetVisible(self.LabelState, true)
        UIHelper.SetString(self.LabelState, "已触发")
    else
        if tZQ.bHasChance then
            if tShowTry.nHasTry == tShowTry.nTryMax then
                UIHelper.SetVisible(self.ImgTried, true)
                UIHelper.SetVisible(self.LabelState, true)
                UIHelper.SetString(self.LabelState, "已尝试")
            else
                UIHelper.SetVisible(self.LabelTrade, true)
                UIHelper.SetString(self.LabelTrade, tShowTry.nHasTry.."/".. tShowTry.nTryMax)
                UIHelper.SetVisible(self.ImgTrade, true)
            end
        elseif tZQ.nChanceState == ADVENTURE_CHANCE_STATE.NO_CHANCE then
            UIHelper.SetVisible(self.ImgNoChance, true)
            UIHelper.SetVisible(self.LabelState, true)
            UIHelper.SetString(self.LabelState, "机缘未到")
        elseif tZQ.nChanceState == ADVENTURE_CHANCE_STATE.EXPLORED then
            UIHelper.SetVisible(self.ImgNoResources, true)
            UIHelper.SetVisible(self.LabelState, true)
            UIHelper.SetString(self.LabelState, "等待探索")
        end
    end
    UIHelper.SetVisible(self.LabelPetName, true)

    local szPetName = string.format("<color=#5F4E3A>%s(%s)</c>", UIHelper.GBKToUTF8(tPet.szName), UIHelper.GBKToUTF8(szMapName))

    for nFontSize = NAME_FONT_SIZE, 1, -1 do
        local width = UIHelper.GetUtf8RichTextWidth(szPetName, nFontSize)
        if width <= NAME_WIDTH then
            UIHelper.SetFontSize(self.LabelPetName, nFontSize)
            break
        end
    end
    UIHelper.SetRichText(self.LabelPetName, szPetName)
    UIHelper.SetTexture(self.ImgQiYuIcon, tZQ.szMobileNamePath)
end

function UIAdventureTryBookCell:UpdateXiYou(tXY, bSelected)
    self.tAdv = tXY
    self.bZhenQi = false

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.SetVisible(self.ImgToday, tXY.bUpBuff)
    UIHelper.SetVisible(self.ImgNoChance, false)
    UIHelper.SetVisible(self.ImgNoResources, false)
    UIHelper.SetVisible(self.ImgDoing, false)
    UIHelper.SetVisible(self.ImgSpecial, tXY.bPerfect)
    UIHelper.SetVisible(self.ImgTried, false)
    UIHelper.SetVisible(self.LabelPetName, false)
    UIHelper.SetVisible(self.LabelTrade, false)
    UIHelper.SetVisible(self.LabelState, false)
    UIHelper.SetVisible(self.ImgSelected, bSelected)

    if tXY.bTrigger then
        UIHelper.SetVisible(self.ImgDoing, true)
        UIHelper.SetVisible(self.LabelState, true)
        UIHelper.SetString(self.LabelState, "已触发")
    else
        if tXY.bHasChance then
            if tXY.bHasTryMax then
                UIHelper.SetVisible(self.ImgTried, true)
                UIHelper.SetVisible(self.LabelState, true)
                UIHelper.SetString(self.LabelState, "已尝试")
            elseif tXY.bTryLess then
                UIHelper.SetVisible(self.LabelTrade, true)
                UIHelper.SetString(self.LabelTrade, g_tStrings.STR_LUCKY_TRYLESS)
                UIHelper.SetVisible(self.ImgTrade, false)
            else
                UIHelper.SetString(self.LabelTrade, tXY.nHasFTry.."/"..#tXY.tTryBook)
                UIHelper.SetVisible(self.ImgTrade, false)
            end
        elseif tXY.nChanceState == ADVENTURE_CHANCE_STATE.NO_CHANCE then
            UIHelper.SetVisible(self.ImgNoChance, true)
            UIHelper.SetVisible(self.LabelState, true)
            UIHelper.SetString(self.LabelState, "机缘未到")
        elseif tXY.nChanceState == ADVENTURE_CHANCE_STATE.EXPLORED then
            UIHelper.SetVisible(self.ImgNoResources, true)
            UIHelper.SetVisible(self.LabelState, true)
            UIHelper.SetString(self.LabelState, "等待探索")
        end
    end
    UIHelper.SetTexture(self.ImgQiYuIcon, tXY.szMobileNamePath)
end

function UIAdventureTryBookCell:DisplayTip()
    local szTip = ""
    local tAdv = self.tAdv
    szTip = szTip .. string.format("<color=#d7f6ff>%s</color>",  UIHelper.GBKToUTF8(tAdv.szName) .. "\n")
	if tAdv.bHasChance then
		local tTryBook = tAdv.tTryBook
		local tDaily = {}
		local tWeekly = {}
		for _, tTry in ipairs(tTryBook) do
			if tTry.nFreshType == 1 then
				table.insert(tDaily, tTry)
			else
				table.insert(tWeekly, tTry)
			end
		end
		if #tDaily ~= 0 then
			szTip = szTip .. string.format("<color=#ffe26e>%s</color>", "\n" .. g_tStrings.STR_LUCKY_DAILY .. "\n")
			for _, tTry in ipairs(tDaily) do
				if tTry.nTryMax == -1 then
					szTip = szTip .. string.format("<color=#aed9e0>%s</color>", UIHelper.GBKToUTF8(tTry.szDesc) .. "\n")
				else
					if tTry.nHasTry >= tTry.nTryMax then
						szTip = szTip .. string.format("<color=#95ff95>%s</color>", UIHelper.GBKToUTF8(tTry.szDesc) .."："..SimpleDate(tTry.nHasTry).."/"..SimpleDate(tTry.nTryMax).."\n")
					else
						szTip = szTip .. string.format("<color=#aed9e0>%s</color>", UIHelper.GBKToUTF8(tTry.szDesc) .."："..SimpleDate(tTry.nHasTry).."/"..SimpleDate(tTry.nTryMax).."\n")
					end
				end
			end
		end

        if #tWeekly ~= 0 then
            szTip = szTip .. string.format("<color=#ffe26e>%s</color>", "\n" .. g_tStrings.STR_LUCKY_WEEKLY .. "\n")
			for _, tTry in ipairs(tWeekly) do
				if tTry.nTryMax == -1 then
					szTip = szTip .. string.format("<color=#aed9e0>%s</color>", UIHelper.GBKToUTF8(tTry.szDesc) .. "\n")
				else
					if tTry.nHasTry >= tTry.nTryMax then
						szTip = szTip .. string.format("<color=#95ff95>%s</color>", UIHelper.GBKToUTF8(tTry.szDesc).."："..SimpleDate(tTry.nHasTry).."/"..SimpleDate(tTry.nTryMax).."\n")
					else
						szTip = szTip .. string.format("<color=#aed9e0>%s</color>", UIHelper.GBKToUTF8(tTry.szDesc).."："..SimpleDate(tTry.nHasTry).."/"..SimpleDate(tTry.nTryMax).."\n")
					end
				end
			end
		end

        local szTips = szTip
        local nDir = TipsLayoutDir.RIGHT_CENTER
        local tips, tipsScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self._rootNode, nDir, szTips)
        local nTipsWidth, nTipsHeight = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
        tips:SetSize(nTipsWidth, nTipsHeight)
        tips:Update()
    else
        if tAdv.szFront ~= "" then
            szTip = szTip .. string.format("<color=#ffe26e>%s</color>",   "\n" .. g_tStrings.STR_LUCKY_CHANCE_NEED .. "\n")
			local tHasChance = tAdv.tHasChance
			local tFront = SplitString(UIHelper.GBKToUTF8(tAdv.szFront), "\n")
			for i, szText in ipairs(tFront) do
				if tHasChance[i] then
                    szTip = szTip .. string.format("<color=#95ff95>%s</color>", szText .. "\n")
				else
					szTip = szTip .. string.format("<color=#aed9e0>%s</color>", szText .. "\n")
				end
			end
            local szTips = szTip
            local nDir = TipsLayoutDir.RIGHT_CENTER
            local tips, tipsScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self._rootNode, nDir, szTips)
            local nTipsWidth, nTipsHeight = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
            tips:SetSize(nTipsWidth, nTipsHeight)
            tips:Update()
		end
    end
end



return UIAdventureTryBookCell