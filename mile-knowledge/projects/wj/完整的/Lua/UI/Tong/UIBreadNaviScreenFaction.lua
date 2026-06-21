-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIBreadNaviScreenFaction
-- Date: 2023-06-20 16:02:10
-- Desc: 帮会-筛选标题栏组件
-- Prefab: WidgetBreadNaviScreenFaction
-- ---------------------------------------------------------------------------------

local UIBreadNaviScreenFaction = class("UIBreadNaviScreenFaction")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIBreadNaviScreenFaction:_LuaBindList()
    self.FirstImgBreadNaviBg = self.FirstImgBreadNaviBg --- 背景（放在第一个时）
    self.FirstLabelBreadNavi = self.FirstLabelBreadNavi --- 文本（放在第一个时）

    self.OtherImgBreadNaviBg = self.OtherImgBreadNaviBg --- 背景（放在其他位置时）
    self.OtherLabelBreadNavi = self.OtherLabelBreadNavi --- 文本（放在其他位置时）

    self.BtnBreadNavi        = self.BtnBreadNavi --- 切换为对应筛选项
end

function UIBreadNaviScreenFaction:OnEnter(bIsFirst, szText, fnCallback)
    self.bIsFirst   = bIsFirst
    self.szText     = szText
    self.fnCallback = fnCallback

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIBreadNaviScreenFaction:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBreadNaviScreenFaction:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBreadNavi, EventType.OnClick, function()
        self.fnCallback()
    end)
end

function UIBreadNaviScreenFaction:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBreadNaviScreenFaction:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIBreadNaviScreenFaction:UpdateInfo()
    UIHelper.SetVisible(self.FirstImgBreadNaviBg, self.bIsFirst)
    UIHelper.SetVisible(self.FirstLabelBreadNavi, self.bIsFirst)

    UIHelper.SetVisible(self.OtherImgBreadNaviBg, not self.bIsFirst)
    UIHelper.SetVisible(self.OtherLabelBreadNavi, not self.bIsFirst)

    UIHelper.SetString(self.FirstLabelBreadNavi, self.szText)
    UIHelper.SetString(self.OtherLabelBreadNavi, self.szText)
end

return UIBreadNaviScreenFaction