-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIEmailView
-- Date: 2022-11-15 09:46:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIEmailView = class("UIEmailView")

local EmailType = {
    System = "system",
    Player = "player",
    Auction = "auction",
}

local nDaySeconds = 60 * 60 * 24
local nHourSeconds = 60 * 60
local nMinuteSeconds = 60

function UIEmailView:OnEnter(dwTargetID,bPet)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nNpcdwID = dwTargetID
    self.bPet = bPet or false -- 是不是通过信鸽打开
    self:InitReceivePage()

    OnCheckAddAchievement(995, "Mail_Frist_Use")
    OnCheckAddAchievement(1000, "Mail_First_Recv")
end

function UIEmailView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIEmailView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        if self.bPet then
            RemoteCallToServer("On_PigeonMail_Close")
        end
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnWrite, EventType.OnClick, function()
        self.bMailNotEnoughRoom = false
        self.MailItemAmountLimit = false
        self.MailMoneyLimit = false

        UIMgr.Open(VIEW_ID.PanelSendMail, self.nNpcdwID, self.bPet)
    end)

    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function()
        UIHelper.ShowConfirm(g_tStrings.STR_MAIL_DEL_SURE,function ()
            local mailInfo = MailMgr.GetMailInfo(self:GetSelectedEmailID())

            if mailInfo and not mailInfo.bItemFlag and not mailInfo.bMoneyFlag then
                MailMgr.DeleteMail(self:GetSelectedEmailID())
            end

            Timer.AddFrame(self, 4, function ()
                self:UpdateMailList()
            end)
        end,nil,false)
    end)

    UIHelper.BindUIEvent(self.BtnReceive, EventType.OnClick, function()
        self.bMailNotEnoughRoom = false
        self.MailItemAmountLimit = false
        self.MailMoneyLimit = false
        self.bReceiveFlag = true
        if PropsSort.IsBagInSort() then
            TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
            return
        end
        self:ReceiveMailItem()
    end)

    UIHelper.BindUIEvent(self.TogSystem, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            if self.szFilter == EmailType.System then
                return
            end
            self.szFilter = EmailType.System

            self:OnSelectChangeTog()
            if self.tbSystemEmailScript and self.tbSystemEmailScript[1] then
                UIHelper.SetSelected(self.tbSystemEmailScript[1].TogFriendEmail02, true)
                UIHelper.ScrollToTop(self.ScrollViewLeft_system, 0)
            end
        end
    end)

    UIHelper.BindUIEvent(self.TogPrivate, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            if self.szFilter == EmailType.Player then
                return
            end
            self.szFilter = EmailType.Player

            self:OnSelectChangeTog()
            if self.tbPlayerEmailScript and self.tbPlayerEmailScript[1] then
                UIHelper.SetSelected(self.tbPlayerEmailScript[1].TogFriendEmail02, true)
                UIHelper.ScrollToTop(self.ScrollViewLeft_player, 0)
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnReply , EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelSendMail,self.nNpcdwID)

        local szName = self:GetMailName()
        local szTitle,szContent = self:GetMailTitleAndContent()
        szTitle = FormatString(g_tStrings.STR_MAIL_REPLAY,szTitle)
        Event.Dispatch(EventType.EmailReply, szName, szTitle, szContent)
    end)

    UIHelper.BindUIEvent(self.BtnForward , EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelSendMail,self.nNpcdwID)

        local szTitle,szContent = self:GetMailTitleAndContent()
        szTitle = FormatString(g_tStrings.STR_MAIL_FORWARD,szTitle)
        Event.Dispatch(EventType.EmailForward, szTitle, szContent)
    end)

    UIHelper.BindUIEvent(self.BtnReport , EventType.OnClick, function()
        local pMailInfo = MailMgr.GetMailInfo(self:GetSelectedEmailID())
        if not pMailInfo then
            return
        end
        if pMailInfo.GetType() ~= MAIL_TYPE.PLAYER then
            return
        end

        local szContent = UIHelper.GBKToUTF8(FormatString(UIHelper.UTF8ToGBK(g_tStrings.STR_MAIL_REPORT), pMailInfo.szTitle, pMailInfo.GetText()))
        local reportView = UIMgr.Open(VIEW_ID.PanelReportPop)
        reportView:UpdateReportInfo(UIHelper.GBKToUTF8(pMailInfo.szSenderName), szContent )
    end)

    UIHelper.BindUIEvent(self.BtnNdr, EventType.OnClick, function()
        UIHelper.ShowConfirm(g_tStrings.STR_MAIL_RETURN_SURE,function ()
            MailMgr.ReturnMail(self:GetSelectedEmailID())

            Timer.AddFrame(self, 4, function ()
                self:UpdateMailList()
            end)
        end,nil,false)
    end)

    UIHelper.BindUIEvent(self.BtnDelete_system, EventType.OnClick, function()
        UIHelper.ShowConfirm(g_tStrings.STR_MAIL_DEL_ALL_SYSTEM_SURE,function ()
            self:DeleteAllbReadMail()
        end,nil,false)
    end)

    UIHelper.BindUIEvent(self.BtnDelete_player, EventType.OnClick, function()
        UIHelper.ShowConfirm(g_tStrings.STR_MAIL_DEL_ALL_PLAYER_SURE,function ()
            self:DeleteAllbReadMail()
        end,nil,false)
    end)

    UIHelper.BindUIEvent(self.BtnReceive_system, EventType.OnClick, function()
        if self.bCanReceive then
            self.bMailNotEnoughRoom = false
            self.MailItemAmountLimit = false
            self.MailMoneyLimit = false

            if PropsSort.IsBagInSort() then
                TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                return
            end

            UIHelper.ShowConfirm(g_tStrings.STR_MAIL_REC_ALL_SYSTEM_SURE,function ()
                self.bAllReceive = true
                self:ReceiveAllbMailItem()
            end,nil,false)
        else
            TipsHelper.ShowNormalTip(g_tStrings.STR_MAIL_ATTACHMENT_TIP)
        end
    end)

    UIHelper.BindUIEvent(self.BtnReceive_player, EventType.OnClick, function()
        if self.bCanReceive then
            self.bMailNotEnoughRoom = false
            self.MailItemAmountLimit = false
            self.MailMoneyLimit = false

            if PropsSort.IsBagInSort() then
                TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                return
            end

            UIHelper.ShowConfirm(g_tStrings.STR_MAIL_REC_ALL_PLAYER_SURE,function ()
                self.bAllReceive = true
                self:ReceiveAllbMailItem()
            end,nil,false)
        else
            TipsHelper.ShowNormalTip(g_tStrings.STR_MAIL_ATTACHMENT_TIP)
        end
    end)

    UIHelper.BindUIEvent(self.ScrollViewLeft_system, EventType.OnScrollingScrollView, function (_, eventType)
		if eventType == ccui.ScrollviewEventType.containerMoved then
			self:UpdateRedPointArrow()
		end
	end)

    UIHelper.BindUIEvent(self.ScrollViewLeft_player, EventType.OnScrollingScrollView, function (_, eventType)
		if eventType == ccui.ScrollviewEventType.containerMoved then
			self:UpdateRedPointArrow()
		end
	end)

    UIHelper.BindUIEvent(self.BtnGet, EventType.OnClick, function ()
        local dwID = self:GetSelectedEmailID()
        local mailInfo = MailMgr.GetMailInfo(dwID)
        mailInfo.TakeMoney(self.nNpcdwID)
	end)
end

function UIEmailView:RegEvent()
    Event.Reg(self, "MAIL_LIST_SYNC_FINISH", function()
        self:InitMailList()
        self:EmailCacheContacts()
        self:CacheContactsList()
        self.bMailListSyncFinish = true
        UIHelper.SetVisible(self.WidgetAnchorLoading, false)
    end)

    Event.Reg(self, "MAIL_LIST_UPDATE", function()
        if not self.bMailListSyncFinish or self.bAllReceive or self.bReceiveFlag then
            return
        end

        self:UpdateMailList()
        self:EmailCacheContacts()
        self:CacheContactsList()
    end)

    Event.Reg(self, "GET_MAIL_CONTENT", function(dwID)
        local tGotContentFlag = self.tbGotContentFlag

        if table_is_empty(tGotContentFlag) then
            self:UpdateMailItemState()
            self:CheckAllReceiveBtnState()
        end

        self:ReReceiveAllbMailItem()
        self:OnGetMainContent(dwID)
    end)

    Event.Reg(self, "FIGHT_HINT", function()
        UIMgr.Close(self)
    end)

    Event.Reg(self, "SYNC_PLAYER_REVIVE", function()
        UIMgr.Close(self)
    end)

    Event.Reg(self, "UPDATE_MAIL_READ_FLAG", function()
        self:UpdateRedDot()
    end)

    Event.Reg(self, EventType.MailNotEnoughRoom, function()
        if not self.bMailNotEnoughRoom then
            self.bMailNotEnoughRoom = true

            self:HandleAllReceiveMail()
        end
    end)

    Event.Reg(self, EventType.MailItemAmountLimit, function()
        if not self.MailItemAmountLimit then
            self.MailItemAmountLimit = true

            self:HandleAllReceiveMail()
        end
    end)

    Event.Reg(self, EventType.MailMoneyLimit, function()
        if not self.MailMoneyLimit then
            self.MailMoneyLimit = true

            self:HandleAllReceiveMail()
        end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function (szName)
        -- if self.szFilter == EmailType.System then
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewLeft_system)
        -- else
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewLeft_player)
        -- end
        self.nHAttachment = UIHelper.GetHeight(self.ScrollViewContent)
        self.nHNotAttachment = UIHelper.GetHeight(self.ScrollViewContent) + UIHelper.GetHeight(self.WidgetAttachment)
    end)
end

function UIEmailView:UnRegEvent()
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIEmailView:UpdateInfo()

end

function UIEmailView:UpdateCoinAndMoney()
    UIHelper.AddPrefab(PREFAB_ID.WidgetCurrency, self.LayoutCurrency)
end

function UIEmailView:InitReceivePage()
    self.szFilter = EmailType.System
    self.bReceiveNum = 0
    self.nHAttachment = UIHelper.GetHeight(self.ScrollViewContent)
    self.nHNotAttachment = UIHelper.GetHeight(self.ScrollViewContent) + UIHelper.GetHeight(self.WidgetAttachment)
    GetMailClient().ApplyMailList()
    self:UpdateCoinAndMoney()
    UIHelper.SetVisible(self.ImgBrid, self.bPet)
end

function UIEmailView:UpdatePageInfo()
    self.nEmailCount = MailMgr.GetMailCount(self.szFilter)

    UIHelper.SetVisible(self.WidgetAnchorRight, self.nEmailCount ~= 0)
    UIHelper.SetVisible(self.WidgetAnchorEmpty, self.nEmailCount == 0)
    UIHelper.SetVisible(self.WidgetAnchorLeft01, self.nEmailCount ~= 0 and self.szFilter == EmailType.System)
    UIHelper.SetVisible(self.WidgetAnchorLeft02, self.nEmailCount ~= 0 and self.szFilter == EmailType.Player)
    UIHelper.SetVisible(self.BtnDelete_system, self.nEmailCount ~= 0 and self.szFilter == EmailType.System)
    UIHelper.SetVisible(self.BtnDelete_player, self.nEmailCount ~= 0 and self.szFilter == EmailType.Player)
    UIHelper.SetVisible(self.BtnReceive_system, self.szFilter == EmailType.System)
    UIHelper.SetVisible(self.BtnReceive_player, self.szFilter == EmailType.Player)
    UIHelper.SetString(self.LabelTitle_copy, "("..self.nEmailCount..")")

    UIHelper.SetVisible(self.BtnReply, self.szFilter ~= EmailType.System)
    UIHelper.SetVisible(self.BtnReport, self.szFilter ~= EmailType.System)
    UIHelper.LayoutDoLayout(self.LayoutTopBtn)
end

function UIEmailView:UpdateRedDot()
    UIHelper.SetVisible(self.ImgRedDot01_system,false)
    UIHelper.SetVisible(self.ImgRedDot02_player,false)

    self:UpdateFilterRedDot(EmailType.System,self.ImgRedDot01_system)
    self:UpdateFilterRedDot(EmailType.Auction,self.ImgRedDot01_system)
    self:UpdateFilterRedDot(EmailType.Player,self.ImgRedDot02_player)

    self:UpdateRedPointArrow()
end

function UIEmailView:UpdateFilterRedDot(szFilter,sRedDotNode)
    local aMail = MailMgr.GetMailList(szFilter)
    for _, dwID in ipairs(aMail) do
        local mailInfo = MailMgr.GetMailInfo(dwID)
        if mailInfo.bReadFlag == false then
            UIHelper.SetVisible(sRedDotNode, true)
            break
        end
    end
end

function UIEmailView:GetSelectedEmailID()
    if self.szFilter == EmailType.System then
        return self.tbEmailIDtabSystem[self.nSel]
    else
        return self.tbEmailIDtabPlayer[self.nSel]
    end
end

function UIEmailView:UpdateMailListInfo()
    self:UpdateRedDot()
    self:UpdatePageInfo()
end

function UIEmailView:InitMailList()
    self.tbEmailIDtabSystem, self.tbEmailIDtabPlayer = MailMgr.GetAllMailList()

    self.tbItemReceivetab = {}
    self.tbReceiveQueue = {}
    self.tbSystemEmailScript = {}
    self.tbPlayerEmailScript = {}

    self:UpdateSystemAndPlayerMailList(self.tbEmailIDtabSystem, true)
    self:UpdateSystemAndPlayerMailList(self.tbEmailIDtabPlayer, false)

    if self.szFilter == EmailType.System and self.tbSystemEmailScript[1] then
        UIHelper.SetSelected(self.tbSystemEmailScript[1].TogFriendEmail02, true)
        UIHelper.SetVisible(self.WidgetAnchorLoading, false)
    elseif self.szFilter == EmailType.Player and self.tbPlayerEmailScript[1] then
        UIHelper.SetSelected(self.tbPlayerEmailScript[1].TogFriendEmail02, true)
        UIHelper.SetVisible(self.WidgetAnchorLoading, false)
    end

    self:UpdateMailListInfo()
    self:CheckAllReceiveBtnState()
end

function UIEmailView:UpdateMailList()
    self.tbEmailIDtabSystem, self.tbEmailIDtabPlayer = MailMgr.GetAllMailList()

    self.tbItemReceivetab = {}
    self.tbReceiveQueue = {}

    self.tbSystemEmailScript = {}
    self.tbEmailIDtabSystem = MailMgr.GetOfficialMailList()
    self.tbPlayerEmailScript = {}
    self.tbEmailIDtabPlayer = MailMgr.GetPlayerMailList()
    self:UpdateSystemAndPlayerMailList(self.tbEmailIDtabSystem, true)
    self:UpdateSystemAndPlayerMailList(self.tbEmailIDtabPlayer, false)

    local tbEmailScript = self.szFilter == EmailType.System and self.tbSystemEmailScript or self.tbPlayerEmailScript
    local nIndex = self.nSel or 1
    if tbEmailScript[nIndex] then
        UIHelper.SetSelected(tbEmailScript[nIndex].TogFriendEmail02, true)
    elseif tbEmailScript[1] then
        UIHelper.SetSelected(tbEmailScript[1].TogFriendEmail02, true)
    end

    self:UpdateMailListInfo()
    self:CheckAllReceiveBtnState()
end

function UIEmailView:UpdateSystemAndPlayerMailList(aMail, bSystem)
    local ScrollView, tbEmailScript
    if bSystem then
        ScrollView = self.ScrollViewLeft_system
        tbEmailScript = self.tbSystemEmailScript
    else
        ScrollView = self.ScrollViewLeft_player
        tbEmailScript = self.tbPlayerEmailScript
    end

    UIHelper.RemoveAllChildren(ScrollView)

    for nIndex, dwID in ipairs(aMail) do
        local mailInfo = MailMgr.GetMailInfo(dwID)

        local dwTime = mailInfo.GetLeftTime()
        local szTimeLeft, szTitle = self:GetTimeLeftAndTitle(dwTime, mailInfo.szTitle)
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetFriendEmail02, ScrollView)

        if script then
            UIHelper.SetVisible(script.ImgRedDot, not mailInfo.bReadFlag)
            UIHelper.SetVisible(script.ImgNormalBg, not mailInfo.bReadFlag)
            UIHelper.SetVisible(script.ImgReadedBg, mailInfo.bReadFlag)

            for i = 1, 3 do
                UIHelper.SetString(script.tbLabelDays[i], szTimeLeft)
                UIHelper.SetString(script.tbLabelEmails[i], szTitle)
                if mailInfo.bPayFlag then
                    UIHelper.SetColor(script.tbLabelDays[i],cc.c3b(255, 192, 203))
                end
            end

            UIHelper.SetVisible(script.WidgetTopIcon, mailInfo.bPayFlag or mailInfo.bItemFlag or mailInfo.bMoneyFlag)
            UIHelper.SetVisible(script.ImgmoneySelect, mailInfo.bPayFlag)
            if not mailInfo.bPayFlag then
                UIHelper.SetVisible(script.ImgPackageSelect, mailInfo.bItemFlag or mailInfo.bMoneyFlag)
            end

            UIHelper.BindUIEvent(script.TogFriendEmail02, EventType.OnSelectChanged, function (_, bSelected)
                if bSelected then
                    UIHelper.SetVisible(script.ImgRedDot, false)
                    UIHelper.SetVisible(script.ImgNormalBg, false)
                    UIHelper.SetVisible(script.ImgReadedBg, true)
                    self.nSel = nIndex
                    self:SelectLetter(nIndex)
                end
            end)

            table.insert(tbEmailScript, script)
        end
    end

    UIHelper.ScrollViewDoLayout(ScrollView)

    self.nSel = self.nSel or 1
    if not tbEmailScript[self.nSel] then
        self.nSel = 1
    end
    UIHelper.ScrollToIndex(ScrollView, self.nSel - 1)
end

function UIEmailView:UpdateMailItemState()
    local tbEmailScript = self.tbSystemEmailScript
    local tbEmailIDtab = self.tbEmailIDtabSystem
    if self.szFilter == EmailType.Player then
        tbEmailScript = self.tbPlayerEmailScript
        tbEmailIDtab = self.tbEmailIDtabPlayer
    end

    for k,script in ipairs(tbEmailScript) do
        local dwID = tbEmailIDtab[k]
        local mailInfo = MailMgr.GetMailInfo(dwID)
        UIHelper.SetVisible(script.ImgRedDot, not mailInfo.bReadFlag)
        UIHelper.SetVisible(script.ImgNormalBg, not mailInfo.bReadFlag)
        UIHelper.SetVisible(script.ImgReadedBg, mailInfo.bReadFlag)
        if self.nSel == k then
            UIHelper.SetVisible(script.ImgRedDot, false)
            UIHelper.SetVisible(script.ImgNormalBg, false)
            UIHelper.SetVisible(script.ImgReadedBg, true)
        end

        UIHelper.SetVisible(script.WidgetTopIcon, mailInfo.bPayFlag or mailInfo.bItemFlag or mailInfo.bMoneyFlag)
        UIHelper.SetVisible(script.ImgmoneySelect, mailInfo.bPayFlag)

        if not mailInfo.bPayFlag then
            UIHelper.SetVisible(script.ImgPackageSelect, mailInfo.bItemFlag or mailInfo.bMoneyFlag)
        end

        for i = 1, 3 do
            if mailInfo.bPayFlag then
                UIHelper.SetColor(script.tbLabelDays[i],cc.c3b(255, 192, 203))
            end
        end
    end
end

function UIEmailView:GetTimeLeftAndTitle(dwTime, szTitle)
    local szTimeLeft = ""
    if dwTime >= nDaySeconds then
        szTimeLeft = tostring(math.floor(dwTime / nDaySeconds))..g_tStrings.STR_TIME_DAY
    elseif dwTime >= nHourSeconds then
        szTimeLeft = tostring(math.floor(dwTime / nHourSeconds))..g_tStrings.STR_TIME_HOUR
    elseif dwTime >= nMinuteSeconds then
        szTimeLeft = tostring(math.floor(dwTime / nMinuteSeconds))..g_tStrings.STR_TIME_MINUTE
    else
        szTimeLeft = g_tStrings.STR_MAIL_LEFT_LESS_ONE_M
    end

    if szTitle and szTitle ~= "" then
        _, szTitle = UIHelper.TruncateString(UIHelper.GBKToUTF8(szTitle), 9, "...")
    end

    return szTimeLeft, szTitle
end

function UIEmailView:CheckAllReceiveBtnState()
    self.tbGotContentFlag = {}

    self.bCanReceive = self:CheckReceiveAllbMailItem()
    if self.szFilter == EmailType.System then
        UIHelper.SetVisible(self.ImgGray_system, not self.bCanReceive)
        UIHelper.SetButtonState(self.BtnReceive_system, self.bCanReceive and BTN_STATE.Normal or  BTN_STATE.Disable)
    else
        UIHelper.SetVisible(self.ImgGray_player, not self.bCanReceive)
        UIHelper.SetButtonState(self.BtnReceive_player, self.bCanReceive and BTN_STATE.Normal or  BTN_STATE.Disable)
    end

    if not self.bCanReceive then
        self.bAllReceive = self.bCanReceive
        self.bReceiveFlag = self.bCanReceive
    end
end

function UIEmailView:SelectLetter(nIndex)
    self.nSel = nIndex

    local mailInfo = MailMgr.GetMailInfo(self:GetSelectedEmailID())

    if not mailInfo then
        return
    end

    if mailInfo.bGotContentFlag then
        mailInfo.Read()
	else
        mailInfo.RequestContent(self.nNpcdwID)
    end

    self:ClearMailInfo()
    self:UpdateMailInfo(self:GetSelectedEmailID())
end

function UIEmailView:ClearMailInfo()
    for k, v in ipairs(self.tbWidgetMoney) do
        UIHelper.SetVisible(v, false)
    end
    UIHelper.LayoutDoLayout(self.LayoutPay)
end

function UIEmailView:UpdateMailInfo(dwID)
    local mailInfo = MailMgr.GetMailInfo(dwID)
    if not mailInfo then
		return
	end

    local szSenderName = UIHelper.GBKToUTF8(mailInfo.szSenderName)
    local pos = string.find(szSenderName, "GM")
    if mailInfo.GetType() == MAIL_TYPE.PLAYER and not pos then
        szSenderName = g_tStrings.STR_MAIL_NO_SYSTEM..szSenderName
    end

    local nSendTime = mailInfo.GetSendTime()
    local szSendTimeDate = os.date("%Y年%m月%d日", nSendTime)
    local szSemdTime = os.date("%H:%M", nSendTime)

    UIHelper.SetString(self.LabelTitle, UIHelper.GBKToUTF8(mailInfo.szTitle))
    UIHelper.SetString(self.LabelSystem, szSenderName)
    UIHelper.SetString(self.LabelDate, szSendTimeDate )
    UIHelper.SetString(self.LabelTime, szSemdTime)
    UIHelper.LayoutDoLayout(self.LayoutTime)
    UIHelper.SetString(self.LabelContent,UIHelper.GBKToUTF8(mailInfo.GetText()))
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTitle_sender)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTitle)

    UIHelper.SetVisible(self.BtnReceive, mailInfo.bMoneyFlag or mailInfo.bItemFlag)
    UIHelper.SetVisible(self.BtnDelete, not (mailInfo.bMoneyFlag or mailInfo.bItemFlag))
    UIHelper.SetVisible(self.WidgetAttachment, mailInfo.bMoneyFlag or mailInfo.bItemFlag)
    UIHelper.SetVisible(self.ImgTitleBg2, mailInfo.bMoneyFlag or mailInfo.bItemFlag)
    UIHelper.SetVisible(self.ImgEMailBg, not mailInfo.bPayFlag)
    UIHelper.SetVisible(self.ImgEMailBg_Money, mailInfo.bPayFlag)

    UIHelper.SetHeight(self.ScrollViewContent, (mailInfo.bMoneyFlag or mailInfo.bItemFlag) and self.nHAttachment or self.nHNotAttachment)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)

    if self.szFilter == EmailType.Player then
        local bFlag = (not mailInfo.bReturnFlag) and (mailInfo.bMoneyFlag or mailInfo.bItemFlag)
        UIHelper.SetVisible(self.BtnNdr, bFlag)
        UIHelper.SetVisible(self.ImgBgTip, bFlag)
    else
        UIHelper.SetVisible(self.BtnNdr, false)
        UIHelper.SetVisible(self.ImgBgTip, false)
    end

    self:UpdateItem(dwID)
end

function UIEmailView:UpdateItem(dwID)
    UIHelper.RemoveAllChildren(self.ScrollViewReward)
    local mailInfo = MailMgr.GetMailInfo(dwID)
    if not mailInfo then
		return
	end

    local tMailItem = {}
    local tBookID = {}
    for i = 0, 7, 1 do
        local item = mailInfo.GetItem(i)
        if item then
            local itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.LayoutReward)
            if itemIcon then
                itemIcon:SetClickNotSelected(true)
                itemIcon:OnInitWithTabID(item.dwTabType, item.dwIndex)
                if item.bCanStack and item.nStackNum > 1 then
                    itemIcon:SetLabelCount(item.nStackNum)
                else
                    itemIcon:SetLabelCount()
                end

                UIHelper.SetAnchorPoint(itemIcon._rootNode, 0.5, 0)
                itemIcon:SetClickCallback(function (nTabType, nTabID)
                    for _, v in ipairs(tMailItem) do
                        if UIHelper.GetSelected(v.ToggleSelect) then
                            UIHelper.SetSelected(v.ToggleSelect,false)
                        end
                    end
                    local _, scriptItemTips = TipsHelper.ShowItemTipsWithItemID(itemIcon._rootNode, item.dwID)
                    if tBookID[i] then
                        scriptItemTips:SetBookID(tBookID[i])
                        scriptItemTips:OnInitWithTabID(nTabType, nTabID)
                    end
                    local tbBtnInfo = {{
                        szName = "领取",
                        OnClick = function()
                            if PropsSort.IsBagInSort() then
                                TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                                return
                            end
                            local tAllItemPrice = FormatMoneyTab(mailInfo.nAllItemPrice)
                            if MoneyOptCmp(tAllItemPrice , 0) > 0 then
                                if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.MAIL, "GiveMoney") then
                                    return
                                end

                                UIMgr.Open(VIEW_ID.PanelNormalConfirmation, g_tStrings.STR_MAIL_TAKE_PAY_MAIL1, function ()
                                    mailInfo.TakePayItem(self.nNpcdwID, i)
                                end,function()
                                end, false, g_tStrings.STR_MAIL_TAKE_PAY_MAIL12, self.tbPayMoney)
                            else
                                mailInfo.TakeItem(self.nNpcdwID, i)
                            end

                            TipsHelper.DeleteAllHoverTips()
                        end}
                    }
                    scriptItemTips:SetBtnState(tbBtnInfo)
                end)

                table.insert(tMailItem, itemIcon)
                if item.nGenre == ITEM_GENRE.BOOK then
                    tBookID[i] = item.nBookID
                end
            end
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewReward)

    self:UpdateItemMoney(mailInfo)
    self:UpdateItemPay(mailInfo)
end

function UIEmailView:UpdateItemMoney(mailInfo)
    UIHelper.SetVisible(self.LayoutResource, mailInfo.bMoneyFlag)

    if mailInfo.bMoneyFlag then
        local tAllMoney = FormatMoneyTab(mailInfo.fMoney64)
        if tAllMoney.nGold >= 10000 then
            UIHelper.SetVisible(self.WidgetBullion_m, true)
            local nGoldB = math.floor(tAllMoney.nGold/10000)
            UIHelper.SetString(self.LabelBullion_m,tostring(nGoldB))

            local nGold = tAllMoney.nGold - (nGoldB * 10000)
            if nGold ~= 0 then
                UIHelper.SetVisible(self.WidgetGold_m, true)
                UIHelper.SetString(self.LabelGold_m,tostring(nGold))
            end
        elseif tAllMoney.nGold ~= 0 then
            UIHelper.SetVisible(self.WidgetGold_m, true)
            UIHelper.SetString(self.LabelGold_m,tostring(tAllMoney.nGold))
        end

        if tAllMoney.nSilver ~= 0 then
            UIHelper.SetVisible(self.WidgetSilver_m, true)
            UIHelper.SetString(self.LabelSilver_m,tostring(tAllMoney.nSilver))
        end

        if tAllMoney.nCopper ~= 0 then
            UIHelper.SetVisible(self.WidgetMoney_m, true)
            UIHelper.SetString(self.LabelMoney_m,tostring(tAllMoney.nCopper))
        end
        UIHelper.CascadeDoLayoutDoWidget(self.LayoutResource,true,false)
    end
end

function UIEmailView:UpdateItemPay(mailInfo)
    local tAllItemPrice = FormatMoneyTab(mailInfo.nAllItemPrice)

    self.tbPayMoney = {}
    UIHelper.SetVisible(self.WidgetPay, false)
    if MoneyOptCmp(tAllItemPrice , 0) > 0 then
        UIHelper.SetVisible(self.WidgetPay, true)
        if tAllItemPrice.nGold >= 10000 then
            UIHelper.SetVisible(self.WidgetMoneyBullion, true)
            local nGoldB = math.floor(tAllItemPrice.nGold/10000)
            UIHelper.SetString(self.LabelBullion,""..nGoldB)

            self.tbPayMoney.nGoldB = nGoldB
            local nGold = tAllItemPrice.nGold - (nGoldB * 10000)

            if nGold ~= 0 then
                UIHelper.SetVisible(self.WidgetMoneyGoldIngot, true)
                UIHelper.SetString(self.LabelGoldIngot,""..nGold)
                self.tbPayMoney.nGold = nGold
            end
        elseif tAllItemPrice.nGold ~= 0 then
            UIHelper.SetVisible(self.WidgetMoneyGoldIngot, true)
            UIHelper.SetString(self.LabelGoldIngot,""..tAllItemPrice.nGold)
            self.tbPayMoney.nGold = tAllItemPrice.nGold
        end

        if tAllItemPrice.nSilver ~= 0 then
            UIHelper.SetVisible(self.WidgetMoneySilverIngot, true)
            UIHelper.SetString(self.LabelSilverIngot,""..tAllItemPrice.nSilver)
            self.tbPayMoney.nSilver = tAllItemPrice.nSilver
        end

        if tAllItemPrice.nCopper ~= 0 then
            UIHelper.SetVisible(self.WidgetMoneyCopper, true)
            UIHelper.SetString(self.LabelCopper,""..tAllItemPrice.nCopper)
            self.tbPayMoney.nCopper = tAllItemPrice.nCopper
        end
    end
    Timer.AddFrame(self, 1, function ()
        UIHelper.LayoutDoLayout(self.LayoutPay)
    end)
end

function UIEmailView:OnGetMainContent(dwID)
    local mailInfo = MailMgr.GetMailInfo(dwID)
    if not mailInfo then
		return
	end

    local nSelID = self:GetSelectedEmailID()

    if nSelID == dwID then
        if mailInfo.bGotContentFlag then
            mailInfo.Read()
        end
        self:UpdateMailInfo(dwID)
    end
end

function UIEmailView:GetMailName()
    local mailInfo = MailMgr.GetMailInfo(self:GetSelectedEmailID())
    local szName = UIHelper.GBKToUTF8(mailInfo.szSenderName)
    return szName
end

function UIEmailView:GetMailTitleAndContent()
    local mailInfo = MailMgr.GetMailInfo(self:GetSelectedEmailID())
    local szTitle = UIHelper.GBKToUTF8(mailInfo.szTitle)
    local szContentGB = mailInfo.GetText()
    local szContent = UIHelper.GBKToUTF8(szContentGB)
    return szTitle,szContent
end

function UIEmailView:DeleteAllbReadMail()
    if self.bAllReceive or self.bReceiveFlag then
        TipsHelper.ShowNormalTip("正在领取中，请不要删除邮件")
        return
    end

    local tbEmailIDtab = self.tbEmailIDtabSystem
    if self.szFilter == EmailType.Player then
        tbEmailIDtab = self.tbEmailIDtabPlayer
    end

    self.nDelMailTimerID = self.nDelMailTimerID or Timer.AddFrameCycle(self, 1, function ()
        self.nDelMailIndex = self.nDelMailIndex or 1
        if self.nDelMailIndex <= #tbEmailIDtab then
            local dwID = tbEmailIDtab[self.nDelMailIndex]
            local mailInfo = MailMgr.GetMailInfo(dwID)
            if mailInfo and mailInfo.bReadFlag and not mailInfo.bItemFlag and not mailInfo.bMoneyFlag then
                MailMgr.DeleteMail(dwID)
            end
            self.nDelMailIndex = self.nDelMailIndex + 1
        else
            self.nDelMailIndex = nil
            Timer.DelTimer(self, self.nDelMailTimerID)
            self.nDelMailTimerID = nil
            self:UpdateMailList()
        end
    end)
end

function UIEmailView:ReceiveAllbMailItem()
    local tbEmailIDtab = self.tbEmailIDtabSystem
    if self.szFilter == EmailType.Player then
        tbEmailIDtab = self.tbEmailIDtabPlayer
    end

    local tReceivetab = self.tbItemReceivetab
    local tReceiveQueue = self.tbReceiveQueue

    for index = #tbEmailIDtab, 1, -1 do
        local dwID = tbEmailIDtab[index]
        local mailInfo = MailMgr.GetMailInfo(dwID)
        if not mailInfo then
            return
        end

        if mailInfo.bMoneyFlag then
            if self.MailMoneyLimit then
                local tbCurMoney = g_pClientPlayer.GetMoney()
                local nCurMoney = ItemData.MoneyFromGoldSilverAndCopper(0, tbCurMoney.nGold, tbCurMoney.nSilver, tbCurMoney.nCopper)
                local nPlayerMoneyLimit = g_pClientPlayer.GetMoneyLimitByGold()
                local nMaxMoney = ItemData.MoneyFromGoldSilverAndCopper(0, nPlayerMoneyLimit, 0, 0)

                if mailInfo.fMoney64 + nCurMoney <= nMaxMoney then
                    local nKey = self:GetKey(dwID, 8)
                    tReceivetab[nKey] = true
                    table.insert(tReceiveQueue, {nMailID = dwID})
                end
            else
                local nKey = self:GetKey(dwID, 8)
                tReceivetab[nKey] = true
                table.insert(tReceiveQueue, {nMailID = dwID})
            end
        end

        if mailInfo.bItemFlag then
            if mailInfo.nAllItemPrice == 0 then
                for i = 0, 7, 1 do
                    local item = mailInfo.GetItem(i)
                    if item then
                        self:HandleReceiveMailItem(i, dwID, item, tReceivetab, tReceiveQueue)
                    end
                end
            end
        end
    end

    if #tReceiveQueue == 0 or self.bReceiveNum >= 5 then
        self.bReceiveNum = 0
        self.bAllReceive = false
    end

    self:MailItemReceiving()
end

function UIEmailView:CheckReceiveAllbMailItem()
    local bCanReceiveAll = false
    local tbEmailIDtab = self.tbEmailIDtabSystem
    local tGotContentFlag = self.tbGotContentFlag

    if self.szFilter == EmailType.Player then
        tbEmailIDtab = self.tbEmailIDtabPlayer
    end

    for index, dwID in ipairs(tbEmailIDtab) do
        local mailInfo = MailMgr.GetMailInfo(dwID)
        if not mailInfo then
            return
        end

        if mailInfo.bItemFlag then
            if mailInfo.nAllItemPrice == 0 then
                if not mailInfo.bGotContentFlag then
                    table.insert(tGotContentFlag, dwID)
                end
                bCanReceiveAll = true
            end
        elseif mailInfo.bMoneyFlag then
            if not mailInfo.bGotContentFlag then
                table.insert(tGotContentFlag, dwID)
            end
            bCanReceiveAll = true
        end
    end

    self:RankRequestContent()

    return bCanReceiveAll
end

function UIEmailView:RankRequestContent()
    local tGotContentFlag = self.tbGotContentFlag

    if not table_is_empty(tGotContentFlag) then
        local dwID = tGotContentFlag[1]
        local mailInfo = MailMgr.GetMailInfo(dwID)
        if mailInfo then
            if not mailInfo.bGotContentFlag then
                mailInfo.RequestContent(self.nNpcdwID)
            end
        end

        table.remove(tGotContentFlag, 1)

        self.nRCTimerID = self.nRCTimerID or Timer.AddFrameCycle(self, 1, function ()
            self:RankRequestContent()
        end)
    else
        tGotContentFlag = {}
        Timer.DelTimer(self, self.nRCTimerID)
        self.nRCTimerID = nil
    end
end

function UIEmailView:ReceiveMailItem(nID)
    local dwID = nID or self:GetSelectedEmailID()

    local tReceiveQueue = self.tbReceiveQueue
    local tReceivetab =  self.tbItemReceivetab

    local mailInfo = MailMgr.GetMailInfo(dwID)
    local tAllItemPrice = FormatMoneyTab(mailInfo.nAllItemPrice)

    if MoneyOptCmp(tAllItemPrice , 0) > 0 and not self.bMailNotEnoughRoom and not self.MailItemAmountLimit then
        if g_pClientPlayer.bFreeLimitFlag then
            TipsHelper.ShowNormalTip(g_tStrings.STR_MAIL_FAILED)
        elseif MoneyOptCmp(g_pClientPlayer.GetMoney(), tAllItemPrice) < 0 then
            TipsHelper.ShowNormalTip(g_tStrings.STR_MAIL_TAKE_PAY_MAIL_NOT_ENOUGH_MONTY)
        else
            if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.MAIL, "GiveMoney") then
                return
            end

            UIMgr.Open(VIEW_ID.PanelNormalConfirmation, g_tStrings.STR_MAIL_TAKE_PAY_MAIL1, function ()
                for i = 0, 7, 1 do
                    local item = mailInfo.GetItem(i)
                    if item then
                        self:HandleReceiveMailItem(i, dwID, item, self.tbItemReceivetab, self.tbReceiveQueue)
                    end
                end

                self:MailItemReceiving()
            end,function()
                self.bReceiveFlag = false
            end, false, g_tStrings.STR_MAIL_TAKE_PAY_MAIL12, self.tbPayMoney)
        end
    else
        if mailInfo.bMoneyFlag then
            if self.MailMoneyLimit then
                local tbCurMoney = g_pClientPlayer.GetMoney()
                local nCurMoney = ItemData.MoneyFromGoldSilverAndCopper(0, tbCurMoney.nGold, tbCurMoney.nSilver, tbCurMoney.nCopper)
                local nPlayerMoneyLimit = g_pClientPlayer.GetMoneyLimitByGold()
                local nMaxMoney = ItemData.MoneyFromGoldSilverAndCopper(0, nPlayerMoneyLimit, 0, 0)

                if mailInfo.fMoney64 + nCurMoney <= nMaxMoney then
                    local nKey = self:GetKey(dwID, 8)
                    tReceivetab[nKey] = true
                    table.insert(tReceiveQueue, {nMailID = dwID})
                end
            else
                local nKey = self:GetKey(dwID, 8)
                tReceivetab[nKey] = true
                table.insert(tReceiveQueue, {nMailID = dwID})
            end
        end

        if mailInfo.bItemFlag then
            for i = 0, 7, 1 do
                local item = mailInfo.GetItem(i)
                if item then
                    self:HandleReceiveMailItem(i, dwID, item, tReceivetab, tReceiveQueue)
                end
            end
        end

        if #tReceiveQueue == 0 or self.bReceiveNum >= 2 then
            self.bReceiveNum = 0
            self.bReceiveFlag = false
        end

        self:MailItemReceiving()
    end
end

function UIEmailView:MailItemReceiving()
    local tReceiveQueue = self.tbReceiveQueue
    local tReceivetab = self.tbItemReceivetab

    if not table_is_empty(tReceiveQueue) then
        local tReceiveItem = tReceiveQueue[1]
        local mailInfo = MailMgr.GetMailInfo(tReceiveItem.nMailID)
        if mailInfo then
            if tReceiveItem.nIndex then
                if mailInfo.nAllItemPrice > 0 then
                    mailInfo.TakePayItem(self.nNpcdwID, tReceiveItem.nIndex)
                else
                    mailInfo.TakeItem(self.nNpcdwID, tReceiveItem.nIndex)
                end
            else
                mailInfo.TakeMoney(self.nNpcdwID)
            end

            -- if not mailInfo.bReadFlag then
            --     mailInfo.Read()
            -- end
        end

        table.remove(tReceiveQueue, 1)
        local nKey = self:GetKey(tReceiveItem.nMailID, tReceiveItem.nIndex or 8)
        tReceivetab[nKey] = nil

        self.nTimerID = self.nTimerID or Timer.AddFrameCycle(self, 4, function ()
            self:MailItemReceiving()
        end)
    else
        tReceiveQueue = {}
        tReceivetab = {}
        Timer.DelTimer(self, self.nTimerID)
        self.nTimerID = nil

        if not self.bAllReceive and not self.bReceiveFlag then
            self:UpdateMailList()
        else
            Timer.Add(self, 1, function ()
                self:ReReceiveAllbMailItem()
            end)
        end
    end
end

function UIEmailView:CalcScrollPosY()
    local ScrollView, tbEmailIDtab, tbEmailScript
    if self.szFilter == EmailType.System then
        ScrollView = self.ScrollViewLeft_system
    else
        ScrollView = self.ScrollViewLeft_player
    end

	local nWorldX, nWorldY = UIHelper.ConvertToWorldSpace(ScrollView, 0, 0)
	self.nScrollViewY = nWorldY
end

function UIEmailView:HasRedPointBelow()
	local bHasRedPointBelow = false
    local nRedPointCount = 0

	if not self.nScrollViewY then
		self:CalcScrollPosY()
	end

    local tbEmailScript
    if self.szFilter == EmailType.System then
        tbEmailScript = self.tbSystemEmailScript
    else
        tbEmailScript = self.tbPlayerEmailScript
    end

	for k, v in ipairs(tbEmailScript) do
		if UIHelper.GetVisible(v.ImgRedDot) then
			local nHeight = UIHelper.GetHeight(v.ImgRedDot)
			local _nWorldX, _nWorldY = UIHelper.ConvertToWorldSpace(v.ImgRedDot, 0, nHeight)
			if _nWorldY < self.nScrollViewY then
				bHasRedPointBelow = true
                nRedPointCount = nRedPointCount + 1
                if nRedPointCount == 99 then
                    break
                end
			end
		end
	end
	return bHasRedPointBelow, nRedPointCount
end

function UIEmailView:UpdateRedPointArrow()
	local bHasRedPointBelow, nRedPointCount = self:HasRedPointBelow()
    UIHelper.SetVisible(self.WidgetRedPointArrow, bHasRedPointBelow)
    UIHelper.SetString(self.LabelRedPoint, nRedPointCount)
	-- UIHelper.SetActiveAndCache(self, self.ImgRedPointArrow, bHasRedPointBelow)
end

function UIEmailView:GetKey(dwID, nIndex)
    return dwID * 10 + nIndex
end

function UIEmailView:CacheContactsList()
    local aMail = MailMgr.GetPlayerMailList()
    local MailContacts = {}
    local MailContactsIndex = {}

    for _, dwID in ipairs(aMail) do
        local mailInfo = MailMgr.GetMailInfo(dwID)
        local szName = UIHelper.GBKToUTF8(mailInfo.szSenderName)
        local nSendTime = mailInfo.GetSendTime()

        if szName ~= "[过期退信]" then
            if table.contain_value(MailContactsIndex,szName) then
                table.remove_value(MailContactsIndex,szName)
            end
            table.insert(MailContactsIndex,1,szName)
            MailContacts[szName] = nSendTime
        end
    end

    for _,szName in ipairs(MailContactsIndex) do
        self:InsertContactsTab(szName,MailContacts[szName])
    end

    Storage.Email.tbContacts = self.tbContacts
    Storage.Email.tbContactsTimes = self.tbContactsTimes

    Storage.Email.Flush()
end

function UIEmailView:InsertContactsTab(szName,nSendTime)
    if #(self.tbContacts) >= 200 then
        table.remove(self.tbContacts, 200)
        table.remove(self.tbContactsTimes,200)
    end
    local time = os.time()

    for i = #(self.tbContacts),1,-1 do
        if (time - self.tbContactsTimes[i]) > 2592000 then
            table.remove(self.tbContacts, i)
            table.remove(self.tbContactsTimes, i)
        else
            break
        end
    end

    if table.contain_value(self.tbContacts,szName) then
        local index = table.get_key(self.tbContacts,szName)
        if nSendTime < self.tbContactsTimes[index] then
            return
        end
        table.remove(self.tbContacts, index)
        table.remove(self.tbContactsTimes, index)
    end

    if #(self.tbContactsTimes) == 0 then
        table.insert(self.tbContacts,1,szName)
        table.insert(self.tbContactsTimes,1,nSendTime)
    else
        for i,time in ipairs(self.tbContactsTimes) do
            if nSendTime > time then
                table.insert(self.tbContacts,i,szName)
                table.insert(self.tbContactsTimes,i,nSendTime)
                return
            end
        end
        table.insert(self.tbContacts,szName)
        table.insert(self.tbContactsTimes,nSendTime)
    end
end

function UIEmailView:EmailCacheContacts()
    self.tbMailContacts = Storage.Email
    self.tbContacts = self.tbMailContacts.tbContacts or {}
    self.tbContactsTimes = self.tbMailContacts.tbContactsTimes or {}
end

function UIEmailView:HandleReceiveMailItem(i, dwID, item, tReceivetab, tReceiveQueue)
    local itemInfo = ItemData.GetItemInfo(item.dwTabType, item.dwIndex)
    local nTotalNum, nBagNum, nBankNum = ItemData.GetItemAllStackNum(item, true)

    if self.bMailNotEnoughRoom or self.MailItemAmountLimit then
        if itemInfo.bCanStack and (itemInfo.nExistType == ITEM_EXIST_TYPE.PERMANENT or itemInfo.nExistType == ITEM_EXIST_TYPE.TIMESTAMP) then
            if self.MailItemAmountLimit and not self.bMailNotEnoughRoom then
                if nBagNum + nBankNum + item.nStackNum <= itemInfo.nMaxExistAmount or itemInfo.nMaxExistAmount == 0 then
                    self:AddItemToReceiveQueue(dwID, i, tReceivetab, tReceiveQueue)
                end
            else
                if nBagNum ~= 0 and (nBagNum + nBankNum + item.nStackNum <= itemInfo.nMaxExistAmount or itemInfo.nMaxExistAmount == 0) then
                    if itemInfo.nMaxExistAmount ~= 0 or math.ceil((nBagNum + item.nStackNum) / itemInfo.nMaxDurability) == math.ceil(nBagNum / itemInfo.nMaxDurability) then
                        self:AddItemToReceiveQueue(dwID, i, tReceivetab, tReceiveQueue)
                    end
                end
            end
        else
            if self.MailItemAmountLimit and (not self.bMailNotEnoughRoom) then
                if nBagNum + nBankNum + item.nStackNum <= itemInfo.nMaxExistAmount or
                itemInfo.nMaxExistAmount == 0 then
                    self:AddItemToReceiveQueue(dwID, i, tReceivetab, tReceiveQueue)
                end
            end
        end
    else
        self:AddItemToReceiveQueue(dwID, i, tReceivetab, tReceiveQueue)
    end
end

function UIEmailView:AddItemToReceiveQueue(dwID, i, tReceivetab, tReceiveQueue)
    local nKey = self:GetKey(dwID, i)
    tReceivetab[nKey] = true
    table.insert(tReceiveQueue, {nMailID = dwID, nIndex = i})
end

function UIEmailView:HandleAllReceiveMail()
    self.tbItemReceivetab = {}
    self.tbReceiveQueue = {}

    if self.bAllReceive then
        self:ReceiveAllbMailItem()
    elseif self.bReceiveFlag then
        self:ReceiveMailItem()
    end
end

function UIEmailView:ReReceiveAllbMailItem()
    if table_is_empty(self.tbReceiveQueue) then
        if self.bAllReceive then
            self.bReceiveNum = self.bReceiveNum + 1
            self:ReceiveAllbMailItem()
        elseif self.bReceiveFlag then
            self:ReceiveMailItem()
        end
    end
end

function UIEmailView:OnSelectChangeTog()
    self.tbItemReceivetab = {}
    self.tbReceiveQueue = {}
    self.bMailNotEnoughRoom = false
    self.MailItemAmountLimit = false
    self.MailMoneyLimit = false
    self.bAllReceive = false
    self.bReceiveFlag = false

    self:UpdateMailListInfo()
    if not self.bMailListSyncFinish then
        self:UpdateMailList()
        UIHelper.SetVisible(self.WidgetAnchorLoading, false)
    end
end

return UIEmailView