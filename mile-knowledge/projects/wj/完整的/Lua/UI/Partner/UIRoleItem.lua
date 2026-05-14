-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIRoleItem
-- Date: 2023-04-23 15:55:20
-- Desc: 侠客-共鸣助战配置界面的选择角色组件
-- Prefab: WidgetRoleItem
-- ---------------------------------------------------------------------------------

---@class UIRoleItem
local UIRoleItem = class("UIRoleItem")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIRoleItem:_LuaBindList()
    self.ImgRoleIcon         = self.ImgRoleIcon --- 侠客图标
    self.ImgKungfu           = self.ImgKungfu --- 心法图标
    self.LabelLevel          = self.LabelLevel --- 等级

    self.BtnChosenPartner    = self.BtnChosenPartner --- 已配置的侠客的按钮
    self.ImgChosenPartner    = self.ImgChosenPartner --- （已废弃）已配置的侠客的标记
    self.ImgSelectNum        = self.ImgSelectNum --- 已配置的侠客的序号的图片背景
    self.LabelTeamNum        = self.LabelTeamNum --- 已配置的侠客的序号
    self.ImgInBattle         = self.ImgInBattle --- 已召请的标记

    self.ToggleCurrentSelect = self.ToggleCurrentSelect --- 当前选中的侠客的toggle

    self.ImgRarityBackGround = self.ImgRarityBackGround --- 侠客稀有度背景

    self.MaskLock            = self.MaskLock --- 未拥有的遮罩
    self.ImgRoleIconLock     = self.ImgRoleIconLock --- 未拥有的角色黑影

    self.ImgMark             = self.ImgMark --- 配置的其他类型的角色的标记，如共鸣模式下，助战角色通过该位置标记为助战，进行区分

    self.LabelName           = self.LabelName --- 侠客名称

    self.ImgTestMask         = self.ImgTestMask --- 试用图标

    self.BtnEmptyAdd         = self.BtnEmptyAdd --- 助战展示界面未配置位置的+号
    self.WidgetHave          = self.WidgetHave --- 正常展示界面

    self.LayoutStaminaNum    = self.LayoutStaminaNum --- 体力值的layout
    self.LabelStaminaNum     = self.LabelStaminaNum --- 体力值的label

    self.LabelNotHave        = self.LabelNotHave --- 未拥有时的提示

    self.ImgRarityUpper      = self.ImgRarityUpper --- 侠客稀有度的上方背景

    self.WidgetNewItem       = self.WidgetNewItem --- 新获得的侠客标记

    self.LayoutFight         = self.LayoutFight --- 战力的上层layout
    self.LabelFight          = self.LabelFight --- 战力
    self.LayoutName          = self.LayoutName --- 名称的layout
    self.LayoutInfo          = self.LayoutInfo --- 战力和体力的layout

    self.LabelCostTime       = self.LabelCostTime --- 侠客出行所需要的时间
    self.ImgInTravel         = self.ImgInTravel --- 出行中的标记
    self.ImgInArranged       = self.ImgInArranged --- 已安排的标记

    self.ImgLimit            = self.ImgLimit --- 限定标记
end

---@param tInfo PartnerNpcInfo
function UIRoleItem:OnEnter(tInfo)
    --- 侠客的配置信息，若为nil，则表示助战展示界面未配置的位置
    self.tInfo = tInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
    
    UIHelper.SetVisible(self.ImgSelectNum, false)
end

function UIRoleItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRoleItem:BindUIEvent()

end

function UIRoleItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "ON_NPC_ASSISTED_RESULT_CODE", function(nResultCode, nArg0, nArg1, nArg2)
        if nResultCode == NPC_ASSISTED_RESULT_CODE.NPC_ASSISTED_INFO_CHANGE then
            --数据变动
            self:UpdateInfo()
        end
    end)
end

function UIRoleItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRoleItem:UpdateInfo()
    local tInfo        = self.tInfo

    local bShowDetails = tInfo ~= nil
    UIHelper.SetVisible(self.BtnEmptyAdd, not bShowDetails)
    UIHelper.SetVisible(self.WidgetHave, bShowDetails)

    UIHelper.SetSwallowTouches(self.ToggleCurrentSelect, false)
    UIHelper.SetSwallowTouches(self.BtnChosenPartner, false)

    if tInfo then
        local dwID = tInfo.dwID

        UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(tInfo.szName))

        UIHelper.SetVisible(self.ImgLimit, PartnerData.NeedShowLimitedTips(tInfo.dwID))

        local szImgPath = tInfo.szAvatarImg
        UIHelper.SetSpriteFrame(self.ImgRoleIcon, szImgPath)

        local nKungfuIndex = tInfo.nKungfuIndex
        UIHelper.SetSpriteFrame(self.ImgKungfu, PartnerKungfuIndexToImg[nKungfuIndex])

        local bHave = tInfo.bHave

        UIHelper.SetVisible(self.MaskLock, not bHave)
        UIHelper.SetSpriteFrame(self.ImgRoleIconLock, szImgPath)

        UIHelper.SetVisible(self.ImgTestMask, tInfo.bTryOut)

        UIHelper.SetVisible(self.LayoutStaminaNum, bHave and not tInfo.bTryOut)
        UIHelper.SetVisible(self.LabelNotHave, not bHave)
        if bHave then
            UIHelper.SetString(self.LabelLevel, tInfo.nLevel .. "级")
        end
        UIHelper.SetVisible(self.LabelLevel, bHave)
        UIHelper.LayoutDoLayout(self.LayoutName)

        local nQuality  = tInfo.nQuality

        local szBgImage = PartnerRarityToSmallCoverImage[nQuality]
        UIHelper.SetSpriteFrame(self.ImgRarityBackGround, szBgImage)

        local szUpperImage = PartnerRarityToSmallBgImage[nQuality]
        UIHelper.SetSpriteFrame(self.ImgRarityUpper, szUpperImage)

        local tPartnerInfo = Partner_GetPartnerInfo(dwID)
        if tPartnerInfo then
            local dwStanima    = tPartnerInfo.dwStamina
            local dwMaxStanima = GetMaxStamina()

            UIHelper.SetString(self.LabelStaminaNum, string.format("%d/%d", dwStanima, dwMaxStanima))
            UIHelper.LayoutDoLayout(self.LayoutStaminaNum)
        end

        local bNewGet = Partner_IsNewAddPartner(dwID)
        UIHelper.SetVisible(self.WidgetNewItem, bNewGet)

        self:UpdateScoreInfo()
    end
end

function UIRoleItem:UnNewAddPartner()
    UIHelper.SetVisible(self.WidgetNewItem, false)

    Partner_UnNewAddPartnerList(self.tInfo.dwID)
end

function UIRoleItem:UpdateScoreInfo()
    if not self.tInfo then
        return
    end

    local dwID = self.tInfo.dwID

    PartnerData.UpdateScoreInfo(nil, dwID, self.LabelFight, self.LayoutFight)

    UIHelper.LayoutDoLayout(self.LayoutInfo)
end

---@param tSelectedPartnerList number[] 已选择的侠客ID列表，根据当前侠客在该列表中的位置，来显示序号
function UIRoleItem:UpdateSelectedIndex(tSelectedPartnerIDList)
    if not self.tInfo then
        UIHelper.SetVisible(self.ImgSelectNum, false)
        return
    end

    local nIndex = table.get_key(tSelectedPartnerIDList, self.tInfo.dwID)
    UIHelper.SetVisible(self.ImgSelectNum, nIndex ~= nil)
    UIHelper.SetString(self.LabelTeamNum, nIndex)
end

return UIRoleItem