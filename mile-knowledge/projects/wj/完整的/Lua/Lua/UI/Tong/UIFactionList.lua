-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIFactionList
-- Date: 2023-12-07 17:37:35
-- Desc: 帮会-帮会列表-帮会信息
-- Prefab: WidgetFactionList
-- ---------------------------------------------------------------------------------

local function IsMsgEditAllowed()
    return UI_IsActivityOn(ACTIVITY_ID.ALLOW_EDIT) -- 此活动在时间上一直开启，通过策划调用指令来改变实际的开启状态
end

---@class UIFactionList
local UIFactionList = class("UIFactionList")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIFactionList:_LuaBindList()
    -- 帮会列表
    self.WidgetADTong           = self.WidgetADTong --- 帮会列表的帮会的组件

    -- 十大推荐帮会
    self.WidgetTopTenTong       = self.WidgetTopTenTong --- 十大推荐帮会的帮会的组件
    self.LabelTopTenName        = self.LabelTopTenName --- 名字
    self.LabelTopTenMasterName  = self.LabelTopTenMasterName --- 帮主名字
    self.LabelTopTenMemberCount = self.LabelTopTenMemberCount --- 帮众人数
    self.LabelTopTenDescription = self.LabelTopTenDescription --- 描述
    self.ImgCamp                = self.ImgCamp --- 阵营图片

    self.BtnApplicationFaction  = self.BtnApplicationFaction --- 申请入帮按钮
    self.ImgSeal                = self.ImgSeal --- 已申请的图标
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIFactionList:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

---@param bTopTen boolean
---@param tTong ADTongInfo|TopTenTongInfo
---@param bHideApply boolean
function UIFactionList:OnEnter(bTopTen, tTong, bHideApply)
    --- true => 帮会列表， false => 十大推荐帮会
    self.bTopTen  = bTopTen
    --- 帮会信息
    self.tTong    = tTong
    --- 多个地方会用这个，在竞标的展示页，需要隐藏申请相关的组件
    self.bHideApply = bHideApply

    self.bApplied = false

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIFactionList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFactionList:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnApplicationFaction, EventType.OnClick, function()
        RemoteCallToServer("On_Tong_ApplyJoinRequest", self.tTong.szTongName)

        local szRespondEventType = "On_Tong_ApplyJoinRespond"
        Event.Reg(self, szRespondEventType, function(nRetCode)
            Event.UnReg(self, szRespondEventType)

            if nRetCode == TONG_APPLY_JOININ_RESULT_CODE.SUCCESS then
                self.bApplied = true
                self:UpdateInfo()
            end
        end)
    end)
end

function UIFactionList:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIFactionList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFactionList:UpdateInfo()
    UIHelper.SetVisible(self.WidgetADTong, not self.bTopTen)
    UIHelper.SetVisible(self.WidgetTopTenTong, self.bTopTen)

    if self.bTopTen then
        self:UpdateTopTenTongInfo()
    else
        -- note: 帮会列表的信息在 UIPanelTongList:UpdateCell 中按另一种方法写的，不用管
    end
end

function UIFactionList:UpdateTopTenTongInfo()
    local tTong = self.tTong
    local g2u   = UIHelper.GBKToUTF8
    
    local _, szDescription = TextFilterReplace(tTong.szDescription)

    local bMsgEditAllowed = IsMsgEditAllowed()

    UIHelper.SetString(self.LabelTopTenName, g2u(tTong.szTongName))
    UIHelper.SetString(self.LabelTopTenMasterName, g2u(tTong.szMasterName))
    UIHelper.SetString(self.LabelTopTenMemberCount, tTong.nMemberCount)
    UIHelper.SetString(self.LabelTopTenDescription, bMsgEditAllowed and g2u(szDescription) or "")
    CampData.SetUICampImg(self.ImgCamp, tTong.nCamp, false, true)

    UIHelper.SetVisible(self.BtnApplicationFaction, not self.bApplied and not self.bHideApply)
    UIHelper.SetVisible(self.ImgSeal, self.bApplied and not self.bHideApply)
end

return UIFactionList