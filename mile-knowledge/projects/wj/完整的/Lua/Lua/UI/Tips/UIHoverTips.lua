-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIHoverTips
-- Date: 2022-11-18 15:52:38
-- Desc: 选服弹窗管理界面
-- ---------------------------------------------------------------------------------

local UIHoverTips = class("UIHoverTips")

local tbLiveTips = {}

function UIHoverTips:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIHoverTips:OnExit()
    self.bInit = false
    --self:UnRegEvent()

    self:DeleteAllHoverTips(true)
end

function UIHoverTips:BindUIEvent()

end

function UIHoverTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHoverTips:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

--- @return HoverTips, table
function UIHoverTips:CreateHoverTips(nPrefabID, ...)
    LOG.INFO("UIHoverTips:CreateHoverTips, nPrefabID = "..tostring(nPrefabID))
    local scriptView = UIMgr.AddPrefab(nPrefabID, self._rootNode, ...)
    local node = scriptView._rootNode or scriptView

    local tips = HoverTips.New(node)
    if scriptView._rootNode then
        scriptView._hoverTips = tips
        if IsFunction(scriptView.OnHoverTipsCreated) then
            scriptView:OnHoverTipsCreated() --tips创建后的时机，用于脚本中调整tips的Size等
        end
    end

    if not tbLiveTips[nPrefabID] then
        tbLiveTips[nPrefabID] = {}
    end
    table.insert(tbLiveTips[nPrefabID], node)

    return tips, scriptView
end

function UIHoverTips:DeleteHoverTips(nPrefabID)
    local tbTips = tbLiveTips[nPrefabID]
    if tbTips then
        for i = 1, #tbTips do
            local node = tbTips[i]
            UIHelper.RemoveToCacheLayer(node)
            Event.Dispatch(EventType.OnHoverTipsDeleted, nPrefabID)
        end
        tbLiveTips[nPrefabID] = nil
    end

    if table.is_empty(tbLiveTips) then
        UIMgr.Close(self)
    end
end

function UIHoverTips:KeepHoverTipsAlive(nPrefabID, bKeepAlive)
    if bKeepAlive == nil then
        bKeepAlive = true
    end

    if tbLiveTips[nPrefabID] then
        tbLiveTips[nPrefabID].bKeepAlive = bKeepAlive
    end
end

function UIHoverTips:IsHoverTipsExist(nPrefabID)
    local tbTips = tbLiveTips[nPrefabID]
    if tbTips and #tbTips > 0 then
        return true
    end
    return false
end

function UIHoverTips:DeleteAllHoverTips(bForceDelete)
    local tbNewAliveTips = {}
    for nPrefabID, tbTips in pairs(tbLiveTips) do
        if tbTips.bKeepAlive and not bForceDelete then
            tbNewAliveTips[nPrefabID] = tbTips
            for i, node in ipairs(tbTips) do
                UIHelper.SetVisible(node, false)
            end
        else
            self:DeleteHoverTips(nPrefabID)
        end
    end
    tbLiveTips = tbNewAliveTips
end

return UIHoverTips