-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISendMailView
-- Date: 2022-11-15 17:29:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISendMailView = class("UISendMailView")

local nSendMoneyMax = 5000000000
local nSendPayMoneyMax = 2000000000
local nSendGoldBMax = 50
local nSendPayGoldBMax = 20

function UISendMailView:OnEnter(dwTargetID,bPet)
    self:InitSendPage()

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nNpcdwID = dwTargetID
    self.bPet = bPet
    self.tWidgetGoodsScript = {}
    UIHelper.SetNodeSwallowTouches(self.BtnEditBoxTheme, false, true)
    self:UpdateInfo()
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
end

function UISendMailView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    FilterDef.SideBag.Reset()
end

function UISendMailView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxName, function()
        local szCMD = UIHelper.GetString(self.EditBoxName)
        self.szName = szCMD
        Event.Dispatch(EventType.OnEditSendName, self.szName)
        self:CheckSendMailBtnState(false)
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxName_title, function()
        local szCMD = UIHelper.GetString(self.EditBoxName_title)
        self.szTitle = szCMD
        self:CheckSendMailBtnState(false)
    end)

    UIHelper.BindUIEvent(self.BtnEditBoxTheme, EventType.OnClick, function()
        self.EditBoxTheme:openKeyboard()
        UIHelper.SetVisible(self.ScrollViewContent, false)
    end)

    self.EditBoxTheme:registerScriptEditBoxHandler(function(szType, _editbox)
        local szCMD = UIHelper.GetString(self.EditBoxTheme)
        local _, szTopChars = UIHelper.TruncateString(szCMD, 406)
        if szType == "changed" then
            UIHelper.SetString(self.EditBoxTheme, szTopChars)
            self.szContent = szTopChars
            local nCharNum = GetStringCharCount(szTopChars)
            UIHelper.SetString(self.LabelNumber,""..nCharNum.."/406")
            self:CheckSendMailBtnState(false)
        elseif szType == "ended" then
            UIHelper.SetVisible(self.EditBoxTheme, false)
            UIHelper.SetVisible(self.ScrollViewContent, true)
            UIHelper.SetString(self.LabelContent, szTopChars)
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
        end
    end)

    for i,EditBox in ipairs(self.tbEditBox) do
        UIHelper.RegisterEditBoxEnded(EditBox, function()
            local szMoney = UIHelper.GetString(EditBox)
            local bNum = self:isNumber(szMoney)
            local nMoney = tonumber(szMoney)
            if bNum == false or nMoney == 0 then
                UIHelper.SetString(EditBox,"")
                return
            else
                UIHelper.SetString(EditBox, nMoney)
            end

            if szMoney and szMoney ~= "" and (not self.szTitle or self.szTitle == "") then
                UIHelper.SetString(self.EditBoxName_title,g_tStrings.STR_MAIL_TITLE_MONEY)
                self.szTitle = g_tStrings.STR_MAIL_TITLE_MONEY
                self:CheckSendMailBtnState()
            end

            self:CheckSendMoneyMax()
        end)
    end

    for i,EditBox in ipairs(self.tbEditBoxpay) do
        UIHelper.RegisterEditBoxEnded(EditBox, function()
            local szMoney = UIHelper.GetString(EditBox)
            local bNum = self:isNumber(szMoney)
            if bNum == false then UIHelper.SetString(EditBox,"") return end
            self:CheckSendMailBtnState()

            self:CheckPayMoneyMax()
        end)
    end

    UIHelper.BindUIEvent(self.BtnSendOut, EventType.OnClick, function()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.MAIL, "send") then
            return
        end

        if PropsSort.IsBagInSort() then
            TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_MAIL_ITEM_INSORT)
            return
        end

        local bCanSend = self:CheckSendMailBtnState(true)
        if bCanSend then
            self.bConfirmation = false
            local tMoney = self:GetSendMoney()
            if tMoney.nGold >= 10000 then
                tMoney.nGoldB = math.floor(tMoney.nGold/10000)
                tMoney.nGold = tMoney.nGold - (tMoney.nGoldB * 10000)
            end
            if self.bConfirmation then
                UIMgr.Open(VIEW_ID.PanelNormalConfirmation, g_tStrings.STR_MAIL_SEND_MONEY_SURE_1, function ()
                    self:SendMail()
                end, nil, false,FormatString(g_tStrings.STR_MAIL_SEND_MONEY_SURE_2,self.szName),tMoney)
            else
                UIHelper.ShowConfirm(g_tStrings.STR_MAIL_SEND_MONEY_SURE,function ()
                    self:SendMail()
                end,nil,false)
            end
        end
    end)

    UIHelper.BindUIEvent(self.TogFriend, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self.szFilter = "Friend"
            UIHelper.SetVisible(self.ScrollViewLeft2, false)
            self:UpdateFriendList()
            UIHelper.SetString(self.EditBoxSearch, "")
        end
    end)

    UIHelper.BindUIEvent(self.TogContacts, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self.szFilter = "Contacts"
            UIHelper.SetVisible(self.WidgetFriend, false)
            UIHelper.SetVisible(self.ScrollViewLeft2, true)
            self:UpdateContactsList()
        end
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxSearch, function()
        local szCMD = UIHelper.GetString(self.EditBoxSearch)
        if not szCMD or szCMD == "" then
            self:UpdateFriendList()
            return
        end

        self.SearchName = {}
        for _, szName in ipairs(self.tbEmailFriendtab) do
            if szCMD == szName then
                table.insert(self.SearchName, szName)
                break
            elseif string.find(szName, szCMD) then
                table.insert(self.SearchName, szName)
            end
        end
        self:UpdateSearchList()
    end)

    UIHelper.BindUIEvent(self.TogOrdinary, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self.bPayMail = false
            for k,v in ipairs(self.tbEditBoxpay) do
                UIHelper.SetString(v,"")
            end
            self:CheckSendMailBtnState()
        end
    end)

    UIHelper.BindUIEvent(self.TogCharge, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self.bPayMail = true
            for k,v in ipairs(self.tbEditBox) do
                UIHelper.SetString(v,"")
            end
            self:CheckSendMailBtnState()
        end
    end)

    for _, btn in ipairs(self.tBtnAdd) do
        UIHelper.BindUIEvent(btn, EventType.OnClick, function()
            --点击呼出背包
            UIHelper.SetVisible(self.WidgetAnchorLeft, false)
            FilterDef.SideBag.Reset()
            self:OpenPublicLeftBag()
        end)
    end
end

function UISendMailView:RegEvent()
    Event.Reg(self, "SEND_MAIL_RESULT", function(nIndex, nCode)
        self:OnSendMailResult(nIndex, nCode)
    end)

    Event.Reg(self,"FELLOWSHIP_ROLE_ENTRY_UPDATE",function (szGlobalID)
        self:UpdateFriendList()
    end)

    Event.Reg(self, "FIGHT_HINT", function()
        UIMgr.Close(self)
    end)

    Event.Reg(self, "SYNC_PLAYER_REVIVE", function()
        UIMgr.Close(self)
    end)

    Event.Reg(self, "BAG_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
        if UIMgr.GetView(VIEW_ID.PanelLeftBag) then
            self:OpenPublicLeftBag()
        end
    end)

    Event.Reg(self, EventType.EmailFriendSelectChanged, function (szName, bSelected)
        if bSelected then
            self:SelectFriend(szName)
        end
    end)

    Event.Reg(self, EventType.EmailReply, function (szName, szTitle, szContent)
        self.szName = szName
        self.szTitle = szTitle
        self.szContent = szContent
        UIHelper.SetString(self.EditBoxName,self.szName)
        UIHelper.SetString(self.EditBoxName_title,self.szTitle)
        UIHelper.SetString(self.EditBoxTheme,self.szContent)
        UIHelper.SetString(self.LabelContent, self.szContent)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
        local nCharNum = GetStringCharCount(szContent)
        UIHelper.SetString(self.LabelNumber,""..nCharNum.."/406")
        self:CheckSendMailBtnState()
    end)

    Event.Reg(self, EventType.EmailForward, function (szTitle,szContent)
        self.szTitle = szTitle
        self.szContent = szContent
        UIHelper.SetString(self.EditBoxName_title,self.szTitle)
        UIHelper.SetString(self.EditBoxTheme,self.szContent)
        UIHelper.SetString(self.LabelContent, self.szContent)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
        local nCharNum = GetStringCharCount(szContent)
        UIHelper.SetString(self.LabelNumber,""..nCharNum.."/406")
        self:CheckSendMailBtnState()
    end)

    Event.Reg(self, EventType.EmailBagItemSelected, function(nBox, nIndex, nCurCount)
        local item = ItemData.GetItemByPos(nBox, nIndex)
        if not item then
            return
        end

        local nCount = #(self.tItem)
        if nCount == 8 and not table.contain_value(self.tItem, item.dwID) then
            TipsHelper.ShowNormalTip(g_tStrings.STR_MAIL_ITEM_LIMIT)
            return
        end

        TipsHelper.DeleteAllHoverTips()

        self:AddMailItem(nBox, nIndex, item, nCurCount)
        self:CheckSendMailBtnState()

        Event.Dispatch(EventType.OnSetUIItemIconChoose, nCurCount ~= 0, nBox, nIndex, nCurCount)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:ClearGoodsState()
    end)

    Event.Reg(self, EventType.OnLeftBagClose, function()
        UIHelper.SetVisible(self.WidgetAnchorLeft, true)
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if not safe_check(editbox) then return end

        if table.contain_value(self.tbEditBox, editbox) then
            local szMoney = UIHelper.GetString(editbox)
            local bNum = self:isNumber(szMoney)
            local nMoney = tonumber(szMoney)
            if bNum == false or nMoney == 0 then
                UIHelper.SetString(editbox,"")
                return
            else
                UIHelper.SetString(editbox, nMoney)
            end

            if szMoney and szMoney ~= "" and (not self.szTitle or self.szTitle == "") then
                UIHelper.SetString(self.EditBoxName_title,g_tStrings.STR_MAIL_TITLE_MONEY)
                self.szTitle = g_tStrings.STR_MAIL_TITLE_MONEY
                self:CheckSendMailBtnState()
            end

            self:CheckSendMoneyMax()
        elseif table.contain_value(self.tbEditBoxpay, editbox) then
            local szMoney = UIHelper.GetString(editbox)
            local bNum = self:isNumber(szMoney)
            if bNum == false then UIHelper.SetString(editbox,"") return end
            self:CheckSendMailBtnState()

            self:CheckPayMoneyMax()
        end
    end)
end

function UISendMailView:UnRegEvent()
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISendMailView:UpdateInfo()
    self:UpdateCoinAndMoney()
    self:UpdateFriendList()
end

function UISendMailView:UpdateCoinAndMoney()
    UIHelper.AddPrefab(PREFAB_ID.WidgetCurrency, self.LaoutCurrency)
    -- UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.LaoutCurrency)
end

function UISendMailView:CheckSendMoneyMax()
    local tMoney = {}

    tMoney.nGoldB = tonumber(UIHelper.GetString(self.tbEditBox[1])) or 0
    if tMoney.nGoldB > nSendGoldBMax then
        tMoney.nGoldB = nSendGoldBMax
        UIHelper.SetString(self.tbEditBox[1], nSendGoldBMax)
    end

    tMoney.nGold = tonumber(UIHelper.GetString(self.tbEditBox[2])) or 0
    tMoney.nSilver = tonumber(UIHelper.GetString(self.tbEditBox[3])) or 0

    local nGold
    if tMoney.nGoldB and tMoney.nGoldB ~= 0 then
        nGold = (tMoney.nGold or 0) + tMoney.nGoldB * 10000
    else
        nGold = tMoney.nGold or 0
    end

    local nMoney = UIHelper.GoldSilverAndCopperToMoney(nGold, tMoney.nSilver or 0, 0)
    if nMoney >= nSendMoneyMax then
        UIHelper.SetString(self.tbEditBox[1], nSendGoldBMax)
        UIHelper.SetString(self.tbEditBox[2], 0)
        UIHelper.SetString(self.tbEditBox[3], 0)
    end
end

function UISendMailView:CheckPayMoneyMax()
    local tMoney = {}
    tMoney.nGoldB = tonumber(UIHelper.GetString(self.tbEditBoxpay[1])) or 0
    if tMoney.nGoldB > nSendPayGoldBMax then
        tMoney.nGoldB = nSendPayGoldBMax
        UIHelper.SetString(self.tbEditBoxpay[1], nSendPayGoldBMax)
    end

    tMoney.nGold = tonumber(UIHelper.GetString(self.tbEditBoxpay[2])) or 0
    tMoney.nSilver = tonumber(UIHelper.GetString(self.tbEditBoxpay[3])) or 0

    local nGold
    if tMoney.nGoldB and tMoney.nGoldB ~= 0 then
        nGold = (tMoney.nGold or 0) + tMoney.nGoldB * 10000
    else
        nGold = tMoney.nGold or 0
    end

    local nMoney = UIHelper.GoldSilverAndCopperToMoney(nGold, tMoney.nSilver or 0, 0)
    if nMoney >= nSendPayMoneyMax then
        UIHelper.SetString(self.tbEditBoxpay[1], nSendPayGoldBMax)
        UIHelper.SetString(self.tbEditBoxpay[2], 0)
        UIHelper.SetString(self.tbEditBoxpay[3], 0)
    end
end

function UISendMailView:InitSendPage()
    self.nSendMoney = 30
    self.szName = ""
    self.szTitle = ""
    self.szContent = ""
    self.szFilter = "Friend"
    self.bPayMail = false
    self.tItem = {}
    self.tItemCount = {}
    self.tbContacts = Storage.Email.tbContacts or {}
    self.tbContactsTimes = Storage.Email.tbContactsTimes or {}
    UIHelper.SetButtonState(self.BtnSendOut,BTN_STATE.Disable)
    UIHelper.SetVisible(self.WidgetFriend, false)
    UIHelper.SetVisible(self.WidgetEmpty, true)
    UIHelper.SetString(self.LabelDescibe01, g_tStrings.STR_MAIL_NOT_FRIEND)
end

function UISendMailView:UpdateFriendList()
    local aFriend = FellowshipData.GetFellowshipInfoList()
    if not aFriend or table.is_empty(aFriend) then
        aFriend = {}
        UIHelper.SetVisible(self.WidgetFriend, false)
        UIHelper.SetVisible(self.WidgetEmpty, true)
        UIHelper.SetString(self.LabelDescibe01, g_tStrings.STR_MAIL_NOT_FRIEND)
        return
    else
        UIHelper.SetVisible(self.WidgetFriend, true)
        UIHelper.SetVisible(self.ScrollViewLeft1, true)
        UIHelper.SetVisible(self.WidgetEmpty, false)
	end

    local fnSortFunction = function(tLeft, tRight)
        return tLeft.attraction > tRight.attraction
    end
    table.sort(aFriend, fnSortFunction)

    UIHelper.RemoveAllChildren(self.ScrollViewLeft1)
    self.tbEmailFriendtab = {}
    self.tbEmailFriendtabByName = {}
    local tbPlayerIDList = {}

    for index, tOneFrend in ipairs(aFriend) do
        local tbRoleEntryInfo = FellowshipData.GetRoleEntryInfo(tOneFrend.id)
        if not tbRoleEntryInfo then
            table.insert(tbPlayerIDList, tOneFrend.id)
        end
        if not FellowshipData.IsRemoteFriend(tOneFrend.id) and tbRoleEntryInfo and tbRoleEntryInfo.szName ~= "" then
            local szName = UIHelper.GBKToUTF8(tbRoleEntryInfo.szName)
            table.insert(self.tbEmailFriendtab,szName)
            self.tbEmailFriendtabByName[szName] = tOneFrend
            UIHelper.AddPrefab(PREFAB_ID.WidgetFriendEmail01, self.ScrollViewLeft1, index, self.szName, szName, tbRoleEntryInfo)
        end
	end

    if not self.bApplyRoleEntryInfo then
        FellowshipData.ApplyRoleEntryInfo(tbPlayerIDList)
        self.bApplyRoleEntryInfo = true
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewLeft1)
end

function UISendMailView:UpdateContactsList()
    if table.is_empty(self.tbContacts) then
        UIHelper.SetVisible(self.ScrollViewLeft2, false)
        UIHelper.SetVisible(self.WidgetEmpty, true)
        UIHelper.SetString(self.LabelDescibe01, g_tStrings.STR_MAIL_NOT_CONTACT)
        return
    else
        UIHelper.SetVisible(self.ScrollViewLeft2, true)
        UIHelper.SetVisible(self.WidgetEmpty, false)
    end

    UIHelper.RemoveAllChildren(self.ScrollViewLeft2)
    for index, szName in ipairs(self.tbContacts) do
        local tbRoleEntryInfo = {}
        if self.tbEmailFriendtabByName and self.tbEmailFriendtabByName[szName] then
            tbRoleEntryInfo = FellowshipData.GetRoleEntryInfo(self.tbEmailFriendtabByName[szName].id)
        end
        UIHelper.AddPrefab(PREFAB_ID.WidgetFriendEmail01, self.ScrollViewLeft2, index, self.szName, szName, tbRoleEntryInfo)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewLeft2)
end

function UISendMailView:UpdateSearchList()
    if table.is_empty(self.SearchName) then
        UIHelper.SetVisible(self.ScrollViewLeft1, false)
        UIHelper.SetVisible(self.WidgetEmpty, true)
        UIHelper.SetString(self.LabelDescibe01, g_tStrings.STR_MAIL_NOT_SEARCH_FRIEND)
        return
    else
        UIHelper.SetVisible(self.WidgetEmpty, false)
    end

    UIHelper.RemoveAllChildren(self.ScrollViewLeft1)
    for index, szName in ipairs(self.SearchName) do
        local tbRoleEntryInfo = FellowshipData.GetRoleEntryInfo(self.tbEmailFriendtabByName[szName].id)
        UIHelper.AddPrefab(PREFAB_ID.WidgetFriendEmail01, self.ScrollViewLeft1, index, szName, szName, tbRoleEntryInfo)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewLeft1)
end

function UISendMailView:SelectFriend(szName)
    self.szName = szName
    UIHelper.SetString(self.EditBoxName,self.szName)
    self:CheckSendMailBtnState()
end

function UISendMailView:OnClickItem(dwItemID,bSelected,nCount,nInex)
    if bSelected then
        local nPosition = nInex or 1
        local tips, scriptItemTip
        if nInex then
            tips, scriptItemTip = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, self.tWidgetGoods[nInex])
        else
            tips, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.tWidgetGoods[1], TipsLayoutDir.TOP_CENTER)
        end

        local dwBox, dwIndex = ItemData.GetItemPos(dwItemID)
        scriptItemTip:ShowPlacementBtn(true,nCount,self.tItemCount[dwItemID])
        scriptItemTip:OnInit(dwBox, dwIndex)

        if nInex and nCount == 1 then
            scriptItemTip:SetBtnState({})
        end

        if not UIMgr.GetView(VIEW_ID.PanelLeftBag) then
            UIHelper.SetVisible(self.WidgetAnchorLeft, false)
            self:OpenPublicLeftBag()
        end
    end
end

function UISendMailView:AddMailItem(nBox,nIndex,item,nCurCount)
    local bContain = table.contain_value(self.tItem, item.dwID)
    if bContain then
        self:RecallMailItem(item.dwID)
    end
    local nCount = #(self.tItem)
    table.insert(self.tItem, item.dwID)
    self.tItemCount[item.dwID] = nCurCount

    self:AddMailItemPrefab(nCount+1, nBox, nIndex, item.dwID)

    if nCount == 0 and (not self.szTitle or self.szTitle == "") then
        local szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(item))
        UIHelper.SetString(self.EditBoxName_title,szName)
        self.szTitle = szName
    end
end

function UISendMailView:RecallMailItem(dwID)
    table.remove_value(self.tItem, dwID)
    self.tItemCount[dwID] = nil

    self.tWidgetGoodsScript = {}

    for i = 1, 8, 1 do
        if self.tItem[i] then
            local nBox, nIndex = ItemData.GetItemPos(self.tItem[i])
            self:AddMailItemPrefab(i, nBox, nIndex, self.tItem[i])
        else
            UIHelper.SetVisible(self.tWidgetGoods[i], false)
        end
    end
end

function UISendMailView:AddMailItemPrefab(nCount,nBox,nIndex,dwID)
    UIHelper.SetVisible(self.tWidgetGoods[nCount], true)

    local ItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.tWidgetGoods[nCount])
    if ItemIcon then
        ItemIcon:OnInit(nBox, nIndex, true)
        ItemIcon:SetLabelCount(self.tItemCount[dwID])

        ItemIcon:SetSelectChangeCallback(function(dwItemID,bSelected)
            self:CheckSendMailBtnState()
            local iItem = ItemData.GetItemByPos(nBox, nIndex)
            local nStackNum = ItemData.GetItemStackNum(iItem)
            self:OnClickItem(dwItemID,bSelected,nStackNum,nCount)
        end)

        ItemIcon:SetRecallVisible(true)
        ItemIcon:SetRecallCallback(function ()
            self:RecallMailItem(dwID)
        end)

        table.insert(self.tWidgetGoodsScript, ItemIcon)
    end
end

function UISendMailView:SendMail()
    local MailClient = GetMailClient()

    local tSendMoney = self:GetSendMoney()
    local tPayMoney = self:GetPayMoney()
    tSendMoney = FormatMoneyTab(tSendMoney)
    tPayMoney = FormatMoneyTab(tPayMoney)
    local nSendMoney = UIHelper.GoldSilverAndCopperToMoney(tSendMoney.nGold, tSendMoney.nSilver, tSendMoney.nCopper)
    local nPayMoney = UIHelper.GoldSilverAndCopperToMoney(tPayMoney.nGold, tPayMoney.nSilver, tPayMoney.nCopper)
    local tPlayerMoney = GetClientPlayer().GetMoney()
    local nPlayerMoney = UIHelper.GoldSilverAndCopperToMoney(tPlayerMoney.nGold,tPlayerMoney.nSilver,tPlayerMoney.nCopper)
    if nSendMoney > nPlayerMoney then
        TipsHelper.ShowNormalTip(g_tStrings.STR_MAIL_NOT_ENOUGHT_MONEY)
        return
    end

    local tItem = {}
    for _, dwID in ipairs(self.tItem) do
        local item, nBox, nIndex = ItemData.GetItem(dwID)
        table.insert(tItem, {dwBox = nBox, dwX = nIndex, dwSplitAmount = item.bCanStack and self.tItemCount[dwID] or 0})
    end

    MailClient.SendMail(1, self.nNpcdwID, UIHelper.UTF8ToGBK(self.szName), UIHelper.UTF8ToGBK(self.szTitle), UIHelper.UTF8ToGBK(self.szContent), nSendMoney, nPayMoney, tItem) --索引

    OnCheckAddAchievement(999, "Mail_First_Send")
end

function UISendMailView:CheckSendMailBtnState(bSend)
    local player = GetClientPlayer()
    if not player then return end

    local nLeft = player.GetCDLeft(1327)
    if nLeft ~= 0 and bSend then
        TipsHelper.ShowNormalTip(g_tStrings.STR_SEND_MAIL_TOO_FREQUENTLY)
    end

    if self.szName and self.szName ~= "" and self.szTitle and self.szTitle ~= "" and not self.bPayMail then
        if not bSend then
            UIHelper.SetButtonState(self.BtnSendOut,BTN_STATE.Normal)
        end
        return true
    elseif (not self.szName or self.szName == "") and bSend then
        TipsHelper.ShowNormalTip(g_tStrings.STR_MAIL_PLS_INPUT_NAME)
    elseif (not self.szTitle or self.szTitle == "") and bSend then
        TipsHelper.ShowNormalTip(g_tStrings.STR_MAIL_PLS_INPUT_TITLE)
    end

    if self.bPayMail then
        if #(self.tItem) == 0  and bSend then
            TipsHelper.ShowNormalTip(g_tStrings.STR_MAIL_TOLL_NEED_ITEM)
        elseif self:GetPayMoney() == 0 and bSend then
            TipsHelper.ShowNormalTip(g_tStrings.STR_MAIL_TOLL_NEED_PRICE)
        elseif self.szName and self.szName ~= "" and self.szTitle and self.szTitle ~= "" then
            UIHelper.SetButtonState(self.BtnSendOut,BTN_STATE.Normal)
            return true
        end
    end

    UIHelper.SetButtonState(self.BtnSendOut,BTN_STATE.Disable)
    return false
end

function UISendMailView:InsertContactsTab()
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
    if not self.szName or self.szName == "" then return end
    if table.contain_value(self.tbContacts,self.szName) then
        local index = table.get_key(self.tbContacts,self.szName)
        table.remove(self.tbContacts, index)
        table.remove(self.tbContactsTimes, index)
    end
    table.insert(self.tbContacts,1,self.szName)
    table.insert(self.tbContactsTimes,1,time)

    Storage.Email.tbContacts = self.tbContacts
    Storage.Email.tbContactsTimes = self.tbContactsTimes

    Storage.Email.Flush()
end

function UISendMailView:OnSendMailResult(nIndex, nCode)
    local bSuccess = false
    if nCode == MAIL_RESPOND_CODE.SUCCEED then
		bSuccess = true
    end

    if bSuccess then
        TipsHelper.ShowNormalTip(g_tStrings.STR_MAIL_SEND_OK)
        self:InsertContactsTab()
        self:ClearMailInfo()
        local nCountdown = 5
        Timer.AddCountDown(self, nCountdown, function ()
            nCountdown = nCountdown - 1--"发送("..nCountdown..")"
            UIHelper.SetString(self.LabelSendOut, FormatString( g_tStrings.STR_SEND_MAIL_BTN_COUNTDOWN, nCountdown))
        end,
        function ()
            UIHelper.SetString(self.LabelSendOut, g_tStrings.STR_SEND_MAIL_BTN)
        end)

        if self.szFilter == "Contacts" then
            self:UpdateContactsList()
        end
    else
        self.tItem = {}
        self.tItemCount = {}
        for i = 1, 8, 1 do
            UIHelper.SetVisible(self.tWidgetGoods[i],false)
        end
    end

    if self.bPet then
		RemoteCallToServer("On_PigeonMail_Close")
	end

    if bSuccess and self.bPet then
        UIMgr.Close(VIEW_ID.PanelEmail)
        UIMgr.Close(VIEW_ID.PanelSendMail)
    end
end

function UISendMailView:GetSendMoney()
    local nGoldB = UIHelper.GetString(self.tbEditBox[1])
    local nGold = UIHelper.GetString(self.tbEditBox[2])
    local nSilver = UIHelper.GetString(self.tbEditBox[3])
    if nGoldB ~= "" or nGold ~= "" or nSilver ~= "" then
        self.bConfirmation = true
    end
	return ConvertMoney(nGoldB, nGold, nSilver)
end

function UISendMailView:GetPayMoney()
	local nGoldB = UIHelper.GetString(self.tbEditBoxpay[1])
    local nGold = UIHelper.GetString(self.tbEditBoxpay[2])
    local nSilver = UIHelper.GetString(self.tbEditBoxpay[3])
	return ConvertMoney(nGoldB, nGold, nSilver)
end

function UISendMailView:ClearMailInfo()
    self.szName = ""
    self.szTitle = ""
    self.szContent = ""

    UIHelper.SetString(self.EditBoxName, self.szName)
    UIHelper.SetString(self.EditBoxName_title, self.szTitle)
    UIHelper.SetString(self.EditBoxTheme,"")
    UIHelper.SetString(self.LabelContent, self.szContent)
    UIHelper.SetString(self.LabelNumber, "0/406")

    for i = 1,3 do
        UIHelper.SetString(self.tbEditBox[i],"")
        UIHelper.SetString(self.tbEditBoxpay[i],"")
    end

    self.tItem = {}
    self.tItemCount = {}
    for i = 1, 8, 1 do
        UIHelper.SetVisible(self.tWidgetGoods[i],false)
    end

    UIHelper.SetButtonState(self.BtnSendOut,BTN_STATE.Disable)
end

function UISendMailView:OpenPublicLeftBag()
    local tItemTabTypeAndIndexList = {}
    for _, tbItemInfo in ipairs(ItemData.GetItemList(ItemData.BoxSet.Bag)) do
        if tbItemInfo.hItem then
            local itemInfo = GetItemInfo(tbItemInfo.hItem.dwTabType, tbItemInfo.hItem.dwIndex)
            if tbItemInfo.hItem.bBind and (not tbItemInfo.hItem.CheckIgnoreBindMask(ITEM_IGNORE_BIND_TYPE.MENTOR)) then
            elseif itemInfo.nExistType ~= ITEM_EXIST_TYPE.PERMANENT then
            else
                local nCount = 0
                if table.contain_value(self.tItem, tbItemInfo.hItem.dwID) then
                    nCount = self.tItemCount[tbItemInfo.hItem.dwID]
                end
                table.insert(tItemTabTypeAndIndexList,{nBox = tbItemInfo.nBox, nIndex = tbItemInfo.nIndex, nSelectedQuantity = nCount, hItem = tbItemInfo.hItem})
            end
        end
    end

    local tbFilterInfo = {}
    tbFilterInfo.Def = FilterDef.SideBag
    tbFilterInfo.tbfuncFilter = BagDef.CommonFilter

    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelLeftBag)
    if not scriptView then
        scriptView = UIMgr.Open(VIEW_ID.PanelLeftBag)
    end
    if scriptView then
        scriptView:OnInitWithBox(tItemTabTypeAndIndexList,tbFilterInfo)
        scriptView:SetClickCallback(function (bSelected, nBox, nIndex)
            local tItem = ItemData.GetItemByPos(nBox, nIndex)
            if tItem then
                local nStackNum = ItemData.GetItemStackNum(tItem)
                self:OnClickItem(tItem.dwID,bSelected,nStackNum)
            end
        end)
        scriptView:OnInitCatogory(BagDef.CommonCatogory)
        scriptView:SetEmptyDes(g_tStrings.STR_MAIL_BAG_EMPTY)
    end
end

function UISendMailView:ClearGoodsState()
    for k,v in ipairs(self.tWidgetGoodsScript) do
        if UIHelper.GetSelected(v.ToggleSelect) then
            UIHelper.SetSelected(v.ToggleSelect, false)
        end
    end
end

function UISendMailView:isNumber(str)
    for i=1,string.len(str) do
        if string.byte(string.sub(str,i,i)) < 48 or string.byte(string.sub(str,i,i)) > 57 then
          return false
        end
    end
    return true
end

return UISendMailView