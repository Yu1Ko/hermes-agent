---@class UIWidgetRenownStoreDescribe
local UIWidgetRenownStoreDescribe = class("UIWidgetRenownStoreDescribe")


function UIWidgetRenownStoreDescribe:OnEnter(dwNpcLinkID, bAlwaysShow)
    self.bAlwaysShow = bAlwaysShow == nil and false or bAlwaysShow

    if not dwNpcLinkID then
        return
    end
    UIHelper.SetTouchEnabled(self.BtnNpcLink, true)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwNpcLinkID = dwNpcLinkID
    self:UpdateInfo(dwNpcLinkID)
end

function UIWidgetRenownStoreDescribe:OnExit()
    self.bInit = false
end

function UIWidgetRenownStoreDescribe:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnClick, function ()
        self:OpenMiddleMap()
    end)

    UIHelper.BindUIEvent(self.BtnMask, EventType.OnClick, function ()
        self:OpenMiddleMap()
    end)
end

function UIWidgetRenownStoreDescribe:RegEvent()
    Event.Reg(self, EventType.OnRichTextOpenUrl, function(szUrl, node)
        if string.is_nil(szUrl) then return end

        szUrl = Base64_Decode(szUrl)

        if szUrl then
            local tbLinkData = JsonDecode(szUrl)
            if not tbLinkData then return end

            local szType = tbLinkData.type or ""
            if szType == "RenownStoreNpcLink" and tbLinkData.dwNpcLinkID == self.dwNpcLinkID then
                UIMgr.Close(VIEW_ID.PanelRenowReputationRule)
                self:OpenMiddleMap()
            end
        end
    end)
end

function UIWidgetRenownStoreDescribe:UpdateInfo(dwNpcLinkID)
    local tLinkInfo = Table_GetCareerLinkNpcInfo(dwNpcLinkID)
    if tLinkInfo then
        local szNpcName = UIHelper.GBKToUTF8(tLinkInfo.szNpcName)
        local tbLinkData = {type = "RenownStoreNpcLink", dwNpcLinkID = dwNpcLinkID}
        local szLink = JsonEncode(tbLinkData)
        szLink = Base64_Encode(szLink)
        local szMsg = "前往声望商<href=%s><color=#79EAB4>%s</color></href><img src='UIAtlas2_Public_PublicButton_PublicButton1_btn_Trace02' width='40' height='40'/>处即可购买。"
        szMsg = string.format(szMsg, szLink, szNpcName)
        UIHelper.SetRichText(self.RichTextContent , szMsg)

        local tMapInfo
        if tLinkInfo.dwMapID > 0 then
            tMapInfo,_,_ = MapHelper.InitMiddleMapInfo(tLinkInfo.dwMapID)
        end

        local bEnabled = tMapInfo ~= nil and table.GetCount(tMapInfo) > 0
        self.bEnabled = bEnabled and (tLinkInfo.fX ~= 0 or tLinkInfo.fY ~= 0)
        UIHelper.SetVisible(self._rootNode, self.bEnabled or self.bAlwaysShow)
    end
    local nHeight = UIHelper.GetHeight(self.RichTextContent)
    UIHelper.SetHeight(self._rootNode, nHeight)
    UIHelper.SetPosition(self.RichTextContent, 0, 0)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UIWidgetRenownStoreDescribe:OpenMiddleMap()
    local bOpened = UIMgr.IsViewOpened(VIEW_ID.PanelMiddleMap)
    if not bOpened then
        local tAllLinkInfo = Table_GetCareerGuideAllLink(self.dwNpcLinkID)
        if tAllLinkInfo and #tAllLinkInfo > 0 then -- 只能定位一个NPC
            local tbInfo = tAllLinkInfo[1]
            local tbPoint = {tbInfo.fX, tbInfo.fY, tbInfo.fZ}
            MapMgr.SetTracePoint(UIHelper.GBKToUTF8(tbInfo.szNpcName), tbInfo.dwMapID, tbPoint)
            UIMgr.Open(VIEW_ID.PanelMiddleMap, tbInfo.dwMapID, 0)
        end
    end
end

return UIWidgetRenownStoreDescribe