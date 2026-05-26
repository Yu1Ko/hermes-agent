-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIActivityLeaveBtnView
-- Date: 2022-12-12 17:42:53
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIActivityLeaveBtnView = class("UIActivityLeaveBtnView")

function UIActivityLeaveBtnView:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if tbInfo then
        self.tbInfo = tbInfo
        self:UpdateInfo()
    end
end

function UIActivityLeaveBtnView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIActivityLeaveBtnView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnLeaveFor, EventType.OnClick, function()
        if self.tbInfo then
            --打开中地图travel
            Event.Dispatch(EventType.OnSelectLeaveForBtn, self.tbInfo)
        else
            self.fnClick()
        end
    end)
end

function UIActivityLeaveBtnView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIActivityLeaveBtnView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIActivityLeaveBtnView:UpdateInfo()
    local szMapName = Table_GetMapName(self.tbInfo.dwMapID)
    local szText = UIHelper.GBKToUTF8(self.tbInfo.szNpcName) .. FormatString(g_tStrings.STR_ALL_PARENTHESES, UIHelper.GBKToUTF8(szMapName))
    local _, szNewText = GetStringCharCountAndTopChars(szText, 15) -- 吴鹏钦定超字省略
    if #szNewText < #szText then
        szText = szNewText .. "..."
    end
    UIHelper.SetString(self.LableLeaveFor, szText)
end

function UIActivityLeaveBtnView:BindClickFunction(fnClick)
    if IsFunction(fnClick) then
        self.fnClick = fnClick
    end
end

function UIActivityLeaveBtnView:SetLabelText(szText)
    UIHelper.SetString(self.LableLeaveFor, szText)
end

return UIActivityLeaveBtnView