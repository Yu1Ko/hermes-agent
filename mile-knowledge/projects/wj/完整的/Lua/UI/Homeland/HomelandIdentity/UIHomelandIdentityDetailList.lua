-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandIdentityDetailList
-- Date: 2024-01-18 19:33:52
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandIdentityDetailList = class("UIHomelandIdentityDetailList")

function UIHomelandIdentityDetailList:OnEnter(tType, tData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tType = tType
    self.tData = tData
    self:UpdateInfo()
end

function UIHomelandIdentityDetailList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandIdentityDetailList:BindUIEvent()
    UIHelper.SetVisible(self.BtnExplain, false)
    -- UIHelper.SetVisible(self.BtnUnlock, false)
end

function UIHomelandIdentityDetailList:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandIdentityDetailList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandIdentityDetailList:UpdateInfo()
    UIHelper.RemoveAllChildren(self.LayoutOrderDetailsListCell)
    local tType = self.tType
    local tData = self.tData
    local szTitle = UIHelper.GBKToUTF8(tType.szName)

    UIHelper.SetString(self.LabelTitle, szTitle)
    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetOrderDetailsListCell, self.LayoutOrderDetailsListCell)
    script:OnEnter(tData)
end

function UIHomelandIdentityDetailList:GetDetailTips()
    local tData = self.tData
    local tbDetailTip = {}
    for _, tInfo in ipairs(tData) do
        local szTitle = UIHelper.GBKToUTF8(tInfo.szName)
        local szDesc = ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(tInfo.szDesc))
        local szLockDesc = UIHelper.GBKToUTF8(tInfo.szLockDesc)
        local bLock = tInfo.tInfo
        if not string.is_nil(szLockDesc) then
            szLockDesc = ParseTextHelper.ParseNormalText(szLockDesc, false)
            szDesc = szDesc.."\n"
        end
        table.insert(tbDetailTip, {szName = szTitle, szContent = szDesc..szLockDesc, bLock = bLock})
    end
end


return UIHomelandIdentityDetailList