-- ---------------------------------------------------------------------------------
-- Author: Liu yu min
-- Name: CrossingHint
-- Date: 2023-03-21 10:20:38
-- Desc: ?
-- ---------------------------------------------------------------------------------

local CrossingHint = class("CrossingHint")

function CrossingHint:OnEnter(tbData)
    self.tbData = tbData
    self.Time = 3
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function CrossingHint:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function CrossingHint:BindUIEvent()

end

function CrossingHint:RegEvent()
end

function CrossingHint:UnRegEvent()
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function CrossingHint:UpdateInfo()
    self:UpdateHintContent()
    self.nTimer = Timer.Add(self, self.Time,function ()
        self:CloseHint()
    end)
end

function CrossingHint:UpdateHintContent()
    if self.tbData.nMaxMission == 1 then
        UIHelper.SetString(self.LabelTitle,string.format("第%s层",UIHelper.NumberToChinese(self.tbData.nLevel)))
    else
        UIHelper.SetString(self.LabelTitle,string.format(CrossingData.szTaskTitleFormat,UIHelper.NumberToChinese(self.tbData.nLevel),UIHelper.NumberToChinese(self.tbData.nCurrentMission) ,  CrossingData.szCurMissionName))
    end
   
    UIHelper.SetString(self.LabelContent,CrossingData.szCurMissionDesc)
end

function CrossingHint:CloseHint()
    UIMgr.Close(VIEW_ID.PanelTestPlaceHint)
end


return CrossingHint