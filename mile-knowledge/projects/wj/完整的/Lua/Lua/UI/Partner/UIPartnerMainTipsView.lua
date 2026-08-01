-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerMainTipsView
-- Date: 2023-03-27 19:30:44
-- Desc: 侠客的提示界面
-- Prefab: PanelPartnerMainTips
-- ---------------------------------------------------------------------------------

local UIPartnerMainTipsView = class("UIPartnerMainTipsView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerMainTipsView:_LuaBindList()
    self.AniAll                 = self.AniAll --- 出现和消失的动画 AniPopUpShow/AniPopUpHide

    self.WidgetDrawTips         = self.WidgetDrawTips --- 喝茶结束的提示（没抽到）
    self.WidgetStartTaskTips    = self.WidgetStartTaskTips --- 开始侠客任务的提示（抽到了）
    self.WidgetSuccess          = self.WidgetSuccess --- 完成任务后获取了对应侠客的提示

    self.LabelFilterMaskText    = self.LabelFilterMaskText --- 喝茶的提示文字

    self.LabelStartTaskTitle    = self.LabelStartTaskTitle --- 开始侠客任务的标题
    self.ImgStartTaskRole       = self.ImgStartTaskRole --- 开始侠客任务的角色图片
    self.ImgStartTaskRoleType   = self.ImgStartTaskRoleType --- 开始侠客任务的角色类型（攻击、治疗、守卫等）图片
    self.LabelStartTaskRoleName = self.LabelStartTaskRoleName --- 开始侠客的角色名称

    self.LabelSuccessTitle      = self.LabelSuccessTitle --- 结识成功的标题
    self.ImgSuccessRole         = self.ImgSuccessRole --- 结识成功的角色图片
    self.ImgSuccessRoleType     = self.ImgSuccessRoleType --- 结识成功的角色类型（攻击、治疗、守卫等）图片
    self.LabelSuccessRoleName   = self.LabelSuccessRoleName --- 结识成功的角色名称
end

function UIPartnerMainTipsView:OnEnter(nTipsType, szFilterMaskText, dwID)
    --- Partner.tTipsType
    self.nTipsType        = nTipsType

    self.szFilterMaskText = szFilterMaskText

    self.dwID             = dwID

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPartnerMainTipsView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerMainTipsView:BindUIEvent()

end

function UIPartnerMainTipsView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPartnerMainTipsView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerMainTipsView:UpdateInfo()
    local tTipsTypeToWidget = {
        [PartnerData.tTipsType.nDrawFailed] = self.WidgetDrawTips,
        [PartnerData.tTipsType.nStartTask] = self.WidgetStartTaskTips,
        [PartnerData.tTipsType.nGetNewPartner] = self.WidgetSuccess,
    }

    for nType, uiWidget in pairs(tTipsTypeToWidget) do
        UIHelper.SetVisible(uiWidget, nType == self.nTipsType)
    end

    if self.nTipsType == PartnerData.tTipsType.nDrawFailed then
        UIHelper.SetString(self.LabelFilterMaskText, self.szFilterMaskText)
    elseif self.nTipsType == PartnerData.tTipsType.nStartTask then
        local tPartnerInfo = Table_GetPartnerNpcInfo(self.dwID)
        if not tPartnerInfo then
            return
        end

        local szImgPath = tPartnerInfo.szBigAvatarImg
        UIHelper.SetTexture(self.ImgStartTaskRole, szImgPath)

        local nKungfuIndex = tPartnerInfo.nKungfuIndex
        UIHelper.SetSpriteFrame(self.ImgStartTaskRoleType, PartnerKungfuIndexToImg[nKungfuIndex])

        UIHelper.SetString(self.LabelStartTaskRoleName, UIHelper.GBKToUTF8(tPartnerInfo.szName))
    elseif self.nTipsType == PartnerData.tTipsType.nGetNewPartner then
        local tPartnerInfo = Table_GetPartnerNpcInfo(self.dwID)
        if not tPartnerInfo then
            return
        end

        local szImgPath = tPartnerInfo.szBigAvatarImg
        UIHelper.SetTexture(self.ImgSuccessRole, szImgPath)

        local nKungfuIndex = tPartnerInfo.nKungfuIndex
        UIHelper.SetSpriteFrame(self.ImgSuccessRoleType, PartnerKungfuIndexToImg[nKungfuIndex])

        UIHelper.SetString(self.LabelSuccessRoleName, UIHelper.GBKToUTF8(tPartnerInfo.szName))
    end

    Timer.AddCountDown(self, 3, function() end, function()
        UIMgr.Close(self)
    end)
end

return UIPartnerMainTipsView