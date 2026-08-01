-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerCardCell
-- Date: 2023-03-28 15:20:10
-- Desc: 侠客-卡片
-- Prefab: WidgetPartnerCardCell
-- ---------------------------------------------------------------------------------

---@class UIPartnerCardCell
local UIPartnerCardCell = class("UIPartnerCardCell")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerCardCell:_LuaBindList()
    self.BtnCard             = self.BtnCard --- 打开对应侠客界面的按钮

    self.LabelName           = self.LabelName --- 名称
    self.LabelLevel          = self.LabelLevel --- 等级（若未获取，则显示 未获得）
    self.ImgRole             = self.ImgRole --- 角色的图片
    self.ImgTag              = self.ImgTag --- 角色类型的图片

    self.WidgetSelect        = self.WidgetSelect --- 选中时的表现，目前供召唤侠客界面使用

    self.ImgRarityFrame      = self.ImgRarityFrame --- 稀有度对应边框的图片
    self.ImgRarityBackGround = self.ImgRarityBackGround --- 稀有度背景的图片

    self.ImgDark             = self.ImgDark --- 未获取时显示的黑色遮罩

    self.ImgTestMask         = self.ImgTestMask --- 试用图标
    self.ImgFrist            = self.ImgFrist --- 首次寻访必得提示

    self.WidgetNewItem       = self.WidgetNewItem --- 新获得的侠客标记
    
    self.LayoutFight         = self.LayoutFight --- 战力的上层容器
    self.LabelFight          = self.LabelFight --- 战力

    self.ImgLimit            = self.ImgLimit --- 限定标记

    self.LayoutXunFangNum    = self.LayoutXunFangNum --- 寻访次数的上层容器
    self.LabelXunFangNum     = self.LabelXunFangNum --寻访次数
end

function UIPartnerCardCell:OnEnter(dwID, tShowPartnerIDList, dwPlayerID)
    self.dwID               = dwID
    self.tShowPartnerIDList = tShowPartnerIDList
    self.dwPlayerID         = dwPlayerID

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPartnerCardCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerCardCell:BindUIEvent()
end

function UIPartnerCardCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "ON_NPC_ASSISTED_RESULT_CODE", function(nRetCode, dwID)
        if dwID ~= self.dwID then
            return
        end

        if nRetCode == NPC_ASSISTED_RESULT_CODE.NPC_ASSISTED_INFO_CHANGE then
            --数据变动
            self:UpdateInfo()
        end
    end)
end

function UIPartnerCardCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerCardCell:UpdateInfo()
    local pPlayer = Partner_GetPlayer(self.dwPlayerID)
    if not pPlayer then
        return
    end

    local tInfo = Table_GetPartnerNpcInfo(self.dwID)

    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(tInfo.szName))

    local szLimitFrame = PartnerData.GetLimitedSpriteFrame(self.dwID, false)
    UIHelper.SetVisible(self.ImgLimit, PartnerData.NeedShowLimitedTips(self.dwID))
    if not string.is_nil(szLimitFrame) then
        UIHelper.SetSpriteFrame(self.ImgLimit, szLimitFrame)
    end

    local tPartner = Partner_GetPartnerInfo(self.dwID, self.dwPlayerID)
    if tPartner then
        UIHelper.SetString(self.LabelLevel, tPartner.nLevel .. "级")
    else
        UIHelper.SetString(self.LabelLevel, "未获得")
    end

    local szImgPath = tInfo.szAvatarImg
    UIHelper.SetSpriteFrame(self.ImgRole, szImgPath)

    UIHelper.SetSpriteFrame(self.ImgDark, szImgPath)
    UIHelper.SetVisible(self.ImgDark, not tPartner)

    UIHelper.SetVisible(self.ImgTestMask, tInfo.bTryOut)

    local nKungfuIndex = tInfo.nKungfuIndex
    UIHelper.SetSpriteFrame(self.ImgTag, PartnerKungfuIndexToImg[nKungfuIndex])

    local nQuality   = tInfo.nQuality

    local szBgImage = PartnerRarityToBackgroundImage[nQuality]
    UIHelper.SetSpriteFrame(self.ImgRarityBackGround, szBgImage)

    local szFrameImage = PartnerRarityToFrameImage[nQuality]
    UIHelper.SetSpriteFrame(self.ImgRarityFrame, szFrameImage)

    if self.Mask then
        UIHelper.UpdateMask(self.Mask)
    end

    local bFirstDrawMustHit = PartnerData.IsFirstDrawMustMeet(self.dwID)
    UIHelper.SetVisible(self.ImgFrist, bFirstDrawMustHit)

    local bIsSelfPlayer = Partner_IsSelfPlayer(self.dwPlayerID)
    local bInTask = false
    if bIsSelfPlayer then
        local nDrawState = GDAPI_GetHeroState(self.dwID)
        if nDrawState == PartnerDrawState.InTask then
            -- 任务中的时候，把卡片亮起来，并显示 前往任务
            UIHelper.SetVisible(self.ImgDark, false)
            UIHelper.SetString(self.LabelLevel, "前往任务")
            bInTask = true
        end

        local bNewGet = Partner_IsNewAddPartner(self.dwID)
        UIHelper.SetVisible(self.WidgetNewItem, bNewGet)
    end

    if bIsSelfPlayer and not tPartner and not bInTask then
        local nTry = pPlayer.GetNpcAssistedStagePoint(self.dwID)
        local szTryNum = ""
        if bIsSelfPlayer and nTry > 0 then
            szTryNum = "已寻访" .. nTry .. "次"
        end
        UIHelper.SetString(self.LabelXunFangNum, szTryNum)
        UIHelper.SetVisible(self.LayoutXunFangNum, true)
    else
        UIHelper.SetVisible(self.LayoutXunFangNum, false)
    end

    self:UpdateScoreInfo()
end

function UIPartnerCardCell:UnNewAddPartner()
    if Partner_IsSelfPlayer(self.dwPlayerID) then
        UIHelper.SetVisible(self.WidgetNewItem, false)

        Partner_UnNewAddPartnerList(self.dwID)
    end
end

function UIPartnerCardCell:UpdateScoreInfo()
    PartnerData.UpdateScoreInfo(self.dwPlayerID, self.dwID, self.LabelFight, self.LayoutFight)
end

return UIPartnerCardCell