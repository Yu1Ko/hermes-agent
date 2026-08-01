-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPetGatherListCell
-- Date: 2023-03-27 15:00:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPetGatherListCell = class("UIPetGatherListCell")

function UIPetGatherListCell:OnEnter(tNodes,nCurIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if not tNodes then return end
    self.tNode1 = tNodes[1]
    self.nCurIndex = nCurIndex
    self.tIndex = {}
    for i = 1,2,1 do
        if tNodes[i] then
            self:UpdateInfo(tNodes[i],i)
            table.insert(self.tIndex,tNodes[i].nIndex)
        end
        UIHelper.SetVisible(self.tbTogPet[i],tNodes[i] and true or false)
        UIHelper.SetVisible(self.tbLabelPetName[i],tNodes[i] and true or false)
    end
end

function UIPetGatherListCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPetGatherListCell:BindUIEvent()
    for i = 1,2,1 do
        UIHelper.BindUIEvent(self.tbTogPet[i], EventType.OnSelectChanged, function(_,bSelected)
            if bSelected then
                Event.Dispatch(EventType.OnSelectPet,self.tIndex[i])
            end
        end)
    end
    for i = 1,2,1 do
        UIHelper.BindUIEvent(self.tbToglike[i], EventType.OnClick, function()
            Event.Dispatch(EventType.OnAddOrDelectPreferFellowPet,self.tIndex[i])
        end)
    end
end

function UIPetGatherListCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPetGatherListCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPetGatherListCell:UpdateInfo(node,i)
    UIHelper.SetVisible(self.tbImglike[i],node.bPrefer)
    UIHelper.SetVisible(self.tbImglike01[i],not node.bPrefer)
    UIHelper.SetVisible(self.tbImgSelect[i],self.nCurIndex == node.nIndex)
    UIHelper.SetString(self.tbLabelPetName[i],UIHelper.GBKToUTF8(node.szName))
    UIHelper.SetVisible(self.tbImgTag[i],node.bLucky)
    UIHelper.SetVisible(self.tbImgTime[i],node.bLimitTime)
    UIHelper.SetVisible(self.tbImglRemind[i],node.bIdentityYS)
    UIHelper.SetVisible(self.tbToglike[i],not node.bOthers)
    UIHelper.SetSpriteFrame(self.tbImgQuality[i], PetImgQuality[node.nQuality])
    UIHelper.SetNodeGray(self.tbImgFrame[i], not node.bHave)

    local szPath = node.szBgPath
    szPath = string.gsub(szPath,"ui\\Image\\Pets\\","Resource/Pets/")
    szPath = string.gsub(szPath,"ui/Image/Pets/","Resource/Pets/")
    szPath = string.gsub(szPath,"tga","png")
    UIHelper.SetTexture(self.tbImgFrame[i],szPath)
end

return UIPetGatherListCell