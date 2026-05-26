-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UICompeteView
-- Date: 2023-05-29 10:22:10
-- Desc: PanelCompete 攻防结算界面
-- ---------------------------------------------------------------------------------

local UICompeteView = class("UICompeteView")

local tValue 			= {30000, 15000} --积分差
local tBattleResult 	=
{
    [CAMP.EVIL] =
    {
        [1]	= "UIAtlas2_Pvp_PvpMainCity_CompeteBgRed4",	--完胜 积分差>=30000
        [2]	= "UIAtlas2_Pvp_PvpMainCity_CompeteBgRed3",	--大胜 积分差>=15000
        [3]	= "UIAtlas2_Pvp_PvpMainCity_CompeteBgRed2",	--险胜 积分差<15000
        [4] = "UIAtlas2_Pvp_PvpMainCity_CompeteBgRed5",	--战平 积分差=2
        [5] = "UIAtlas2_Pvp_PvpMainCity_CompeteBgRed6",	--失败
    },

    [CAMP.GOOD] =
    {
        [1] = "UIAtlas2_Pvp_PvpMainCity_CompeteBgBlue4",
        [2] = "UIAtlas2_Pvp_PvpMainCity_CompeteBgBlue3",
        [3] = "UIAtlas2_Pvp_PvpMainCity_CompeteBgBlue2",
        [4] = "UIAtlas2_Pvp_PvpMainCity_CompeteBgBlue5",
        [5] = "UIAtlas2_Pvp_PvpMainCity_CompeteBgBlue6",
    }
}

local tImgBg = {
    [1] = "UIAtlas2_Pvp_PvpMainCity_CompeteBg1", --胜利
    [2] = "UIAtlas2_Pvp_PvpMainCity_CompeteBg1", --胜利
    [3] = "UIAtlas2_Pvp_PvpMainCity_CompeteBg1", --胜利
    [4] = "UIAtlas2_Pvp_PvpMainCity_CompeteBg2", --战平
    [5] = "UIAtlas2_Pvp_PvpMainCity_CompeteBg3", --失败
}

local tAniName = {
    [1] = "AniVictory", --胜利
    [2] = "AniVictory", --胜利
    [3] = "AniVictory", --胜利
    [4] = "AniDraw",    --战平
    [5] = "AniDefeat",  --失败
}

local tBgColor = {
    [1] = cc.c3b(255, 136, 41), --胜利
    [2] = cc.c3b(255, 136, 41), --胜利
    [3] = cc.c3b(255, 136, 41), --胜利
    [4] = cc.c3b(139, 232, 222), --战平
    [5] = cc.c3b(255, 255, 255), --失败
}

--client\ui\Config\Default\EndOfBattle.lua
local tRewardItemEx =
{
	{5, 85494, 90},
	{5, 85494, 60},
	{5, 85494, 30},
}

--分页
local BATTLE_END = {
    MAIN    = 1,    --主战场
    SNEAK   = 2,    --奇袭场
}

function UICompeteView:OnEnter(tInfo)
    self.tInfo = tInfo
    --print_table(tInfo)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.cellPool = self.cellPool or PrefabPool.New(PREFAB_ID.WidgetCompeteListCell)
        self.tLiveCell = {}
    end

    self:UpdateInfo()
    UIMgr.HideLayer(UILayer.Main)
end

function UICompeteView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    UIMgr.ShowLayer(UILayer.Main)
    self:ClearPoolNode()
    if self.cellPool then self.cellPool:Dispose() end
    self.cellPool = nil
end

function UICompeteView:BindUIEvent()
    UIHelper.BindUIEvent(self.TogBattlefield, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            UIHelper.SetSelected(self.TogRaid, false)
            self.nCurrentPage = BATTLE_END.MAIN
            self:UpdatePage()
        end
    end)
    UIHelper.BindUIEvent(self.TogRaid, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            UIHelper.SetSelected(self.TogBattlefield, false)
            self.nCurrentPage = BATTLE_END.SNEAK
            self:UpdatePage()
        end
    end)

    UIHelper.BindUIEvent(self.BtnQuestion, EventType.OnClick, function()
        self:ShowTips()
    end)
    UIHelper.BindUIEvent(self.BtnReward, EventType.OnClick, function()
        self:ShowRewardTip()
    end)
    UIHelper.BindUIEvent(self.BtnLeave, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UICompeteView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICompeteView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UICompeteView:ClearPoolNode()
    for i = 1, #self.tLiveCell do
        local node = self.tLiveCell[i]
        self.cellPool:Recycle(node)
    end
    self.tLiveCell = {}
end

function UICompeteView:UpdateInfo()
    local tInfo = self.tInfo
    local tMainWarInfo  	 = tInfo.tMainWarInfo
    local tSneakWarInfo  	 = tInfo.tSneakWarInfo

    --显示/隐藏分页Toggle
    UIHelper.SetVisible(self.WidgetBtns, tSneakWarInfo ~= nil)

    self.tMainWarInfo  	 = tMainWarInfo
    self.tSneakWarInfo 	 = tSneakWarInfo
    self.bCanReceiveReward = tInfo.bCanReceiveReward
    self.nContribution 	 = tInfo.nContribution
    self.tMoney		 	 = tInfo.tMoney
    if tMainWarInfo.nInfoID then
        local tLine  = g_tTable.EndOfBattleInfo:Search(tMainWarInfo.nInfoID)
        if tLine then
            self.tLine  = tLine
        end
        UIHelper.SetVisible(self.ImgMiddleMark1, tMainWarInfo.nInfoID == 1)
        UIHelper.SetVisible(self.ImgMiddleMark2, tMainWarInfo.nInfoID == 2)
    end
    self.nMainSumScore  = {[CAMP.GOOD] = 0, [CAMP.EVIL] = 0}
    self.nSneakSumScore = {[CAMP.GOOD] = 0, [CAMP.EVIL] = 0}
    self.nCurrentPage   = BATTLE_END.MAIN

    self:InitTipsText()
    self:UpdatePage()
end

function UICompeteView:InitTipsText()
    local tTipsText = {}

    local function _handleMsgInfo(tUIMsgInfo)
        if not tUIMsgInfo then
            return
        end

        for i = 1, 2 do
            local tBattleList = tUIMsgInfo[i]
            for _, nType in ipairs(tBattleList) do
                local tLine = g_tTable.EndBattle:Search(nType)
                if tLine and tLine.szLinkTip and tLine.szLinkTip ~= "" then
                    local szTitle = UIHelper.GBKToUTF8(tLine.szName)
                    local szLinkTip = UIHelper.GBKToUTF8(tLine.szLinkTip)
                    local szTipText = szTitle .. "：" .. szLinkTip
                    if not table.contain_value(tTipsText, szTipText) then
                        table.insert(tTipsText, szTipText) --保证顺序
                    end
                end
            end
        end
    end

    _handleMsgInfo(self.tMainWarInfo and self.tMainWarInfo.tUIMsgInfo)
    _handleMsgInfo(self.tSneakWarInfo and self.tSneakWarInfo.tUIMsgInfo)

    self.tTipsText = tTipsText
end

function UICompeteView:UpdatePage()
    --数据列表
    self:UpdateCellList() --这里会计算总分，然后下面UpdateResult的时候会显示总分

    --战斗结果
    self:UpdateResult()

    --个人贡献
    self:UpdateContribution()

    --判断是否存在奖励，若不存在奖励则隐藏查看奖励按钮
    self:UpdateRewardState()

    self:SetCurrentPageOpenState()
end

--顶部战斗结果
function UICompeteView:UpdateResult()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local nCamp = hPlayer.nCamp
    local nSumScore_HQ = self:GetCurrentPageScore(CAMP.GOOD)
    local nSumScore_ER = self:GetCurrentPageScore(CAMP.EVIL)

    --顶部积分
    UIHelper.SetString(self.LabelCompetLeftNum, nSumScore_HQ)
    UIHelper.SetString(self.LabelCompetRightNum, nSumScore_ER)

    local nValue = 0
    if nCamp == CAMP.GOOD then
        nValue = nSumScore_HQ - nSumScore_ER
    elseif nCamp == CAMP.EVIL then
        nValue = nSumScore_ER - nSumScore_HQ
    else
        return
    end

    local tLine = self.tLine
    local nValue1
    local nValue2
    if tLine and tLine.nValue1 and tLine.nValue1 ~= 0 and tLine.nValue2 and tLine.nValue2 ~= 0 then
        nValue1 = tLine.nValue1
        nValue2 = tLine.nValue2
    else
        nValue1 = tValue[1]
        nValue2 = tValue[2]
    end

    local nIndex
    if nValue >= nValue1 then
        nIndex = 1
    elseif nValue >= nValue2 and nValue < nValue1 then
        nIndex = 2
    elseif nValue > 0 and nValue < nValue2 then
        nIndex = 3
    elseif nValue == 0 then
        nIndex = 4
    elseif nValue < 0 then
        nIndex = 5
    end

    local szBattleResult = tBattleResult[nCamp][nIndex]
    local szImgBg = tImgBg[nIndex]
    local szAniName = tAniName[nIndex]
    local tColor = tBgColor[nIndex]

    --UIHelper.SetString(self.LabelCompeteTitle, szBattleResult)
    UIHelper.SetSpriteFrame(self.ImgMiddleTitle, szImgBg)
    UIHelper.SetSpriteFrame(self.ImgMiddleTitle1, szBattleResult)

    UIHelper.PlayAni(self, self.AniAll, szAniName)
    UIHelper.SetColor(self.ImgCompeteTitleBg1, tColor)
end

--中间数据列表
function UICompeteView:UpdateCellList()
    local tWarInfo = self:GetCurrentPageWarInfo()
    local tScore_HQ 	= tWarInfo[CAMP.GOOD]["Score"]
    local tScore_ER 	= tWarInfo[CAMP.EVIL]["Score"]
    local tUIMsgInfo 	= tWarInfo.tUIMsgInfo

    local bFirst = not self:GetCurrentPageOpenState()

    self:ClearPoolNode()

    for i = 1, 2 do
        local tBattleList = tUIMsgInfo[i]
        for j = 1, 6 do --要填充空白位置，所以固定1~6
            local nType = tBattleList[j]
            local tLine = nType and g_tTable.EndBattle:Search(nType)
            if tLine then
                local tLineData = {}
                tLineData.szTitle = UIHelper.GBKToUTF8(tLine.szName)
                tLineData.szLinkTip = UIHelper.GBKToUTF8(tLine.szLinkTip)
                for k, v in pairs(tScore_HQ) do
                    if v.nType == tLine.nType then
                        tLineData.szCount_HQ = UIHelper.GBKToUTF8(tostring(v.szCount))
                        tLineData.nScore_HQ = v.nScore
                        if bFirst then
                            self:AddSumScore(CAMP.GOOD, v.nScore)
                        end
                        break
                    end
                end

                for k, v in pairs(tScore_ER) do
                    if v.nType == tLine.nType then
                        tLineData.szCount_ER = UIHelper.GBKToUTF8(tostring(v.szCount))
                        tLineData.nScore_ER = v.nScore
                        if bFirst then
                            self:AddSumScore(CAMP.EVIL, v.nScore)
                        end
                        break
                    end
                end

                local node = self.cellPool:Allocate(self.LayoutCompeteList, tLineData)
                table.insert(self.tLiveCell, node)

                UIHelper.SetLocalZOrder(node, i == 1 and -1 or 0)
            else
                --layout问题，放一个挖空的node填充
                local tLineData = {
                    szTitle = "",
                    szLinkTip = "",
                    szCount_HQ = "",
                    nScore_HQ = "",
                    szCount_ER = "",
                    nScore_ER = "",
                }

                local node = self.cellPool:Allocate(self.LayoutCompeteList, tLineData)
                table.insert(self.tLiveCell, node)

                UIHelper.SetLocalZOrder(node, i == 1 and -1 or 0)
            end
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutCompeteList)
end

--贡献值
function UICompeteView:UpdateContribution()
    local nContribution = self.nContribution
    if nContribution then
        if self.nCurrentPage == BATTLE_END.MAIN then
            UIHelper.SetVisible(self.WidgetDevotion, true)
            UIHelper.SetString(self.LabelDevotion, nContribution)
        elseif self.nCurrentPage == BATTLE_END.SNEAK then
            UIHelper.SetVisible(self.WidgetDevotion, false)
        end
    else
        UIHelper.SetVisible(self.WidgetDevotion, false)
    end
end

--底部奖励按钮和提示文字
function UICompeteView:UpdateRewardState()
    self:InitAwardList()
    
    local bHasReward = #self.tbAwardList > 0

    --UIHelper.SetVisible(self.BtnReward, bHasReward)
    UIHelper.SetVisible(self.LayoutReward, bHasReward)
    UIHelper.SetVisible(self.ImgRewardBg, bHasReward)
    UIHelper.SetVisible(self.LabelDevotionTips, not bHasReward)

    for nIndex, widgetReward in ipairs(self.tbWidgetReward) do
        if self.tbAwardList[nIndex] then
            UIHelper.SetVisible(widgetReward, true)
            local scriptReward = UIHelper.GetBindScript(widgetReward)
            scriptReward:UpdateInfo(self.tbAwardList[nIndex])
        else
            UIHelper.SetVisible(widgetReward, false)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutReward)

    local tLine = self.tLine
    if tLine then
        if self.nCurrentPage == BATTLE_END.MAIN then
            UIHelper.SetString(self.LabelDevotionTips, UIHelper.GBKToUTF8(tLine.szNotGetExplain))
        elseif self.nCurrentPage == BATTLE_END.SNEAK then
            UIHelper.SetString(self.LabelDevotionTips, UIHelper.GBKToUTF8(tLine.szSneakExplain))
        end
    end
end

function UICompeteView:GetCurrentPageWarInfo()
    if self.nCurrentPage == BATTLE_END.MAIN then
        return self.tMainWarInfo
    elseif self.nCurrentPage == BATTLE_END.SNEAK then
        return self.tSneakWarInfo
    end
end

function UICompeteView:SetCurrentPageOpenState()
	if self.nCurrentPage == BATTLE_END.MAIN and not self.bMainPageOpen then
		self.bMainPageOpen = true
	elseif self.nCurrentPage == BATTLE_END.SNEAK and not self.bSneakPageOpen then
		self.bSneakPageOpen = true
	end
end

function UICompeteView:GetCurrentPageOpenState()
	if self.nCurrentPage == BATTLE_END.MAIN then
		return self.bMainPageOpen
	else
		return self.bSneakPageOpen
	end
end

function UICompeteView:AddSumScore(nCamp, nAddScore)
    if self.nCurrentPage == BATTLE_END.MAIN then
        self.nMainSumScore[nCamp] = self.nMainSumScore[nCamp] + nAddScore
    elseif self.nCurrentPage == BATTLE_END.SNEAK then
        self.nSneakSumScore[nCamp] = self.nSneakSumScore[nCamp] + nAddScore
    end
end

function UICompeteView:GetCurrentPageScore(nCamp)
    if self.nCurrentPage == BATTLE_END.MAIN then
        return self.nMainSumScore[nCamp]
    elseif self.nCurrentPage == BATTLE_END.SNEAK then
        return self.nSneakSumScore[nCamp]
    end
end

function UICompeteView:InitAwardList()
    self.tbAwardList = {}

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local nCamp = hPlayer.nCamp
    if nCamp == CAMP.NEUTRAL then
        return
    end

    local tWarInfo = self:GetCurrentPageWarInfo()
    local tPrize = tWarInfo[nCamp]["Reward"]

    local tPerson = tPrize["Personal"]
    local tTong = tPrize["Tong"]

    local function _insertItem(tItem)
        if not tItem then
            return
        end

        local dwTabType = tItem[1]
        local dwIndex = tItem[2]
        local nCount = tItem[3]

        local tItemInfo = ItemData.GetItemInfo(dwTabType, dwIndex)
        local szItemName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(tItemInfo))

        table.insert(self.tbAwardList, {szItemName, nCount, dwTabType, dwIndex})
    end

    if tPerson then
        local nTitlePoint = tPerson["nTitlePoint"] --战阶
        local nPrestige = tPerson["nPrestige"]     --威名

        if nTitlePoint and nTitlePoint > 0 then
            table.insert(self.tbAwardList, {"战阶", nTitlePoint})
        end
        if nPrestige and nPrestige > 0 then
            table.insert(self.tbAwardList, {"威名", nPrestige})
        end

        --个人奖励
        local tPersonItem = tPerson["tItem"] and tPerson["tItem"][1]
        _insertItem(tPersonItem)
    end

    --帮会奖励
    if tTong then
        local tTongItem = tTong["tItem"] and tTong["tItem"][1]
        _insertItem(tTongItem)
    end
end

function UICompeteView:ShowRewardTip()
    TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetRewardPreview, self.BtnReward, TipsLayoutDir.TOP_CENTER, self.tbAwardList, PREFAB_ID.WidgetAward)
end

function UICompeteView:ShowTips()
    local tLine = self.tLine
    local szText = ""

    --tLine = g_tTable.EndOfBattleInfo:Search(1) --测试用

    local function _appendItemText(tItem)
        local dwTabType = tonumber(tItem[1])
        local dwIndex = tonumber(tItem[2])
        local nCount = tonumber(tItem[3])

        local tItemInfo = ItemData.GetItemInfo(dwTabType, dwIndex)
        local szItemName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(tItemInfo))
        local szItemIconPath = UIHelper.GetIconPathByItemInfo(tItemInfo, true)
        szText = szText .. "<img src='" .. szItemIconPath .. "' width='60' height='60' type='0'/>" .. szItemName .. "×" .. nCount --type='0' 表示显示Texture
    end

    if tLine then
        local tTitle = { "完胜", "大胜", "险胜" }

        --szText = szText .. UIHelper.GBKToUTF8(tLine.szName) .. "\n\n"
        szText = szText .. UIHelper.AttachTextColor("【奖励规则】\n", FontColorID.ImportantYellow)
        szText = szText .. UIHelper.GBKToUTF8(tLine.szBaseAwardDesc) .. "\n\n"
        szText = szText .. "额外奖励：" .. UIHelper.GBKToUTF8(tLine.szExtraAwardDesc) .. "\n\n"
        szText = szText .. "攻防结算：\n"
        for i = 1, 3 do
            local szIntegralDifference = UIHelper.GBKToUTF8(tLine["szIntegralDifference" .. i])
            szIntegralDifference = UIHelper.RichTextEscape(szIntegralDifference)

            local szTitlePoint = UIHelper.GBKToUTF8(tLine["szTitlePoint" .. i])
            local szPrestige = UIHelper.GBKToUTF8(tLine["szPrestige" .. i])
            local szTitlePointIconPath = CurrencyData.tbImageSmallIcon[CurrencyType.TitlePoint]
            local szPrestigeIconPath = CurrencyData.tbImageSmallIcon[CurrencyType.Prestige]
            szTitlePointIconPath = string.gsub(szTitlePointIconPath, ".png", "")
            szPrestigeIconPath = string.gsub(szPrestigeIconPath, ".png", "")

            szText = szText .. UIHelper.AttachTextColor(tTitle[i], FontColorID.ImportantYellow) .. " "
            szText = szText .. szIntegralDifference .. " "
            szText = szText .. "<img src='" .. szTitlePointIconPath .. "' width='40' height='40'/>" .. szTitlePoint .. " "
            szText = szText .. "<img src='" .. szPrestigeIconPath .. "' width='40' height='40'/>" .. szPrestige .. " "

            local szBox = tLine["szRewardItem" .. i]
            if szBox and szBox ~= "" then
                szBox = string.gsub(szBox, " ", "")
                local tItem = SplitString(szBox, ",")
                _appendItemText(tItem)
            end

            szText = szText .. "\n"
        end
    else
        szText = szText .. UIHelper.AttachTextColor("【奖励】\n", FontColorID.ImportantYellow)
        for _, tItem in ipairs(tRewardItemEx) do
            _appendItemText(tItem)
            szText = szText .. "\n\n"
        end
    end

    local tTipsText = self.tTipsText or {}
    if #tTipsText > 0 then
        szText = szText .. UIHelper.AttachTextColor("\n【成就信息】\n", FontColorID.ImportantYellow)

        for _, szTipsText in ipairs(tTipsText) do
            szText = szText .. szTipsText .. "\n"
        end
    end

    szText = UIHelper.AttachTextColor(szText, FontColorID.Text_Level2)

    local tip, scriptView = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPvpLabelTips, self.BtnQuestion, szText)
    local nTipsWidth, nTipsHeight = UIHelper.GetContentSize(scriptView.ImgPublicLabelTips)
    tip:SetSize(nTipsWidth, nTipsHeight)
    tip:UpdatePosByNode(self.BtnQuestion)
end

return UICompeteView