-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipContent10TraceCell
-- Date: 2023-11-30 19:55:53
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIItemTipContent10TraceCell = class("UIItemTipContent10TraceCell")

function UIItemTipContent10TraceCell:OnEnter(tbInfo, nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    self.nIndex = nIndex
    self:UpdateInfo(tbInfo)
end

function UIItemTipContent10TraceCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIItemTipContent10TraceCell:BindUIEvent()
    UIHelper.SetTouchDownHideTips(self.BtnTrace, false)
    UIHelper.SetSwallowTouches(self.BtnTrace, false)
    UIHelper.BindUIEvent(self.BtnTrace, EventType.OnClick, function()
        local szLinkInfo = self.tbInfo.szLinkInfo
        if string.is_nil(szLinkInfo) then
            return
        end

        local fnAction = function()
            local szLinkEvent, szLinkArg = szLinkInfo:match("(%w+)/(.*)")
            if szLinkEvent == "ShowItemInfo" then
                local nTabType, nIndex = szLinkArg:match("(%w+)/(%w+)")
                TipsHelper.ShowItemTips(self._rootNode, tonumber(nTabType), tonumber(nIndex), false)
            end

            if OBDungeonData.IsPlayerInOBDungeon() then
                TipsHelper.ShowNormalTip("正在观战中，无法跳转到其他界面。")
                return
            end

            if szLinkEvent == "CollectionFunc" then
                CollectionFuncList.Excute(szLinkArg)
            elseif szLinkEvent ~= "ShowItemTips" then
                Event.Dispatch("EVENT_LINK_NOTIFY", szLinkInfo)
                Event.Dispatch(EventType.HideAllHoverTips)
            end
            Event.Dispatch(EventType.OnGuideItemSource, self.nIndex)
        end

        if UIMgr.GetView(VIEW_ID.PanelConstructionMain) then
            local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelConstructionMain)
            scriptView:ConfirmQuitAndDoAction(fnAction)
        else
            fnAction()
        end
    end)
end

function UIItemTipContent10TraceCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemTipContent10TraceCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓�?
-- ----------------------------------------------------------

function UIItemTipContent10TraceCell:UpdateInfo(tbInfo)
    UIHelper.SetRichText(self.LabelTraceDetail, tbInfo.szText)
end

return UIItemTipContent10TraceCell