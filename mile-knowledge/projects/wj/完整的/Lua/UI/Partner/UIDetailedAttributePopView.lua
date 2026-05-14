-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIDetailedAttributePopView
-- Date: 2023-03-29 17:04:10
-- Desc: 侠客-详细属性
-- Prefab: PanelDetailedAttributePop
-- ---------------------------------------------------------------------------------

local UIDetailedAttributePopView = class("UIDetailedAttributePopView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIDetailedAttributePopView:_LuaBindList()
    self.BtnClose            = self.BtnClose --- 关闭界面
    self.ScrollViewAttribute = self.ScrollViewAttribute --- 属性的scroll view
end

function UIDetailedAttributePopView:OnEnter(dwID, dwPlayerID)
    self.dwID       = dwID
    self.dwPlayerID = dwPlayerID

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIDetailedAttributePopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDetailedAttributePopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIDetailedAttributePopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDetailedAttributePopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIDetailedAttributePopView:UpdateInfo()
    local pPlayer = Partner_GetPlayer(self.dwPlayerID)
    if not pPlayer then
        return
    end

    local nLevel       = 1
    local nStage       = 0

    local tPartnerInfo = Partner_GetPartnerInfo(self.dwID, self.dwPlayerID)
    if tPartnerInfo then
        nLevel = tPartnerInfo.nLevel
        nStage = tPartnerInfo.nStage
    end

    UIHelper.RemoveAllChildren(self.ScrollViewAttribute)

    local tPartnerAttribute = GDAPI_GetHeroAttributes(pPlayer, self.dwID, nLevel, nStage)
    for idx, nAttributeIndex in ipairs(PartnerData.tAttributeIndex) do
        local szName = g_tStrings.STR_PARTNER_ATTRIBUTE[idx]
        local nValue = tPartnerAttribute[nAttributeIndex]

        UIMgr.AddPrefab(PREFAB_ID.WidgetAttributeCell, self.ScrollViewAttribute, szName, nValue, idx)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAttribute)
end

return UIDetailedAttributePopView