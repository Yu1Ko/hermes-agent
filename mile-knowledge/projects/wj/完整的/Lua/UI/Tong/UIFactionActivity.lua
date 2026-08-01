-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIFactionActivity
-- Date: 2023-05-17 17:48:04
-- Desc: 帮会-活动分页
-- Prefab: WidgetFactionActivity
-- ---------------------------------------------------------------------------------

local UIFactionActivity = class("UIFactionActivity")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIFactionActivity:_LuaBindList()
    self.ScrollViewContent                 = self.ScrollViewContent --- 活动组件的scroll view

    self.WidgetAnchorFactionActivity       = self.WidgetAnchorFactionActivity --- 活动左侧边栏列表的组件
    self.WidgetAnchorFactionActivityDetail = self.WidgetAnchorFactionActivityDetail --- 具体展开某个活动时的组件
end

function UIFactionActivity:Init()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIFactionActivity:UnInit()
    self.bInit = false
    self:UnRegEvent()

    --- 退出界面时，强制修改为显示列表模式，确保右上角详情页时的返回按钮隐藏，避免玩家无法退出帮会页面
    self:ShowSpecificActivity(false)

    UIHelper.RemoveFromParent(self._rootNode, true)
end

function UIFactionActivity:BindUIEvent()

end

function UIFactionActivity:RegEvent()
    --Event.Reg(self, EventType.XXX, func)

    Event.Reg(self, EventType.OnRichTextOpenUrl, function(szUrl, node)
        if string.is_nil(szUrl) then
            return
        end

        szUrl                        = Base64_Decode(szUrl)

        local szLinkEvent, szLinkArg = szUrl:match("(%w+)/(.*)")

        if szLinkEvent == "NPCGuide" then
            -- NPCGuide/120
            local nLinkID      = tonumber(szLinkArg)

            local tAllLinkInfo = Table_GetCareerGuideAllLink(nLinkID)
            if #tAllLinkInfo > 0 then
                -- todo: 暂时先只显示第一个
                local tLink  = tAllLinkInfo[1]

                local tPoint = { tLink.fX, tLink.fY, tLink.fZ }
                MapMgr.SetTracePoint(UIHelper.GBKToUTF8(tLink.szNpcName), tLink.dwMapID, tPoint)
                UIMgr.Open(VIEW_ID.PanelMiddleMap, tLink.dwMapID, 0)
            end
        elseif szLinkEvent == "TongActivity" then
            -- TongActivity/4/0/0
            local szClassID, szSubClassID, szID = szLinkArg:match("(%d+)/(%d+)/(%d+)")

            self:ScrollToClass(tonumber(szClassID), tonumber(szSubClassID))
        elseif szLinkEvent == "ItemLinkInfo" then
            -- ItemLinkInfo/5/20788
            local szType, szID = szLinkArg:match("(%d+)/(%d+)")
            local dwType       = tonumber(szType)
            local dwID         = tonumber(szID)

            TipsHelper.ShowItemTips(node, dwType, dwID)
        else
            LOG.ERROR("UIFactionActivity 尚未支持的链接: %s", szUrl)
        end
    end)

    Event.Reg(self, EventType.OnClickBtnFactionActivityDetailReturn, function()
        self:ShowSpecificActivity(false)
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
        UIHelper.ScrollToLeft(self.ScrollViewContent, 0)
    end)
end

function UIFactionActivity:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFactionActivity:UpdateInfo()
    self:UpdateInfoActivityList()
end

function UIFactionActivity:UpdateInfoActivityList()
    UIHelper.RemoveAllChildren(self.ScrollViewContent)

    local tTongActivity = Table_GetTongActivityList()

    local nIndex        = 0
    for _, tClass in pairs(tTongActivity) do
        nIndex              = nIndex + 1

        local nCurrentIndex = nIndex

        if tClass then
            local bShowDetail = false
            local script      = UIHelper.AddPrefab(PREFAB_ID.WidgetActivityOverview, self.ScrollViewContent, tClass, bShowDetail)
            UIHelper.BindUIEvent(script.TogCompare, EventType.OnClick, function()
                self:ShowSpecificActivity(true)
                self:UpdateInfoSpecificActivity(tClass)
            end)
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
    UIHelper.ScrollToLeft(self.ScrollViewContent, 0)
end

function UIFactionActivity:ShowSpecificActivity(bShow)
    UIHelper.SetVisible(self.WidgetAnchorFactionActivity, not bShow)
    UIHelper.SetVisible(self.WidgetAnchorFactionActivityDetail, bShow)

    Event.Dispatch(EventType.SwitchFactionSpecificActivityShowStatus, bShow)
end

function UIFactionActivity:ScrollToClass(nClassID, nSubClassID)
    -- 跳转到指定的活动
    local nIndex = 0
    local tClass

    for idx, tChildNode in ipairs(UIHelper.GetChildren(self.ScrollViewContent)) do
        local script = UIHelper.GetBindScript(tChildNode)
        if script.tClass.tInfo.dwClassID == nClassID then
            nIndex = idx - 1
            tClass = script.tClass
            UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewContent, true, true)
            UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
            break
        end
    end
    UIHelper.ScrollToIndex(self.ScrollViewContent, nIndex, 0)

    if tClass then
        self:ShowSpecificActivity(true)
        self:UpdateInfoSpecificActivity(tClass, nSubClassID)
    end
end

function UIFactionActivity:UpdateInfoSpecificActivity(tClass, nSubClassID)
    local bSameClass = false
    if self.scriptActivityDetail and self.scriptActivityDetail.tClass.tInfo.dwClassID == tClass.tInfo.dwClassID then
        bSameClass = true
    end

    if not bSameClass then
        UIHelper.RemoveAllChildren(self.WidgetAnchorFactionActivityDetail)

        local bShowDetail         = true
        ---@type UIActivityOverview
        self.scriptActivityDetail = UIHelper.AddPrefab(PREFAB_ID.WidgetActivityOverview, self.WidgetAnchorFactionActivityDetail, tClass, bShowDetail)
        UIHelper.SetAnchorPoint(self.scriptActivityDetail._rootNode, 0.5, 0.5)
    end

    local script = self.scriptActivityDetail

    if nSubClassID then
        -- 跳转到指定的子活动
        local nSubClassIndex = 0
        for idx, uiActivityDetailCell in ipairs(UIHelper.GetChildren(script.ScrollViewActivityDetail)) do
            ---@type UIActivityDetailCell
            local scriptActivityDetailCell = UIHelper.GetBindScript(uiActivityDetailCell)
            if scriptActivityDetailCell.nSubClassID == nSubClassID then
                nSubClassIndex = idx - 1
                break
            end
        end

        Timer.AddFrame(self, 8, function()
            UIHelper.ScrollToIndex(script.ScrollViewActivityDetail, nSubClassIndex, 0)
        end)
    end

    UIHelper.BindUIEvent(script.TogCompare, EventType.OnClick, function()
        self:ShowSpecificActivity(false)
    end)
end

return UIFactionActivity