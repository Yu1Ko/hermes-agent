-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UILoginServerListCellLine
-- Date: 2023-10-11 16:56:29
-- Desc: UILoginServerListCell
-- ---------------------------------------------------------------------------------

local UILoginServerListCellLine = class("UILoginServerListCellLine")

function UILoginServerListCellLine:OnEnter(nStartIndex, uiView)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.tScriptList = {}
        local children = UIHelper.GetChildren(self._rootNode)
        for _, node in ipairs(children) do
            local script = UIHelper.GetBindScript(node)
            if script then
                table.insert(self.tScriptList, script)
            end
        end
    end

    self:UpdateInfo(nStartIndex, uiView)
end

function UILoginServerListCellLine:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UILoginServerListCellLine:BindUIEvent()
    
end

function UILoginServerListCellLine:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UILoginServerListCellLine:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UILoginServerListCellLine:UpdateInfo(nStartIndex, uiView)
    for i = 1, #self.tScriptList do
        local script = self.tScriptList[i]
        script:OnEnter(nStartIndex + i - 1, uiView)
    end
end


return UILoginServerListCellLine