-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationCenterViewBottom
-- Date: 2026-03-25 15:55:18
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationCenterViewBottom = class("UIOperationCenterViewBottom")

function UIOperationCenterViewBottom:OnEnter(nOperationID, nID, nPrefabID, bWithoutHideAll)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nLastOperationID = self.nOperationID

    self.nOperationID = nOperationID
    self.nID = nID
    self.nPrefabID = nPrefabID
    self.bWithoutHideAll = bWithoutHideAll

    self:UpdateInfo()
end

function UIOperationCenterViewBottom:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationCenterViewBottom:BindUIEvent()

end

function UIOperationCenterViewBottom:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationCenterViewBottom:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIOperationCenterViewBottom:UpdateInfo()
    UIHelper.SetVisible(self._rootNode, true)

    if not self.bWithoutHideAll then
        self:HideAllChildren()
    end
end

function UIOperationCenterViewBottom:HideAllChildren()
    UIHelper.HideAllChildren(self._rootNode)
end

function UIOperationCenterViewBottom:GetPrefabParent(nCount)
    if nCount > 3 then
        return self.ScorllViewBotton, true
    else
        return self.LayOutBottonCardListLess, false
    end
end

function UIOperationCenterViewBottom:SetTitle(szText)
    UIHelper.SetVisible(self.LabelBottoScorllViewTitle, true)
    UIHelper.SetString(self.LabelBottoScorllViewTitle, szText)
end

-- 父子活动
function UIOperationCenterViewBottom:UpdateParentChildrenList(nChildOperationID)
    local tChildren = OperationCenterData.GetOpenChildOperations(self.nOperationID)
    local parent, bScroll = self:GetPrefabParent(#tChildren)
    if self.nLastOperationID ~= self.nOperationID then
        self.tScriptList = {}
        UIHelper.RemoveAllChildren(parent)
        local nSelectIndex = 1
        for nIndex = #tChildren, 1, -1 do
            local tInfo = tChildren[nIndex]
            local script = UIHelper.AddPrefab(self.nPrefabID, parent, tInfo, nIndex)
            if script then
                script:SetfnCallBack(function()
                    local tContext = OperationCenterData.GetViewComponentContext()
                    if tContext and tContext.scriptCenter then
                        tContext.scriptCenter:SetDisplayOperationID(tInfo.dwID)
                    end
                end)
                local tActivity = TabHelper.GetHuaELouActivityByOperationID(tInfo.dwID)
                script:SetImage(tActivity.szSmallImg or "")
                script:SetText(UIHelper.GBKToUTF8(tInfo.szName))
                UIHelper.SetAnchorPoint(script._rootNode, 0, 0)
                table.insert(self.tScriptList, script)
                if tInfo.dwID == nChildOperationID then
                    nSelectIndex = #self.tScriptList
                end
            end
        end
        if bScroll then
            UIHelper.ScrollViewDoLayoutAndToTop(parent)
            Timer.AddFrame(self, 1, function()
                UIHelper.ScrollToIndex(parent, nSelectIndex - 1)
            end)
        else
            UIHelper.LayoutDoLayout(parent)
        end
    end
    UIHelper.SetVisible(parent, true)
    Timer.AddFrame(self, 1, function()
        local nSelectIndex = 1
        for _, script in ipairs(self.tScriptList) do
            if script.tInfo.dwID == nChildOperationID then
                nSelectIndex = script.nIndex
                break
            end
        end
        Event.Dispatch(EventType.OnOperationSelectBtnImgLink, nSelectIndex)
    end)
end

function UIOperationCenterViewBottom:Reset()
    UIHelper.SetVisible(self.WidgetArrow, false)
    UIHelper.SetTabVisible(self.tbImgTogRedPoint, false)
end

return UIOperationCenterViewBottom