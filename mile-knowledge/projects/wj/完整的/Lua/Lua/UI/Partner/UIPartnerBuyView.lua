-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerBuyView
-- Date: 2024-05-23 11:03:08
-- Desc: 购买管家侠客
-- Prefab: PanelPartnerBuy
-- ---------------------------------------------------------------------------------

---@class UIPartnerBuyView
local UIPartnerBuyView = class("UIPartnerBuyView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerBuyView:_LuaBindList()
    self.BtnClose              = self.BtnClose --- 关闭界面

    self.ImgRoleTag            = self.ImgRoleTag --- 侠客心法类型
    self.LabelRoleName         = self.LabelRoleName --- 名称
    self.LabelRoleInfo         = self.LabelRoleInfo --- 描述
    self.ImgRoleMeetState      = self.ImgRoleMeetState --- 侠客结缘状态的图片
    self.ImgRole               = self.ImgRole --- 侠客立绘

    self.LayoutCurrency        = self.LayoutCurrency --- 货币的上层layout

    self.LabelCostArchitecture = self.LabelCostArchitecture --- 购买所需的园宅币
    self.LayoutCost            = self.LayoutCost --- 购买消耗上层的layout

    self.BtnBuy                = self.BtnBuy --- 购买按钮
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIPartnerBuyView:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIPartnerBuyView:OnEnter(tInfoList, nSelID)
    ---@type PartnerDrawInfo[]
    self.tInfoList = tInfoList
    self.nSelID    = nSelID

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPartnerBuyView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerBuyView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function()
        local dwPartnerID = self.nSelID
        if not dwPartnerID then
            return
        end

        if g_pClientPlayer.IsHaveNpcAssisted(dwPartnerID) then
            OutputMessage("MSG_SYS", g_tStrings.STR_PARTNER_ALREADY_HAVE)
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_PARTNER_ALREADY_HAVE)
            return
        end

        local tInfo             = Table_GetPartnerNpcInfo(dwPartnerID)
        local nCostArchitecture = tInfo.nPrice

        local szTitle           = "雇佣"
        local szContent1        = string.format("确认雇佣%s吗？", UIHelper.GBKToUTF8(tInfo.szName))
        local szContent2        = "共需支付：（可选择以下方式结算）"

        ---@see UIItemMultiPurchasePopView#OnEnter
        UIMgr.Open(VIEW_ID.PanelItemMultiPurchasePop, nCostArchitecture, szTitle, szContent1, szContent2,
                   function(nCostArch, tMoney)
                       RemoteCallToServer("On_Hero_BuyServant", dwPartnerID, nCostArch, tMoney)
                   end
        )
    end)
end

function UIPartnerBuyView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPartnerBuyView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerBuyView:UpdateInfo()
    local tInfo     = Table_GetPartnerNpcInfo(self.nSelID)
    local tDrawInfo = self:GetSelPartnerDrawInfo()

    UIHelper.SetSpriteFrame(self.ImgRoleTag, PartnerKungfuIndexToImg[tInfo.nKungfuIndex])
    UIHelper.SetString(self.LabelRoleName, UIHelper.GBKToUTF8(tInfo.szName))
    UIHelper.SetString(self.LabelRoleInfo, UIHelper.GBKToUTF8(tInfo.szIntroduce))

    local szImgPath = tInfo.szBigAvatarImg
    UIHelper.SetTexture(self.ImgRole, szImgPath)

    local bInTaskOrMeet = tDrawInfo.nState == PartnerDrawState.InTask or tDrawInfo.nState == PartnerDrawState.Meet

    local szMeetStateImg
    if bInTaskOrMeet then
        szMeetStateImg = "UIAtlas2_Partner_PartnerTips_xunfangMark2.png"
    else
        szMeetStateImg = "UIAtlas2_Partner_PartnerTips_xunfangMark1.png"
    end
    UIHelper.SetSpriteFrame(self.ImgRoleMeetState, szMeetStateImg)

    UIHelper.SetString(self.LabelCostArchitecture, tInfo.nPrice)
    UIHelper.LayoutDoLayout(self.LayoutCost)

    self:UpdateCurrencyInfo()
end

---@return PartnerDrawInfo
function UIPartnerBuyView:GetSelPartnerDrawInfo(nSelID)
    if nSelID == nil then
        nSelID = self.nSelID
    end

    for _, tDrawInfo in ipairs(self.tInfoList) do
        if tDrawInfo.dwID == nSelID then
            return tDrawInfo
        end
    end

    return nil
end

function UIPartnerBuyView:UpdateCurrencyInfo()
    UIHelper.RemoveAllChildren(self.LayoutCurrency)

    ---@see UICoin#OnEnter
    UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutCurrency, CurrencyType.Architecture)

    ---@see UIMoney#OnEnter
    UIHelper.AddPrefab(PREFAB_ID.WidgetCurrency, self.LayoutCurrency)

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutCurrency, true, true)
end

return UIPartnerBuyView