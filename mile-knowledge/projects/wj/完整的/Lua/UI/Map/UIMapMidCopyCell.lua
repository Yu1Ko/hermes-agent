-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMapMidCopyCell
-- Date: 2024-05-15 17:09:27
-- Desc: 地图分线节点
-- ---------------------------------------------------------------------------------

local UIMapMidCopyCell = class("UIMapMidCopyCell")

function UIMapMidCopyCell:OnEnter(nCopyIndex , bCurCopy , fnClickCallback, bCamp, tbHeatMapModeInfo, nDefaultCampMode)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bCurCopy = bCurCopy
    self.nCopyIndex = nCopyIndex
    self.fnClickCallback = fnClickCallback
    self.bCamp = bCamp
    self.tbHeatMapModeInfo = tbHeatMapModeInfo
    self.nDefaultCampMode = nDefaultCampMode
    self:UpdateInfo()
end

function UIMapMidCopyCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMapMidCopyCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnShunt , EventType.OnClick , function ()
        if self.fnClickCallback then
            self.fnClickCallback(self.nCopyIndex)
        end
    end)

    UIHelper.BindUIEvent(self.TogShunt_Camp , EventType.OnSelectChanged , function (_, bSelcet)
        if bSelcet then
            Event.Dispatch(EventType.OnSelectHeatMapMode, self.tbHeatMapModeInfo.nIndex)
        end
    end)
end

function UIMapMidCopyCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIMapMidCopyCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMapMidCopyCell:UpdateInfo()
    
    UIHelper.SetVisible(self.BtnShunt, not self.bCamp)
    UIHelper.SetVisible(self.TogShunt_Camp, self.bCamp)

    if not self.bCamp then
        UIHelper.SetVisible(self.ImgBg_Now , self.bCurCopy)
        UIHelper.SetString(self.LabelShunt , string.format("%d线",self.nCopyIndex))
        UIHelper.SetString(self.LabelShunt_Select , string.format("%d线",self.nCopyIndex))
        UIHelper.SetTouchDownHideTips(self.BtnShunt , false)
    else
        UIHelper.SetString(self.LabelShunt_Camp, self.tbHeatMapModeInfo.szTitle)
        UIHelper.SetSelected(self.TogShunt_Camp, self.nDefaultCampMode == self.tbHeatMapModeInfo.nIndex)
        UIHelper.SetToggleGroupIndex(self.TogShunt_Camp, ToggleGroupIndex.HeatMapMode)
    end
end


return UIMapMidCopyCell