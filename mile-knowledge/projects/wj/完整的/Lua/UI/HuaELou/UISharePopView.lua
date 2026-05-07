-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISharePopView
-- Date: 2024-04-13 10:54:32
-- Desc: 分享界面
-- ---------------------------------------------------------------------------------

local UISharePopView = class("UISharePopView")
local bTestEnv = false
function UISharePopView:OnEnter(szConditionType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szConditionType = szConditionType
    self:UpdateInfo()
end

function UISharePopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISharePopView:BindUIEvent()

    UIHelper.BindUIEvent(self.BtnQQFriend, EventType.OnClick, function ()
        self:SendSchool("qqimagetext")
    end)

    UIHelper.BindUIEvent(self.BtnWeChat, EventType.OnClick, function ()
        self:SendSchool("weichatfriendweb")
    end)

    UIHelper.BindUIEvent(self.BtnCopyLink, EventType.OnClick, function ()
        self:CopyLink()
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UISharePopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISharePopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISharePopView:UpdateInfo()
    if Channel.Is_DouYin() then
        UIHelper.SetVisible(self.WidgetBtnWeChatFriend, false)
    end
    UIHelper.LayoutDoLayout(self.LayoutContent)
end

function UISharePopView:GetAutoShareUrl()
    local Url = "https://jx3.xoyo.com/p/zt/2024/05/27/public-testing/index.html#/guest?share_token="
    local testUrl = "https://test-zt.xoyo.com/jx3.xoyo.com/p/zt/2024/05/27/public-testing/index.html#/guest?share_token="

    local account = Login_GetAccount()
    local token
    local data
    local key = "kingt9Joy:8Xit"
    token = MD5(account .. key)
    data = account .. "&" .. token

    data = Base64_Encode( data )
    data = UrlEncode(data)

    local url = Url .. data
    return url
end

-- -------------------------------- 二测裂变活动 begin -------------------------------------------
function UISharePopView:SendShare(szChannel)
    local folder = GetStreamAdaptiveDirPath(UIHelper.GBKToUTF8(GetFullPath("dcim/")))
    CPath.MakeDir(folder)
    local filePath = folder.."ImgWeChatShare.png"
    if not Lib.IsPNGFileExist(filePath) then
        --拷贝文件
        cc.FileUtils:getInstance():pakV5WriteFileToLocal("mui/Texture/HuaELouReward/ImgWeChatShare.png" ,"dcim/ImgWeChatShare.png")
    end
    local szUid = Login_GetUnionAccount()
    local szAccountName = Login_GetAccount()
    local player = GetClientPlayer()
    local szRoleId = "NoRole"
    if player then
        szRoleId = tostring(player.dwID)
    end
    local szTitle = "番薯小侠！剑网3正在召唤你"
    local szContent = "你的好友为你挖来了一个剑网3无界二测资格！"

    local szUrl = string.format("account=%s&type=%s",szAccountName,self.szConditionType)
    szUrl = Base64_Encode( szUrl)
    local szShareUrl = "https://test-zt.xoyo.com/jx3.xoyo.com/p/m/2024/03/26/final-test/index.html?params="..szUrl.."#/invite"
    if not bTestEnv then
        szShareUrl = "https://jx3.xoyo.com/p/m/2024/04/25/final-test/index.html?params="..szUrl.."#/invite"
    end
    if Platform.IsMobile() then
        XGSDK_Share(szUid, szRoleId, szChannel, szShareUrl, szTitle, szContent, "", filePath)
    else
        SetClipboard(szShareUrl)
        TipsHelper.ShowNormalTip("已复制分享链接至剪切板")
    end
    XGSDK_TrackEvent("game.share.liebianActivity", "share", {{"conditionType", self.szConditionType}})
end

-- -------------------------------- 二测裂变活动 end -------------------------------------------

-- -------------------------------- 校服裂变活动 begin-------------------------------------------
function UISharePopView:CopyLink()
    local szShareUrl = self:GetAutoShareUrl()
    SetClipboard(szShareUrl)
    TipsHelper.ShowNormalTip("邀请链接复制成功，快发送给好友吧！")
    XGSDK_TrackEvent("game.share.liebianActivity", "share", {})
end

function UISharePopView:SendSchool(szChannel)
    local folder = GetStreamAdaptiveDirPath(UIHelper.GBKToUTF8(GetFullPath("dcim/")))
    CPath.MakeDir(folder)
    local filePath = folder.."ImgSchoolShare.png"
    if not Lib.IsPNGFileExist(filePath) then
        --拷贝文件
        cc.FileUtils:getInstance():pakV5WriteFileToLocal("mui/Texture/HuaELouReward/ImgWeChatShare.png" ,"dcim/ImgSchoolShare.png")
    end
    local szUid = Login_GetUnionAccount()
    local player = GetClientPlayer()
    local szRoleId = "NoRole"
    if player then
        szRoleId = tostring(player.dwID)
    end
    local szTitle = "千套校服，免费任选"
    local szContent = "手机上可以玩剑网3啦，千套校服免费任选！快邀请你的朋友一起来玩！"

    local szShareUrl = self:GetAutoShareUrl()
    if Platform.IsMobile() then
        XGSDK_Share(szUid, szRoleId, szChannel, szShareUrl, szTitle, szContent, "", filePath)
    else
        -- local szUrl = UIHelper.UTF8ToGBK("手机上可以玩剑网3啦！现在参与免费领校服活动，千套校服免费任选！还有概率获得iPhone 15 Pro，京东卡等惊喜好礼。") .. szShareUrl
        SetClipboard(szShareUrl)
        TipsHelper.ShowNormalTip("邀请链接复制成功，快发送给好友吧！")
    end
    XGSDK_TrackEvent("game.share.liebianActivity", "share", {})
end

-- -------------------------------- 校服裂变活动 end-------------------------------------------

return UISharePopView