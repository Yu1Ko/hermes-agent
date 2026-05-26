-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetBubbleListView
-- Date: 2024-03-01 18:58:20
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetBubbleListView = class("UIWidgetBubbleListView")

function UIWidgetBubbleListView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bShowShuoShuren = false
    self.bShowBarTitle = false
    self:SetVisible(false)
end

function UIWidgetBubbleListView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBubbleListView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBubbleList, EventType.OnClick, function()
        if self.bShowBarTitle then
            if self.fnBarFunction then
                local szAction = self.fnBarFunction
                if IsFunction(szAction) then
                    szAction()
                elseif IsString(szAction) then
                    if not string.is_nil(szAction) then
                        BubbleMsgData.OpenMsgPanel()
                    end
                end
            end
        end
	end)

    UIHelper.BindUIEvent(self.BtnCloseShuoShuRen, EventType.OnClick, function()
        SwordMemoriesData.StopSound()
    end)
end

function UIWidgetBubbleListView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnSwordMemoriesSoundChanged, function()
        self.bShouldShowShuoShuRen = SwordMemoriesData.IsSoundPlaying()
        if not self.bShowBarTitle and self.bShouldShowShuoShuRen then--进入说书人
            self:ShowShuoShuren()
        elseif not self.bShouldShowShuoShuRen and self.bShowShuoShuren then--退出说书人
            self:HideShuoShuren()
        end
    end)
end

function UIWidgetBubbleListView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetBubbleListView:UpdateInfo()
    
end

function UIWidgetBubbleListView:SetString(szText)
    if self:IsShowShuoShuren() then
        self:HideShuoShuren(function()
            UIHelper.SetString(self.LabelBubbleList, szText)
        end)
    else
        UIHelper.SetString(self.LabelBubbleList, szText)
    end
end

function UIWidgetBubbleListView:PlayAnimation(szAnimName, callback)
    UIHelper.StopAllAni(self)
    UIHelper.PlayAni(self, self._rootNode, szAnimName, callback)
end

function UIWidgetBubbleListView:SetVisible(bVisible)
    UIHelper.SetVisible(self._rootNode, bVisible)
end

function UIWidgetBubbleListView:GetVisible()
    UIHelper.GetVisible(self._rootNode)
end

function UIWidgetBubbleListView:OnShowBarTitle()
    self.bShowBarTitle = true
    UIHelper.SetVisible(self._rootNode, true)
    self:PlayAnimation("AniBubbleListShow")
end

function UIWidgetBubbleListView:OnHideBarTitle()
    self:SetVisible(false)
    self.bShowBarTitle = false
    if self.bShouldShowShuoShuRen then
        self:ShowShuoShuren()
    end
    -- self:PlayAnimation("AniBubbleListHide", function()
    --     --Hide结束后隐藏，避免队尾的MainCityIcon事件退出时再次弹出
    --     Timer.AddFrame(self, 1, function ()
    --         self:SetVisible(false)
    --         self.bShowBarTitle = false
    --         if self.bShouldShowShuoShuRen then
    --             self:ShowShuoShuren()
    --         end
    --     end)
    -- end)
end

function UIWidgetBubbleListView:UpdateBubbleListImg(szImagePath)
    UIHelper.SetSpriteFrame(self.imgBubbleList, szImagePath)
end

function UIWidgetBubbleListView:ShowShuoShuren()

    self.bShowShuoShuren = true
    UIHelper.SetVisible(self.ImgShuoShuRen, true)
    UIHelper.SetVisible(self.BtnCloseShuoShuRen, true)
    UIHelper.SetString(self.LabelBubbleList, "说书人")

    self:PlayAnimation("AniBubbleListShow", function()
        UIHelper.SetVisible(self._rootNode, true)
        UIHelper.PlayAni(self, self.WidgetVoice, "AniVoiceLoop", nil, 2)
        UIHelper.SetTouchEnabled(self.BtnBubbleList, false)
    end)
end

function UIWidgetBubbleListView:HideShuoShuren(callback)

    self.bShowShuoShuren = false
    self:PlayAnimation("AniBubbleListHide", function()
        UIHelper.SetVisible(self._rootNode, false)
        UIHelper.SetVisible(self.ImgShuoShuRen, false)
        UIHelper.SetVisible(self.BtnCloseShuoShuRen, false)
        if callback then callback() end
        UIHelper.StopAni(self, self.WidgetVoice, "AniVoiceLoop")
        UIHelper.SetTouchEnabled(self.BtnBubbleList, true)
    end)
end

function UIWidgetBubbleListView:IsShowShuoShuren()
    return self.bShowShuoShuren
end

function UIWidgetBubbleListView:SetBarFunction(fn)
    self.fnBarFunction = fn
end

return UIWidgetBubbleListView