-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPlotDialogueOldNormalBigImage
-- Date: 2023-04-26 20:18:18
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPlotDialogueOldNormalBigImage = class("UIPlotDialogueOldNormalBigImage")

function UIPlotDialogueOldNormalBigImage:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UIPlotDialogueOldNormalBigImage:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPlotDialogueOldNormalBigImage:BindUIEvent()
    
end

function UIPlotDialogueOldNormalBigImage:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPlotDialogueOldNormalBigImage:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPlotDialogueOldNormalBigImage:UpdateInfo()
    UIHelper.SetTexture(self.ImgPicture, self.tbInfo.szIconName)
end


return UIPlotDialogueOldNormalBigImage