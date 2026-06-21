-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetDistriRecordPlayerItem
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetDistriRecordPlayerItem = class("UIWidgetDistriRecordPlayerItem")

function UIWidgetDistriRecordPlayerItem:OnEnter(dwPlayerID, fnSelect)
    if not dwPlayerID then
        return
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    
    self.dwPlayerID = dwPlayerID
    self.fnSelect = fnSelect

    local szTag = AuctionData.GetPlayerTag(dwPlayerID)
    self:UpdateInfo(dwPlayerID, szTag)
end

function UIWidgetDistriRecordPlayerItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIWidgetDistriRecordPlayerItem:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        self.fnSelect(bSelected)
    end)
end

function UIWidgetDistriRecordPlayerItem:RegEvent()
    Event.Reg(self, EventType.OnAuctionTagChanged, function ()
        local szTag = AuctionData.GetPlayerTag(self.dwPlayerID)
        self:SetTag(szTag)
    end)
end

function UIWidgetDistriRecordPlayerItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetDistriRecordPlayerItem:UpdateInfo(dwPlayerID, szTag)
    local tbMemberInfo = TeamData.GetMemberInfo(dwPlayerID)
    if not tbMemberInfo then
        return
    end

    local playerName = tbMemberInfo.szName
    playerName = UIHelper.GBKToUTF8(playerName)
    UIHelper.SetString(self.LabelPlayerName, playerName, 8)

    self:SetTag(szTag)

    local nLevel = tbMemberInfo.nLevel
    UIHelper.SetString(self.LabelPick, tostring(nLevel))

    local dwForceID = tbMemberInfo.dwForceID
    local szImgName = PlayerForceID2SchoolImg2[dwForceID]
    UIHelper.SetSpriteFrame(self.ImgSchool, szImgName)

    if not self.scriptHead then
        self.scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead, dwID)
    end
    self.scriptHead:SetHeadInfo(dwPlayerID, tbMemberInfo.dwMiniAvatarID, tbMemberInfo.nRoleType, tbMemberInfo.dwForceID)

    UIHelper.SetToggleGroupIndex(self.ToggleSelect, ToggleGroupIndex.AuctionDistribution)
end

function UIWidgetDistriRecordPlayerItem:SetTag(szTag)
    self.szTag = szTag
    UIHelper.SetVisible(self.LabelTag, szTag ~= nil)
    if szTag then
        UIHelper.SetString(self.LabelTag, "("..szTag..")")
    end
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.LabelTag))
end

return UIWidgetDistriRecordPlayerItem