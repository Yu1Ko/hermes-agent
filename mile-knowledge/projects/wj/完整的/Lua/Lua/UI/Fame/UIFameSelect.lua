-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIFameSelect
-- Date: 2023-06-07 20:22:21
-- Desc: 名望-名望势力
-- Prefab: WidgetFameSelect
-- ---------------------------------------------------------------------------------

local UIFameSelect = class("UIFameSelect")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIFameSelect:_LuaBindList()
    -- 以下是未选中时的组件
    self.NormalImgFigure                 = self.NormalImgFigure --- 背景图片
    self.NormalLayoutLabel               = self.NormalLayoutLabel --- 各种文字信息上层的layout
    self.NormalLabelFameName             = self.NormalLabelFameName --- 名称
    self.NormalLabelFameLevel            = self.NormalLabelFameLevel --- 等级
    self.NormalLabelUnlock               = self.NormalLabelUnlock --- 未解锁的提示
    self.NormalWidgetFameEventLocation   = self.NormalWidgetFameEventLocation --- 名望事件的上层组件
    self.NormalLabelFameLocation         = self.NormalLabelFameLocation --- 当前的名望事件地点

    -- 以下是选中时的组件
    self.SelectedImgFigure               = self.SelectedImgFigure --- 背景图片
    self.SelectedLayoutLabel             = self.SelectedLayoutLabel --- 各种文字信息上层的layout
    self.SelectedLabelFameName           = self.SelectedLabelFameName --- 名称
    self.SelectedLabelFameLevel          = self.SelectedLabelFameLevel --- 等级
    self.SelectedLabelUnlock             = self.SelectedLabelUnlock --- 未解锁的提示
    self.SelectedWidgetFameEventLocation = self.SelectedWidgetFameEventLocation --- 名望事件的上层组件
    self.SelectedLabelFameLocation       = self.SelectedLabelFameLocation --- 当前的名望事件地点

    -- 以下是共用的组件
    self.CommonImgIcon                   = self.CommonImgIcon --- 图标
    self.TogFameSelect                   = self.TogFameSelect --- 控制选中状态的toggle
end

---@param tFameInfo FameInfo
function UIFameSelect:OnEnter(tFameInfo)
    self.tFameInfo = tFameInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIFameSelect:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFameSelect:BindUIEvent()

end

function UIFameSelect:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIFameSelect:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFameSelect:UpdateInfo()
    local tInfo = self.tFameInfo

    UIHelper.SetSpriteFrame(self.CommonImgIcon, tInfo.szVKImagePath)

    UIHelper.SetToggleGroupIndex(self.TogFameSelect, ToggleGroupIndex.PartnerEquip)

    local function _fillInfo(tImgFigure, tLayoutLabel, tLabelFameName, tLabelFameLevel, tLabelUnlock, tWidgetFameEventLocation, tLabelFameLocation)
        --local szFameBgPath = string.gsub(tInfo.szFameBgPath, "UITex", "Tga")
        --UIHelper.SetTexture(tImgFigure, szFameBgPath)

        UIHelper.SetString(tLabelFameName, UIHelper.GBKToUTF8(tInfo.szName))
        UIHelper.SetString(tLabelFameLevel, string.format("%d/%d级", tInfo.nNowLevel, tInfo.nMaxLevel))

        UIHelper.SetVisible(tLabelFameLevel, not tInfo.bLocked)
        UIHelper.SetVisible(tLabelUnlock, tInfo.bLocked)
        UIHelper.SetVisible(tWidgetFameEventLocation, not tInfo.bLocked)

        local nHappenMapId = GDAPI_GetFamePlaceHappen(g_pClientPlayer, tInfo.dwID)
        local szMapName    = Table_GetMapName(nHappenMapId)
        UIHelper.SetString(tLabelFameLocation, UIHelper.GBKToUTF8(szMapName))

        UIHelper.LayoutDoLayout(tLayoutLabel)
    end

    -- 未选中
    _fillInfo(self.NormalImgFigure, self.NormalLayoutLabel, self.NormalLabelFameName, self.NormalLabelFameLevel,
              self.NormalLabelUnlock, self.NormalWidgetFameEventLocation, self.NormalLabelFameLocation)

    -- 选中
    _fillInfo(self.SelectedImgFigure, self.SelectedLayoutLabel, self.SelectedLabelFameName, self.SelectedLabelFameLevel,
              self.SelectedLabelUnlock, self.SelectedWidgetFameEventLocation, self.SelectedLabelFameLocation)
end

return UIFameSelect