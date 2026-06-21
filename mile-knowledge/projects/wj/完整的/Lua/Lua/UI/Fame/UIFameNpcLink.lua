-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIFameNpcLink
-- Date: 2023-06-09 15:18:16
-- Desc: 名望-NPC指引
-- Prefab: PanelFame/AniAll/WidgetAniRight/WidgetAnchorRight/LayoutFameDetail/WidgetFameTitle/WidgetAnchorFameStore
-- 基于: UIWidgetRenownStoreDescribe.lua
-- ---------------------------------------------------------------------------------

local UIFameNpcLink = class("UIFameNpcLink")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIFameNpcLink:_LuaBindList()
    self.LabelNpcLink = self.LabelNpcLink --- NPC描述
    self.BtnNpcLink   = self.BtnNpcLink --- 点击打开导航
end

function UIFameNpcLink:OnEnter(dwNpcLinkID, bAlwaysShow)
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

function UIFameNpcLink:OnExit()
    self.bInit = false
end

function UIFameNpcLink:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnNpcLink, EventType.OnClick, function()
        local tAllLinkInfo = Table_GetCareerGuideAllLink(self.dwNpcLinkID)
        if tAllLinkInfo and #tAllLinkInfo > 0 then
            -- 只能定位一个NPC
            local tbInfo  = tAllLinkInfo[1]
            local tbPoint = { tbInfo.fX, tbInfo.fY, tbInfo.fZ }
            MapMgr.SetTracePoint(UIHelper.GBKToUTF8(tbInfo.szNpcName), tbInfo.dwMapID, tbPoint)
            UIMgr.Open(VIEW_ID.PanelMiddleMap, tbInfo.dwMapID, 0)
        end
    end)
end

function UIFameNpcLink:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIFameNpcLink:UpdateInfo(dwNpcLinkID)
    local tLinkInfo = Table_GetCareerLinkNpcInfo(dwNpcLinkID)
    if tLinkInfo then
        local szNpcName = UIHelper.GBKToUTF8(tLinkInfo.szNpcName)
        UIHelper.SetString(self.LabelNpcLink, szNpcName)

        local tMapInfo, _, _ = MapHelper.InitMiddleMapInfo(tLinkInfo.dwMapID)
        local bEnabled       = tMapInfo ~= nil and table.GetCount(tMapInfo) > 0
        self.bEnabled        = bEnabled and (tLinkInfo.fX ~= 0 or tLinkInfo.fY ~= 0)
        UIHelper.SetVisible(self._rootNode, self.bEnabled or self.bAlwaysShow)
    end

    UIHelper.LayoutDoLayout(self.BtnNpcLink)
    UIHelper.LayoutDoLayout(self._rootNode)

end

return UIFameNpcLink