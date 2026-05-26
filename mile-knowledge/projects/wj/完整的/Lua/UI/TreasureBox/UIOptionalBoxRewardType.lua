-- ---------------------------------------------------------------------------------
-- 自选宝箱奖励cell
-- WidgetTogRewardType
-- ---------------------------------------------------------------------------------

local UIOptionalBoxRewardCell = class("UIOptionalBoxRewardCell")

function UIOptionalBoxRewardCell:_LuaBindList()
    self.TogRewardType          = self.TogRewardType --- tog
    self.LabelRewardName        = self.LabelRewardName --- 类别名称
    self.LabelRewardNameSe      = self.LabelRewardNameSe --- 类别名称selected
end

function UIOptionalBoxRewardCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIOptionalBoxRewardCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOptionalBoxRewardCell:BindUIEvent()
    
end

function UIOptionalBoxRewardCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOptionalBoxRewardCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOptionalBoxRewardCell:UpdateInfo(szType)
    -- 背部挂件
    UIHelper.SetString(self.LabelRewardName, szType)
    UIHelper.SetString(self.LabelRewardNameSe, szType)
end

function UIOptionalBoxRewardCell:ShowColltImg(bShow)
    UIHelper.SetVisible(self.ImgTipBg, bShow)
end


return UIOptionalBoxRewardCell