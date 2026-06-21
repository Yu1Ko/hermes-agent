-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIInteractionMorePop
-- Date: 2022-11-24 19:31:15
-- Desc: 交互嵌套按钮点出的tips的内容
-- ---------------------------------------------------------------------------------

local UIInteractionMorePop = class("UIInteractionMorePop")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIInteractionMorePop:_LuaBindList()
    self.ImgPopBg   = self.ImgPopBg --- 背景图片
    self.LayoutMore = self.LayoutMore --- 按钮容器
end

function UIInteractionMorePop:OnEnter(fnOnMorePopClose)
    self.fnOnMorePopClose = fnOnMorePopClose

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIInteractionMorePop:OnExit()
    self.bInit = false

    if self.fnOnMorePopClose then
        self.fnOnMorePopClose()
    end

    self:UnRegEvent()
end

function UIInteractionMorePop:BindUIEvent()
    UIHelper.BindUIEvent(self.ScrollviewMore, EventType.OnTouchEnded, function()
        local nPercent = UIHelper.GetScrollPercent(self.ScrollviewMore)
        if nPercent >= 100 then
            UIHelper.SetVisible(self.WidgetArrow, false)
            UIHelper.UnBindUIEvent(self.ScrollviewMore, EventType.OnTouchEnded)
        end
    end)
end

function UIInteractionMorePop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIInteractionMorePop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIInteractionMorePop:UpdateInfo()

end

return UIInteractionMorePop
