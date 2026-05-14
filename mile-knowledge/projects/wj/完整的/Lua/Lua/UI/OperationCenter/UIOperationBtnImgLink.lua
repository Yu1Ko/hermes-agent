-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationBtnImgLink
-- Date: 2026-03-20
-- Desc: 运营活动图片链接按钮组件
-- ---------------------------------------------------------------------------------

local UIOperationBtnImgLink = class("UIOperationBtnImgLink")

--------------------------------------------------------
-- 生命周期
--------------------------------------------------------
function UIOperationBtnImgLink:OnEnter(tInfo, nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nIndex = nIndex
    self.tInfo = tInfo
end

function UIOperationBtnImgLink:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationBtnImgLink:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnImgLink, EventType.OnClick, function(btn)
        if self.fnCallBack then
            self.fnCallBack()
        end
    end)
end

function UIOperationBtnImgLink:RegEvent()
    Event.Reg(self, EventType.OnOperationSelectBtnImgLink, function(nIndex)
        self:SetSelected(nIndex == self.nIndex)
    end)
end

function UIOperationBtnImgLink:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

--------------------------------------------------------
-- 内部工具函数
--------------------------------------------------------

-- 判断是否为小图类型（nType=1）
function UIOperationBtnImgLink:IsSmallType()
    return tonumber(self.nType) == 1
end

--------------------------------------------------------
-- 细粒度更新 API
--------------------------------------------------------

-- 设置按钮图片
function UIOperationBtnImgLink:SetImage(szImagePath)
    if szImagePath and szImagePath ~= "" then
        UIHelper.SetTexture(self.ImgImgLink, szImagePath)
    end
end

-- 设置标签文本（仅小图类型有效）
function UIOperationBtnImgLink:SetText(szText)
    if not self:IsSmallType() then
        return
    end

    if szText and szText ~= "" then
        UIHelper.SetRichText(self.LabelContent, szText)
        UIHelper.SetVisible(self.LabelContent, true)
    else
        UIHelper.SetVisible(self.LabelContent, false)
    end
end

-- 设置选中状态（仅小图类型有效）
function UIOperationBtnImgLink:SetSelected(bSelected)
    if not self:IsSmallType() then
        return
    end

    UIHelper.SetVisible(self.ImgSelect, bSelected == true)
end

--------------------------------------------------------
-- 回调设置
--------------------------------------------------------

-- 设置按钮点击回调
function UIOperationBtnImgLink:SetfnCallBack(fnCallBack)
    self.fnCallBack = fnCallBack
end


return UIOperationBtnImgLink
