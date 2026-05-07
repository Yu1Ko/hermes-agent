-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: CurrencyData
-- Date: 2022-12-29 15:08:10
-- Desc: 货币统一数据,方便管理
-- ---------------------------------------------------------------------------------

CurrencyData = CurrencyData or {}
local self = CurrencyData
-------------------------------- 消息定义 --------------------------------
CurrencyData.Event = {}
CurrencyData.Event.XXX = "CurrencyData.Msg.XXX"

CurrencyNameToType = {
    ["money"] = CurrencyType.Money,
    ["train"] = CurrencyType.Train,
    ["vigor"] = CurrencyType.Vigor,
    ["experience"] = CurrencyType.Experience,
    ["titlepoint"] = CurrencyType.TitlePoint,
    ["prestige"] = CurrencyType.Prestige,
    ["justice"] = CurrencyType.Justice,
    ["coin"] = CurrencyType.Coin,
    ["storepoint"] = CurrencyType.StorePoint,
    ["gangfunds"] = CurrencyType.GangFunds,
    ["tongfund"] = CurrencyType.GangFunds,
    ["architecture"] = CurrencyType.Architecture,
    ["coinshopvoucher"] = CurrencyType.CoinShopVoucher,
    ["achievementpoint"] = CurrencyType.AchievementPoint,
    ["reputation"] = CurrencyType.Reputation,
    ["tongresource"] = CurrencyType.TongResource,
    ["normalfragment"] = CurrencyType.NormalFragment,
    ["FishExp"] = CurrencyType.FishExp,
    ["FlowerExp"] = CurrencyType.FlowerExp,
    ["SellerExp"] = CurrencyType.SellerExp,
    ["PersonAthScore"] = CurrencyType.PersonAthScore,
    ["WinItem"] = CurrencyType.WinItem,
    ["Contribution"] = CurrencyType.Contribution,
    ["LeYouBi"] = CurrencyType.LeYouBi,
    ["FaceVouchers"] = CurrencyType.FaceVouchers,
    ["contribution"] = CurrencyType.Contribution,
    ["prestigelimit"] = CurrencyType.PrestigeLimit,
    ["examprint"] = CurrencyType.ExamPrint,
    ["Rover"] = CurrencyType.Rover,
    ["HomelandToken"] = CurrencyType.HomelandToken,
    ["SandstormAward"] = CurrencyType.SandstormAward,
    ["ArenaTowerAward"] = CurrencyType.ArenaTowerAward,
    ["SeasonHonorXiuXian"] = CurrencyType.SeasonHonorXiuXian,
    ["SeasonHonorMiJing"] = CurrencyType.SeasonHonorMiJing,
    ["SeasonHonorPVP"] = CurrencyType.SeasonHonorPVP
}
CurrencyData.szGetDesc = "获取"
CurrencyData.szSourceDesc = "来源"
CurrencyData.szPurposeDesc = "用途"
CurrencyData.tbImageBigIcon = {
    [CurrencyType.Money] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_Img_JinQianAll_Big.png",
    [CurrencyType.Train] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_XiuWei_Big.png",
    [CurrencyType.Vigor] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_JingLi_Big.png",
    [CurrencyType.Experience] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_YueLi_Big.png",
    [CurrencyType.TitlePoint] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_ZhanJieJiFen_Big.png",
    [CurrencyType.Prestige] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_WeiMingDian_Big.png",
    [CurrencyType.Justice] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_XiaYiZhi_Big.png",
    [CurrencyType.Coin] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_TongBao_Big.png",
    [CurrencyType.StorePoint] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_JiFen_Big.png",
    [CurrencyType.GangFunds] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_BangHui_Big.png",
    [CurrencyType.TotalGangFunds] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_BangHui_Big.png",
    [CurrencyType.Architecture] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_YuanZhaiBi_Big.png",
    [CurrencyType.CoinShopVoucher] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_TongRenYinPiao_Big.png",
    [CurrencyType.AchievementPoint] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img-ZiLi_Big.png",
    [CurrencyType.MentorAward] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_ShiTu_Big.png",
    [CurrencyType.Reputation] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_ShengWang_Big.png",
    [CurrencyType.TongResource] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_ShengWang_Big.png",
    [CurrencyType.NormalFragment] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_JieLu.png",
    [CurrencyType.FishExp] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_YueLi_Big.png",
    [CurrencyType.FlowerExp] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_YueLi_Big.png",
    [CurrencyType.SellerExp] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_YueLi_Big.png",
    [CurrencyType.PersonAthScore] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_JingJiFen_Big",
    [CurrencyType.WinItem] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_ShengWang_Big",
    [CurrencyType.Contribution] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_xiuxian_big.png",
    [CurrencyType.LeYouBi] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_leyoubi_big.png",
    [CurrencyType.FaceVouchers] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_NieLian_Big.png",
    [CurrencyType.PrestigeLimit] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_WeiMingDian_Big.png",
    [CurrencyType.FeiShaWand] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_FeiShaLing_Big.png",
    [CurrencyType.ExamPrint] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_QiJing_Big.png",
    [CurrencyType.HomelandToken] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_Dsnfl.png",
    [CurrencyType.DungeonTowerAward] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_Xlzy1.png",
    [CurrencyType.Rover] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_Lkj.png",
    [CurrencyType.ArenaTowerAward] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_YangDao_MingZhengYu.png",
    [CurrencyType.TianJiToken] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_YangDao_TianJiChou.png",
    [CurrencyType.MonopolyCoin] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_YangDao_TianJiChou.png",
    [CurrencyType.MonopolyMoney] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_YangDao_TianJiChou.png",
    [CurrencyType.MonopolyPoint] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_YangDao_TianJiChou.png",
    [CurrencyType.TongLeaguePoint] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_ZhanxunLabel.png",
    [CurrencyType.WeekAward] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_ZhouKe.png",
    [CurrencyType.SeasonHonorXiuXian] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_PvxB.png",
    [CurrencyType.SeasonHonorMiJing] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_PveB.png",
    [CurrencyType.SeasonHonorPVP] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_PvpB.png",
    [CurrencyType.ZhuiGanShopAward] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_ZhuiGan.png",
}

CurrencyData.tbImageSmallIcon = {
    [CurrencyType.Money] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_Img_JinQianAll.png",
    [CurrencyType.Train] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_XiuWei.png",
    [CurrencyType.Vigor] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_JingLi.png",
    [CurrencyType.Experience] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YueLi.png",
    [CurrencyType.TitlePoint] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_ZhanJieJiFen.png",
    [CurrencyType.Prestige] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_WeiMingDian.png",
    [CurrencyType.Justice] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_XiaYiZhi.png",
    [CurrencyType.Coin] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_TongBao.png",
    [CurrencyType.StorePoint] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_JiFen.png",
    [CurrencyType.GangFunds] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_BangHui.png",
    [CurrencyType.TotalGangFunds] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_BangHui.png",
    [CurrencyType.Architecture] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YuanZhaiBi.png",
    [CurrencyType.CoinShopVoucher] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_TongRenYinPiao.png",
    [CurrencyType.AchievementPoint] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img-ZiLi.png",
    [CurrencyType.FeiShaWand] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_FeiShaLing.png",
    [CurrencyType.MentorAward] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_ShiTu.png",
    [CurrencyType.Reputation] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_ShengWang.png",
    [CurrencyType.TongResource] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_ShengWang.png",
    [CurrencyType.NormalFragment] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_JieLu.png",
    [CurrencyType.FishExp] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YueLi.png",
    [CurrencyType.FlowerExp] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YueLi.png",
    [CurrencyType.SellerExp] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YueLi.png",
    [CurrencyType.PersonAthScore] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_JingJiFen",
    [CurrencyType.WinItem] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_ShengWang",
    [CurrencyType.Contribution] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_xiuxian.png",
    [CurrencyType.LeYouBi] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_leyoubi.png",
    [CurrencyType.FaceVouchers] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_NieLian.png",
    [CurrencyType.ExamPrint] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_QiJing.png",
    [CurrencyType.HomelandToken] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Dsnfl.png",
    [CurrencyType.DungeonTowerAward] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Xlzy1.png",
    [CurrencyType.Rover] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Lkj.png",
    [CurrencyType.ArenaTowerAward] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YangDao_MingZhengYu_s.png",
    [CurrencyType.TianJiToken] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YangDao_TianJiChou_s.png",
    [CurrencyType.MonopolyCoin] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YangDao_TianJiChou_s.png",
    [CurrencyType.MonopolyMoney] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YangDao_TianJiChou_s.png",
    [CurrencyType.MonopolyPoint] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YangDao_TianJiChou_s.png",
    [CurrencyType.TongLeaguePoint] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_ZhanxunLabel.png",
    [CurrencyType.WeekAward] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_ZhouKe.png",
    [CurrencyType.SeasonHonorXiuXian] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_PvxB.png",
    [CurrencyType.SeasonHonorMiJing] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_PveB.png",
    [CurrencyType.SeasonHonorPVP] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_PvpB.png",
    [CurrencyType.ZhuiGanShopAward] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_ZhuiGan.png",
}

CurrencyData.tbSourceDesc = {
    -- 来源
    [CurrencyType.Money] = "<color=#AED6E0>当前金钱携带上限为<color=#FFEA88>5000万金</c>，超出该上限，将不能再继续获取得金钱<color=#FFEA88>（1金砖=10000金）</c>\n金币主要来源于任务，历程，副本以及活动奖励</c>",
    [CurrencyType.Train] = "<color=#AED6E0>修为主要通过任务，门派活动及生活以及药品</c>",
    [CurrencyType.Vigor] = "<color=#AED6E0>角色精力：\n为该角色专属，可通过团队秘境、名剑大会、龙门绝境、日常任务等途径获得。\n账号精力：\n为本区服所有角色共享，随时间自然回复不占周上限，需要绑定实体密保锁或手机版密保锁方可使用。详情请按打开账号安全中心查看</c>",
    [CurrencyType.Experience] = "<color=#AED6E0>阅历主要来源于任务，历程及副本奖励</c>",
    [CurrencyType.TitlePoint] = "<color=#AED6E0>战阶积分主要来源于名剑大会、各种阵营活动与阵营任务奖励</c>",
    [CurrencyType.Prestige] = "<color=#AED6E0>威名点主要来源于名剑大会、各种阵营活动与阵营任务奖励威名点周上限主要来源于战阶排名奖励、名剑大会、战场、逐鹿中原、阴山商路、亲传师父奖励等</c>",
    [CurrencyType.Justice] = "<color=#AED6E0>侠行点主要来源秘境首领击败</c>",
    [CurrencyType.Coin] = "<color=#AED6E0>通宝主要来源于付费充值</c>",
    [CurrencyType.StorePoint] = "<color=#AED6E0>充值月卡或点卡可额外获得积分，月/点卡面额（原价）积分获得=1:2；使用通宝消费或使用不绑定道具实穿后可额外获得积分，可获得积分数详见商品/道具内容提示</c>",
    [CurrencyType.Architecture] = "<color=#AED6E0>园宅币主要来源于家园种植、家园日常、宠物游历等玩法</c>",
    [CurrencyType.FeiShaWand] = "<color=#AED6E0>飞沙令碎片主要来源于绝境战场</c>",
    [CurrencyType.MentorAward] = "<color=#AED6E0>桃李值主要来源于师徒对抗、协作、休闲活动时获得</c>",
    [CurrencyType.GangFunds] = "<color=#AED6E0>帮会资金主要来源于帮会成员完成游戏内各种任务，捐献，帮会休闲玩法获取帮会资金</c>",
    [CurrencyType.TotalGangFunds] = "<color=#AED6E0>帮会资金主要来源于帮会成员完成游戏内各种任务，捐献，帮会休闲玩法获取帮会资金</c>",
    [CurrencyType.Reputation] = "<color=#AED6E0>声望可以通过地图日常声望任务，公共日常声望任务，秘境挑战，阵营矿车日常声望任务等获取声望</c>",
    [CurrencyType.TongResource] = "<color=#AED6E0>载具物资主要来源于对抗任务及活动</c>",
    [CurrencyType.NormalFragment] = "<color=#AED6E0>某个领域的点数积累满后，该玩法的剩余点数将会转换为通用点数，继续参与对应玩法将获得通用点数</c>",
    [CurrencyType.FishExp] = "<color=#AED6E0>主要来源于每日垂钓捕鱼</c>",
    [CurrencyType.FlowerExp] = "<color=#AED6E0>主要来源于每日收花订单和调香</c>",
    [CurrencyType.SellerExp] = "<color=#AED6E0>主要来源于每日大掌柜烹饪和出摊售卖</c>",
    [CurrencyType.PersonAthScore] = "<color=#AED6E0>个人竞技分来源于名剑大会，2对2、3对3、5对5，代表对应的竞技实力</c>",
    [CurrencyType.WinItem] = "<color=#AED6E0>昭武符·日来源于各种竞技玩法、阵营活动与阵营任务奖励</c>",
    [CurrencyType.Contribution] = "<color=#AED6E0>主要来源于各类休闲玩法</c>",
    [CurrencyType.LeYouBi] = "<color=#AED6E0>主要来源于乐游记相关玩法</c>",
    [CurrencyType.PrestigeLimit] = "",
    [CurrencyType.AchievementPoint] = "<color=#AED6E0>主要来源于完成隐元秘鉴中成就的奖励</c>",
    [CurrencyType.ExamPrint] = "<color=#AED6E0>奇境宝钞主要来源于绝境战场寻宝模式，其中【纷争】模式获得的奇境宝钞不占用每周上限。</c>",
    [CurrencyType.WeekAward] = "<color=#AED6E0>主要来源于每周活跃奖励</c>",
    [CurrencyType.SeasonHonorXiuXian] = "<color=#AED6E0>主要来源于休闲任务奖励</c>",
    [CurrencyType.SeasonHonorMiJing] = "<color=#AED6E0>主要来源于秘境任务奖励</c>",
    [CurrencyType.SeasonHonorPVP] = "<color=#AED6E0>主要来源于竞技任务奖励</c>",

    [CurrencyType.Rover] = "",
    [CurrencyType.DungeonTowerAward] = "",
    [CurrencyType.HomelandToken] = "",
    [CurrencyType.TongLeaguePoint] = "",
    [CurrencyType.ArenaTowerAward] = "<color=#AED6E0>主要来源于扬刀大会玩法每周首通奖励</c>",
    [CurrencyType.TianJiToken] = "<color=#AED6E0>主要来源于扬刀大会玩法局内通关奖励</c>",
    [CurrencyType.MonopolyCoin] = "<color=#AED6E0>主要来源于大富翁玩法局内通关奖励</c>",
    [CurrencyType.MonopolyMoney] = "<color=#AED6E0>主要来源于大富翁玩法局内</c>",
    [CurrencyType.MonopolyPoint] = "<color=#AED6E0>主要来源于大富翁玩法局内</c>",
    [CurrencyType.ZhuiGanShopAward] = "",
}

CurrencyData.tbPurposeDesc = {
    -- 用途
    [CurrencyType.Money] = "<color=#AED6E0>金币可以在商人处购买物品</c>",
    [CurrencyType.Train] = "<color=#AED6E0>修为主要用于装备栏精炼</c>",
    [CurrencyType.Vigor] = "<color=#AED6E0>精力可以用于生活技艺制造，书籍抄录</c>",
    [CurrencyType.Experience] = "<color=#AED6E0>阅历用于提升等级</c>",
    [CurrencyType.TitlePoint] = "<color=#AED6E0>战阶积分主要用于提升战阶等级</c>",
    [CurrencyType.Prestige] = "<color=#AED6E0>威名点主要用于兑换对抗装备</c>",
    [CurrencyType.Justice] = "<color=#AED6E0>侠行点主要用于兑换秘境装备</c>",
    [CurrencyType.Coin] = "<color=#AED6E0>通宝主要用于商城消费</c>",
    [CurrencyType.StorePoint] = "<color=#AED6E0>商城积分主要用于商城兑换物品和道具</c>",
    [CurrencyType.Architecture] = "<color=#AED6E0>园宅币可以用于购买家园建筑，家具等</c>",
    [CurrencyType.FeiShaWand] = "<color=#AED6E0>飞沙令碎片主要用于飞沙令兑换商店购买装备、挂件、强化道具等</c>",
    [CurrencyType.MentorAward] = "<color=#AED6E0>桃李值主要用于在扬州敬师堂纪天下处购买跟宠、挂件等物资</c>",
    [CurrencyType.GangFunds] = "<color=#AED6E0>帮会资金可以在帮会界面解锁新的帮会等级，天工树</c>",
    [CurrencyType.TotalGangFunds] = "<color=#AED6E0>帮会资金可以在帮会界面解锁新的帮会等级，天工树</c>",
    [CurrencyType.Reputation] = "<color=#AED6E0>声望达到尊敬或者钦佩以后，侠士可以去对应地图的声望商换取自己喜欢的挂件、家具、马具、称号、知交等奖励</c>",
    [CurrencyType.TongResource] = "<color=#AED6E0>载具物资可以用于在逐鹿中原活动中购买载具道具</c>",
    [CurrencyType.NormalFragment] = "<color=#AED6E0>通用点数会有50%损耗转换成另一个玩法点数</c>",
    [CurrencyType.FishExp] = "<color=#AED6E0>垂钓客阅历用于提升垂钓客等级，垂钓客等级无法超过家园等级</c>",
    [CurrencyType.FlowerExp] = "<color=#AED6E0>调香师阅历用于提升调香师等级，调香师等级无法超过家园等级</c>",
    [CurrencyType.SellerExp] = "<color=#AED6E0>大掌柜阅历用于提升大掌柜等级，大掌柜等级无法超过家园等级</c>",
    [CurrencyType.PersonAthScore] = "<color=#AED6E0>个人竞技分主要用于提升名剑大会的段位，段位越高可获取的奖励越好</c>",
    [CurrencyType.WinItem] = "<color=#AED6E0>昭武符·日主要用于获取威名点周上限</c>",
    [CurrencyType.Contribution] = "<color=#AED6E0>休闲点主要用于兑换休闲装备</c>",
    [CurrencyType.LeYouBi] = "<color=#AED6E0>乐游币可在乐游记商店中购买道具</c>",
    [CurrencyType.FaceVouchers] = "<color=#AED6E0>捏脸时优先消耗此货币，1通宝代金币=1通宝</c>",
    [CurrencyType.CoinShopVoucher] = "<color=#AED6E0>购买同人嘉年华外观时优先消耗此货币，1佟仁银票=1通宝。永久有效。</c>",
    [CurrencyType.PrestigeLimit] = "",
    [CurrencyType.ExamPrint] = "<color=#AED6E0>奇境宝钞主要用于在林海寻宝商店中购买林海寻宝所需物资</c>",
    [CurrencyType.ArenaTowerAward] = "<color=#AED6E0>可兑换扬刀大会玩法相关奖励及专属宝箱</c>",
    [CurrencyType.TianJiToken] = "<color=#AED6E0>扬刀大会玩法内专属，可用于祈卦及特殊卦象效果消耗</c>",
    [CurrencyType.MonopolyCoin] = "<color=#AED6E0>可兑换大富翁玩法相关奖励及专属宝箱</c>",
    [CurrencyType.MonopolyMoney] = "<color=#AED6E0>可在大富翁玩法内购买</c>",
    [CurrencyType.MonopolyPoint] = "<color=#AED6E0>可在大富翁玩法内购买</c>",
    [CurrencyType.WeekAward] = "<color=#AED6E0>周行令主要用于商城兑换物品和道具</c>",
    [CurrencyType.ZhuiGanShopAward] = "",
}

CurrencyData.tbGetLimit = {
    --账号精力：hPlayer.nCurrentStamina, hPlayer.nMaxStamina
    [CurrencyType.Train] = "<color=#AED6E0>修为：<color=#FFEA88>%s/%s</c></c>",
    [CurrencyType.Vigor] = "<color=#AED6E0>精力：<color=#FFEA88>%s/%s</c> \n账号精力：<color=#FFEA88>%s/%s</c> \n角色精力：<color=#FFEA88>%s/%s</c> \n本周还可获得：<color=#FFEA88>%s</c></c>",
    [CurrencyType.TitlePoint] = "<color=#AED6E0>战阶积分：<color=#FFEA88>%s</c> \n至下一级战阶升级进度：<color=#FFEA88>%s</c></c>",
    [CurrencyType.Prestige] = "<color=#AED6E0>威名点：<color=#FFEA88>%s/%s</c> \n本周还可获得：<color=#FFEA88>%s</c> \n本周未用完的周上限将累积到下周周上限中\n本周可获威名点周上限：<color=#FFEA88>%s</c>%s</c>",
    [CurrencyType.Justice] = "<color=#AED6E0>侠行点：<color=#FFEA88>%s/%s</c> </c>",
    [CurrencyType.FeiShaWand] = "<color=#AED6E0>飞沙令：<color=#FFEA88>%s/%s</c> </c>",
    [CurrencyType.MentorAward] = "<color=#AED6E0>桃李值：<color=#FFEA88>%s/%s</c></c>",
    [CurrencyType.Architecture] = "<color=#AED6E0>园宅币：<color=#FFEA88>%s/%s</c> </c>",
    [CurrencyType.Contribution] = "<color=#AED6E0>休闲点：<color=#FFEA88>%s/%s</c> </c>",
    [CurrencyType.PrestigeLimit] = "",
    [CurrencyType.ExamPrint] = "<color=#AED6E0>奇境宝钞：<color=#FFEA88>%s/%s</c> </c>",
    -- [CurrencyType.Reputation] = "",
    [CurrencyType.Rover] = "<color=#AED6E0>浪客笺：<color=#FFEA88>%s/%s</c> </c>",
    [CurrencyType.DungeonTowerAward] = "<color=#AED6E0>修罗之印：<color=#FFEA88>%s/%s</c> </c>",
    [CurrencyType.HomelandToken] = "<color=#AED6E0>大水南方令：<color=#FFEA88>%s/%s</c> </c>",
    [CurrencyType.ArenaTowerAward] = "<color=#AED6E0>鸣铮玉：<color=#FFEA88>%s/%s</c></c>",
    [CurrencyType.TianJiToken] = "<color=#AED6E0>天机筹：<color=#FFEA88>%s/%s</c></c>",
    [CurrencyType.MonopolyCoin] = "<color=#AED6E0>大富翁代币：<color=#FFEA88>%s/%s</c></c>",
    [CurrencyType.TongLeaguePoint] = "<color=#AED6E0>功勋点：<color=#FFEA88>%s/%s</c> </c>",
    [CurrencyType.WeekAward] = "<color=#AED6E0>周行令：<color=#FFEA88>%s/%s</c> </c>",
    [CurrencyType.ZhuiGanShopAward] = "<color=#AED6E0>追云令：<color=#FFEA88>%s/%s</c> </c>",
    [CurrencyType.SeasonHonorXiuXian] = "<color=#AED6E0>休闲通令：<color=#FFEA88>%s/%s</c> </c>",
    [CurrencyType.SeasonHonorMiJing] = "<color=#AED6E0>秘境通令：<color=#FFEA88>%s/%s</c> </c>",
    [CurrencyType.SeasonHonorPVP] = "<color=#AED6E0>对抗通令：<color=#FFEA88>%s/%s</c> </c>",
}

-- 提示跳转配置
CurrencyData.tbTipGoTo = {
    [CurrencyType.Vigor] = --精力→生活技能面板
    {
        szBtnName = "使用",
        fnGoto = function()
            if UIMgr.GetView(VIEW_ID.PanelLifeMain) then
                TipsHelper.ShowNormalTip("已在当前界面")
            else
                UIMgr.Open(VIEW_ID.PanelLifeMain)
            end
        end
    },
    [CurrencyType.TitlePoint] = --战阶→战阶排名说明-- 跳大侠之路阵营页签
    {
        szBtnName = "使用",
        fnGoto = function()
            local player = g_pClientPlayer
            if not player then
                return
            end
            local nCamp = player.nCamp
            if nCamp == CAMP.GOOD or nCamp == CAMP.EVIL then
                UIMgr.Open(VIEW_ID.PanelRoadCollection, COLLECTION_PAGE_TYPE.CAMP)
            else
                TipsHelper.ShowNormalTip("侠士还未加入阵营")
            end
        end
    },
    [CurrencyType.Prestige] = --威望→威望商店
    {
        szBtnName = "使用",
        fnGoto = function()
            local player = g_pClientPlayer
            if not player then
                return
            end
            local nCamp = player.nCamp
            if nCamp == CAMP.GOOD then
                CurrencyData.GoToShop(60, 1002, "已在当前商店")
            elseif nCamp == CAMP.EVIL then
                CurrencyData.GoToShop(60, 1001, "已在当前商店")
            else
                CurrencyData.GoToShop(60, 1001, "已在当前商店")
            end
        end
    },
    [CurrencyType.Justice] = --侠义→侠义商店
    {
        szBtnName = "使用",
        fnGoto = function()
            CurrencyData.GoToShop(61, 922, "已在当前商店")
        end
    },
    [CurrencyType.MentorAward] = --师徒→师徒商店
    {
        szBtnName = "使用",
        fnGoto = function()
            CurrencyData.GoToShop(62, 1184, "已在当前商店")
        end
    },
    [CurrencyType.Contribution] = --休闲点→休闲点商店
    {
        szBtnName = "使用",
        fnGoto = function()
            CurrencyData.GoToShop(62, 1478, "已在当前商店")
        end
    },
    [CurrencyType.Architecture] = --园宅→家园商店
    {
        szBtnName = "使用",
        fnGoto = function()
            CurrencyData.GoToShop(0, 1294, "已在当前商店")
        end
    },
    [CurrencyType.Money] = --金钱→其他商店
    {
        szBtnName = "使用",
        fnGoto = function()
            CurrencyData.GoToShop(66, nil, "已在当前商店")
        end
    },
    [CurrencyType.Train] = --修为→强化-装备栏精炼
    {
        szBtnName = "使用",
        fnGoto = function()
            if UIMgr.GetView(VIEW_ID.PanelPowerUp) then
                TipsHelper.ShowNormalTip("已在当前界面")
            else
                UIMgr.Open(VIEW_ID.PanelPowerUp)
            end
        end
    },
    [CurrencyType.Coin] = --通宝→外观
    {
        szBtnName = "使用",
        fnGoto = function()
            if UIMgr.GetView(VIEW_ID.PanelExteriorMain) then
                TipsHelper.ShowNormalTip("已在当前界面")
            else
                CoinShopData.Open()
            end
        end
    },
    [CurrencyType.AchievementPoint] = --资历→成就
    {
        szBtnName = "使用",
        fnGoto = function()
            if UIMgr.GetView(VIEW_ID.PanelAchievementMian) then
                TipsHelper.ShowNormalTip("已在当前界面")
            else
                UIMgr.Open(VIEW_ID.PanelAchievementMian)
            end
        end
    },
    [CurrencyType.ExamPrint] = -- 奇境宝钞→寻宝商店
    {
        szBtnName = "使用",
        fnGoto = function()
            ShopData.OpenSystemShopGroup(27, 1536)
        end
    },
    [CurrencyType.ArenaTowerAward] =  -- 鸣铮玉→鸣铮玉商店
    {
        szBtnName = "使用",
        fnGoto = function()
            ArenaTowerData.OpenArenaTowerAwardShop()
        end
    },
    [CurrencyType.WeekAward] =
    {
        szBtnName = "使用",
        fnGoto = function()
            CurrencyData.GoToShop(62, 1564, "已在当前商店")
        end
    },

    [CurrencyType.FeiShaWand] =
    {
        szBtnName = "使用",
        fnGoto = function()
            CurrencyData.GoToShop(61, 1134, "已在当前商店")
        end
    },
    [CurrencyType.Rover] =
    {
        szBtnName = "使用",
        fnGoto = function()
            CurrencyData.GoToShop(61, 1222, "已在当前商店")
        end
    },
    [CurrencyType.HomelandToken] =
    {
        szBtnName = "使用",
        fnGoto = function()
            local tUseSource = Table_GetCurrencyShopUseList(CurrencyType.HomelandToken)
            local tUse = ItemData.GetCurrencySourceShop(tUseSource)
            if tUse[1] then
                Event.Dispatch("EVENT_LINK_NOTIFY", tUse[1].szLinkInfo)
            end
        end
    },
    [CurrencyType.DungeonTowerAward] =
    {
        szBtnName = "使用",
        fnGoto = function()
            CurrencyData.GoToShop(61, 1387, "已在当前商店")
        end
    },
    [CurrencyType.TongLeaguePoint] =
    {
        szBtnName = "使用",
        fnGoto = function()
            CurrencyData.GoToShop(61, 1561, "已在当前商店")
        end
    },
}


--当前打开界面是否为背包
CurrencyData.bCurrentBagView = false

function CurrencyData.Init()

end

function CurrencyData.UnInit()

end

function CurrencyData.OnLogin()

end

function CurrencyData.OnFirstLoadEnd()

end

-- 获取当前货币数量
function CurrencyData.GetCurCurrencyCount(type)
    local player = GetClientPlayer()
    if not player or not type then
        return 0
    end

   if type == CurrencyType.Coin then
        return player.nCoin
    elseif type == CurrencyType.TitlePoint then
        return player.nTitlePoint
    elseif type == CurrencyType.Train then
        return player.nCurrentTrainValue
    elseif type == CurrencyType.Money then
        return self.UnpackMoneyEx(player.GetMoney())
    elseif type == CurrencyType.Experience then
        return player.nExperience
    elseif type == CurrencyType.MentorAward then
        return player.nMentorAward
    --elseif type == CurrencyType.ApprenticeEquipsScore then
    --    return player.dwTAEquipsScore
    elseif type == CurrencyType.Vigor then
        return player.nVigor + player.nCurrentStamina
    --elseif type == CurrencyType.TongRenBi then
    --    return player.GetExtPoint(663)
    elseif type == CurrencyType.StorePoint then
        return player.GetRewards()
    elseif type == CurrencyType.CoinShopVoucher then
        local tFristVoucher = CoinShopData.GetCurrentCoinShopVoucher()
        return tFristVoucher and tFristVoucher.nCount or 0
    elseif type == CurrencyType.GangFunds then
        return TongData.HavePlayerJoinedTong() and TongData.GetTodayRemainFund() or 0
   elseif type == CurrencyType.TotalGangFunds then
       return TongData.HavePlayerJoinedTong() and TongData.GetFund() or 0
    elseif type == CurrencyType.AchievementPoint then
        return player.GetAchievementRecord()
    elseif type == CurrencyType.LeYouBi then
        local LeYouBiItemNum = 0
        local tLeYouBiItem = {48845, 49329, 50571, 50659, 50671, 66349, 66494}
        for k, v in pairs(tLeYouBiItem) do
            if player.GetItemAmountInAllPackages(5, v) > 0 then
                LeYouBiItemNum = player.GetItemAmountInAllPackages(5, v)
            end
        end
        return LeYouBiItemNum
    elseif type == CurrencyType.FaceVouchers then
        local nVouchers = 0
        if GetFaceLiftManager() then
            nVouchers = GetFaceLiftManager().GetVouchers()
        end
        return nVouchers
    elseif type == CurrencyType.NormalFragment then
        local nNormalFragment = 0
        if HomelandAchievement then
            nNormalFragment = HomelandAchievement.GetNormalFragment()
        end
        return nNormalFragment
    elseif type == CurrencyType.TianJiToken then
        local nCoinInGame, _ = ArenaTowerData.GetCoinInGameInfo()
        return nCoinInGame
    elseif type == CurrencyType.MonopolyCoin then
        local nCoin = player.GetCurrency(CURRENCY_TYPE.ACTCOINDFW) or 0
        return nCoin
    elseif type == CurrencyType.MonopolyMoney then
        local nPlayerIndex = MonopolyData.GetClientPlayerIndex() or 0
        local nMoney = DFW_GetPlayerMoney(nPlayerIndex) or 0
        return nMoney
    elseif type == CurrencyType.MonopolyPoint then
        local nPlayerIndex = MonopolyData.GetClientPlayerIndex() or 0
        local nPoint = DFW_GetPlayerPointNum(nPlayerIndex) or 0
        return nPoint
    end

    local nType = Currency_Base.GetCurrencyTypeID(type)
    if not nType then
        LOG.ERROR("no type found " .. type)
        return 0
    end
    return Currency_Base.GetCurrencyNumber(type)
end

function CurrencyData.GetTotleranceCount(type)
    local player = GetClientPlayer()
    if not player then
        return 0
    end
    if type == CurrencyType.MentorAward then
        return player.AcquiredMentorValue
    end
end


-- 获取上限
function CurrencyData.GetCurCurrencyLimit(type)
    local player = GetClientPlayer()
    if not player then
        return 0
    end

    if type == CurrencyType.Prestige then
        local nCur, nTotal = GDAPI_CampZhanghunCheng()
        if nTotal > 0 then
            return player.nCurrentPrestige , player.GetMaxPrestige(), player.GetPrestigeRemainSpace(), player.GetPrestigeMaxExtSpace() , string.format("\n本周可用战魂·承：<color=#FFEA88>%d/%d</c>",nCur , nTotal)
        else
            return player.nCurrentPrestige , player.GetMaxPrestige(), player.GetPrestigeRemainSpace(), player.GetPrestigeMaxExtSpace() , ""
        end
    elseif type == CurrencyType.Train then
        return player.nCurrentTrainValue , player.nMaxTrainValue
    elseif type == CurrencyType.Vigor then
        --精力：%s/%s /n账号精力：%s/%s /n角色精力：%s/%s /n本周还可获得：%s
        return player.nVigor + player.nCurrentStamina, player.GetMaxVigor() +player.nMaxStamina ,player.nCurrentStamina, player.nMaxStamina,player.nVigor, player.GetMaxVigor(), player.GetVigorRemainSpace()
    elseif type == CurrencyType.TitlePoint then
        local maxPointPercentage = player.GetRankPointPercentage()
        return player.nTitlePoint ,  maxPointPercentage == -1 and "已达最高战阶等级" or string.format("%s%%",tostring(maxPointPercentage))
    elseif type == CurrencyType.TianJiToken then
        local nCoinInGame, nMaxCoinInGame = ArenaTowerData.GetCoinInGameInfo()
        return nCoinInGame, nMaxCoinInGame
    elseif type == CurrencyType.MonopolyCoin then
        local nCoin = player.GetCurrency(CURRENCY_TYPE.ACTCOINDFW) or 0
        local nMaxCoin = player.GetMaxCurrency(CURRENCY_TYPE.ACTCOINDFW) or 0
        return nCoin, nMaxCoin
    end

    local nType = Currency_Base.GetCurrencyTypeID(type)
    if not nType then
        LOG.ERROR("no type found " .. type)
        return 0
    end

    return Currency_Base.GetCurrencyNumber(type), Currency_Base.GetCurrencyMaxNumber(type), Currency_Base.GetCurrencyWeekRemain(type)
end

function CurrencyData.UnpackMoneyEx(t)
    local nGold = t.nGold or 0
    local nGoldB = math.floor(nGold / 10000)
    return nGoldB, (nGold - nGoldB * 10000), (t.nSilver or 0), (t.nCopper or 0)
end

function CurrencyData.IsCurrencyType(szName)
    for k, v in pairs(CurrencyType) do
        if v == szName then
            return true
        end
    end
    return false
end

function CurrencyData.GetCurrencyTypeByName(szName)
    if CurrencyNameToType[szName] then
        return CurrencyNameToType[szName]
    end
    
    szName = string.lower(szName)
    return CurrencyNameToType[szName] or CurrencyType.None
end

function CurrencyData.GetCurCurrencyIconPath()
    local moneyIcon = ""
    local nGoldB, nGold, nSilver, nCopper = CurrencyData.GetCurCurrencyCount(CurrencyType.Money)
    if nGoldB > 0 then
        moneyIcon = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_Zhuan_Big.png";
    elseif nGold > 0 then
        moneyIcon = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_Jin_Big.png";
    elseif nSilver > 0 then
        moneyIcon = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_Yin_Big.png";
    else
        moneyIcon = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_Tong_Big.png";
    end
    return moneyIcon
end

function CurrencyData.GoToShop(nOpenSystemID, nShopID, szTipContent)
    if not SystemOpen.IsSystemOpen(nOpenSystemID, true) then
        return
    end

    local storeView = UIMgr.GetViewScript(VIEW_ID.PanelPlayStore)
    if storeView then
        if storeView.nShopID == nShopID then
            TipsHelper.ShowNormalTip(szTipContent)
            return
        end
    end

    ShopData.OpenSystemShopGroup(1, nShopID)
end

function CurrencyData.ShowCurrencyHoverTips(nodeLayout, szCurrencyType)
    if CurrencyData.tbSourceDesc[szCurrencyType] then
        local _, scriptTips = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, nodeLayout)
        scriptTips:OnInitCurrency(szCurrencyType)
    else
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetTipsWithSubtitle, nodeLayout, szCurrencyType)
    end
end

function CurrencyData.ShowCurrencyHoverTipsInDir(nodeLayout, layoutDir, szCurrencyType)
    if CurrencyData.tbSourceDesc[szCurrencyType] then
        local _, scriptTips = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, nodeLayout, layoutDir)
        scriptTips:OnInitCurrency(szCurrencyType)
    else
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetTipsWithSubtitle, nodeLayout, layoutDir, szCurrencyType)
    end
end

--- 输入如CurrencyType.Contribution
function CurrencyData.GetCurrencyName(szMoneyType)
    local tCurrencyInfo = Table_GetCurrencyInfoByIndex(szMoneyType)
    local szCurrencyName = tCurrencyInfo and UIHelper.GBKToUTF8(tCurrencyInfo.szDescription)
    return szCurrencyName or szMoneyType
end

-----------------------26年4月份版本货币新接口--------------------------

Currency_Base = {
    tCurrencyList = {},
    tCurrencyMap = {},
    tCurrencyChineseNameToType = {},
}

function Currency_Base.GetCurrencyTypeID(szCurrency)
    if not szCurrency or type(szCurrency) ~= "string" then
        return nil
    end
    local szKey = szCurrency:match("^%s*(.-)%s*$")  -- 去除首尾空白
    if szKey == "" then
        return nil
    end
    return CURRENCY_TYPE[szKey:upper()]
end

function Currency_Base.GetCurrencyNumber(szCurrency)
    local nType = Currency_Base.GetCurrencyTypeID(szCurrency)
    if not nType then
        return
    end

    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    return pPlayer.GetCurrency(nType)
end

function Currency_Base.GetCurrencyMaxNumber(szCurrency)
    local nType = Currency_Base.GetCurrencyTypeID(szCurrency)
    if not nType then
        return
    end

    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    return pPlayer.GetMaxCurrency(nType)
end

function Currency_Base.GetCurrencyWeekRemain(szCurrency)
    local nType = Currency_Base.GetCurrencyTypeID(szCurrency)
    if not nType then
        return
    end

    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    return pPlayer.GetCurrencyRemainSpace(nType)
end

function Currency_Base.InitCurrencyList()
    local tList = Table_GetCurrencyInfo()
    if tList then
        for k, v in ipairs(tList) do
            local szCurrency = v.szName
            if szCurrency and type(szCurrency) == "string" and szCurrency ~= "" then
                table.insert(Currency_Base.tCurrencyList, szCurrency)
                Currency_Base.tCurrencyMap[szCurrency] = true
                Currency_Base.tCurrencyChineseNameToType[UIHelper.GBKToUTF8(v.szDescription)] = szCurrency
            end
        end
    end
    return
end

function Currency_Base.GetCurrencyList()
    local tRes = {}

    if not Currency_Base.tCurrencyList or IsTableEmpty(Currency_Base.tCurrencyList) then
        Currency_Base.InitCurrencyList()
    end
    tRes = clone(Currency_Base.tCurrencyList)

    return tRes
end

function Currency_Base.GetCurrencyChineseNameToTypeTable()
    local tRes = {}

    if not Currency_Base.tCurrencyChineseNameToType or IsTableEmpty(Currency_Base.tCurrencyChineseNameToType) then
        Currency_Base.InitCurrencyList()
    end
    tRes = Currency_Base.tCurrencyChineseNameToType

    return tRes
end

-- 判断货币是否应该在货币背包中显示
-- nShowActivityID == 0 或未填：始终显示
-- nShowActivityID > 0：对应活动开启时才显示
function Currency_Base.IsCurrencyVisible(tInfo)
    if not tInfo then
        return false
    end
    local nActivityID = tInfo.nShowActivityID
    if not nActivityID or nActivityID == 0 then
        return true
    end
    if nActivityID < 0 then
        return false
    end
    return UI_IsActivityOn(nActivityID) or IsActivityOn(nActivityID)
end
