local UIWidgetRenownNpcBar = class("UIWidgetRenownNpcBar")

local DEFAULT_PARTNER_PATH = "Resource/ReputationPanel/partner/null.png"
function UIWidgetRenownNpcBar:OnEnter(dwForceID, bReceived, fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if not dwForceID then
        return
    end

    self.dwForceID = dwForceID
    self.bReceived = bReceived
    self.fCallBack = fCallBack
    self:UpdateInfo(dwForceID)
end

function UIWidgetRenownNpcBar:OnExit()
    self.bInit = false
end

function UIWidgetRenownNpcBar:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self.fCallBack()
        end
    end)
end

function UIWidgetRenownNpcBar:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetRenownNpcBar:UpdateInfo(dwForceID)
    local tServantInfo, bSuccess = RepuData.GetServantInfoByForceID(dwForceID)
    if not bSuccess then
		---Log("ERROR!找不到声望势力ID == " .. tostring(dwForceID) .. "的NPC奖励信息！")
		return false
	end
    local szNpcName = UIHelper.GBKToUTF8(tServantInfo.szNpcName)
    local tUIServantInfo = Table_GetServantInfo(tServantInfo.dwNpcIndex)
    local szImagePath = DEFAULT_PARTNER_PATH
    if tUIServantInfo then
        szImagePath = tUIServantInfo.szImagePath
    end
    self.szRoleType = tServantInfo.szRoleType
    self.szNpcName = szNpcName
    UIHelper.SetString(self.LabelFriendName, szNpcName)
    UIHelper.SetTexture(self.ImgPartnerUnSelect, szImagePath)
    UIHelper.SetSwallowTouches(self.ToggleSelect, false)
    UIHelper.SetNodeGray(self.ImgPartnerUnSelect, not self.bReceived, true)
end

return UIWidgetRenownNpcBar