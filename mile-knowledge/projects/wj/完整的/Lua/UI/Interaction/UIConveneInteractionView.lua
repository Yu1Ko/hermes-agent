-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIConveneInteractionView
-- Date: 2023-12-01 10:53:40
-- Desc: 召请界面
-- ---------------------------------------------------------------------------------

local UIConveneInteractionView = class("UIConveneInteractionView")

function UIConveneInteractionView:OnEnter(dwItemID, tEvokeList , bIsFriend)
    self.dwItemID = dwItemID
    self.tEvokeList = tEvokeList
    self.bIsFriend = bIsFriend
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIConveneInteractionView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIConveneInteractionView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBox , EventType.OnClick , function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCloseRight , EventType.OnClick , function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAdd , EventType.OnClick , function ()
        local item = ItemData.GetItem(self.dwItemID)
        local szItemName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(item))
        local szMessage = ""
        local szItemContent = "["..szItemName.."]"--GetFormatText("["..szItemName.."]",nil, GetItemFontColorByQuality(item.nQuality, false))
        self.tbEvokeSel = {}
        if  self.bIsFriend  then
            local evokeInfo = self.tbSelectItem[1]:GetData()
            szMessage = string.format(g_tStrings.CALL_FRIEND_SURE,szItemContent,"[".. UIHelper.GBKToUTF8(evokeInfo.szName).."]",szItemContent)
            self.tbEvokeSel =  {evokeInfo.dwID}
        else
            local szName = ""
            for i, v in ipairs(self.tbSelectItem) do
                local evokeInfo = v:GetData()
                if szName ~= "" then
                    szName = szName..g_tStrings.STR_COMMA.."["..UIHelper.GBKToUTF8(evokeInfo.szName).."]"
                else
                    szName = "["..UIHelper.GBKToUTF8(evokeInfo.szName).."]"
                end
                table.insert(self.tbEvokeSel, evokeInfo.dwID)
            end
            szMessage = string.format(g_tStrings.CALL_GUILD_MEMBER_SURE, szItemContent,"["..szName.."]",szItemContent)
        end
        local Dialog = UIHelper.ShowConfirm(szMessage, function ()
            RemoteCallToServer("OnItemEvoke", self.dwItemID,self.tbEvokeSel)
            UIMgr.Close(self)	
        end)
        Dialog:SetButtonContent("Confirm", g_tStrings.STR_HOTKEY_SURE)
        Dialog:SetButtonContent("Cancel",  g_tStrings.STR_HOTKEY_CANCEL)
    end)
end

function UIConveneInteractionView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIConveneInteractionView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end





-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIConveneInteractionView:UpdateInfo()
    self.tbSelectItem = {}
    UIHelper.SetVisible(self.LableFriendTips , self.bIsFriend )
    UIHelper.SetVisible(self.LableConveneTips , not self.bIsFriend )
    local item = ItemData.GetItem(self.dwItemID)
    UIHelper.SetString(self.LabelTitle , UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(item)))
    local bIsEmpty = table.get_len(self.tEvokeList) == 0
    UIHelper.SetVisible(self.WidgetEmpty , bIsEmpty)
    self:UpdateAddState()
    if bIsEmpty then
         UIHelper.SetVisible(self.LableSix , self.bIsFriend )
        UIHelper.SetVisible(self.LableBangHui , not self.bIsFriend )
    end
    local onSelectCallback = function(nIndex , itemScript , bSelect)
        if bSelect then
            if self:CheckSelect() then
                table.insert(self.tbSelectItem , itemScript)
            else
                itemScript:CancelSelect()
            end
            self:UpdateAddState()
        else
            for k, v in pairs(self.tbSelectItem) do
                if v.nIndex == nIndex then
                    table.remove(self.tbSelectItem , k)
                    break
                end
            end
            self:UpdateAddState()
        end
    end
    for k, v in pairs(self.tEvokeList) do
        if self.bIsFriend then
            local aRoleEntry = FellowshipData.GetRoleEntryInfo(v.dwID)
            v.szName = aRoleEntry.szName
            v.dwForceID = aRoleEntry.nForceID
            v.nLevel = aRoleEntry.nLevel
        end
       

        UIHelper.AddPrefab(PREFAB_ID.WidgetConvenePlayerTog , self.ScrollViewConvenPlayer ,k, v , onSelectCallback , self.bIsFriend)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewConvenPlayer)
end

function UIConveneInteractionView:CheckSelect()
    if  self.bIsFriend  then
        if table.get_len(self.tbSelectItem) >= 1 then
            self.tbSelectItem[1]:CancelSelect()
            table.remove(self.tbSelectItem , 1)
        end
        return true
    else
        if table.get_len(self.tbSelectItem) >= 5 then
            TipsHelper.ShowNormalTip(g_tStrings.CALL_GUILD_MEMBER_LIMIT)
            return false
        end
        return true
    end
end

function UIConveneInteractionView:UpdateAddState()
    UIHelper.SetVisible(self.BtnAdd , table.get_len(self.tbSelectItem) > 0)
end

return UIConveneInteractionView