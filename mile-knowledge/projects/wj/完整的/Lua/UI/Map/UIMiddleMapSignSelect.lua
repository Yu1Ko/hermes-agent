local UIMiddleMapSignSelect = class("UIMiddleMapSignSelect")

local TYPE_IMAGE_BG = {
    ["Transfer"] = "UIAtlas2_Map_MapButton_img_zhuizongBg2.png",
}

local CANT_SELECT_TYPE = {
    ["Wanted"] = true,
    ["Teammate"] = true,
}

function UIMiddleMapSignSelect:OnEnter()
    self:RegisterEvent()
end

function UIMiddleMapSignSelect:RegisterEvent()
    UIHelper.BindUIEvent(self.TogSighSelect, EventType.OnSelectChanged, function(_, bSelected)
        self.bSelected = bSelected
        -- TODO
        if self.fnSelected then
            self.fnSelected(self.bSelected)
        end
        self.tbMarkNode:DoAction()
    end)
end

function UIMiddleMapSignSelect:HasScript(script)
    return self.tbMarkNode == script
end

function UIMiddleMapSignSelect:UpdateInfo(tbMarkNode)
    self.tbMarkNode = tbMarkNode

    if tbMarkNode.szFrame then
        UIHelper.SetSpriteFrame(self.ImgIcon, tbMarkNode.szFrame)
    end

    local bButtonGray = self.tbMarkNode:IsButtonGray()
    UIHelper.SetNodeGray(self.ImgIcon, bButtonGray, true)

    if tbMarkNode.bIllegal then
        UIHelper.SetNodeGray(self.ImgIcon, true)
    end

    local szImageBg = TYPE_IMAGE_BG[tbMarkNode.szType]
    if szImageBg then
        UIHelper.SetSpriteFrame(self.ImgNormalBg01, szImageBg)
    end

    UIHelper.SetVisible(self.ImgTaskBg, tbMarkNode.nIndex ~= nil and not tbMarkNode.bFinished)
    if tbMarkNode.nIndex then
        UIHelper.SetString(self.LabelTask, tbMarkNode.nIndex)
    end

    UIHelper.SetVisible(self.ImgCantSelect, CANT_SELECT_TYPE[tbMarkNode.szType] ~= nil)
    UIHelper.SetVisible(self.ImgNormalBg01, CANT_SELECT_TYPE[tbMarkNode.szType] == nil)

    self.LabelNormal01:setString(tbMarkNode:GetTitle())
    self.LabelSelect02:setString(tbMarkNode:GetTitle())

    UIHelper.SetVisible(self.ImgLook, tbMarkNode:IsRedPointQuest())
end

return UIMiddleMapSignSelect