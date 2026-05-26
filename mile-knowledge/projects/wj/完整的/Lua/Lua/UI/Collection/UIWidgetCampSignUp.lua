-- ---------------------------------------------------------------------------------
-- Name: UIWidgetCampSignUp
-- PanelFactionElectionPop
-- Desc: 阵营 - 指挥竞选 - 帮主参选
-- ---------------------------------------------------------------------------------

local UIWidgetCampSignUp = class("UIWidgetCampSignUp")

local MIN_LIMITED_MONEY = {nGold = 1000}
local MAX_LIMITED_MONEY = {nGold = 10000}

local NMIN_LIMITED_MONEY = 1000
local NMAX_LIMITED_MONEY = 10000


function UIWidgetCampSignUp:OnEnter(tInfo, bModify)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bModify = bModify
    self.m_tSendInfo = {}
    self:UpdateInfo(tInfo, bModify)
end

function UIWidgetCampSignUp:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetCampSignUp:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function()
        self:CheckAndCommit()
    end)

    UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function()
        local szTips = 
    "<color=#D7F6FF>攻防指挥权限说明\n</c><color=#FFE26E>指挥团团长： </c><color=#D7F6FF>可从指挥团中挑选一名团员任命为下场攻防主指挥；\n</c>"
     .. "<color=#FFE26E>辅官：</c><color=#D7F6FF>拥有查看攻防战术面板和指挥管理面板的权限；\n</c>"
     .. "<color=#FFE26E>调度官：</c><color=#D7F6FF>拥有查看攻防战术面板和指挥管理面板、添加攻防资金的权限;\n</c>"
     .. "<color=#FFE26E>指挥：</c><color=#D7F6FF>拥有查看攻防战术面板和指挥管理面板、添加攻防资金、购买和分配物品的权限；\n</c>"
     .. "<color=#FFE26E>总指挥：</c><color=#D7F6FF>拥有操作攻防战术面板和指挥管理面板的所有权限。</c>"
     TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnDetail, TipsLayoutDir.RIGHT_CENTER, szTips)
    end)
end

function UIWidgetCampSignUp:RegEvent()
    Event.Reg(self, "CUSTOM_RANK_UPDATE", function()
        self:Updatelist()
    end)
end

function UIWidgetCampSignUp:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIWidgetCampSignUp:UpdateInfo(tInfo, bModify)
    if tInfo.szTName then
        UIHelper.SetString(self.LabelTName, UIHelper.GBKToUTF8(tInfo.szTName) )
        self.m_tSendInfo.szTName = tInfo.szTName
	end

    if g_pClientPlayer and g_pClientPlayer.nCamp ==  CAMP.GOOD then
        UIHelper.SetString(self.EditSlogan, g_tStrings.STR_COMMAND_SLOGAN_GOOD)
	elseif g_pClientPlayer and g_pClientPlayer.nCamp == CAMP.EVIL then
        UIHelper.SetString(self.EditSlogan, g_tStrings.STR_COMMAND_SLOGAN_GOOD)
	end

    -- self.m_tMoney = PackMoney(0, 0, 0)
    self.nGBMoney = 0
    if not bModify then
        local nGoldB, nGold = UnpackMoneyEx(MIN_LIMITED_MONEY)
        UIHelper.SetText(self.EditMoneyB, nGoldB)
        UIHelper.SetText(self.EditMoney, nGold)

        if g_pClientPlayer.nCamp == 1 then
            UIHelper.SetString(self.EditSlogan, g_tStrings.STR_COMMAND_SLOGAN_GOOD)
        elseif	g_pClientPlayer.nCamp == 2 then
            UIHelper.SetString(self.EditSlogan, g_tStrings.STR_COMMAND_SLOGAN_EVIL)
        end
        
    else
        local szTitle = "指挥团竞选修改"
        UIHelper.SetString(self.LabelTitle, szTitle)

        UIHelper.SetText(self.EditTeamName[1], UIHelper.GBKToUTF8(tInfo.szName))

        if tInfo.tTeamInfo then
            local pos = 2
			for szName, _ in pairs(tInfo.tTeamInfo) do
                UIHelper.SetText(self.EditTeamName[pos], UIHelper.GBKToUTF8(szName))
                pos = pos + 1
			end
		end

        if tInfo.nMoney then
            local nGoldB, nGold = ConvertGoldToGBrick(tInfo.nMoney)
            UIHelper.SetText(self.EditMoneyB, nGoldB)
            UIHelper.SetText(self.EditMoney, nGold)
            -- self.m_tMoney = PackMoney((nGoldB * 10000 + nGold), 0, 0)
            self.nGBMoney = nGoldB * 10000 + nGold
        end

        if tInfo.szMsg then
            UIHelper.SetString(self.EditSlogan, UIHelper.GBKToUTF8(tInfo.szMsg) )
		end
    end
end

function UIWidgetCampSignUp:CheckAndCommit()
    if self:CheckLeaderRight() == true and self:CheckMoneyRight() == true then
        self.m_tSendInfo.nAddMoney = self:GetAddMoney()
        self.m_tSendInfo.szMsg = UIHelper.UTF8ToGBK(UIHelper.GetText(self.EditSlogan) )
        self.m_tSendInfo.tName = self:GetInputName()
        RemoteCallToServer("On_Camp_ComSignUp", self.m_tSendInfo, self.bModify)
    end
end

function UIWidgetCampSignUp:CheckLeaderRight()
    local szname = UIHelper.GetText(self.EditTeamName[1])
    if szname == "" then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_COMMAND_NO_LEADER)
		return false
    end
    return true
end

-- function UIWidgetCampSignUp:CheckMoneyRight()
--     local nGoldB = tonumber(UIHelper.GetText(self.EditMoneyB))
--     local nGold = tonumber(UIHelper.GetText(self.EditMoney))
--     local tHaveMoney = g_pClientPlayer.GetMoney()
--     local tNowMoney = PackMoney((nGoldB * 10000 + nGold), 0, 0)
--     local tAddMoney =  MoneyOptSub(tNowMoney, self.m_tMoney)
--     local szMsg = ""

--     if MoneyOptCmp(tAddMoney, tHaveMoney) > 0 then
--         tAddMoney = tHaveMoney
--     end
--     tNowMoney = MoneyOptAdd(tAddMoney, self.m_tMoney)
    
--     if self.bModify and MoneyOptCmp(self.m_tMoney, tNowMoney) > 0 then
--         local nGoldB, nGold = UnpackMoneyEx(self.m_tMoney)
--         UIHelper.SetText(self.EditMoneyB, nGoldB)
--         UIHelper.SetText(self.EditMoney, nGold)
--         OutputMessage("MSG_ANNOUNCE_RED", "需要增加投入资金")
--         return false
--     end

--     if MoneyOptCmp(MIN_LIMITED_MONEY, tNowMoney) > 0 then
--         local nGoldB, nGold = UnpackMoneyEx(MIN_LIMITED_MONEY)
--         UIHelper.SetText(self.EditMoneyB, nGoldB)
--         UIHelper.SetText(self.EditMoney, nGold)
--         szMsg = g_tStrings.STR_CMD_SIGN_UP_MONEY .. 0.1 .. g_tStrings. STR_CMD_MONEY_UNIT
--         OutputMessage("MSG_ANNOUNCE_RED", szMsg)
--         return false
--     elseif MoneyOptCmp(tNowMoney, MAX_LIMITED_MONEY) > 0 then
--         local nGoldB, nGold = UnpackMoneyEx(MAX_LIMITED_MONEY)
--         UIHelper.SetText(self.EditMoneyB, nGoldB)
--         UIHelper.SetText(self.EditMoney, nGold)
--         return true
--     end

--     return true
-- end

function UIWidgetCampSignUp:CheckMoneyRight()
    local nGoldB = tonumber(UIHelper.GetText(self.EditMoneyB))
    local nGold = tonumber(UIHelper.GetText(self.EditMoney))
    local nHaveMoney = g_pClientPlayer.GetMoney().nGold
    local nNowMoney = nGoldB * 10000 + nGold
    local nAddMoney = nNowMoney
    if self.nGBMoney then
        nAddMoney = nNowMoney - self.nGBMoney
    end
    local szMsg = ""

    if nAddMoney - nHaveMoney > 0 then
        nAddMoney = nHaveMoney
        nNowMoney = nAddMoney + self.nGBMoney
    end
    
    if self.bModify and nAddMoney < 0 then
        local nGoldB, nGold = ConvertGoldToGBrick(self.nGBMoney)
        UIHelper.SetText(self.EditMoneyB, nGoldB)
        UIHelper.SetText(self.EditMoney, nGold)
        OutputMessage("MSG_ANNOUNCE_RED", "不能减少投入资金")
        return false
    end

    if NMIN_LIMITED_MONEY - nNowMoney > 0 then
        local nGoldB, nGold = UnpackMoneyEx(MIN_LIMITED_MONEY)
        UIHelper.SetText(self.EditMoneyB, nGoldB)
        UIHelper.SetText(self.EditMoney, nGold)
        szMsg = g_tStrings.STR_CMD_SIGN_UP_MONEY .. 0.1 .. g_tStrings. STR_CMD_MONEY_UNIT
        OutputMessage("MSG_ANNOUNCE_RED", szMsg)
        return false
    elseif nNowMoney - NMAX_LIMITED_MONEY > 0 then
        local nGoldB, nGold = UnpackMoneyEx(MAX_LIMITED_MONEY)
        UIHelper.SetText(self.EditMoneyB, nGoldB)
        UIHelper.SetText(self.EditMoney, nGold)
        return true
    end

    return true
end

function UIWidgetCampSignUp:GetAddMoney()
    local nGoldB = tonumber(UIHelper.GetText(self.EditMoneyB))
    local nGold = tonumber(UIHelper.GetText(self.EditMoney))
    local nNowMoney = nGoldB * 10000 + nGold
    local nAddMoney = nNowMoney - self.nGBMoney
	return nAddMoney
end

function UIWidgetCampSignUp:GetInputName()
	-- tRet = { [0] = "aaa", [1] = "bbb"}
	-- [0] 为指挥团团长, [1] - [4]为指挥团团员。
	local tRet = {}
	for i = 1, 5 do
        local szName = UIHelper.GetText(self.EditTeamName[i])
		if szName ~= "" then 
			tRet[i - 1] = UIHelper.UTF8ToGBK(szName)
		end
	end
	return tRet
end

function UIWidgetCampSignUp:SetCmdNameWrongMsg(tInfo)
	for i = 1, 5 do
		local szWrongMsg =  tInfo[i - 1]
        local szName = UIHelper.GetText(self.EditTeamName[i])
		if not szWrongMsg and szName ~= "" then
            UIHelper.SetVisible(self.BtnMessage[i], true)
            UIHelper.SetVisible(self.ImgIconR[i], true)
            UIHelper.SetVisible(self.ImgIconF[i], false)

            UIHelper.SetTouchEnabled(self.BtnMessage[i], false)
        elseif szWrongMsg then
            UIHelper.SetVisible(self.BtnMessage[i], true)
            UIHelper.SetVisible(self.ImgIconR[i], false)
            UIHelper.SetVisible(self.ImgIconF[i], true)

            UIHelper.SetTouchEnabled(self.BtnMessage[i], true)
            UIHelper.BindUIEvent(self.BtnMessage[i], EventType.OnClick, function()
                TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnMessage[i], TipsLayoutDir.RIGHT_CENTER, UIHelper.GBKToUTF8(szWrongMsg))
            end)
		end
	end
end

return UIWidgetCampSignUp