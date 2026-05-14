-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIFameEvent
-- Date: 2023-06-09 15:18:16
-- Desc: 名望-事件
-- Prefab: WidgetFameEvent
-- ---------------------------------------------------------------------------------

local UIFameEvent = class("UIFameEvent")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIFameEvent:_LuaBindList()
    self.LabelEventTimeLine = self.LabelEventTimeLine --- 时间与地点
    self.ImgNow             = self.ImgNow --- 当前的事件的标记
end

function UIFameEvent:OnEnter(bCurrentEvent, szTime, nMapId)
    self.bCurrentEvent = bCurrentEvent
    self.szTime        = szTime
    self.nMapId        = nMapId

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIFameEvent:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFameEvent:BindUIEvent()

end

function UIFameEvent:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIFameEvent:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFameEvent:UpdateInfo()
    local szMapName = UIHelper.GBKToUTF8(Table_GetMapName(self.nMapId))
    local szTip = string.format("%s  %s", self.szTime, szMapName)
    
    UIHelper.SetString(self.LabelEventTimeLine, szTip)
    UIHelper.SetVisible(self.ImgNow, self.bCurrentEvent)
end

return UIFameEvent