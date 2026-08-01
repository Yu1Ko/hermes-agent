-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetOlympicsCell
-- Date: 2024-08-22 10:27:17
-- Desc: WidgetOlympicsCell 音游玩法，点击节点
-- ---------------------------------------------------------------------------------

local UIWidgetOlympicsCell = class("UIWidgetOlympicsCell")

local IMG_PATH = {
    ["F"] = {
        Basic = "UIAtlas2_Olympics_Olympics_img_First_Yellow",
        Center = "UIAtlas2_Olympics_Olympics_img_Icon_Yellow",
        -- Progress = "UIAtlas2_Olympics_Olympics_img_ProgressY",
        Click_Light = "UIAtlas2_Olympics_Olympics_img_Feedback_Yellow",
    },
    ["J"] = {
        Basic = "UIAtlas2_Olympics_Olympics_img_First_B",
        Center = "UIAtlas2_Olympics_Olympics_img_Icon_B",
        -- Progress = "UIAtlas2_Olympics_Olympics_img_ProgressB",
        Click_Light = "UIAtlas2_Olympics_Olympics_img_Feedback_Blue",
    },
}

-- local SFX_PATH = {
--     ["F"] = {
--         SfxAppraise = {
--             Miss = "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符评价疏漏01.pss",
--             Good = "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符评价尚可01.pss",
--             Nice = "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符评价卓绝01.pss",
--             Perfect = "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符评价超尘01.pss",
--         },
--         SfxPlay = {
--             NotPerfect = "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符完美执行01.pss",
--             Perfect = "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符完美执行01.pss",
--         },
--         SfxStart = {
--             "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符开始01.pss",
--             "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符开始01_100.pss",
--             "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符开始01_200.pss",
--             "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符开始01_300.pss",
--             "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符开始01_400.pss",
--             "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符开始01_500.pss",
--             "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符开始01_600.pss",
--         },
--         SfxCenterPerfect = {
--             CenterPerfect = "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符开始01_完美高亮.pss",
--             CenterPerfect_Playing = "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符长按反馈01.pss",
--         },
--         SfxGetScore = {
--             Perfect = "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符评价超尘长按01.pss",
--             Good = "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符评价尚可长按01.pss",
--             Nice = "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符评价卓绝长按01.pss",
--         },
--     },
--     ["J"] = {
--         SfxAppraise = {
--             Miss = "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符评价疏漏01.pss",
--             Good = "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符评价尚可01.pss",
--             Nice = "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符评价卓绝01.pss",
--             Perfect = "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符评价超尘01.pss",
--         },
--         SfxPlay = {
--             NotPerfect = "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符完美执行蓝01.pss",
--             Perfect = "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符完美执行蓝01.pss",
--         },
--         SfxStart = {
--             "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符开始01蓝.pss",
--             "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符开始01蓝_100.pss",
--             "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符开始01蓝_200.pss",
--             "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符开始01蓝_300.pss",
--             "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符开始01蓝_400.pss",
--             "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符开始01蓝_500.pss",
--             "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符开始01蓝_600.pss",
--         },
--         SfxCenterPerfect = {
--             CenterPerfect = "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符开始01_完美高亮蓝.pss",
--             CenterPerfect_Playing = "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符长按反馈蓝01.pss",
--         },
--         SfxGetScore = {
--             Perfect = "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符评价超尘长按蓝01.pss",
--             Good = "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符评价尚可长按01.pss",
--             Nice = "data\\source\\other\\HD特效\\其他\\Pss\\UI_音符评价卓绝长按01.pss",
--         },
--     }
-- }

local tLevel2AppraiseIndex = {
    Miss = 1,
    Good = 2,
    Nice = 3,
    Perfect = 4,
}

local tLevel2GertScoreIndex = {
    Perfect = 1,
    Good = 2,
    Nice = 3,
}

function UIWidgetOlympicsCell:OnEnter(szNodeType, szPressButton)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetOlympicsCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetOlympicsCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnOlympics, EventType.OnTouchBegan, function()
        Event.Dispatch(EventType.FancySkating_OnButtonDown, self.szPressButton, self.nNodeIndex)
    end)
    UIHelper.BindUIEvent(self.BtnOlympics, EventType.OnTouchEnded, function()
        Event.Dispatch(EventType.FancySkating_OnButtonUp, self.szPressButton, self.nNodeIndex)
    end)
    UIHelper.BindUIEvent(self.BtnOlympics, EventType.OnTouchCanceled, function()
        Event.Dispatch(EventType.FancySkating_OnButtonUp, self.szPressButton, self.nNodeIndex)
    end)
end

function UIWidgetOlympicsCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetOlympicsCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetOlympicsCell:OnInit(szNodeType, szPressButton, nNodeIndex, nX, nY)
    self.szNodeType = szNodeType --Node：点击，LongNode：长按
    self.szPressButton = szPressButton --F：黄，J：蓝
    self.nNodeIndex = nNodeIndex
    Timer.DelAllTimer(self)
    UIHelper.SetLocalZOrder(self._rootNode, -nNodeIndex)
    UIHelper.SetName(self._rootNode, szNodeType .. "_" .. szPressButton .. "_" .. nNodeIndex)
    UIHelper.SetPosition(self._rootNode, nX, nY)
    self:UpdateInfo()
end

function UIWidgetOlympicsCell:UpdateInfo()
    local szPressButton = self.szPressButton

    UIHelper.SetSwallowTouches(self.BtnOlympics, true)

    local bCanTouch = (not Platform.IsWindows() and not Platform.IsMac()) or Channel.Is_WLColud()
    local nScale = bCanTouch and 1.5 or 0.8
    UIHelper.SetTouchEnabled(self.BtnOlympics, bCanTouch)
    UIHelper.SetScale(self.WidgetScaleOlympics, nScale, nScale)

    UIHelper.SetSpriteFrame(self.ImgBasic, IMG_PATH[szPressButton].Basic)
    UIHelper.SetSpriteFrame(self.ImgCenter, IMG_PATH[szPressButton].Center)
    -- UIHelper.SetSpriteFrame(self.ImgProgress, IMG_PATH[szPressButton].Progress) --cocos的Sprite设为ProgressBar那种样式之后不能改图
    UIHelper.SetSpriteFrame(self.ImgClick, IMG_PATH[szPressButton].Click_Light)
    UIHelper.SetVisible(self.WidgetEff_Yellow, szPressButton == "F")
    UIHelper.SetVisible(self.WidgetEff_Blue, szPressButton == "J")

    self:SetTabVisible(self.tSfxAppraiseF, false)
    self:SetTabVisible(self.tSfxAppraiseJ, false)
    self:SetTabVisible(self.tSfxPlayF, false)
    self:SetTabVisible(self.tSfxPlayJ, false)
    self:SetTabVisible(self.tSfxStartF, false)
    self:SetTabVisible(self.tSfxStartJ, false)
    self:SetTabVisible(self.tSfxCenterPerfectF, false)
    self:SetTabVisible(self.tSfxCenterPerfectJ, false)
    self:SetTabVisible(self.tSfxGetScoreF, false)
    self:SetTabVisible(self.tSfxGetScoreJ, false)

    if szPressButton == "F" then
        self.ImgProgress = self.ImgProgressF
    elseif szPressButton == "J" then
        self.ImgProgress = self.ImgProgressJ
    else
        self.ImgProgress = nil
    end

    UIHelper.SetOpacity(self.ImgProgress, 115)
end

function UIWidgetOlympicsCell:PlaySfx(sfxNode, bLoop)
    UIHelper.SetOpacity(sfxNode, 255) --SetVisible会触发LoadSfx，在手机端会有较大延迟
    UIHelper.PlaySFX(sfxNode, bLoop and 1 or 0)
end

function UIWidgetOlympicsCell:HideSfx(sfxNode)
    UIHelper.SetOpacity(sfxNode, 0)
end

function UIWidgetOlympicsCell:SetTabVisible(tbNode, bVisible)
    for _, v in pairs(tbNode or {}) do
        UIHelper.SetOpacity(v, bVisible and 255 or 0)
    end
end

function UIWidgetOlympicsCell:ShowAppraiseSfx(szLevel)
    local tSfxNode = self.szPressButton and self["tSfxAppraise" .. self.szPressButton]
    local sfxNode = tSfxNode and tSfxNode[tLevel2AppraiseIndex[szLevel]]
    if not sfxNode then
        return
    end

    self:PlaySfx(sfxNode)
    Timer.AddFrame(self, 1, function()
        UIHelper.SetSwallowTouches(self.BtnOlympics, false)
    end)
end

function UIWidgetOlympicsCell:ShowPlaySfx(bPerfect)
    local tSfxNode = self.szPressButton and self["tSfxPlay" .. self.szPressButton]
    local sfxNode = tSfxNode and (bPerfect and tSfxNode[2] or tSfxNode[1])
    if not sfxNode then
        return
    end

    self:PlaySfx(sfxNode, true)
    UIHelper.SetOpacity(self.ImgProgress, bPerfect and 255 or 115)
end

function UIWidgetOlympicsCell:ShowStartSfx(nIndex)
    local tSfxNode = self.szPressButton and self["tSfxStart" .. self.szPressButton]
    local sfxNode = tSfxNode and tSfxNode[nIndex + 1]
    if not sfxNode then
        return
    end

    self:PlaySfx(sfxNode)
end

function UIWidgetOlympicsCell:ShowCenterPerfectSfx(bPlaying)
    local tSfxNode = self.szPressButton and self["tSfxCenterPerfect" .. self.szPressButton]
    local sfxNode = tSfxNode and (bPlaying and tSfxNode[2] or tSfxNode[1])
    if not sfxNode then
        return
    end

    self:PlaySfx(sfxNode, true)
end

function UIWidgetOlympicsCell:ShowGetScoreSfx(szLevel)
    local tSfxNode = self.szPressButton and self["tSfxGetScore" .. self.szPressButton]
    local sfxNode = tSfxNode and tSfxNode[tLevel2GertScoreIndex[szLevel]]
    if not sfxNode then
        return
    end

    self:PlaySfx(sfxNode)
end

function UIWidgetOlympicsCell:HideAppraiseSfx()
    self:SetTabVisible(self.tSfxAppraiseF, false)
    self:SetTabVisible(self.tSfxAppraiseJ, false)
end

function UIWidgetOlympicsCell:HidePlaySfx()
    self:SetTabVisible(self.tSfxPlayF, false)
    self:SetTabVisible(self.tSfxPlayJ, false)
end

function UIWidgetOlympicsCell:HideStartSfx()
    self:SetTabVisible(self.tSfxStartF, false)
    self:SetTabVisible(self.tSfxStartJ, false)
end

function UIWidgetOlympicsCell:HideCenterPerfectSfx(bPlaying)
    if bPlaying then
        self:HideSfx(self.tSfxCenterPerfectF[2])
        self:HideSfx(self.tSfxCenterPerfectJ[2])
    else
        self:HideSfx(self.tSfxCenterPerfectF[1])
        self:HideSfx(self.tSfxCenterPerfectJ[1])
    end
end

function UIWidgetOlympicsCell:HideGetScoreSfx()
    self:SetTabVisible(self.tSfxGetScoreF, false)
    self:SetTabVisible(self.tSfxGetScoreJ, false)
end

function UIWidgetOlympicsCell:SetVisible(bVisible)
    UIHelper.SetVisible(self._rootNode, bVisible)
end

function UIWidgetOlympicsCell:SetProgress(nProgress)
    UIHelper.SetProgressBarPercent(self.ImgProgress, nProgress * 100)
end

function UIWidgetOlympicsCell:SetProgressVisible(bVisible)
    UIHelper.SetVisible(self.ImgProgress, bVisible)
end

function UIWidgetOlympicsCell:SetClickVisible(bVisible)
    UIHelper.SetVisible(self.ImgClick, bVisible)
end

function UIWidgetOlympicsCell:SetImgBgVisible(bVisible)
    UIHelper.SetVisible(self.WidgetBg, bVisible)
end

return UIWidgetOlympicsCell