-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIFactionRecommendAuctionPopView
-- Date: 2023-12-07 21:48:25
-- Desc: 帮会-推荐竞标
-- Prefab: PanelFactionRecommendAuctionPop
-- ---------------------------------------------------------------------------------

---@class UIFactionRecommendAuctionPopView
local UIFactionRecommendAuctionPopView = class("UIFactionRecommendAuctionPopView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIFactionRecommendAuctionPopView:_LuaBindList()
    self.BtnClose           = self.BtnClose --- 关闭按钮
    self.LabelLastCost      = self.LabelLastCost --- 最低竞标费用
    self.LabelTongName      = self.LabelTongName --- 帮会名称
    self.EditBoxMyPrice     = self.EditBoxMyPrice --- 我的出价
    self.EditBoxDescription = self.EditBoxDescription --- 帮会简介
    self.BtnCancel          = self.BtnCancel --- 取消按钮
    self.BtnConfirm         = self.BtnConfirm --- 确认按钮
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIFactionRecommendAuctionPopView:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIFactionRecommendAuctionPopView:OnEnter(nLastCost)
    self.nLastCost = nLastCost

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIFactionRecommendAuctionPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFactionRecommendAuctionPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        self:AddTopTenRequest()
    end)
end

function UIFactionRecommendAuctionPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "ON_TONG_TOP_TEN_RESPOND", function(nRetCode)
        if nRetCode == TONG_PUBLICITY_RESULT_CODE.COMPETITIVERANKING_SUCCESS then
            RemoteCallToServer("On_Tong_GetTopTenCost")
            UIMgr.Close(self)
        end
    end)
end

function UIFactionRecommendAuctionPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFactionRecommendAuctionPopView:UpdateInfo()
    local szTongName = UIHelper.GBKToUTF8(TongData.GetName())

    UIHelper.SetString(self.LabelLastCost, self.nLastCost)
    UIHelper.SetString(self.LabelTongName, szTongName)
end

function UIFactionRecommendAuctionPopView:AddTopTenRequest()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local bHaveTong = TongData.HavePlayerJoinedTong()
    if not bHaveTong then
        return
    end

    local hTongClient = GetTongClient()
    if not hTongClient then
        return
    end

    local szMyPrice     = UIHelper.GetString(self.EditBoxMyPrice)
    local szDescription = UIHelper.GetString(self.EditBoxDescription)

    local nCost         = tonumber(szMyPrice) or 0

    if self.nLastCost and nCost <= self.nLastCost then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tTongAddTopTongReult[TONG_PUBLICITY_RESULT_CODE.COMPETITIVERANKING_LOWERFUNC])
        OutputMessage("MSG_SYS", g_tStrings.tTongAddTopTongReult[TONG_PUBLICITY_RESULT_CODE.COMPETITIVERANKING_LOWERFUNC] .. g_tStrings.STR_FULL_STOP .. "\n")
        return
    end

    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE, "Tong") then
        return
    end

    RemoteCallToServer("On_Tong_AddTopTenRequest", nCost, UIHelper.UTF8ToGBK(szDescription))
end

return UIFactionRecommendAuctionPopView