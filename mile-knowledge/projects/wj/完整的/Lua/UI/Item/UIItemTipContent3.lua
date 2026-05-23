-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipContent3
-- Date: 2022-11-15 15:45:32
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIItemTipContent3 = class("UIItemTipContent3")

function UIItemTipContent3:OnEnter(tbAttribInfos)
    if not tbAttribInfos then return end

    self.tbAttribInfos = tbAttribInfos

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIItemTipContent3:OnExit()
    self.bInit = false
end

function UIItemTipContent3:BindUIEvent()

end

function UIItemTipContent3:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemTipContent3:UpdateInfo()
    UIHelper.RemoveAllChildren(self.LayoutAttri)

    if not self.tbAttribInfos or table.is_empty(self.tbAttribInfos) then
        UIHelper.SetVisible(self._rootNode, false)
        UIHelper.SetVisible(self.ImgLine, false)
    else
        for i, tbInfo in ipairs(self.tbAttribInfos) do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent3AttribCell, self.LayoutAttri)
            script:OnEnter(tbInfo)
        end

        UIHelper.SetVisible(self._rootNode, true)
        UIHelper.SetVisible(self.ImgLine, true)

        UIHelper.LayoutDoLayout(self.LayoutAttri)
        UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
    end
end


return UIItemTipContent3