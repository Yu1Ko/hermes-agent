-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipContent13
-- Date: 2024-07-08 14:46:48
-- Desc: ?
-- ---------------------------------------------------------------------------------

local _L = {
    ['WBL Source'] = '来源',
    ['WBL StartSellTime'] = '推出时间',
    ['WBL HighestPrice'] = '历史最高价格',
    ['WBL NumberOfTrades'] = '30日交易热度',
    ['WBL NumberOfUse'] = '30日活跃玩家实穿热度',
    ['WBL NumberOfUse More'] = '(实穿热度不统计未上线角色)',
    ['WBL Tips Title'] = '\n万宝楼交易信息',
    ['WBL Tips Title More'] = '(由剑心插件提供)\n',
    ['WBL Tips Waiting'] = '信息正在获取中或暂未收录该物品信息',
    ['WBL Tips Waiting30'] = '信息正在处理中，请30秒后重试',
    ['WBL Forbid RemoteServer'] = '当前为跨服状态，暂时无法查询信息',
}

local tFormatData = {
    {attr = "Source",         default = "", title = _L['WBL Source'], formatvalue = function(a,b) return a==b and "-\n" or string.format("%s\n", a) end},
    {attr = "StartSellTime",  default = "", title = _L['WBL StartSellTime'], formatvalue = function(a,b) return a==b and "-\n" or string.format("%s\n", a) end},
    {attr = "HighestPrice",   default = 0,  title = _L['WBL HighestPrice'], formatvalue = function(a,b) return a==b and "-\n" or string.format("￥%.2f\n", a/100) end},
    {attr = "NumberOfTrades", default = 0,  title = _L['WBL NumberOfTrades'], formatvalue = function(a,b) return a==b and "-\n" or string.format("%s\n", a) end},
    {attr = "NumberOfUse",    default = 0,  title = _L['WBL NumberOfUse'], titlemore = _L['WBL NumberOfUse More'], formatvalue = function(a,b) return a==b and "-\n" or string.format("%s\n", a) end},
}

local UIItemTipContent13 = class("UIItemTipContent13")

function UIItemTipContent13:OnEnter(dwTabType, dwIndex, bEvent)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.dwTabType = dwTabType
    self.dwIndex = dwIndex
    self.bEvent = bEvent
    self:UpdateInfo()
end

function UIItemTipContent13:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIItemTipContent13:BindUIEvent()

end

function UIItemTipContent13:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemTipContent13:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIItemTipContent13:GetTradingInfo(dwTabType, dwIndex, bEvent)
    local hMallClient = GetTradeMallClient()
    if not hMallClient then
        return false
    end
    local t = hMallClient.GetTradingInfo(dwTabType, dwIndex)
    if not t then
        return false
    end
    local bIsNil = true
    for _, v in pairs(tFormatData) do
        if t[v.attr] and t[v.attr] ~= v.default then
            bIsNil = false
            break
        end
    end
    if not bIsNil then
        return t
    elseif bEvent then
        return true
    else
        return false
    end
end

function UIItemTipContent13:GetFormatTipsInfo(t)
    local szText = ""
    if type(t) ~= "table" then
        return string.format("<color=#AED9E0>%s</c>", _L['WBL Tips Waiting30'])
    end
    for _, v in ipairs(tFormatData) do
        if t[v.attr] then
            szText = szText .. string.format("<color=#D7F6FF>%s: </c>", v.title)
            local attr
            if IsString(t[v.attr]) then
                attr = UIHelper.GBKToUTF8(t[v.attr])
            else
                attr = t[v.attr]
            end
            szText = szText .. string.format("<color=#FFE26E>%s</c>",v.formatvalue(attr, v.default))
            if v.titlemore then
                szText = szText .. string.format("<color=#AED9E0><size=20>%s</s></c>", v.titlemore)
            end
        end
    end
    return szText
end

function UIItemTipContent13:UpdateInfo()
    local player = GetClientPlayer()
    if not player then
        return
    end
    local szTips = ""
    if IsRemotePlayer(player.dwID) then
        szTips = szTips .. string.format("<color=#AED9E0>%s</c>", _L['WBL Forbid RemoteServer'])
    else
        local tRespond = self:GetTradingInfo(self.dwTabType, self.dwIndex, self.bEvent)
        if not tRespond then
            szTips = szTips .. string.format("<color=#AED9E0>%s</c>", _L['WBL Tips Waiting'])
        else
            szTips = szTips .. self:GetFormatTipsInfo(tRespond)
        end
    end
    UIHelper.SetRichText(self.RichTextContent, szTips)
    UIHelper.LayoutDoLayout(self.LayoutContent)
    UIHelper.LayoutDoLayout(self._rootNode)
end


return UIItemTipContent13