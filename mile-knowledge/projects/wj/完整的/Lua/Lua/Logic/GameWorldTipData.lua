
-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: GameWorldTipData
-- Date: 2024-02-29 16:13:46
-- Desc: ?

-- ---------------------------------------------------------------------------------
GameWorldTipData = GameWorldTipData or {className = "GameWorldTipData"}
local self = GameWorldTipData

local COLOR_TABLE = {
	[0] = 31,		-- 这个是专门用来做 TITLE 文字的
	[1] = 100,		-- 黄色
	[2] = 101,		-- 橘色
	[3] = 102,		-- 红色
	[4] = 103,		-- 紫色
	[5] = 104,		-- 蓝色
	[6] = 105,		-- 绿色
	[7] = 106,		-- 白色
	[8] = 107,		-- 灰色亮度4
	[9] = 108,		-- 灰色亮度3
	[10] = 109,		-- 灰色亮度2
	[11] = 110,		-- 灰色亮度1
	[12] = 111,		-- 粉红
	[13] = 112,		-- 粉紫
	[14] = 113,		-- 粉蓝
}
local g_aGameWorldTip =
{
	[0] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("未获得信息\n", 0) ..
		self.ColorText("你还没有获得此信息。\n各种案件相关的信息都是通过故事的进展陆续获得的。\n\n", 7)
		return szTip
	end,
	[1] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("出示道具\n", 0) ..
		self.ColorText("将案件相关的道具出示给对方，用以引出新的话题或者指明矛盾等。\n\n", 7) ..
		self.ColorText("这些道具不会占用背包。", 6)
		return szTip
	end,
	[2] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("指出人物或处所\n", 0) ..
		self.ColorText("将案件相关的人物或者处所告知对方，用以引出新的话题或者指明矛盾等。\n\n", 7) ..
		self.ColorText("人物或处所信息会在游戏过程中自动追加。", 6)
		return szTip
	end,
	[3] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("出示案件资料\n", 0) ..
		self.ColorText("将案件相关的资料告知对方，用以引出新的话题或者指明矛盾等。\n\n", 7) ..
		self.ColorText("案件资料会在游戏过程中自动追加。", 6)
		return szTip
	end,
	[4] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("提出质问\n", 0) ..
		self.ColorText("在对话过程中，对有疑问或者有矛盾的谈话内容进行质问，可能获得新的信息。\n\n", 7) ..
		self.ColorText("可能引起对方的反感。", 6)
		return szTip
	end,
	[5] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("听对方上一句话\n", 0) ..
		self.ColorText("目标可能会有多句话，此按钮用来回顾上一句对话内容。\n\n", 7)
		return szTip
	end,
	[6] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("成步堂的证词\n", 0) ..
		self.ColorText("将案件相关的证据出示给对方，用以引出新的话题或者指明矛盾等。\n\n", 7)
		return szTip
	end,
	[7] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("指出人物或处所\n", 0) ..
		self.ColorText("将案件相关的人物或者处所告知对方，用以引出新的话题或者指明矛盾等。\n\n", 7) ..
		self.ColorText("每句话的衍生内容不能做此操作。", 3)
		return szTip
	end,
	[8] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("出示案件资料\n", 0) ..
		self.ColorText("将案件相关的资料告知对方，用以引出新的话题或者指明矛盾等。\n\n", 7) ..
		self.ColorText("每句话的衍生内容不能做此操作。", 3)
		return szTip
	end,
	[9] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("提出疑问\n", 0) ..
		self.ColorText("在对话过程中，对有疑问或者有矛盾的谈话内容进行询问，可能获得新的信息。\n\n", 7)
		return szTip
	end,
	[10] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("听对方下一句话\n", 0) ..
		self.ColorText("目标可能会有多句话，此按钮用来跳转到下一句对话内容。", 7)
		return szTip
	end,
	[11] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("仵作的证词\n", 0) ..
		self.ColorText("尸体被发现的时候是平躺在地面上，死亡时间大概是", 7) ..
		self.ColorText("午时后一刻", 3) ..
		self.ColorText("，致命死因是", 7) ..
		self.ColorText("胸口的剪刀刀伤，刀口向上，应该是蓄意伤人", 3) ..
		self.ColorText("，凶器就扔在旁边。周围有搏斗的痕迹。", 7)
		return szTip
	end,
	[12] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("王氏的证词\n", 0) ..
		self.ColorText("秀茹可是个好女孩，说话细声细语的，平时大门不出二门不迈，也就找几个闺房密友去家里下棋。", 7)
		return szTip
	end,
	[13] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("曾氏的证词\n", 0) ..
		self.ColorText("秀茹啊，她", 7) ..
		self.ColorText("下棋的技术很高，人也很冷静，从来没冲动过", 3) ..
		self.ColorText("，据说一般的国手都下不过她呢。", 7)
		return szTip
	end,
	[14] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("张屠夫的证词\n", 0) ..
		self.ColorText("那天啊，正好我家里有事，", 7) ..
		self.ColorText("中午就没开张。", 3)
		return szTip
	end,
	[15] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("李屠夫的证词\n", 0) ..
		self.ColorText("秀茹妹子那天的确在我这里买肉了，具体时间我记不住了，大概是", 7) ..
		self.ColorText("中午之后", 3) ..
		self.ColorText("吧。", 7)
		return szTip
	end,
	[16] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("秀茹的证词\n", 0) ..
		self.ColorText("买好肉回到家，我就看见夫君和人在搏斗，我就开始呼喊，这时候那人刺了夫君一刀就跑掉了。", 7)
		return szTip
	end,
	[17] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("焦枯的树枝\n", 0) ..
		self.ColorText("残留着冷石灰的烧焦的树枝。冷石是炼丹产物。有剧毒。", 7)
		return szTip
	end,
	[18] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("炼丹道士的证词\n", 0) ..
		self.ColorText("有一位姓林的画师给我银子，让我给他炼制冷石。", 7)
		return szTip
	end,
	[19] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("罗轩的证词\n", 0) ..
		self.ColorText("当年武及侵犯了张德的妻子，结果夫妇两被误杀，儿子张白尘失踪。\n武及被害的前天晚上有黑衣人行刺武及未遂，左手受伤。行刺之人极有可能是张白尘。", 7)
		return szTip
	end,
	[20] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("夜行衣\n", 0) ..
		self.ColorText("藏在金水镇东北的空宅子里的夜行衣，左袖被划了一道口子，上面还沾着血渍。", 7)
		return szTip
	end,
	[21] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("武及的验尸报告\n", 0) ..
		self.ColorText("死亡时间大概是昨日入夜戌时；死亡原因是有一根绣花针刺入脑门要害处。", 7)
		return szTip
	end,
	[22] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("凶器·绣花针\n", 0) ..
		self.ColorText("这根绣花针有点特别，半银半铜所制，上半部分是银色，下半部分是金色。", 7)
		return szTip
	end,
	[23] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("武晖的证词\n", 0) ..
		self.ColorText("罗轩急匆匆地从外头跑回来进房子里和爹说了什么，然后就出来带一群人往贡橘林去了。之后爹呆在房间里一直没什么动静，第二天起来发现爹爹已死去多时。", 7)
		return szTip
	end,
	[24] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("小叫花的证词\n", 0) ..
		self.ColorText("那个人是个左撇子！嗯，没错！他给我冷石，付我银两都是用的左手，从来就没见他动过右手，这点我记得很清楚！我当时还纳闷的，金水镇我没见过有左撇子的啊！", 7)
		return szTip
	end,
	[25] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("武晴的证词一\n", 0) ..
		self.ColorText("当天我吃完晚饭就买绣花针去了。我的绣花针被罗轩叔叔借去挑刺给弄丢了。", 7)
		return szTip
	end,
	[26] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("武晴的证词二\n", 0) ..
		self.ColorText("罗轩叔叔右手被刺伤了，流了好多血！大夫说都伤到筋了。说不定，说不定右手就给废了。", 7)
		return szTip
	end,
	[27] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("鉴定过的凶器\n", 0) ..
		self.ColorText("这正是被罗轩借去的武晴的绣花针。", 7)
		return szTip
	end,
	[28] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("林白轩的画\n", 0) ..
		self.ColorText("林白轩作的画，上面白色的云雾皆是用冷石粉所图，吸入过多冷石粉便会中毒而死。", 7)
		return szTip
	end,
	[29] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("这个就是测试啊\n", 0) ..
		self.ColorText("你看到的都是测试用TIPS.\n", 7) ..
		self.ColorText("点击: 那是没有用的!", 6)
		return szTip
	end,
	[30] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"-50"
		local szTip =	self.ColorText("将预付押金减少", 6) ..
		self.ColorText("五十银", 0) ..
		self.ColorText("。", 6)
		return szTip
	end,
	[31] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"-10"
		local szTip =	self.ColorText("将预付押金减少", 6) ..
		self.ColorText("一千叶子令", 0) ..
		self.ColorText("。", 6)
		return szTip
	end,
	[32] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"+10"
		local szTip =	self.ColorText("将预付押金增加", 6) ..
		self.ColorText("一千叶子令", 0) ..
		self.ColorText("。", 6)
		return szTip
	end,
	[33] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"+50"
		local szTip =	self.ColorText("将预付押金增加", 6) ..
		self.ColorText("五十银", 0) ..
		self.ColorText("。", 6)
		return szTip
	end,
	[34] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"刷新"
		local szTip =	self.ColorText("刷新当前页面。\n\n", 7) ..
		self.ColorText("获得最新的战斗者列表和报名者列表信息。", 6)
		return szTip
	end,
	[35] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("将设置好的预付押金提交给擂台管理员。\n\n", 7) ..
		self.ColorText("如果有其他玩家提交了更高的金额，你有可能被挤出报名队列，你之前支付的押金将通过信使全额返还给你。\n", 6) ..
		self.ColorText("押金必须高于当前报名列表中金额最少的玩家。", 3)
		return szTip
	end,
	--
	--宠物木屋相关
	--宠物回收
	[36] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("回收跟宠\n", 7) ..
		self.ColorText("取消当前宠物的跟随状态，将其收回到跟宠木屋中来。\n", 6) ..
		self.ColorText("侠士也可以通过右键点击跟随状态图标来取消跟随状态。", 1)
		return szTip
	end,
	--吉祥虎
	[37] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("醉寅视肉: 吉祥虎\n", 7) ..
		self.ColorText("香喷喷的视肉，可以将吉祥虎召唤出来。\n", 6) ..
		self.ColorText("平丘有视肉，食之尽，寻复更生。\n每次召唤持续二十四小时。", 1)
		return szTip
	end,
	--兔瑞瑞（白）
	[38] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("甘荀萝卜: 兔瑞瑞（粉色）\n", 7) ..
		self.ColorText("用美味的胡萝卜，可召唤粉红色的“兔瑞瑞”。\n", 6) ..
		self.ColorText("抱着一根萝卜，啃啊啃，兔瑞瑞很快就会长大了。\n甘荀萝卜: 胡萝卜的别称，又称丁香萝卜。\n每次召唤持续二十四小时。", 1)
		return szTip
	end,
	--兔瑞瑞（灰）
	[39] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("土酥萝卜: 兔瑞瑞（灰色）\n", 7) ..
		self.ColorText("用此萝卜，可召唤灰色的“兔瑞瑞”。\n", 6) ..
		self.ColorText("抱着一根胡萝卜，啃啊啃，等兔瑞瑞长大就能找到兔祥祥了。\n土酥: 萝卜的别名，杜甫有诗云: “长安冬菹酸且绿，金城土酥净如练”。\n每次召唤持续二十四小时。", 1)
		return szTip
	end,
	--兔祥祥（白）
	[40] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("莱菔萝卜: 兔祥祥（粉色）\n", 7) ..
		self.ColorText("用萝卜将躲在木屋中的粉红色的兔祥祥召唤出来。\n", 6) ..
		self.ColorText("兔子急了也会吃“莱菔”的。\n莱菔: 萝卜的别称，早见于《尔雅》记载。\n每次召唤持续二十四小时。", 1)
		return szTip
	end,
	--兔祥祥（灰）
	[41] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("雹葖萝卜: 兔祥祥（灰色）\n", 7) ..
		self.ColorText("用胡萝卜将躲在木屋中灰色的兔祥祥召唤出来。\n", 6) ..
		self.ColorText("兔祥祥一直在找兔瑞瑞，它们都是祥瑞兔年的吉祥宝贝。\n雹葖: 萝卜的别称，晋之郭义恭《广志》有记载。\n每次召唤持续二十四小时。", 1)
		return szTip
	end,
	--兔轶轶（灰）
	[42] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("心里美萝卜: 兔轶轶（灰色）\n", 7) ..
		self.ColorText("用此萝卜将躲在木屋中灰色的兔轶轶召唤出来。\n", 6) ..
		self.ColorText("兔轶轶只爱“心里美”，没了“心里美”兔轶轶就要溜了，哼！\n每次召唤持续二十四小时。", 1)
		return szTip
	end,
	--兔轶轶（白）
	[43] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("心里美萝卜: 兔轶轶（粉色）\n", 7) ..
		self.ColorText("用此萝卜将躲在木屋中粉红色的兔轶轶召唤出来。\n", 6) ..
		self.ColorText("兔轶轶只爱“心里美”，没了“心里美”兔轶轶就要溜了，哼！\n每次召唤持续二十四小时。", 1)

		return szTip
	end,
	--祥兔阿甘
	[44] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("祥兔阿甘\n", 7) ..
		self.ColorText("先组装阿甘机关，然后将祥兔放进去作为动力。\n", 6) ..
		self.ColorText("“祥兔阿甘”最勤快，不像“瑞兔阿甘”那样每天懒洋洋的。\n每次召唤持续三十分钟。", 1)
		return szTip
	end,
	--瑞兔阿甘
	[45] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("瑞兔阿甘\n", 7) ..
		self.ColorText("先组装阿甘机关，然后将瑞兔放进去作为动力。\n", 6) ..
		self.ColorText("咔。。咔。。“瑞兔阿甘”很聪明，还能帮忙修东西。\n带有特殊商店的宠物每二十小时只可以召唤一次，每次持续十分钟。", 1)
		return szTip
	end,
	--比翼鸟
	[46] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("比翼\n", 7) ..
		self.ColorText("放飞两只比翼小鸟，环绕在你的周围。\n", 6) ..
		self.ColorText("在天愿作比翼鸟 在地愿为连理枝。\n每次召唤持续二十四小时。", 1)
		return szTip
	end,
	--熊猫滚滚
	[47] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("竹子: 阿宝\n", 7) ..
		self.ColorText("用鲜嫩的竹子，将那个圆滚滚的阿宝从懒洋洋的美梦中唤醒吧。\n", 6) ..
		self.ColorText("养肥了会变超级强力熊猫人，切忌今天俯卧，明天撑哦。\n每次召唤持续二十四小时。", 1)
		return szTip
	end,
	--机关猪1
	[48] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("唐门机关猪·毒箭\n", 7) ..
		self.ColorText("点击选定获取该宠物\n", 6) ..
		self.ColorText("唐门秘制机关猪，会卖子弹会卖萌。", 1)
		return szTip
	end,
	--机关猪2
	[49] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("唐门机关猪·短刀\n", 7) ..
		self.ColorText("点击选定获取该宠物\n", 6) ..
		self.ColorText("唐门秘制机关猪，会卖子弹会卖萌。", 1)
		return szTip
	end,
	--机关猪3
	[50] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("唐门机关猪·飞镖\n", 7) ..
		self.ColorText("点击选定获取该宠物\n", 6) ..
		self.ColorText("唐门秘制机关猪，会卖子弹会卖萌。", 1)
		return szTip
	end,
	--机关猪4
	[51] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("唐门机关猪·竹简\n", 7) ..
		self.ColorText("点击选定获取该宠物\n", 6) ..
		self.ColorText("唐门秘制机关猪，会卖子弹会卖萌。", 1)
		return szTip
	end,
	--御灯龙--商店
	[52] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("御灯龙·吉\n", 7) ..
		self.ColorText("召唤御灯龙·吉。\n", 6) ..
		self.ColorText("灯，等灯等灯～机关匣装有御龙袋，里边藏着好东西～\n带有特殊商店的宠物每二十小时只可以召唤一次，每次持续十分钟。", 1)
		return szTip
	end,
	--灯龙宝宝
	[53] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("灯龙宝宝\n", 7) ..
		self.ColorText("召唤灯龙宝宝。\n", 6) ..
		self.ColorText("御龙行千里，华灯照万家。\n每次召唤持续二十四小时。", 1)
		return szTip
	end,
	--御灯龙--无商店
	[54] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("御灯龙·福\n", 7) ..
		self.ColorText("召唤御灯龙·福。\n", 6) ..
		self.ColorText("灯，等灯等灯～\n每次召唤持续二十四小时。", 1)
		return szTip
	end,
	----------------------------
	--藏剑任务矿石图标
	[55] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("黑乌石\n", 7) ..
		self.ColorText("点击选择黑乌石。\n", 6)
		return szTip
	end,
	--藏剑任务矿石图标
	[56] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("西域金精石\n", 7) ..
		self.ColorText("点击选择西域金精石。\n", 6)
		return szTip
	end,
	--藏剑任务矿石图标
	[57] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("赤火石\n", 7) ..
		self.ColorText("点击选择赤火石。\n", 6)
		return szTip
	end,
	--万花任务名琴图标
	[58] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("【焦尾】\n", 7) ..
		self.ColorText("点击选择【焦尾】琴。\n", 6)
		return szTip
	end,
	--万花任务名琴图标
	[59] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("【绿绮】\n", 7) ..
		self.ColorText("点击选择【绿绮】琴。\n", 6)
		return szTip
	end,
	--万花任务名琴图标
	[60] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("【绕梁】\n", 7) ..
		self.ColorText("点击选择【绕梁】琴。\n", 6)
		return szTip
	end,
	--万花任务名琴图标
	[61] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("【号钟】\n", 7) ..
		self.ColorText("点击选择【号钟】琴。\n", 6)
		return szTip
	end,
	--入门图标相关--------
	[62] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("加入七秀坊\n", 7) ..
		self.ColorText("点击加入七秀坊，成为七秀坊正式弟子！\n", 6)
		return szTip
	end,
	--入门图标相关
	[63] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("加入万花谷\n", 7) ..
		self.ColorText("点击加入万花谷，成为万花谷正式弟子！\n", 6)
		return szTip
	end,
	--入门图标相关
	[64] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("加入五毒教\n", 7) ..
		self.ColorText("点击加入五毒教，成为五毒教正式弟子！\n", 6)
		return szTip
	end,
	--入门图标相关
	[65] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("加入唐门\n", 7) ..
		self.ColorText("点击加入唐门，成为唐家堡正式弟子！\n", 6)
		return szTip
	end,
	--入门图标相关
	[66] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("加入天策府\n", 7) ..
		self.ColorText("点击加入天策府，成为天策府正式弟子！\n", 6)
		return szTip
	end,
	--入门图标相关
	[67] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szName =	"确定"
		local szTip =	self.ColorText("加入少林寺\n", 7) ..
		self.ColorText("点击加入少林寺，成为少林寺正式弟子！\n", 6)
		return szTip
	end,
	--入门图标相关
	[68] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("加入纯阳宫\n", 7) ..
		self.ColorText("点击加入纯阳宫，成为纯阳宫正式弟子！\n", 6)
		return szTip
	end,
	--入门图标相关
	[69] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("加入藏剑山庄\n", 7) ..
		self.ColorText("点击加入藏剑山庄，成为藏剑山庄正式弟子！\n", 6)
		return szTip
	end,
	----------------------------
	----------------------------
	[70] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("水云坊", 5)
		return szTip
	end,
	[71] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("听香坊", 5)
		return szTip
	end,
	[72] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("星月坊", 5)
		return szTip
	end,
	[73] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("忆盈楼", 5)
		return szTip
	end,
	[74] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("二十四桥", 5)
		return szTip
	end,
	[75] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("仙乐码头", 5)
		return szTip
	end,
	[76] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("指挥你下属士兵向北移动", 5)
		return szTip
	end,
	[77] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("发动你下属士兵的特殊技能", 5)
		return szTip
	end,
	[78] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("指挥你下属士兵向东移动", 5)
		return szTip
	end,
	[79] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("指挥你下属士兵停止移动", 5)
		return szTip
	end,
	[80] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("指挥你下属士兵向西移动", 5)
		return szTip
	end,
	[81] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("指挥你下属士兵攻击你的当前目标", 5)
		return szTip
	end,
	[82] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("指挥你下属士兵在你南面横向集合", 5)
		return szTip
	end,
	[83] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("指挥你下属士兵向南移动", 5)
		return szTip
	end,
	[84] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("指挥你下属士兵在你南面纵向集合", 5)
		return szTip
	end,
	[100] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("纸条\n", 0) ..
		self.ColorText("使用: 阅读纸条。", 6)
		return szTip
	end,
	--孔明灯·碧
	[101] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("孔明灯·碧\n", 7) ..
		self.ColorText("点亮孔明灯·碧。\n", 6) ..
		self.ColorText("燃放一盏随身飞舞的绿色孔明灯\n诚挚祈福。", 1)
		return szTip
	end,
	--孔明灯·苍
	[102] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("孔明灯·苍\n", 7) ..
		self.ColorText("点亮孔明灯·苍。\n", 6) ..
		self.ColorText("燃放一盏随身飞舞的蓝色孔明灯\n诚挚祈福。", 1)
		return szTip
	end,
	--孔明灯·朱
	[103] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("孔明灯·朱\n", 7) ..
		self.ColorText("点亮孔明灯·朱。\n", 6) ..
		self.ColorText("燃放一盏随身飞舞的红色孔明灯\n诚挚祈福。", 1)
		return szTip
	end,
	--孔明灯·执子之手
	[104] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("孔明灯·执子之手\n", 7) ..
		self.ColorText("点亮孔明灯·执子之手。\n", 6) ..
		self.ColorText("燃放一盏随身飞舞明亮夺目的孔明灯\n诚挚祈福。", 1)
		return szTip
	end,
	--喂食草料，一级草料
	[105] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("一级草料·百脉根\n", 7) ..
		self.ColorText("为马儿喂食【一级草料·百脉根】。可增加饱食度15点。\n", 6)
		return szTip
	end,
	--喂食草料，一级草料
	[106] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("一级草料·百脉根（绑定）\n", 7) ..
		self.ColorText("为马儿喂食【一级草料·百脉根（绑定）】。可增加饱食度15点。\n", 6)
		return szTip
	end,
	--喂食草料，二级草料
	[107] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("二级草料·紫花苜蓿\n", 7) ..
		self.ColorText("为马儿喂食【二级草料·紫花苜蓿】。可增加饱食度75点。\n", 6)
		return szTip
	end,
	--喂食草料，二级草料
	[108] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("二级草料·紫花苜蓿（绑定）\n", 7) ..
		self.ColorText("为马儿喂食【二级草料·紫花苜蓿（绑定）】。可增加饱食度75点。\n", 6)
		return szTip
	end,
	--喂食草料，三级草料
	[109] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("三级草料·甜象草\n", 7) ..
		self.ColorText("为马儿喂食【三级草料·甜象草】。可增加饱食度150点。\n", 6)
		return szTip
	end,
	--喂食草料，四级草料
	[110] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("四级草料·皇竹草\n", 7) ..
		self.ColorText("为马儿喂食【四级草料·皇竹草】。可增加饱食度300点。\n", 6)
		return szTip
	end,
	--喂食草料，特殊草料
	[111] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("草料·雪露翠青\n", 7) ..
		self.ColorText("为马儿喂食【草料·雪露翠青】。可增加饱食度75点。\n", 6) ..
		self.ColorText("【草料·雪露翠青】可额外提高马驹的成长经验。\n", 1)
		return szTip
	end,
	[112] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("加入明教\n", 7) ..
		self.ColorText("点击加入明教，成为明教正式弟子！\n", 6)
		return szTip
	end,
	[113] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("加入丐帮\n", 7) ..
		self.ColorText("点击加入丐帮，成为丐帮正式弟子！\n", 6)
		return szTip
	end,
	--喂食草料，三级草料
	[114] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("三级草料·甜象草（绑定）\n", 7) ..
		self.ColorText("为马儿喂食【三级草料·甜象草（绑定）】。可增加饱食度150点。\n", 6)
		return szTip
	end,
	--喂食草料，四级草料
	[115] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("四级草料·皇竹草（绑定）\n", 7) ..
		self.ColorText("为马儿喂食【四级草料·皇竹草（绑定）】。可增加饱食度300点。\n", 6)
		return szTip
	end,
	--丐帮做菜系列任务图素
	[126] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("油\n", 0) ..
		self.ColorText("新鲜的菜籽油，做菜必不可少的材料。\n", 7)
		return szTip
	end,
	[127] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("盐\n", 0) ..
		self.ColorText("来自蜀中的井盐，做菜必不可少的材料。\n", 7)
		return szTip
	end,
	[128] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("酱\n", 0) ..
		self.ColorText("以黄豆为主要原料酿制，香气四溢，为菜肴添加香味。\n", 7)
		return szTip
	end,
	[129] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("文火\n", 0) ..
		self.ColorText("文火慢炖，令菜肴慢慢入味，酥软。\n", 7)
		return szTip
	end,
	[130] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("武火\n", 0) ..
		self.ColorText("武火急烹，给食材快速加热，令其熟烂。\n", 7)
		return szTip
	end,
	[131] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【菜谱·蝴蝶过海】\n", 0) ..
		self.ColorText("选用洞庭湖所产青鱼，带皮片成厚薄均匀的鱼片，放入事先调好味的热汤中汆烫，待鱼肉收缩即可。\n", 7) ..
		self.ColorText("调料：盐两份，油一份。\n", 7)  ..
		self.ColorText("火候：武火烧开汤料，武火汆烫，之后文火加温。\n", 7)
		return szTip
	end,
	[132] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【菜谱·银鱼翻江】\n", 0) ..
		self.ColorText("君山名菜，选用洞庭湖所产之银鱼，辅以君山银针茶液烹制，鲜香俱佳。\n", 7)  ..
		self.ColorText("调料：盐一份，油两份。\n", 7)  ..
		self.ColorText("火候：武火炒制，文火入茶汤，之后武火烧开。\n", 7)
		return szTip
	end,
	[133] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【菜谱·百味香酥鸡】\n", 0) ..
		self.ColorText("又名叫花鸡。\n", 7)  ..
		self.ColorText("将去毛洗净的整鸡涂抹香料，腹腔中填入香菇，用荷叶包裹，再敷上泥土，放入火中烤制。\n", 7)  ..
		self.ColorText("调料：盐三份，油、酱各一份。\n", 7)  ..
		self.ColorText("火候：武火烧至泥土坚硬，之后文火，如此交替。\n", 7)
		return szTip
	end,
	[134] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【菜谱·烤野鸽】\n", 0) ..
		self.ColorText("巧妇无米炊，美味天上来。\n", 7)  ..
		self.ColorText("将去毛洗净的野鸽涂抹涂抹食盐，腹腔中填入百香草，用树枝穿入其腹腔，放在火堆上烤制。\n", 7)  ..
		self.ColorText("调料：盐三份，酱两份。\n", 7)  ..
		self.ColorText("火候：文火烤至金黄，之后武火烤制，如此交替。\n", 7)
		return szTip
	end,
	[135] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("猪肉\n", 0) ..
		self.ColorText("常见的家畜，肉质较嫩，有肥有瘦。\n", 7)
		return szTip
	end,
	[136] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("牛肉\n", 0) ..
		self.ColorText("常见家畜，肉色偏红，有嚼劲。\n", 7)
		return szTip
	end,
	[137] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("银鱼\n", 0) ..
		self.ColorText("体细长，似鲑，无鳞，泛银白色，味道鲜美。\n", 7)
		return szTip
	end,
	[138] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("青鱼\n", 0) ..
		self.ColorText("性味甘、平，无毒，有益气化湿、和中、截疟、养肝明目、养胃之功效。肉质肥嫩，味鲜腴美常见淡水鱼品种。\n", 7)
		return szTip
	end,
	[139] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("带鱼\n", 0) ..
		self.ColorText("又叫刀鱼，性温、味甘、咸，归肝、脾经，海洋常见鱼类。\n", 7)
		return szTip
	end,
	[140] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("整鸡\n", 0) ..
		self.ColorText("去毛洗净的肉鸡，肉质鲜嫩，肥厚适当。\n", 7)
		return szTip
	end,
	[141] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("君山银针\n", 0) ..
		self.ColorText("茶芽内面呈金黄色，外层白毫显露完整，包裹坚实，形细如针，散发阵阵茶香，乃茶中上品。\n", 7)
		return szTip
	end,
	[142] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("野鸽\n", 0) ..
		self.ColorText("山间野味，肉质紧致，腥味较重。\n", 7)
		return szTip
	end,
	[143] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("香菇\n", 0) ..
		self.ColorText("一种生长在木材上的菌类。味道鲜美，香气沁人，营养丰富。\n", 7)
		return szTip
	end,
	[144] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("百香草\n", 0) ..
		self.ColorText("多年生草本，全株具有类似柑橘的香味，生长范围较广。\n", 7)
		return szTip
	end,
	[145] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("豆腐\n", 0) ..
		self.ColorText("将黄豆浆煮熟点制而成，洁白如玉，营养丰富，中原常见的食材。\n", 7)
		return szTip
	end,
	[146] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("黄瓜\n", 0) ..
		self.ColorText("也称胡瓜、青瓜，瓜圆筒形，皮色深绿，气味清新。\n", 7)
		return szTip
	end,
	[147] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("起锅\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("做好了，起锅！\n", 7)
		return szTip
	end,
	[148] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("重来\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("好像和食谱上写的不太一样啊，重做吧。\n", 7)
		return szTip
	end,
	[149] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("油\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("新鲜的菜籽油，做菜必不可少的材料。\n", 7)
		return szTip
	end,
	[150] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("盐\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("来自蜀中的井盐，做菜必不可少的材料。\n", 7)
		return szTip
	end,
	[151] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("酱\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("以黄豆为主要原料酿制，香气四溢，为菜肴添加香味。\n", 7)
		return szTip
	end,
	[152] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("文火\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("文火慢炖，令菜肴慢慢入味，酥软。\n", 7)
		return szTip
	end,
	[153] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("武火\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("武火急烹，给食材快速加热，令其熟烂。\n", 7)
		return szTip
	end,
	[154] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("猪肉\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("常见的家畜，肉质较嫩，有肥有瘦。\n", 7)
		return szTip
	end,
	[155] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("牛肉\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("常见家畜，肉色偏红，有嚼劲。\n", 7)
		return szTip
	end,
	[156] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("银鱼\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("体细长，似鲑，无鳞，泛银白色，味道鲜美。\n", 7)
		return szTip
	end,
	[157] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("青鱼\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("性味甘、平，无毒，有益气化湿、和中、截疟、养肝明目、养胃之功效。肉质肥嫩，味鲜腴美常见淡水鱼品种。\n", 7)
		return szTip
	end,
	[158] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("带鱼\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("又叫刀鱼，性温、味甘、咸，归肝、脾经，海洋常见鱼类。\n", 7)
		return szTip
	end,
	[159] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("整鸡\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("去毛洗净的肉鸡，肉质鲜嫩，肥厚适当。\n", 7)
		return szTip
	end,
	[160] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("君山银针\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("茶芽内面呈金黄色，外层白毫显露完整，包裹坚实，形细如针，散发阵阵茶香，乃茶中上品。\n", 7)
		return szTip
	end,
	[161] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("野鸽\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("山间野味，肉质紧致，腥味较重。\n", 7)
		return szTip
	end,
	[162] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("香菇\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("一种生长在木材上的菌类。味道鲜美，香气沁人，营养丰富。\n", 7)
		return szTip
	end,
	[163] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("百香草\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("多年生草本，全株具有类似柑橘的香味，生长范围较广。\n", 7)
		return szTip
	end,
	[164] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("豆腐\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("将黄豆浆煮熟点制而成，洁白如玉，营养丰富，中原常见的食材。\n", 7)
		return szTip
	end,
	[165] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("黄瓜\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("也称胡瓜、青瓜，瓜圆筒形，皮色深绿，气味清新。\n", 7)
		return szTip
	end,
	[166] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("鲮鱼\n", 0) ..
		self.ColorText("常见鱼类，身体延长，腹部圆，头短小，吻圆钝。味甘、性平、无毒，入肝、肾、脾、胃四经。\n", 7)
		return szTip
	end,
	[167] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("鲮鱼\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("常见鱼类，身体延长，腹部圆，头短小，吻圆钝。味甘、性平、无毒，入肝、肾、脾、胃四经。\n", 7)
		return szTip
	end,
	[168] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【菜谱·特制鱼糕】\n", 0) ..
		self.ColorText("全称只饮半壶小食神特制鱼糕。\n", 7)  ..
		self.ColorText("将鲮鱼去鳞、去骨刺，剁成鱼糜，将带肥猪肉剁成肉糜，两者混合加入调味料上劲，入锅蒸制。\n", 7)  ..
		self.ColorText("调料：盐两份，油一份。\n", 7)  ..
		self.ColorText("火候：武火加热至水沸，武火持续加热，文火慢烹。\n", 7)
		return szTip
	end,
	[169] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【雏鸟·飞鸿】\n", 0) ..
		self.ColorText("点击选定获取该幼隼。\n", 6) ..
		self.ColorText("燕隼，燕雀焉知，鸿鹄之志。\n", 7)
		return szTip
	end,
	[170] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【雏鸟·栖夜】\n", 0) ..
		self.ColorText("点击选定获取该幼隼。\n", 6) ..
		self.ColorText("墨隼，月黑风高，静谧猎手。\n", 7)
		return szTip
	end,
	[171] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【雏鸟·赤箭】\n", 0) ..
		self.ColorText("点击选定获取该幼隼。\n", 6) ..
		self.ColorText("红隼，如箭在弦，勇往直前。\n", 7)
		return szTip
	end,
	[172] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【雏鸟·紫翎】\n", 0) ..
		self.ColorText("点击选定获取该幼隼。\n", 6) ..
		self.ColorText("紫隼，穿云御风，亟如闪电。\n", 7)
		return szTip
	end,
	[173] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【雏鸟·白凤】\n", 0) ..
		self.ColorText("点击选定获取该幼隼。\n", 6) ..
		self.ColorText("白隼，雪白无垢，鸟中王者。\n", 7)
		return szTip
	end,
	[174] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("鼠标左键点击前往门派。\n", 0)
		return szTip
	end,
	[175] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("鼠标左键点击加入藏剑山庄。\n", 0)
		return szTip
	end,
	[176] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("鼠标左键点击加入纯阳宫。\n", 0)
		return szTip
	end,
	[177] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("鼠标左键点击加入丐帮。\n", 0)
		return szTip
	end,
	[178] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("鼠标左键点击加入明教。\n", 0)
		return szTip
	end,
	[179] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("鼠标左键点击加入七秀坊。\n", 0)
		return szTip
	end,
	[180] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("鼠标左键点击加入少林寺。\n", 0)
		return szTip
	end,
	[181] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("鼠标左键点击加入唐家堡。\n", 0)
		return szTip
	end,
	[182] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("鼠标左键点击加入天策府。\n", 0)
		return szTip
	end,
	[183] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("鼠标左键点击加入万花谷。\n", 0)
		return szTip
	end,
	[184] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("鼠标左键点击加入五毒教。\n", 0)
		return szTip
	end,
	[185] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("鼠标左键点击加入苍云军。\n", 0)
		return szTip
	end,
	[186] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("小麦粉\n", 0) ..
		self.ColorText("小麦磨成的面粉，可制出各种特色面食，花样百出，风味迥异。\n", 7)
		return szTip
	end,
	[187] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("莜麦粉\n", 0) ..
		self.ColorText("用产于塞北高寒之地的莜麦磨制而成，营养丰富，风味独特，多用来制作当地特色面食。\n", 7)
		return szTip
	end,
	[188] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("葱\n", 0) ..
		self.ColorText("味辛，性微温，有发表通阳，解毒调味的作用。通常将其切碎后洒在面上。\n", 7)
		return szTip
	end,
	[189] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("小麦粉\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("小麦磨成的面粉，可制出各种特色面食，花样百出，风味迥异。\n", 7)
		return szTip
	end,
	[190] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("莜麦粉\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("用产于塞北高寒之地的莜麦磨制而成，营养丰富，风味独特，多用来制作当地特色面食。\n", 7)
		return szTip
	end,
	[191] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("葱\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("味辛，性微温，有发表通阳，解毒调味的作用。通常将其切碎后洒在面上。\n", 7)
		return szTip
	end,
	[192] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【食谱·猫耳朵】\n", 0) ..
		self.ColorText("选用北方高寒之地所产的莜麦粉，用热水泼起和好，用湿布把面团盖好，趁热切成三分大小的剂头，用拇指与食指推捻成猫耳状，上笼蒸熟即可。\n", 7)  ..
		self.ColorText("调料：油一份，盐两份。\n", 7)  ..
		self.ColorText("火候：武火烫热蒸笼，武火蒸制，文火焖制。\n", 7)
		return szTip
	end,
	[193] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【食谱·刀削面】\n", 0) ..
		self.ColorText("选用江南一带的肉猪柔软的腹部割下的五花肉切成小丁，放进锅里小火煸炒，丢入葱段姜片干辣椒等调料炒至肉色微黄加汤，再加入以刀削制而成的面条，煮熟出锅即可。\n", 7)  ..
		self.ColorText("调料：盐两份，酱两份，油一份。\n", 7)  ..
		self.ColorText("火候：武火煮开肉臊，文火焖煮，武火煮面。\n", 7)
		return szTip
	end,
	[194] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("五花肉\n", 0) ..
		self.ColorText("由猪腹部割下的新鲜五花肉，精肥细瘦，肉质滑腻，五花三层。\n", 7)
		return szTip
	end,
	[195] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("精瘦肉\n", 0) ..
		self.ColorText("肉猪身上最结实的部位割下的精瘦肉，不带一丁点儿肥肉。\n", 7)
		return szTip
	end,
	[196] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("五花肉\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("由猪腹部割下的新鲜五花肉，精肥细瘦，肉质滑腻，五花三层。\n", 7)
		return szTip
	end,
	[197] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("精瘦肉\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("肉猪身上最结实的部位割下的精瘦肉，不带一丁点儿肥肉。\n", 7)
		return szTip
	end,
	[198] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【幼狮·鼎鼎】\n", 0) ..
		self.ColorText("点击选定获取该幼狮。\n", 6) ..
		self.ColorText("白狮鼎鼎，威风傲气小霸王。\n", 7)
		return szTip
	end,
	[199] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【幼狮·兜兜】\n", 0) ..
		self.ColorText("点击选定获取该幼狮。\n", 6) ..
		self.ColorText("白狮兜兜，乖巧柔顺爱撒娇。\n", 7)
		return szTip
	end,
	[200] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【幼狮·圈圈】\n", 0) ..
		self.ColorText("点击选定获取该幼狮。\n", 6) ..
		self.ColorText("白狮圈圈，天真可爱惹人怜。\n", 7)
		return szTip
	end,
	[201] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【幼狮·悠悠】\n", 0) ..
		self.ColorText("点击选定获取该幼狮。\n", 6) ..
		self.ColorText("棕狮悠悠，活泼俏皮爱捣蛋。\n", 7)
		return szTip
	end,
	[202] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("绿豆糕\n", 6) ..
		self.ColorText("使用：增加内功攻击力472点，持续15分钟。\n", 6) ..
		self.ColorText("将绿豆磨成沙泥做馅，面粉与各种辅料裹之，即成绿豆糕。\n", 0)  ..
		self.ColorText("\n点击制作：需材料【万能小糖包】一份，【绿豆】一份。\n", 7)
		return szTip
	end,
	[203] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("花生酥\n", 6) ..
		self.ColorText("使用：增加外功攻击力395点，持续15分钟。\n", 6) ..
		self.ColorText("松松脆脆的，小朋友们最喜欢的吃的零嘴儿之一。\n", 0)  ..
		self.ColorText("\n点击制作：需材料【万能小糖包】一份，【花生】一份。\n", 7)
		return szTip
	end,
	[204] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("果味糖\n", 6) ..
		self.ColorText("使用：武器伤害提高593，持续15分钟。\n", 6) ..	--增加阅历获取速度30%，持续30分钟。
		self.ColorText("酸酸甜甜，吃完一颗还想再吃。\n", 0)  ..
		self.ColorText("\n点击制作：需材料【万能小糖包】一份，【野果】一份。\n", 7)
		return szTip
	end,
	[205] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("南瓜小点\n", 6) ..
		self.ColorText("使用：增加气血上限5163点，持续15分钟。\n", 6) ..
		self.ColorText("南瓜是点心的主要成分，几乎没有混入其他食材。\n", 0)  ..
		self.ColorText("\n点击制作：需材料【万能小糖包】一份，【南瓜】一份。\n", 7)
		return szTip
	end,
	[206] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("红豆糕\n", 6) ..
		self.ColorText("使用：增加治疗量426点，持续15分钟。\n", 6) ..
		self.ColorText("口感松软，甜香绵长。微尝些许，似乎便能忆起远去的时光，还有心底的那个人。\n", 0)  ..
		self.ColorText("\n点击制作：需材料【万能小糖包】一份，【红豆】一份。\n", 7)
		return szTip
	end,
	[207] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("高级甜点\n", 5) ..
		self.ColorText("产出：云片宝珠、梅花宝珠、南瓜宝珠、芝麻宝珠、米花宝珠中的一种。还有几率获得【龙须酥】和【山楂果】。\n", 6) ..
		self.ColorText("神奇的糖块能制作出神奇的糕点，真的很神奇。\n", 0)  ..
		self.ColorText("\n点击制作：需材料【黏糊糊的糖块】一份。\n", 7)
		return szTip
	end,
	[208] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("丑丑的糖葫芦\n", 5) ..
		self.ColorText("使用：吃掉这个丑丑的糖葫芦！\n", 6) ..
		self.ColorText("丑丑哒一看就没有食欲。串起来的时候还掉了三颗山楂果！\n", 0)  ..
		self.ColorText("\n点击制作：需材料【山楂果】八份，【竹签】一份。\n", 7)
		return szTip
	end,
	[209] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【食谱·百香水鸭蛋】\n", 0) ..
		self.ColorText("将百香草洗净，切段，入锅内爆香。取草原上特有的水鸭之蛋，搅打均匀。锅置于火上，烧热后放入油，烧到五成熟时倒入蛋液，适当晃动，煎成浅黄色出锅即可。\n", 7)  ..
		self.ColorText("调料：盐两份，酱两份，油一份。\n", 7)  ..
		self.ColorText("火候：武火煸香，文火成型，文火翻熟。\n", 7)
		return szTip
	end,
	[210] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("水鸭蛋\n", 0) ..
		self.ColorText("草原上的水鸭所产之蛋，醇香甜嫩，别有风味。\n", 7)
		return szTip
	end,
	[211] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("普通鸡蛋\n", 0) ..
		self.ColorText("集市上买来的鸡蛋，没什么味道。\n", 7)
		return szTip
	end,
	[212] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("鼠标左键点击加入长歌门。\n", 0)
		return szTip
	end,
	[213] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【画作·微山湖景】\n", 0) ..
		self.ColorText("一幅俯瞰微山书院湖景全景的画作，出自长歌上任门主杨尹安之手。画作是在上好的净皮宣纸上绘制而成，共分五彩，以月白、墨灰、水色为主，建筑部分以小狼毫工笔勾线，再以羊毫斗笔罩染山水，最后以湿笔分染墨色，使墨色呈现出浓淡变化。\n", 7) ..
		self.ColorText("配色：月白色二分，墨灰色一分，水色二分。\n", 7)  ..
		self.ColorText("笔法：工笔勾线，斗笔罩染山水，斗笔分染墨色。\n", 7)
		return szTip
	end,
	[214] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("净皮宣纸\n", 0) ..
		self.ColorText("檀皮含量达到八成的宣纸，檀皮成分越重，纸张越能经受拉力，更能体现丰富的墨迹层次和润墨效果，适合用来作画。\n", 7)
		return szTip
	end,
	[215] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("玉版生宣\n", 0) ..
		self.ColorText("具有极强的吸水性和沁水性，易产生丰富的墨韵变化，渗墨迅速，落笔即定，适合用来书写。\n", 7)
		return szTip
	end,
	[216] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("月白色\n", 0) ..
		self.ColorText("《史记·封禅书》中有云：“太一宰则衣紫及绣。五帝各如其色，日赤，月白。”月白色名称本此。\n", 7)
		return szTip
	end,
	[217] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("墨灰色\n", 0) ..
		self.ColorText("以黑色与灰色调配而成的颜色，曾有诗云：“梅山渡影风吹尽，点墨山水染苍穹。”正是形容阴雨天气夜晚的天空，如墨色被水晕开一般。\n", 7)
		return szTip
	end,
	[218] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("水色\n", 0) ..
		self.ColorText("梁简文帝 《饯别》诗中有云：“窗阴随影度，水色带风移。”\n", 7)
		return szTip
	end,
	[219] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("工笔勾线\n", 0) ..
		self.ColorText("作此画须谨记，用笔如轻云舒卷、自如似水、转折柔和、流畅不滞。\n", 7)
		return szTip
	end,
	[220] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("斗笔晕染\n", 0) ..
		self.ColorText("“墨即是色”，以墨的浓淡变化来渲染山水的层次感，表现出远近深浅。\n", 7)
		return szTip
	end,
	[221] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("净皮宣纸\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("檀皮含量达到八成的宣纸，檀皮成分越重，纸张越能经受拉力，更能体现丰富的墨迹层次和润墨效果，适合用来作画。\n", 7)
		return szTip
	end,
	[222] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("玉版生宣\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("具有极强的吸水性和沁水性，易产生丰富的墨韵变化，渗墨迅速，落笔即定，适合用来书写。\n", 7)
		return szTip
	end,
	[223] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("月白色\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("《史记·封禅书》中有云：“太一宰则衣紫及绣。五帝各如其色，日赤，月白。”月白色名称本此。\n", 7)
		return szTip
	end,
	[224] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("墨灰色\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("以黑色与灰色调配而成的颜色，曾有诗云：“梅山渡影风吹尽，点墨山水染苍穹。”正是形容阴雨天气夜晚的天空，如墨色被水晕开一般。\n", 7)
		return szTip
	end,
	[225] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("水色\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("梁简文帝 《饯别》诗中有云：“窗阴随影度，水色带风移。\n", 7)
		return szTip
	end,
	[226] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("工笔勾线\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("作此画须谨记，用笔如轻云舒卷、自如似水、转折柔和、流畅不滞。\n", 7)
		return szTip
	end,
	[227] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("斗笔晕染\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("“墨即是色”，以墨的浓淡变化来渲染山水的层次感，表现出远近深浅。\n", 7)
		return szTip
	end,
	[228] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("作画\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("选好了，开始作画吧！\n", 7)
		return szTip
	end,
	[229] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("重来\n", 0) ..
		self.ColorText("点击选取。\n", 6) ..
		self.ColorText("好像和介绍上写的不太一样啊，重新选一次。\n", 7)
		return szTip
	end,
	[230] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("石头\n", 0) ..
		self.ColorText("点击出拳。\n", 6) ..
		self.ColorText("克制“剪刀”，被“布”克制。\n", 7)
		return szTip
	end,
	[231] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("剪刀\n", 0) ..
		self.ColorText("点击出拳。\n", 6) ..
		self.ColorText("克制“布”，被“石头”克制。\n", 7)
		return szTip
	end,
	[232] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("布\n", 0) ..
		self.ColorText("点击出拳。\n", 6) ..
		self.ColorText("克制“石头”，被“剪刀”克制。\n", 7)
		return szTip
	end,
	[233] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("石头\n", 0) ..
		self.ColorText("克制“剪刀”，被“布”克制。\n", 7)
		return szTip
	end,
	[234] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("剪刀\n", 0) ..
		self.ColorText("克制“布”，被“石头”克制。\n", 7)
		return szTip
	end,
	[235] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("布\n", 0) ..
		self.ColorText("克制“石头”，被“剪刀”克制。\n", 7)
		return szTip
	end,
	[236] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【猞猁·霜锋】\n", 0) ..
		self.ColorText("点击获取该宠物。\n", 6) ..
		self.ColorText("霜光乍开冲牛斗，三尺青锋斩邪祟。\n", 7)
		return szTip
	end,
	[237] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【猞猁·云渊】\n", 0) ..
		self.ColorText("点击获取该宠物。\n", 6) ..
		self.ColorText("轻身腾起掠云去，逐风跃渊疾千里。\n", 7)
		return szTip
	end,
	[238] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【猞猁·青阳】\n", 0) ..
		self.ColorText("点击获取该宠物。\n", 6) ..
		self.ColorText("春风三月渡钱江，青阳临岁启花朝。\n", 7)
		return szTip
	end,
	[239] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【猞猁·寒烟】\n", 0) ..
		self.ColorText("点击获取该宠物。\n", 6) ..
		self.ColorText("清电忽过步惊寒，飒沓无踪隐如烟。\n", 7)
		return szTip
	end,
	[240] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【猞猁·鸣玉】\n", 0) ..
		self.ColorText("点击获取该宠物。\n", 6) ..
		self.ColorText("击玉为歌鸣剑意，万金掷去买酒回。\n", 7)
		return szTip
	end,
	[241] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【灵猴·悟凡】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("嬉笑腾挪悟凡尘，九窍玲珑参众生。\n", 7)
		return szTip
	end,
	[242] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【灵猴·灵心】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("方寸灵台却前事，瞑目只观菩提心。\n", 7)
		return szTip
	end,
	[243] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【灵猴·明意】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("莲台趺坐持清净，意如明镜照因缘。\n", 7)
		return szTip
	end,
	[244] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【灵猴·知禅】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("花开指上拈取笑，竹隐禅心偕暮归。\n", 7)
		return szTip
	end,
	[245] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【灵猴·谛梵】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("青灯燃香忘痴嗔，五蕴皆空听梵音。\n", 7)
		return szTip
	end,
	[246] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【兔子·黛眉】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("青烟淡笼远山颦，黛色新着犹昨画。\n", 7)
		return szTip
	end,
	[247] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【兔子·绾桃】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("一枝横斜春风里，云鬓凝光绾夭华。\n", 7)
		return szTip
	end,
	[248] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【兔子·湫瞳】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("三千潋滟动秋心，盈盈剪尽相思意。\n", 7)
		return szTip
	end,
	[249] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【兔子·绯心】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("小袖连翩舞霓裳，谁点朱砂记眉心。\n", 7)
		return szTip
	end,
	[250] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【兔子·嫣染】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("箫管寄情逗嫣然，碧桃入画扇染香。\n", 7)
		return szTip
	end,
	[251] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【松鼠·琢玉】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("天工巧致造风流，切磋琢磨凝匠心。\n", 7)
		return szTip
	end,
	[252] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【松鼠·云萝】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("云间拾径采药去，青萝绕溪忘归期。\n", 7)
		return szTip
	end,
	[253] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【松鼠·雨墨】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("雨翻山岚风满楼，几点入诗湮墨色。\n", 7)
		return szTip
	end,
	[254] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【松鼠·银朱】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("妙笔绘成丹青意，指染朱砂缠情思。\n", 7)
		return szTip
	end,
	[255] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【松鼠·檀书】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("数缕檀烟暗香渡，漫卷诗书挑灯花。\n", 7)
		return szTip
	end,
	[256] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【小狼·昊苍】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("昊穹长啸霜晨月，一身独立临苍巅。\n", 7)
		return szTip
	end,
	[257] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【小狼·雪影】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("雪原驰影斗虎豹，凛寒孤心本不群。\n", 7)
		return szTip
	end,
	[258] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【小狼·风霆】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("势如霹雳龙蛇惧，奔突远趋动风霆。\n", 7)
		return szTip
	end,
	[259] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【小狼·越泽】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("矫身信纵越重泽，足踏惊雷绝天涯。\n", 7)
		return szTip
	end,
	[260] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【小狼·疾幽】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("疾电裂空破混沌，玄影无迹探幽皋。\n", 7)
		return szTip
	end,
	[261] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【凌霄】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("扶摇直起凌风去，一声长唳清重霄。\n", 7)
		return szTip
	end,
	[262] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【隐雪】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("身本寂寥著霜雪，千山尽素隐仙姿。\n", 7)
		return szTip
	end,
	[263] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【归云】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("谁照九天瑶池影，便振遥翮归云间。\n", 7)
		return szTip
	end,
	[264] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【观月】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("流光浮动舞玉羽，月下临泉观道心。\n", 7)
		return szTip
	end,
	[265] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【聆松】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("万壑声起尽松音，独立林中且听风。\n", 7)
		return szTip
	end,
	[266] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【华羽】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("华光落羽绘锦屏，独栖仙乡远流年。\n", 7)
		return szTip
	end,
	[267] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【惊虹】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("一曲清舞惊九天，便裁虹色织绣衣。\n", 7)
		return szTip
	end,
	[268] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【素翎】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("灵秀天成傲凡羽，玉雪为魂着素裳。\n", 7)
		return szTip
	end,
	[269] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【璨星】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("璨彩浮金曜尘寰，从容闲步倾众生。\n", 7)
		return szTip
	end,
	[270] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【银月】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("琢银叠玉化仙身，清泉濯羽伴月眠。\n", 7)
		return szTip
	end,
	[271] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【猞猁·飞景】\n", 0) ..
		self.ColorText("点击获取该宠物。\n", 6) ..
		self.ColorText(" 流光飞景醉里看，依山煮酒意逍遥。\n", 7)
		return szTip
	end,
	[272] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【碧灵】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("碧衣独舞应丝竹，翩然乘月归瑶宫。\n", 7)
		return szTip
	end,
	[273] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【栖寒】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("性喜清寒栖云山，孤绝只为松石客。\n", 7)
		return szTip
	end,
	[274] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【小狼·凌岳】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("万仞险峰何足惧，直上峥嵘凌绝顶。\n", 7)
		return szTip
	end,
	[275] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【松鼠·风荷】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("风动满池清圆举，小舟一叶载荷来。\n", 7)
		return szTip
	end,
	[276] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【兔子·青蘅】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("朝步兰泽撷幽草，晚来涉江采蘅归。\n", 7)
		return szTip
	end,
	[277] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【灵猴·了然】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("往来三生皆了然，芥子须弥一笑观。\n", 7)
		return szTip
	end,
	[278] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("唐门机关猪·镖靶\n", 7) ..
		self.ColorText("点击选定获取该宠物\n", 6) ..
		self.ColorText("唐门秘制机关猪，会卖子弹会卖萌。", 1)
		return szTip
	end,
	[279] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"确定"
		local szTip =	self.ColorText("唐门机关猪·飞翼\n", 7) ..
		self.ColorText("点击选定获取该宠物\n", 6) ..
		self.ColorText("唐门秘制机关猪，会卖子弹会卖萌。", 1)
		return szTip
	end,
	[280] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【飞鸿】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("燕隼，燕雀焉知，鸿鹄之志。\n", 7)
		return szTip
	end,
	[281] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【栖夜】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("墨隼，月黑风高，静谧猎手。\n", 7)
		return szTip
	end,
	[282] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【赤箭】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("红隼，如箭在弦，勇往直前。\n", 7)
		return szTip
	end,
	[283] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【紫翎】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("紫隼，穿云御风，亟如闪电。\n", 7)
		return szTip
	end,
	[284] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【白凤】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("白隼，雪白无垢，鸟中王者。\n", 7)
		return szTip
	end,
	[285] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【苍翼】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("苍隼，翼展宽大，迅猛霸王。\n", 7)
		return szTip
	end,
	[286] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【球球】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6)
		return szTip
	end,
	[287] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【花花】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6)
		return szTip
	end,
	[288] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【桃桃】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6)
		return szTip
	end,
	[289] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【糖糖】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6)
		return szTip
	end,
	[290] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【妃妃】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6)
		return szTip
	end,
	[291] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【豆豆】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6)
		return szTip
	end,

	[292] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【吟风】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6)
		return szTip
	end,
	[293] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【踏雪】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6)
		return szTip
	end,
	[294] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【暮春】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6)
		return szTip
	end,
	[295] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【画秋】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6)
		return szTip
	end,
	[296] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【立夏】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6)
		return szTip
	end,
	[297] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【银冬】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6)
		return szTip
	end,
	
	[298] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【鼎鼎】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("白狮鼎鼎，威风傲气小霸王。\n", 7)
		return szTip
	end,
	[299] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【兜兜】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("白狮兜兜，乖巧柔顺爱撒娇。\n", 7)
		return szTip
	end,
	[300] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【圈圈】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("白狮圈圈，天真可爱惹人怜。\n", 7)
		return szTip
	end,
	[301] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【悠悠】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("棕狮悠悠，活泼俏皮爱捣蛋。\n", 7)
		return szTip
	end,
	[302] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【云云】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("白狮云云，乖乖萌萌惹人爱。", 7)
		return szTip
	end,
	[303] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【路路】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("黄狮路路，帅气坚毅胆子大。", 7)
		return szTip
	end,
	[304] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【明月幽昙】\n", 0) ..
		self.ColorText("点击选定获取该背部挂件。\n", 6) ..
		self.ColorText("月出皎兮，佼人僚兮。舒窈纠兮，劳心悄兮。", 7)
		return szTip
	end,
	[305] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【暗香疏影】\n", 0) ..
		self.ColorText("点击选定获取该背部挂件。\n", 6) ..
		self.ColorText("香中别有韵，清极不知寒。", 7)
		return szTip
	end,
	[306] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("鼠标左键点击加入霸刀山庄。\n", 0)
		return szTip
	end,
	[307] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【骞雷】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("疾电骞飞裂青冥，刀引风雷动北关。", 7)
		return szTip
	end,
	[308] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【映霜】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("山月照林白露起，流霜映谷浮清光。", 7)
		return szTip
	end,
	[309] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【璎珞】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("榴珠绛玉散银盘，泠响应歌笑语传。", 7)
		return szTip
	end,
	[310] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【重雪】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("雪重阶前琼花隐，小炉拥衣酌酒观。", 7)
		return szTip
	end,
	[311] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【秋岚】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("微雨带岚逗秋寒，丹枫映霞听晚鸦。", 7)
		return szTip
	end,
	[312] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【逐星】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("星垂平野孤月冷，穿山越林影如风。", 7)
		return szTip
	end,	
	[313] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【游春图】\n", 0) ..
		self.ColorText("白轩之评\n此画为隋展子虞所作。山形耸峙，水波浩淼，万物复苏，祥云涌动。游人从四方纷至沓来，有泛舟水上者，有骑马伫立者，三两成群翘首山景。游人与山水之间的和谐，只觉春意盎然，极富情趣。展子虞不愧为山水之画的鼻祖。", 7)
		return szTip
	end,
	[314] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【京畿瑞雪图纨扇轴】\n", 0) ..
		self.ColorText("白轩之评\n此画原为雨鸾纨扇之图，乃前人李思训所作，我将其临摹于纸上。冬雪之后，并未完全融化，尚有积雪在房顶，而地面却已然干净清爽。京城之中，已见人行走，外出。小小的画中，竟将多人的姿态神情表现得如此细腻，淋漓尽致，实在是佩服！", 7)
		return szTip
	end,
	[315] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【洛神】\n", 0) ..
		self.ColorText("白轩之评\n东晋大画家顾恺之所画《洛神赋图》，源自三国曹植的洛神赋。翩若惊鸿，婉若游龙。荣曜秋菊，华茂春松。仿佛兮若轻云之蔽月，飘飘兮若流风之回雪。远而望之，皎若太阳升朝霞；迫而察之，灼若芙蕖出渌波。襛纤得衷，修短合度。肩若削成，腰如约素。延颈秀项，皓质呈露。芳泽无加，铅华弗御。云髻峨峨，修眉联娟。丹唇外朗，皓齿内鲜，明眸善睐，靥辅承权。瑰姿艳逸，仪静体闲。柔情绰态，媚于语言。奇服旷世，骨像应图。披罗衣之璀粲兮，珥瑶碧之华琚。戴金翠之首饰，缀明珠以耀躯。践远游之文履，曳雾绡之轻裾。微幽兰之芳蔼兮，步踟蹰于山隅。", 7)
		return szTip
	end,
	[316] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【远眺纯阳三清殿】\n", 0) ..
		self.ColorText("白轩之评\n华山之巅，纯阳三清，云雾缭绕，瑞雪四方。远眺三清殿，隐于雪云之中，恢弘而清秀，大有道家之幽宁。有箫笙之曲缓缓而来，让人忘却世间尘事，犹如来到仙境一般。此等景象显于画中尚且如此，何况亲到纯阳坐山远眺？", 7)
		return szTip
	end,
	[317] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【维摩诘像】\n", 0) ..
		self.ColorText("白轩之评\n三国吴人曹不兴，乃是佛家画像的祖师，旗下弟子甚多：顾恺之，张僧繇皆随其学过作画。此幅维摩诘像，众人皆传为顾恺之所作，然以我之见，此画的手法及风格与曹不兴极其相似。年代过去久远却也无法考证。", 7)
		return szTip
	end,
	[318] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【吴道子之神仙图】\n", 0) ..
		self.ColorText("白轩之评\n此卷为吾师吴道子所画《神仙图》：东华帝君、南极帝君在侍者、仪杖、乐队的陪同之下，率领真人、神仙、金童、玉女、神将前去朝谒道教三位天尊。画中神将开道；帝君头上有背光，居于众仙之中；其他神仙则持幡旗、伞盖、贡品、乐器等，簇拥着帝君从右往左浩荡行而进。众仙中，帝君、神仙形象端庄，神将威风凛凛，众多仙女轻盈秀丽。吴道子用刚中有柔，遒劲潇洒的线条将风动云飘的神仙之境尽显于纸上。", 7)
		return szTip
	end,
	[319] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【阎立本之步辇图】\n", 0) ..
		self.ColorText("白轩之评\n初唐阎立本善人物画，多画宫廷帝王之像。此画描绘了吐蕃王松赞干布遣使臣禄东赞来唐迎文成公主入藏成亲。此画笔法遒劲简练，设色浓重而无繁复，仅著红、黑、白、淡赭而成，却已丰满无比。", 7)
		return szTip
	end,
	[320] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【张旭·古诗四帖】\n", 0) ..
		self.ColorText("颜真卿之评\n张旭向来以草书知名，此帖形式高美、气魂宏大，犹若展开一幅雄伟壮阔的书卷。", 7)
		return szTip
	end,
	[321] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【王羲之·丧乱帖】\n", 0) ..
		self.ColorText("颜真卿之评\n此帖为勾填本，摹填精良。此帖为书信，随手拟就，无意于书，故书逾见自然。用笔结字略带古意，或云比之兰亭更近王右军字之本貌。", 7)
		return szTip
	end,
	[322] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【欧阳询·张翰帖】\n", 0) ..
		self.ColorText("颜真卿之评\n此帖字体修长，笔力刚劲挺拔，风格险峻，精神外露。", 7)
		return szTip
	end,
	[323] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("玩具·风车\n", 7) ..
		self.ColorText("使用：放入玩具柜中，可增加好感度。\n", 6) ..
		self.ColorText("相当常见的玩具，孩子们应该会喜欢。\n", 0)  ..
		self.ColorText("\n点击制作：需拥有相应挂件作为原型。\n", 7)
		return szTip
	end,
	[324] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("玩具·风筝\n", 7) ..
		self.ColorText("使用：放入玩具柜中，可增加好感度。\n", 6) ..
		self.ColorText("相当常见的玩具，孩子们应该会喜欢。\n", 0)  ..
		self.ColorText("\n点击制作：需拥有相应挂件作为原型。\n", 7)
		return szTip
	end,
	[325] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("玩具·灯笼\n", 7) ..
		self.ColorText("使用：放入玩具柜中，可增加好感度。\n", 6) ..
		self.ColorText("相当常见的玩具，孩子们应该会喜欢。\n", 0)  ..
		self.ColorText("\n点击制作：需拥有相应挂件作为原型。\n", 7)
		return szTip
	end,
	[326] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("玩具·号角\n", 7) ..
		self.ColorText("使用：放入玩具柜中，可增加好感度。\n", 6) ..
		self.ColorText("相当常见的玩具，孩子们应该会喜欢。\n", 0)  ..
		self.ColorText("\n点击制作：需拥有相应挂件作为原型。\n", 7)
		return szTip
	end,
	[327] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("玩具·娃娃\n", 6) ..
		self.ColorText("使用：放入玩具柜中，可增加好感度。\n", 6) ..
		self.ColorText("较为精致的玩具，受孩子们欢迎。\n", 0)  ..
		self.ColorText("\n点击制作：需拥有相应挂件作为原型。\n", 7)
		return szTip
	end,
	[328] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("玩具·三味净琉璃\n", 6) ..
		self.ColorText("使用：放入玩具柜中，可增加好感度。\n", 6) ..
		self.ColorText("较为精致的玩具，受孩子们欢迎。\n", 0)  ..
		self.ColorText("\n点击制作：需拥有相应挂件作为原型。\n", 7)
		return szTip
	end,
	[329] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("玩具·忆红颜\n", 5) ..
		self.ColorText("使用：放入玩具柜中，可增加好感度。\n", 6) ..
		self.ColorText("非常精致的玩具，孩子们很喜欢。\n", 0)  ..
		self.ColorText("\n点击制作：需拥有相应挂件作为原型。\n", 7)
		return szTip
	end,
	[330] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("玩具·肚兜娃娃\n", 5) ..
		self.ColorText("使用：放入玩具柜中，可增加好感度。\n", 6) ..
		self.ColorText("非常精致的玩具，孩子们很喜欢。\n", 0)  ..
		self.ColorText("\n点击制作：需拥有相应挂件作为原型。\n", 7)
		return szTip
	end,
	[331] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("玩具·风荷凌波\n", 13) ..
		self.ColorText("使用：放入玩具柜中，可增加好感度。\n", 6) ..
		self.ColorText("极为精巧的玩具，是孩子们的最爱。\n", 0)  ..
		self.ColorText("\n点击制作：需拥有相应挂件作为原型。\n", 7)
		return szTip
	end,
	[332] = function(rect, bVisibleWhenHideUI) --未使用
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("玩具·碧麟\n", 5) ..
		self.ColorText("使用：放入玩具柜中，可增加好感度。\n", 6) ..
		self.ColorText("非常精致的玩具，孩子们很喜欢。\n", 0)  ..
		self.ColorText("\n点击制作：需拥有相应挂件作为原型。\n", 7)
		return szTip
	end,
	[333] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("玩具·鲤鱼\n", 5) ..
		self.ColorText("使用：放入玩具柜中，可增加好感度。\n", 6) ..
		self.ColorText("非常精致的玩具，孩子们很喜欢。\n", 0)  ..
		self.ColorText("\n点击制作：需拥有相应挂件作为原型。\n", 7)
		return szTip
	end,
	[334] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("玩具·腰鼓\n", 5) ..
		self.ColorText("使用：放入玩具柜中，可增加好感度。\n", 6) ..
		self.ColorText("非常精致的玩具，孩子们很喜欢。\n", 0)  ..
		self.ColorText("\n点击制作：需拥有相应挂件作为原型。\n", 7)
		return szTip
	end,
	[335] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("玩具·童梦\n", 5) ..
		self.ColorText("使用：放入玩具柜中，可增加好感度。\n", 6) ..
		self.ColorText("非常精致的玩具，孩子们很喜欢。\n", 0)  ..
		self.ColorText("\n点击制作：需拥有相应挂件作为原型。\n", 7)
		return szTip
	end,
	[336] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("玩具·木鱼\n", 13) ..
		self.ColorText("使用：放入玩具柜中，可增加好感度。\n", 6) ..
		self.ColorText("极为精巧的玩具，是孩子们的最爱。\n", 0)  ..
		self.ColorText("\n点击制作：需拥有相应挂件作为原型。\n", 7)
		return szTip
	end,
	[337] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("玩具·愤怒的鸟杖\n", 13) ..
		self.ColorText("使用：放入玩具柜中，可增加好感度。\n", 6) ..
		self.ColorText("极为精巧的玩具，是孩子们的最爱。\n", 0)  ..
		self.ColorText("\n点击制作：需拥有相应挂件作为原型。\n", 7)
		return szTip
	end,
	[338] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("玩具·木武童\n", 13) ..
		self.ColorText("使用：放入玩具柜中，可增加好感度。\n", 6) ..
		self.ColorText("极为精巧的玩具，是孩子们的最爱。\n", 0)  ..
		self.ColorText("\n点击制作：需拥有相应挂件作为原型。\n", 7)
		return szTip
	end,
	[339] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("玩具·惊声尖叫\n", 13) ..
		self.ColorText("使用：放入玩具柜中，可增加好感度。\n", 6) ..
		self.ColorText("极为精巧的玩具，是孩子们的最爱。\n", 0)  ..
		self.ColorText("\n点击制作：需拥有相应挂件作为原型。\n", 7)
		return szTip
	end,
	[340] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("玩具·塞外声\n", 13) ..
		self.ColorText("使用：放入玩具柜中，可增加好感度。\n", 6) ..
		self.ColorText("极为精巧的玩具，是孩子们的最爱。\n", 0)  ..
		self.ColorText("\n点击制作：需拥有相应挂件作为原型。\n", 7)
		return szTip
	end,
	[341] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("玩具·七彩风车\n", 13) ..
		self.ColorText("使用：放入玩具柜中，可增加好感度。\n", 6) ..
		self.ColorText("极为精巧的玩具，是孩子们的最爱。\n", 0)  ..
		self.ColorText("\n点击制作：需拥有相应挂件作为原型。\n", 7)
		return szTip
	end,
	[342] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("玩具·玲珑藏梦\n", 13) ..
		self.ColorText("使用：放入玩具柜中，可增加好感度。\n", 6) ..
		self.ColorText("极为精巧的玩具，是孩子们的最爱。\n", 0)  ..
		self.ColorText("\n点击制作：需拥有相应挂件作为原型。\n", 7)
		return szTip
	end,
	[343] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("玩具·溯流光\n", 13) ..
		self.ColorText("使用：放入玩具柜中，可增加好感度。\n", 6) ..
		self.ColorText("极为精巧的玩具，是孩子们的最爱。\n", 0)  ..
		self.ColorText("\n点击制作：需拥有相应挂件作为原型。\n", 7)
		return szTip
	end,
	[344] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("稻香饼\n", 6) ..
		self.ColorText("稻米做成可口米饼，农家风味。\n", 0)  ..
		self.ColorText("\n点击制作：消耗精力13点。需【精制面粉】两份，【大葱】两份。\n", 7)
		return szTip
	end,
	[345] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("鲜肉包子\n", 6) ..
		self.ColorText("白面包鲜肉，香溢蒸笼间。\n", 0)  ..
		self.ColorText("\n点击制作：消耗精力7点。需【碎肉】两份，【精制面粉】一份，【调料】一份。\n", 7)
		return szTip
	end,
	[346] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("馄饨\n", 6) ..
		self.ColorText("清汤、薄皮、鲜肉馅儿！\n", 0)  ..
		--self.ColorText("\n点击制作：消耗精力13点。需【碎肉】两份，【精制面粉】两份，【调料】一份，【五莲泉】一份。\n", 7)
		self.ColorText("\n点击制作：消耗精力13点。需【碎肉】两份，【精制面粉】两份，【调料】一份。\n", 7)
		return szTip
	end,
	[347] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("肉馅团子\n", 6) ..
		self.ColorText("团团圆圆，雪雪一顿能吃下几个呢？\n", 0)  ..
		self.ColorText("\n点击制作：消耗精力15点。需【杂碎】一份，【大葱】五份，【精肉】十五份，【料酒】一份。\n", 7)
		return szTip
	end,
	[348] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("冬瓜烧肉\n", 6) ..
		self.ColorText("有点儿难烧的家常菜。\n", 0)  ..
		self.ColorText("\n点击制作：消耗精力15点。需【杂碎】一份，【新鲜冬瓜】五份，【精肉】十五份，【调料】一份。\n", 7)
		return szTip
	end,
	[349] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("黄瓜烧肉\n", 6) ..
		self.ColorText("有点儿难烧的家常菜。\n", 0)  ..
		self.ColorText("\n点击制作：消耗精力15点。需【杂碎】一份，【青瓜】五份，【精肉】十五份，【料酒】一份。\n", 7)
		return szTip
	end,
	[350] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("肉粥\n", 6) ..
		self.ColorText("鲜香的肉粥，肉放得有点儿多。\n", 0)  ..
		self.ColorText("\n点击制作：消耗精力15点。需【杂碎】一份，【老姜】五份，【精肉】十五份，【调料】一份。\n", 7)
		return szTip
	end,
	[351] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("蘑菇炖肉\n", 6) ..
		self.ColorText("有点儿难烧的家常菜。\n", 0)  ..
		self.ColorText("\n点击制作：消耗精力15点。需【杂碎】一份，【菌菇】五份，【精肉】十五份，【料酒】一份。\n", 7)
		return szTip
	end,
	[352] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("鼠标左键点击加入蓬莱。\n", 0)
		return szTip
	end,
	[353] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【戏鞠】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("平野新绿逐飞球，小儿戏鞠莫识愁。", 7)
		return szTip
	end,	
	[354] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【羽仪】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("春日花繁莺啼色，东风摇树满庭芳。", 7)
		return szTip
	end,	
	[355] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【瑶华】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("瑶山琼台舒高意，昊境天姿化清绝。", 7)
		return szTip
	end,	
	[356] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【霂霏】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("霏霏霂雨浥罗裳，云伞步微踏青阳。", 7)
		return szTip
	end,	
	[357] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【晴鸢】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("晴空一片尽沧海，鸢飞万里渡重天。", 7)
		return szTip
	end,	
	[358] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【珠玑】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("波顷云涛连天涌，白浪浮崖溅珠玑。", 7)
		return szTip
	end,	
	[359] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("凝血露\n", 5) ..
		self.ColorText("使用：回复中量气血，可在战斗中使用。\n", 6)  ..
		self.ColorText("由凝血灵草粗炼而成，止血疗伤效果甚佳。\n", 0)  ..
		self.ColorText("点击制作：需【凝血草】一份。\n", 7)
		return szTip
	end,	
	[360] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("凝血精\n", 13) ..
		self.ColorText("使用：回复大量气血，可在战斗中使用。\n", 6)  ..
		self.ColorText("集凝血之精，腐骨生肌，滞脉重续，不在话下。\n", 0)  ..
		self.ColorText("点击制作：需【凝血草】三份。\n", 7)
		return szTip
	end,
	[361] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("劲骨散\n", 5) ..
		self.ColorText("使用：驱散两时辰外功防御等级降低不利效果。\n", 6)  ..
		self.ColorText("劲骨灵草入药而成，效用倍增。\n", 0)  ..
		self.ColorText("点击制作：需【引灵草】一份，【劲骨草】两份。\n", 7)
		return szTip
	end,
	[362] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("伤阳散\n", 5) ..
		self.ColorText("使用：驱散两时辰阳性内功防御等级降低不利效果。\n", 6)  ..
		self.ColorText("伤阳草入药而成，有传一无名游医采草作方，炼制而出。\n", 0)  ..
		self.ColorText("点击制作：需【引灵草】一份，【伤阳草】两份。\n", 7)
		return szTip
	end,
	[363] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("化阴散\n", 5) ..
		self.ColorText("使用：驱散两时辰阴性内功防御等级降低不利效果。\n", 6)  ..
		self.ColorText("化阴草入药而成，因化阴伤阳二草药性相仿，功效相反，便按伤阳散方炼制而成，亦有奇效。\n", 0)  ..
		self.ColorText("点击制作：需【引灵草】一份，【化阴草】两份。\n", 7)
		return szTip
	end,
	[364] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("毒清散\n", 5) ..
		self.ColorText("使用：驱散两时辰毒性内功防御等级降低不利效果。\n", 6)  ..
		self.ColorText("初为山野樵民猎户所用以防毒蛇，后人改良后使其效用更广。\n", 0)  ..
		self.ColorText("点击制作：需【引灵草】一份，【毒清草】两份。\n", 7)
		return szTip
	end,
	[365] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("静神丹\n", 13) ..
		self.ColorText("使用：驱散两时辰所有非防御属性等级降低不利时辰效果。\n", 6)  ..
		self.ColorText("谓言灵无上，妙药心神秘。\n", 0)  ..
		self.ColorText("点击制作：需【引灵草】一份，【静神草】两份。\n", 7)
		return szTip
	end,
	[366] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("稻香饭\n", 6) ..
		self.ColorText("使用：增加饱食度，回复生命值。\n", 6)  ..
		self.ColorText("脱粟为餐，炊红稻熟，珠润融香，食饱正酣。\n", 0)  ..
		self.ColorText("点击制作：需【米】一份。\n", 7)
		return szTip
	end,
	[367] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("劲骨餐\n", 6) ..
		self.ColorText("使用：增加饱食度，回复生命值，一时辰内少量提升外功防御等级。\n", 6)  ..
		self.ColorText("入鼎资过熟，加餐愁欲无。\n", 0)  ..
		self.ColorText("点击制作：需【米】一份，【劲骨草】一份。\n",7)
		return szTip
	end,
	[368] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("佳·劲骨餐\n", 5) ..
		self.ColorText("使用：增加饱食度，回复生命值，一时辰内中量提升外功防御等级。\n", 6)  ..
		self.ColorText("饼炉饭甑无饥色，接到西风熟稻天。\n", 0)  ..
		self.ColorText("点击制作：需【米】一份，【劲骨草】两份。\n",7)
		return szTip
	end,
	[369] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("伤阳餐\n", 6) ..
		self.ColorText("使用：增加饱食度，回复生命值，一时辰内少量提升阳性内功防御等级。\n", 6)  ..
		self.ColorText("彼君子兮，不素餐兮！\n", 0)  ..
		self.ColorText("点击制作：需【米】一份，【伤阳草】一份。\n",7)
		return szTip
	end,
	[370] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("佳·伤阳餐\n", 5) ..
		self.ColorText("使用：增加饱食度，回复生命值，一时辰内中量提升阳性内功防御等级。\n", 6)  ..
		self.ColorText("幡幡瓠叶，采之亨之。\n", 0)  ..
		self.ColorText("点击制作：需【米】一份，【伤阳草】两份。\n",7)
		return szTip
	end,
	[371] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("化阴餐\n", 6) ..
		self.ColorText("使用：增加饱食度，回复生命值，一时辰内少量提升阴性内功防御等级。\n", 6)  ..
		self.ColorText("笾豆有践，兄弟无远。\n", 0)  ..
		self.ColorText("点击制作：需【米】一份，【化阴草】一份。\n",7)
		return szTip
	end,
	[372] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("佳·化阴餐\n", 5) ..
		self.ColorText("使用：增加饱食度，回复生命值，一时辰内中量提升阴性内功防御等级。\n", 6)  ..
		self.ColorText("碧鲜俱照箸，香饭兼苞芦。\n", 0)  ..
		self.ColorText("点击制作：需【米】一份，【化阴草】两份。\n",7)
		return szTip
	end,
	[373] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("毒清餐\n", 6) ..
		self.ColorText("使用：增加饱食度，回复生命值，一时辰内少量提升毒性内功防御等级。\n", 6)  ..
		self.ColorText("香稻熟来秋菜嫩，伴僧餐了听云和。\n", 0)  ..
		self.ColorText("点击制作：需【米】一份，【毒清草】一份。\n",7)
		return szTip
	end,
	[374] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("佳·毒清餐\n", 5) ..
		self.ColorText("使用：增加饱食度，回复生命值，一时辰内中量提升毒性内功防御等级。\n", 6)  ..
		self.ColorText("柴门寂寂黍饭馨，山家烟火春雨晴。\n", 0)  ..
		self.ColorText("点击制作：需【米】一份，【毒清草】两份。\n",7)
		return szTip
	end,
	[375] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("会力餐\n", 6) ..
		self.ColorText("使用：增加饱食度，回复生命值，两时辰内少量提升基础攻击。\n", 6)  ..
		self.ColorText("厨香吹黍调和酒，窗暖安弦拂拭琴。\n", 0)  ..
		self.ColorText("点击制作：需【米】一份，【会力草】一份。\n",7)
		return szTip
	end,
	[376] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("佳·会力餐\n", 5) ..
		self.ColorText("使用：增加饱食度，回复生命值，两时辰内中量提升基础攻击。\n", 6)  ..
		self.ColorText("霜余蔬甲淡中甜，春近录苗嫩不蔹。\n", 0)  ..
		self.ColorText("点击制作：需【米】一份，【会力草】两份。\n",7)
		return szTip
	end,
	[377] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("香炙肉\n", 6) ..
		self.ColorText("使用：增加饱食度，恢复生命值和心情值。\n", 6)  ..
		self.ColorText("秀色可怜刀切肉，清香不断鼎烹龙。\n", 0)  ..
		self.ColorText("点击制作：需【生肉】一份。\n", 7)
		return szTip
	end,
	[378] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("碧丝玉脍\n", 5) ..
		self.ColorText("使用：增加饱食度，恢复生命值和心情值，一时辰内受到的治疗效果小幅提升。\n", 6)  ..
		self.ColorText("饔子左右挥双刀，脍飞金盘白雪高。\n", 0)  ..
		self.ColorText("点击制作：需【生肉】一份，【会力草】一份。\n", 7)
		return szTip
	end,
	[379] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("盐菽青\n", 5) ..
		self.ColorText("使用：增加饱食度，回复生命值，短时间内免疫减攻击力时辰不利效果。\n", 6)  ..
		self.ColorText("饼炉饭甑无饥色，接到西风熟稻天。\n", 0)  ..
		self.ColorText("点击制作：需【米】一份，【劲骨草】两份，【伤阳草】两份。\n", 7)
		return szTip
	end,
	[380] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("春蓼盘\n", 5) ..
		self.ColorText("使用：增加饱食度，回复生命值，短时间内免疫减气血上限时辰不利效果。\n", 6)  ..
		self.ColorText("朝食琅轩实，夕饮玉池津。\n", 0)  ..
		self.ColorText("点击制作：需【米】一份，【劲骨草】两份，【化阴草】两份。\n", 7)
		return szTip
	end,
	[381] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("浮蔷苋\n", 5) ..
		self.ColorText("使用：增加饱食度，回复生命值，短时间内免疫持续掉血时辰不利效果。\n", 6)  ..
		self.ColorText("食饱心自若，酒酣气益振。\n", 0)  ..
		self.ColorText("点击制作：需【米】一份，【毒清草】两份，【伤阳草】两份。\n", 7)
		return szTip
	end,
	[382] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("蒲江荠\n", 5) ..
		self.ColorText("使用：增加饱食度，回复生命值，短时间内免疫减疗时辰不利效果。\n", 6)  ..
		self.ColorText("我得宛丘平易法，只将食粥致神仙。\n", 0)  ..
		self.ColorText("点击制作：需【米】一份，【化阴草】两份，【毒清草】两份。\n", 7)
		return szTip
	end,
	[383] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("大碗稻香饭\n", 5) ..
		self.ColorText("使用：增加饱食度，快速回复大量生命值。\n", 6)  ..
		self.ColorText("脱粟为餐，炊红稻熟，珠润融香，食饱正酣。\n", 0)  ..
		self.ColorText("点击制作：需【米】十份。\n", 7)
		return szTip
	end,
	[384] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("鼠标左键点击加入凌雪阁。\n", 0)
		return szTip
	end,

	
	[385] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【白牙】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("白牙咎齿，不问是非。", 7)
		return szTip
	end,
	[386] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【暮鸦】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("暮鸦啼晓，柳暗花明。", 7)
		return szTip
	end,
	[387] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【摧火】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("摧火焚心，但为君故。", 7)
		return szTip
	end,
	[388] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【铁锋】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("铁锋掠空，踏雁无痕。", 7)
		return szTip
	end,
	[389] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【渔灯】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("渔灯不眠，初心不灭。", 7)
		return szTip
	end,
	[390] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【荒丘】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("荒丘白骨，不见归人。", 7)
		return szTip
	end,
	[391] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("饺子\n", 0) ..
		self.ColorText("一份冒着热气的饺子。\n", 6) ..
		self.ColorText("这份饺子，有人说咸，有人说淡。", 7)
		return szTip
	end,
	[392] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("茶水\n", 0) ..
		self.ColorText("唇齿留香。\n", 6) ..
		self.ColorText("甜甜温泉山庄特供茶水。", 7)
		return szTip
	end,
	[393] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("皮衣\n", 0) ..
		self.ColorText("皮质的贴身衣物，轻便保暖。\n", 6) ..
		self.ColorText("如果它有外观，一定很贵。", 7)
		return szTip
	end,
	[394] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("玉山酒\n", 0) ..
		self.ColorText("玉山泉水所酿的酒，回味甘甜。\n", 6) ..
		self.ColorText("醋簇说它真的没有兑水。", 7)
		return szTip
	end,
	[395] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("药包\n", 0) ..
		self.ColorText("温泉用药包。\n", 6) ..
		self.ColorText("据说令人神清气爽，延年益寿。", 7)
		return szTip
	end,
	[396] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("玉雕\n", 0) ..
		self.ColorText("携带：玉质小巧的雕像，据传能够辟邪。\n", 6) ..
		self.ColorText("甜甜温泉山庄特产玉雕。", 7)
		return szTip
	end,
	[397] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("面粉\n", 0) ..
		self.ColorText("携带：常见的面粉，可从行脚商处购得。\n", 6) ..
		self.ColorText("馒头、包子、面条都是面做的，超好吃。", 7)
		return szTip
	end,
	[398] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("茶叶\n", 0) ..
		self.ColorText("常见的茶叶，可从行脚商处购得。\n", 6) ..
		self.ColorText("茶，是一门艺术。", 7)
		return szTip
	end,
	[399] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("糖\n", 0) ..
		self.ColorText("携带：常见的白糖，可从行脚商处购得。\n", 6) ..
		self.ColorText("甜的，吃了心情会变好。", 7)
		return szTip
	end,
	[400] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("米\n", 0) ..
		self.ColorText("携带：常见的大米，可从行脚商处购得。\n", 6) ..
		self.ColorText("一顿不吃，饿得慌。", 7)
		return szTip
	end,
	[401] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("布\n", 0) ..
		self.ColorText("常见的布匹，可从行脚商处购得。\n", 6) ..
		self.ColorText("可以做漂亮的衣服。", 7)
		return szTip
	end,
	[402] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("木材\n", 0) ..
		self.ColorText("用于建造房屋或维持整个山庄供暖。\n", 6) ..
		self.ColorText("木头是普通木头，但能起到十分重要的作用。", 7)
		return szTip
	end,
	[403] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("石材\n", 0) ..
		self.ColorText("用于建造房屋。\n", 6) ..
		self.ColorText("建造房屋的必备材料之一。", 7)
		return szTip
	end,
	[404] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("炒饭\n", 0) ..
		self.ColorText("简单的炒饭。\n", 6) ..
		self.ColorText("好吃，不腻。", 7)
		return szTip
	end,
	[405] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("地三鲜\n", 0) ..
		self.ColorText("清淡的素菜，很养生。\n", 6) ..
		self.ColorText("甜甜温泉山庄特供，傲油的拿手菜之一。", 7)
		return szTip
	end,
	[406] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("锅包肉\n", 0) ..
		self.ColorText("外表酥脆，内里多汁。\n", 6) ..
		self.ColorText("甜甜温泉山庄特供，傲油的拿手菜之一。", 7)
		return szTip
	end,
	[407] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("菌菇宴\n", 0) ..
		self.ColorText("携带：用各种菌类做成的美味菌菇宴。\n", 6) ..
		self.ColorText("听闻吃多了会看见归墟玄晶。", 7)
		return szTip
	end,
	[408] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("玉山茶\n", 0) ..
		self.ColorText("玉山泉水所煮的茶水。\n", 6) ..
		self.ColorText("茶姹说她泡的茶可好喝了！", 7)
		return szTip
	end,
	[409] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("鹿茸片\n", 0) ..
		self.ColorText("名贵中药。\n", 6) ..
		self.ColorText("甜甜温泉山庄特供鹿茸片。", 7)
		return szTip
	end,
	[410] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("甜点\n", 0) ..
		self.ColorText("用白糖制作的甜点。\n", 6) ..
		self.ColorText("甜点当然是用糖做的呀！", 7)
		return szTip
	end,
	[411] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("浴衣\n", 0) ..
		self.ColorText("用布制成的浴衣。\n", 6) ..
		self.ColorText("甜甜温泉山庄专供浴衣。", 7)
		return szTip
	end,
	[412] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("酒水\n", 0) ..
		self.ColorText("后劲十足。\n", 6) ..
		self.ColorText("甜甜温泉山庄特供酒水。", 7)
		return szTip
	end,
	[413] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("汤药\n", 0) ..
		self.ColorText("用多种药材制成的汤药。\n", 6) ..
		self.ColorText("甜甜温泉山庄特供汤药。", 7)
		return szTip
	end,
	[414] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("方灭丹\n", 2) ..
		self.ColorText("使用：使用后心情值变化速度下降20%，凝血精可使用数量增加一瓶。\n", 6)  ..
		self.ColorText("十心方灭，百转不生，力壮三分，易害己身。\n", 0)  ..
		self.ColorText("获得配方即可通过制药制作。\n", 7)
		return szTip
	end,
	[415] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("忘忧水\n", 2) ..
		self.ColorText("使用：回复心情值100点。\n", 6)  ..
		self.ColorText("世间几多烦恼，不如一梦忘忧。\n", 0)  ..
		self.ColorText("获得配方即可通过制药制作。\n", 7)
		return szTip
	end,
	[416] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("糊涂丹\n", 2) ..
		self.ColorText("使用：将自身任意一个时辰状态转化为相反的时辰状态。\n", 6)  ..
		self.ColorText("阴阳乾坤皆颠倒，举世皆明我糊涂。\n", 0)  ..
		self.ColorText("获得配方即可通过制药制作。\n", 7)
		return szTip
	end,
	[417] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("火毒瓶\n", 2) ..
		self.ColorText("使用：对敌对目标使用。使目标获得三层火毒效果。\n", 6)  ..
		self.ColorText("灼灼烈焰，焚尽污浊。\n", 0)  ..
		self.ColorText("获得配方即可通过制药制作。\n", 7)
		return szTip
	end,
	[418] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("老鸭汤\n", 2) ..
		self.ColorText("使用：回复80点饱食度。\n", 6)  ..
		self.ColorText("以金陵老鸭熬制三个时辰方成的浓汤。\n", 0)  ..
		self.ColorText("获得配方即可通过烹饪制作。\n", 7)
		return szTip
	end,
	[419] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("水晶柿\n", 2) ..
		self.ColorText("使用：饱食度上限提升至120点。\n", 6)  ..
		self.ColorText("柿叶翻红霜景秋，碧天如水倚红楼。\n", 0)  ..
		self.ColorText("获得配方即可通过烹饪制作。\n", 7)
		return szTip
	end,
	[420] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("五谷粥\n", 2) ..
		self.ColorText("使用：5分钟内，闪避提升20%。\n", 6)  ..
		self.ColorText("羹中有八宝，留香唇齿间。\n", 0)  ..
		self.ColorText("获得配方即可通过烹饪制作。\n", 7)
		return szTip
	end,
	[421] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("龙血果\n", 2) ..
		self.ColorText("使用：5分钟内，血量上限提升20%。\n", 6)  ..
		self.ColorText("龙潜于渊战于野，其血凝天地之间。\n", 0)  ..
		self.ColorText("获得配方即可通过烹饪制作。\n", 7)
		return szTip
	end,
	[422] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("史思明反贼名录\n", 7)  ..
		self.ColorText("记录了与史思明有往来的官员名录。\n", 7)
		return szTip
	end,
	[423] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("往来文牒\n", 7)  ..
		self.ColorText("与史思明往来的文字记录。\n", 7)
		return szTip
	end,
	[424] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("阿史那承庆铁券\n", 7)  ..
		self.ColorText("沉甸甸的很有分量。\n", 7)
		return szTip
	end,
	[425] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("清除杂草\n", 6)  ..
		self.ColorText("要求：无。\n", 6)  ..
		self.ColorText("奖励：必得：【庶务杂记·领悟】*1。\n低概率获得：【闲居逸趣·苑圃】*1，【闲居逸趣·炊事】*1，【闲居逸趣·杂务】*1。\n", 0)  ..
		self.ColorText("总共耗时：2小时。\n", 7)
		return szTip
	end,
	[426] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("清扫落叶\n", 6)  ..
		self.ColorText("要求：无。\n", 6)  ..
		self.ColorText("奖励：必得：【庶务杂记·领悟】*1。\n低概率获得：【闲居逸趣·苑圃】*1，【闲居逸趣·炊事】*1，【闲居逸趣·杂务】*1。\n", 0)  ..
		self.ColorText("总共耗时：2小时。\n", 7)
		return szTip
	end,
	[427] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("收集花瓣\n", 6)  ..
		self.ColorText("要求：无。\n", 6)  ..
		self.ColorText("奖励：必得：【庶务杂记·领悟】*1。\n低概率获得：【闲居逸趣·苑圃】*1，【闲居逸趣·炊事】*1，【闲居逸趣·杂务】*1。\n", 0)  ..
		self.ColorText("总共耗时：2小时。\n", 7)
		return szTip
	end,
	[428] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("打扫房间\n", 6)  ..
		self.ColorText("要求：无。\n", 6)  ..
		self.ColorText("奖励：必得：【庶务杂记·领悟】*1。\n低概率获得：【闲居逸趣·苑圃】*1，【闲居逸趣·炊事】*1，【闲居逸趣·杂务】*1。\n", 0)  ..
		self.ColorText("总共耗时：2小时。\n", 7)
		return szTip
	end,
	[429] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("整理房间\n", 6)  ..
		self.ColorText("要求：无。\n", 6)  ..
		self.ColorText("奖励：必得：【庶务杂记·领悟】*1。\n低概率获得：【闲居逸趣·苑圃】*1，【闲居逸趣·炊事】*1，【闲居逸趣·杂务】*1。\n", 0)  ..
		self.ColorText("总共耗时：2小时。\n", 7)
		return szTip
	end,
	[430] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("花园施肥\n", 6)  ..
		self.ColorText("要求：无。\n", 6)  ..
		self.ColorText("奖励：必得：【庶务杂记·领悟】*1。\n低概率获得：【闲居逸趣·苑圃】*1，【闲居逸趣·炊事】*1，【闲居逸趣·杂务】*1。\n", 0)  ..  
		self.ColorText("总共耗时：2小时。\n", 7)
		return szTip
	end,
	[431] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("花园浇水\n", 6)  ..
		self.ColorText("要求：无。\n", 6)  ..
		self.ColorText("奖励：必得：【庶务杂记·领悟】*1。\n低概率获得：【闲居逸趣·苑圃】*1，【闲居逸趣·炊事】*1，【闲居逸趣·杂务】*1。\n", 0)  ..
		self.ColorText("总共耗时：2小时。\n", 7)
		return szTip
	end,
	[432] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("邻里往来\n", 6)  ..
		self.ColorText("要求：无。\n", 6)  ..
		self.ColorText("奖励：必得：【庶务杂记·领悟】*1。\n低概率获得：【闲居逸趣·苑圃】*1，【闲居逸趣·炊事】*1，【闲居逸趣·杂务】*1。\n", 0)  .. 
		self.ColorText("总共耗时：2小时。\n", 7)
		return szTip
	end,
	[433] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("采买食材\n", 5)  ..
		self.ColorText("要求：需要管家习得【炊·研习】。\n", 6)  ..
		self.ColorText("奖励：必得：【庶务杂记·熟稔】*1。\n中概率获得：【闲居逸趣·苑圃】*1，【闲居逸趣·炊事】*1，【闲居逸趣·杂务】*1。\n", 0)  ..  
		self.ColorText("总共耗时：3小时。\n", 7)
		return szTip
	end,
	[434] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("喂养宠物\n", 5)  ..
		self.ColorText("要求：需要管家习得【宠·礼物】。\n", 6)  ..
		self.ColorText("奖励：必得：【庶务杂记·熟稔】*1。\n中概率获得：【闲居逸趣·苑圃】*1，【闲居逸趣·炊事】*1，【闲居逸趣·杂务】*1。\n", 0)  ..   
		self.ColorText("总共耗时：3小时。\n", 7)
		return szTip
	end,
	[435] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("清扫街道\n", 5)  ..
		self.ColorText("要求：需要管家等级达到2级。\n", 6)  ..
		self.ColorText("奖励：必得：【庶务杂记·熟稔】*1。\n中概率获得：【闲居逸趣·苑圃】*1，【闲居逸趣·炊事】*1，【闲居逸趣·杂务】*1。\n", 0)  ..
		self.ColorText("总共耗时：3小时。\n", 7)
		return szTip
	end,
	[436] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("进购货物\n", 5)  ..
		self.ColorText("要求：需要管家等级达到2级。\n", 6)  ..
		self.ColorText("奖励：必得：【庶务杂记·熟稔】*1。\n中概率获得：【闲居逸趣·苑圃】*1，【闲居逸趣·炊事】*1，【闲居逸趣·杂务】*1。\n", 0)  ..   
		self.ColorText("总共耗时：3小时。\n", 7)
		return szTip
	end,
	[437] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("回乡探亲\n", 5)  ..
		self.ColorText("要求：需要管家等级达到2级。\n", 6)  ..
		self.ColorText("奖励：必得：【庶务杂记·熟稔】*1。\n中概率获得：【闲居逸趣·苑圃】*1，【闲居逸趣·炊事】*1，【闲居逸趣·杂务】*1。\n", 0)  ..  
		self.ColorText("总共耗时：3小时。\n", 7)
		return szTip
	end,
	[438] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("美化小镇\n", 5)  ..
		self.ColorText("要求：需要管家习得【苑·丰收】。\n", 6)  ..
		self.ColorText("奖励：必得：【庶务杂记·熟稔】*1。\n中概率获得：【闲居逸趣·苑圃】*1，【闲居逸趣·炊事】*1，【闲居逸趣·杂务】*1。\n", 0)  .. 
		self.ColorText("总共耗时：3小时。\n", 7)
		return szTip
	end,
	[439] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("社区巡逻\n", 2)  ..
		self.ColorText("要求：需要管家等级达到3级。\n", 6)  ..
		self.ColorText("奖励：必得：【庶务杂记·精通】*1。\n高概率获得：【闲居逸趣·苑圃】*1，【闲居逸趣·炊事】*1，【闲居逸趣·杂务】*1，【东篱相伴】*1。\n", 0)  ..  
		self.ColorText("总共耗时：4小时。\n", 7)
		return szTip
	end,
	[440] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("烹饪食物\n", 2)  ..
		self.ColorText("要求：需要管家等级达到2级并且习得【炊·丰收】。\n", 6)  ..
		self.ColorText("奖励：必得：【庶务杂记·精通】*1。\n高概率获得：【闲居逸趣·苑圃】*1，【闲居逸趣·炊事】*1，【闲居逸趣·杂务】*1，【东篱相伴】*1。\n", 0)  ..   
		self.ColorText("总共耗时：4小时。\n", 7)
		return szTip
	end,
	[441] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("携手出游\n", 2)  ..
		self.ColorText("要求：需要管家好感度等级达到3级。\n", 6)  ..
		self.ColorText("奖励：必得：【庶务杂记·精通】*1。\n高概率获得：【闲居逸趣·苑圃】*1，【闲居逸趣·炊事】*1，【闲居逸趣·杂务】*1，【东篱相伴】*1。\n", 0)  ..   
		self.ColorText("总共耗时：4小时。\n", 7)
		return szTip
	end,
	[442] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("驱逐贼寇\n", 2)  ..
		self.ColorText("要求：需要管家等级达到2级并且习得【战·击破】。\n", 6)  ..
		self.ColorText("奖励：必得：【庶务杂记·精通】*1。\n高概率获得：【闲居逸趣·苑圃】*1，【闲居逸趣·炊事】*1，【闲居逸趣·杂务】*1，【东篱相伴】*1。\n", 0)  ..   
		self.ColorText("总共耗时：4小时。\n", 7)
		return szTip
	end,
	[443] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("增加\n", 0)
		return szTip
	end,
	[444] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("减少\n", 0)
		return szTip
	end,
	[445] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("桴海厅·三\n", 5)  ..
		self.ColorText("奖励：织梦梭：560；辰羽灼华：14。\n", 0)  ..  
		self.ColorText("说明：通关桴海厅后解锁，可重复开启。\n", 7)		
		return szTip
	end,
	[446] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("青桃堂·三\n", 5)  ..
		self.ColorText("奖励：织梦梭：600；辰羽灼华：16。\n", 0)  ..  
		self.ColorText("说明：通关青桃堂后解锁，可重复开启。\n", 7)		
		return szTip
	end,
	[447] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("与归院·三\n", 5)  ..
		self.ColorText("奖励：织梦梭：640；辰羽灼华：20。\n", 0)  ..  
		self.ColorText("说明：通关与归院后解锁，可重复开启。\n", 7)		
		return szTip
	end,
	[448] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("地牢·三\n", 5)  ..
		self.ColorText("奖励：织梦梭：680；辰羽灼华：22。\n", 0)  ..  
		self.ColorText("说明：通关地牢后解锁，可重复开启。\n", 7)		
		return szTip
	end,
	[449] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("死牢·三\n", 5)  ..
		self.ColorText("奖励：织梦梭：720；辰羽灼华：26。\n", 0)  ..  
		self.ColorText("说明：通关死牢后解锁，可重复开启。\n", 7)		
		return szTip
	end,
	[450] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("后山入口·三\n", 5)  ..
		self.ColorText("奖励：织梦梭：1160；辰羽灼华：60。\n", 0)  ..  
		self.ColorText("说明：通关后山入口后解锁，可重复开启。本关包含首领【沐秋月】。\n", 7)		
		return szTip
	end,
	[451] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("半山·三\n", 5)  ..
		self.ColorText("奖励：织梦梭：800；辰羽灼华：32。\n", 0)  ..  
		self.ColorText("说明：通关半山后解锁，可重复开启。\n", 7)		
		return szTip
	end,
	[452] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("瞻明云巅·三\n", 5)  ..
		self.ColorText("奖励：织梦梭：1400；辰羽灼华：78。\n", 0)  ..  
		self.ColorText("说明：通关瞻明云巅后解锁，可重复开启。本关包含首领【陈徽】。\n", 7)		
		return szTip
	end,
	[453] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("绪之关\n", 2)  ..
		self.ColorText("奖励：织梦梭：600；辰羽灼华：45。\n", 0)  ..  
		self.ColorText("说明：通关瞻明云巅后解锁，可重复开启。本关无法自行选择侠影。\n", 7)		
		return szTip
	end,
	[454] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("竭之关\n", 2)  ..
		self.ColorText("奖励：织梦梭：600；辰羽灼华：45。\n", 0)  ..  
		self.ColorText("说明：通关瞻明云巅后解锁，可重复开启。本关无法选择心影。\n", 7)		
		return szTip
	end,
	[455] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("守之关\n", 2)  ..
		self.ColorText("奖励：织梦梭：600；辰羽灼华：45。\n", 0)  ..  
		self.ColorText("说明：通关瞻明云巅后解锁，可重复开启。本关需保护场上的多多。\n", 7)		
		return szTip
	end,
	[456] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("鼠标左键点击加入衍天宗。\n", 0)
		return szTip
	end,
	--衍天宗宠物 开始
	[457] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【太炎】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("长风起兮鸣玉珰，趋炎华兮践太初。", 7)
		return szTip
	end,	
	[458] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【晴霜】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("叱紫电兮踏星霜，鸣长铗兮眠晴霞。", 7)
		return szTip
	end,	
	[459] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【禾稷】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("黍离离兮稷苗繁，彼苍天兮忧士民。", 7)
		return szTip
	end,	
	[460] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【春辰】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("寄晨星兮游太乙，浮桴槎兮祝春辰。", 7)
		return szTip
	end,	
	[461] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【玄昊】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("东岳秀兮冲青天，空岩寂兮幽以玄。", 7)
		return szTip
	end,	
	[462] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【如幻】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("真如寂兮寻幻梦，惘太极兮肇苍天。", 7)
		return szTip
	end,
	--衍天宗宠物 结束
	[463] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("门客的行动纲领·入门\n", 0) ..
		self.ColorText("使用：选中门客可以使其获得100点阅历值。仅有本场景的主人才能操作哦！\n", 6) ..
		self.ColorText("阅览此书，倒背如流，方不辱门客身份。", 7)
		return szTip
	end,
	[464] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("门客的行动纲领·精通\n", 0) ..
		self.ColorText("使用：选中门客可以使其获得1000点阅历值。仅有本场景的主人才能操作哦！\n", 6) ..
		self.ColorText("阅览此书，倒背如流，方不辱门客身份。", 7)
		return szTip
	end,
	[465] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("石之关\n", 2)  ..
		self.ColorText("奖励：织梦梭：600；辰羽灼华：45。\n", 0)  ..  
		self.ColorText("说明：通关瞻明云巅后解锁，可重复开启。本关需使用滚石与火石击败敌人。\n", 7)		
		return szTip
	end,
	[466] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("鼠标左键点击加入北天药宗。\n", 0)
		return szTip
	end,

	--北天药宗宠物 开始
	[467] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【缀柳】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("三分春色行将半，一束东风缀柳绵。", 7)
		return szTip
	end,	
	[468] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【栖桃】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("春烟拢湿群芳谱，矮角偷栖小桃枝。", 7)
		return szTip
	end,	
	[469] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【鸣杏】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("小扇错落玉子累，碎金如许未肯枯。", 7)
		return szTip
	end,	
	[470] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【移枫】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("秋移素月霜犹洒，暮系丹枫露褪香。", 7)
		return szTip
	end,	
	[471] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【垂红】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("雪边抽簪清气绕，海棠睡久露垂红。", 7)
		return szTip
	end,	
	[472] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【扶枝】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("朔风几见枝雪凛，何时春枝恣相邀。", 7)
		return szTip
	end,
	--北天药宗宠物 结束
	--828小道具
	[473] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【小鱼干】\n", 0) ..
		self.ColorText("喂给猫猫。\n", 6) ..
		self.ColorText("苗老板特制小鱼干，猫猫们都喜欢吃。\n", 7)
		return szTip
	end,
	[474] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【逗猫棒】\n", 0) ..
		self.ColorText("陪猫猫玩。\n", 6) ..
		self.ColorText("小胖的专属逗猫棒，其实是你表演给它看。\n", 7)
		return szTip
	end,
	[475] = function(rect, bVisibleWhenHideUI)
		local nIconID = 0
		local szCategory = "默认分类"
		local szName = "默认名字"
		local szTip = self.ColorText("【毛线团】\n", 0) ..
		self.ColorText("给猫猫玩。\n", 6) ..
		self.ColorText("没有猫猫不喜欢毛线团。\n", 7)
		return szTip
	end,
	--828小道具结束
	[476] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("鼠标左键点击加入刀宗。\n", 0)
		return szTip
	end,
	[477] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("领取奖励\n", 0)
		return szTip
	end,
	[478] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("领取完毕\n", 0)
		return szTip
	end,
	[479] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("不可领取\n", 0)
		return szTip
	end,
	[480] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("点击选定找回该外观\n", 0)
		return szTip
	end,
	--刀宗宠物 开始
	[481] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【江南沧浪子】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("入世沧浪子，出世解语花。", 7)
		return szTip
	end,	
	[482] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【九州百人语】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("九州百人语，一鸟一台戏。", 7)
		return szTip
	end,	
	[483] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【岚峰小二爷】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("岚峰小二爷，乖僻话无多。", 7)
		return szTip
	end,	
	[484] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【瀚海小旋风】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("振翅掠海过，彼岸生飓风。", 7)
		return szTip
	end,	
	[485] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【翁洲青蓑衣】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("拔刀不留名，我即青蓑衣。", 7)
		return szTip
	end,	
	[486] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【滩涂背刀客】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("任侠走江湖，背刀不出刀。", 7)
		return szTip
	end,
		--刀宗宠物 结束
	--万灵山庄宠物 开始
	[487] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【黎野】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("露白发曙，黎野重明。", 7)
		return szTip
	end,	
	[488] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【心澈】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("风潮涤荡，稚心不摇。", 7)
		return szTip
	end,	
	[489] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【山炳】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("彪炳日月，登峰为王。", 7)
		return szTip
	end,	
	[490] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【巡赭】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("揽虹巡风，霞光烟赭。", 7)
		return szTip
	end,	
	[491] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【兴云】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("月暗清霄，云兴夜幕。", 7)
		return szTip
	end,	
	[492] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【飞羽】\n", 0) ..
		self.ColorText("点击选定获取该宠物。\n", 6) ..
		self.ColorText("凌志奋翼，白羽飞锋。", 7)
		return szTip
	end,
	--万灵山庄宠物 结束
	[493] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("鼠标左键点击加入万灵山庄。\n", 0)
		return szTip
	end,
	--雷首飞电的缰绳 开始
	[494] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【雷首飞电·惊辰】\n", 0) ..
		self.ColorText("这只雷首飞电的特点为：\n【抗摔·强健】\n【气力·调息】\n【骑术·纵驰天下】\n", 6)..
		self.ColorText("我要选择这只【雷首飞电】！\n", 7) 
		return szTip
	end,
	[495] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【雷首飞电·驰辉】\n", 0) ..
		self.ColorText("这只雷首飞电的特点为：\n【精饲·三级】\n【速度·劲足】\n【骑术·直行百里】\n", 6)..
		self.ColorText("我要选择这只【雷首飞电】！\n", 7) 
		return szTip
	end,
	[496] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【雷首飞电·逾虹】\n", 0) ..
		self.ColorText("这只雷首飞电的特点为：【精饲·四级】\n【同骑·并驾】\n【骑术·直行疾驰】\n", 6)..
		self.ColorText("我要选择这只【雷首飞电】！\n", 7) 
		return szTip
	end,

	[497] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip =	self.ColorText("【雷首飞电·步景】\n", 0) ..
		self.ColorText("这只雷首飞电的特点为：\n【抗摔·强健】\n【气力·调息】\n【骑术·纵驰天下】\n", 6)..
		self.ColorText("我要选择这只【雷首飞电】！\n", 7) 
		return szTip
	end,
	--雷首飞电的缰绳 结束
	
	--侠客的战斗策略图标2024 开始
	--[[
	{szName = "伴随跳跃", szNotice = "伴随你进行跳跃", tBuff = {23767, 1}, },
	{szName = "自动释放绝技", szNotice = "战斗中可以释放绝技时将直接释放", nPos = WIFU_NPCCUSTOM.ORDER_AUTOULT,},
	{szName = "永久停留", szNotice = "停留在原地，无视面板上的跟随和停留指令，攻击指令只接受切换目标的部分。开启后会关闭永久跟随指令", nPos = WIFU_NPCCUSTOM.ORDER_ALWAYSSTAND,tEvent_Open = {2001,0,3},tEvent_Close = {2001,0,0}, },
	{szName = "永久跟随", szNotice = "一直跟随你，无视面板上的跟随和停留指令，攻击指令只接受切换目标的部分。开启后会关闭永久停留指令", nPos = WIFU_NPCCUSTOM.ORDER_ALWAYSFOLLOW,tEvent_Open = {2001,0,2},tEvent_Close = {2001,0,0}, },
	--]]
	[498] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"策略"
		local szTip =	self.ColorText("伴随跳跃\n", 7) ..
		self.ColorText("伴随你进行跳跃。\n", 6) ..
		self.ColorText("当前：关闭。\n点击开启策略。", 1)
		return szTip
	end,
	[499] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"策略"
		local szTip =	self.ColorText("伴随跳跃\n", 7) ..
		self.ColorText("伴随你进行跳跃。\n", 6) ..
		self.ColorText("当前：开启。\n点击关闭策略。", 1)
		return szTip
	end,
	[500] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"策略"
		local szTip =	self.ColorText("自动释放绝技\n", 7) ..
		self.ColorText("战斗中可以释放绝技时将直接释放。\n", 6) ..
		self.ColorText("当前：关闭。\n点击开启策略。", 1)
		return szTip
	end,
	[501] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"策略"
		local szTip =	self.ColorText("自动释放绝技\n", 7) ..
		self.ColorText("战斗中可以释放绝技时将直接释放。\n", 6) ..
		self.ColorText("当前：开启。\n点击关闭策略。", 1)
		return szTip
	end,
	[502] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"策略"
		local szTip =	self.ColorText("永久停留\n", 7) ..
		self.ColorText("停留在原地，无视面板上的跟随和停留指令，攻击指令只接受切换目标的部分。开启后会关闭永久跟随指令。\n", 6) ..
		self.ColorText("当前：关闭。\n点击开启策略。", 1)
		return szTip
	end,
	[503] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"策略"
		local szTip =	self.ColorText("永久停留\n", 7) ..
		self.ColorText("停留在原地，无视面板上的跟随和停留指令，攻击指令只接受切换目标的部分。开启后会关闭永久跟随指令。\n", 6) ..
		self.ColorText("当前：开启。\n点击关闭策略。", 1)
		return szTip
	end,
	[504] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"策略"
		local szTip =	self.ColorText("永久跟随\n", 7) ..
		self.ColorText("一直跟随你，无视面板上的跟随和停留指令，攻击指令只接受切换目标的部分。开启后会关闭永久停留指令。\n", 6) ..
		self.ColorText("当前：关闭。\n点击开启策略。", 1)
		return szTip
	end,
	[505] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"策略"
		local szTip =	self.ColorText("永久跟随\n", 7) ..
		self.ColorText("一直跟随你，无视面板上的跟随和停留指令，攻击指令只接受切换目标的部分。开启后会关闭永久停留指令。\n", 6) ..
		self.ColorText("当前：开启。\n点击关闭策略。", 1)
		return szTip
	end,	
	[506] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"策略"
		local szTip =	self.ColorText("洗髓\n", 7) ..
		self.ColorText("战斗时对敌人进行威压，提升自身威胁值900%。\n", 6) ..
		self.ColorText("当前：关闭。\n点击开启策略。", 1)
		return szTip
	end,
	[507] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"策略"
		local szTip =	self.ColorText("洗髓\n", 7) ..
		self.ColorText("战斗时对敌人进行威压，提升自身威胁值900%。\n", 6) ..
		self.ColorText("当前：开启。\n点击关闭策略。", 1)
		return szTip
	end,
	[508] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"策略"
		local szTip =	self.ColorText("明尊\n", 7) ..
		self.ColorText("战斗时对敌人进行威压，提升自身威胁值900%。\n", 6) ..
		self.ColorText("当前：关闭。\n点击开启策略。", 1)
		return szTip
	end,
	[509] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"策略"
		local szTip =	self.ColorText("明尊\n", 7) ..
		self.ColorText("战斗时对敌人进行威压，提升自身威胁值900%。\n", 6) ..
		self.ColorText("当前：开启。\n点击关闭策略。", 1)
		return szTip
	end,
	[510] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"策略"
		local szTip =	self.ColorText("水斗神拳\n", 7) ..
		self.ColorText("战斗时对敌人进行威压，提升自身威胁值900%。\n", 6) ..
		self.ColorText("当前：关闭。\n点击开启策略。", 1)
		return szTip
	end,
	[511] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"策略"
		local szTip =	self.ColorText("水斗神拳\n", 7) ..
		self.ColorText("战斗时对敌人进行威压，提升自身威胁值900%。\n", 6) ..
		self.ColorText("当前：开启。\n点击关闭策略。", 1)
		return szTip
	end,	
	--侠客的战斗策略图标2024 结束

	--仙剑联动 开始
	[513] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"摆拳&刺拳&扫叶腿"
		local szTip =	self.ColorText("摆拳&刺拳&扫叶腿\n", 0) ..
		self.ColorText("基础的江湖拳脚，但不乏威力。\n", 7) ..
		self.ColorText("一段·摆拳：\n对半径2.5*3.5尺矩形范围内的鼠精造成50000点伤害并击飞一段距离。\n二段·刺拳：\n对半径2.5*3.5尺矩形范围内的鼠精造成50000点伤害并击飞一段距离。\n三段·扫叶腿：\n对半径3.5尺半圆范围内的鼠精造成60000点伤害并击飞一段距离。\n", 6)	
		return szTip
	end,

	[514] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"捕鼠绳"
		local szTip =	self.ColorText("捕鼠绳\n", 0) ..
		self.ColorText("锦八爷为圣灵挑战准备的神奇绳子。\n", 7) ..
		self.ColorText("将半径8尺半圆范围内的鼠精拉至脚下，造成30000点伤害，并击晕3秒。", 6)		
		return szTip
	end,

	[515] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"地裂山崩掌"
		local szTip =	self.ColorText("地裂山崩掌\n", 0) ..
		self.ColorText("一路易学难精的掌法，有开山裂石之威力。\n", 7) ..
		self.ColorText("瞬移至指定位置，对以落地点为圆心，半径3.5尺范围内的鼠精造成85000点伤害，并击晕8秒。", 6)		
		return szTip
	end,

	[516] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"风起云扬腿"
		local szTip =	self.ColorText("风起云扬腿\n", 0) ..
		self.ColorText("传说当这路腿法被施展之后，风云也会随之涌动。\n", 7) ..
		self.ColorText("每隔0.5秒对距离自身3.5尺内的全部鼠精造成40000点伤害，并击晕5秒；\n技能持续时间5秒，使用过程中可移动。", 6)		
		return szTip
	end,

	[517] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"乾坤一掷"
		local szTip =	self.ColorText("乾坤一掷\n", 0) ..
		self.ColorText("传说曾有人能同时掷出五千个铜钱，但是你不会，你只会一次扔一个。\n", 7) ..
		self.ColorText("对单一鼠精造成30000点伤害，打断目标鼠精施法，击晕目标鼠精1秒。", 6)		
		return szTip
	end,
	[518] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"水灵之力"
		local szTip =	self.ColorText("水灵之力\n", 0) ..
		self.ColorText("威力强大的招式，可召请来自上古水神的力量。\n", 7) ..
		self.ColorText("使用后清除所有武学技能的调息时间。", 6)		
		return szTip
	end,

	[519] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"风灵之力"
		local szTip =	self.ColorText("风灵之力\n", 0) ..
		self.ColorText("威力强大的招式，可召请来自上古风神的力量。\n", 7) ..
		self.ColorText("为自己添加【风灵之力】增益状态。\n【风灵之力】：\n你的跑速提高70%。", 6)		
		return szTip
	end,

	[520] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"火灵之力"
		local szTip =	self.ColorText("火灵之力\n", 0) ..
		self.ColorText("威力强大的招式，可召请来自上古火神的力量。\n", 7) ..
		self.ColorText("为自己添加【火灵之力】增益状态。\n【火灵之力】：\n你使用武学技能（除风起云扬腿外）命中鼠精时，会额外造成一段伤害值为技能伤害值60%的伤害；\n你使用风起云扬腿、五灵技能命中鼠精时，会额外造成一段伤害值为技能伤害值100%的伤害。", 6)		
		return szTip
	end,

	[521] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"雷灵之力"
		local szTip =	self.ColorText("雷灵之力\n", 0) ..
		self.ColorText("威力强大的招式，可召请来自上古雷神的力量。\n", 7) ..
		self.ColorText("对单一鼠精每隔0.5秒释放一次伤害值为50000的伤害，持续10秒；\n技能使用过程中可移动。", 6)		
		return szTip
	end,

	[522] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"土灵之力"
		local szTip =	self.ColorText("土灵之力\n", 0) ..
		self.ColorText("威力强大的招式，可召请来自上古山神的力量。\n", 7) ..
		self.ColorText("对面前10*20尺矩形范围内的鼠精造成20000点伤害并击飞一段距离，并使鼠精落地后晕眩20秒。", 6)		
		return szTip
	end,
	--仙剑联动 结束
		[523] = function(rect, bVisibleWhenHideUI)
		local nIconID =	0
		local szCategory =	"默认分类"
		local szName =	"默认名字"
		local szTip = self.ColorText("一颗发光的珠子\n", 5) ..
		self.ColorText("携带：在吐宝鼠处兑换玩具【摩尼宝珠】。\n", 6) ..
		self.ColorText("现在我们都会吐宝了~\n", 0)  ..
		self.ColorText("\n点击制作：需材料【云片宝珠】、【梅花宝珠】、【南瓜宝珠】、【芝麻宝珠】、【米花宝珠】各一份。\n", 7)
		return szTip
	end,
	[1002] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("李屠夫的证词\n", 0) .. self.ColorText("秀茹妹子那天的确在我这里买肉了，具体时间我记不住了，大概是中午之后吧", 7)
		return szTip
	end,

	[1003] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("王氏的证词\n", 0) .. self.ColorText("秀茹可是个好女孩，说话细声细语的，平时大门不出二门不迈，也就找几个闺房密友去家里下棋。", 7)
		return szTip
	end,

	[1004] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("仵作的证词\n", 0) .. self.ColorText("尸体被发现的时候是平躺在地面上，死亡时间大概是午时后一刻，致命死因是胸口的剪刀刀伤，刀口向上，应该是蓄意伤人，凶器就扔在旁边。周围有搏斗的痕迹。", 7)
		return szTip
	end,

	[1005] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("张屠夫的证词\n", 0) .. self.ColorText("那天啊，正好我家里有事，中午就没开张。", 7)
		return szTip
	end,

	[1002] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("李屠夫的证词\n", 0) .. self.ColorText("秀茹妹子那天的确在我这里买肉了，具体时间我记不住了，大概是中午之后吧", 7)
		return szTip
	end,

	[1003] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("王氏的证词\n", 0) .. self.ColorText("秀茹可是个好女孩，说话细声细语的，平时大门不出二门不迈，也就找几个闺房密友去家里下棋。", 7)
		return szTip
	end,

	[1004] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("仵作的证词\n", 0) .. self.ColorText("尸体被发现的时候是平躺在地面上，死亡时间大概是午时后一刻，致命死因是胸口的剪刀刀伤，刀口向上，应该是蓄意伤人，凶器就扔在旁边。周围有搏斗的痕迹。", 7)
		return szTip
	end,

	[1005] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("张屠夫的证词\n", 0) .. self.ColorText("那天啊，正好我家里有事，中午就没开张。", 7)
		return szTip
	end,

	[1002] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("李屠夫的证词\n", 0) .. self.ColorText("秀茹妹子那天的确在我这里买肉了，具体时间我记不住了，大概是中午之后吧", 7)
		return szTip
	end,

	[1003] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("王氏的证词\n", 0) .. self.ColorText("秀茹可是个好女孩，说话细声细语的，平时大门不出二门不迈，也就找几个闺房密友去家里下棋。", 7)
		return szTip
	end,

	[1004] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("仵作的证词\n", 0) .. self.ColorText("尸体被发现的时候是平躺在地面上，死亡时间大概是午时后一刻，致命死因是胸口的剪刀刀伤，刀口向上，应该是蓄意伤人，凶器就扔在旁边。周围有搏斗的痕迹。", 7)
		return szTip
	end,

	[1005] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("张屠夫的证词\n", 0) .. self.ColorText("那天啊，正好我家里有事，中午就没开张。", 7)
		return szTip
	end,

	[1006] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("焦枯的树枝\n", 0) .. self.ColorText("残留着冷石灰的烧焦的树枝。冷石是炼丹产物。有剧毒。", 7)
		return szTip
	end,

	[1007] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("炼丹道士的证词\n", 0) .. self.ColorText("有一位姓林的画师给我银子，让我给他炼制冷石。", 7)
		return szTip
	end,

	[1008] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("罗轩的证词\n", 0) .. self.ColorText("当年武及侵犯了张德的妻子，结果夫妇两被误杀，儿子张白尘失踪。\n武及被害的前天晚上有黑衣人行刺武及未遂，左手受伤。行刺之人极有可能是张白尘。", 7)
		return szTip
	end,

	[1009] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("夜行衣\n", 0) .. self.ColorText("藏在金水镇东北的空宅子里的夜行衣，左袖被划了一道口子，上面还沾着血渍。", 7)
		return szTip
	end,

	[1006] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("焦枯的树枝\n", 0) .. self.ColorText("残留着冷石灰的烧焦的树枝。冷石是炼丹产物。有剧毒。", 7)
		return szTip
	end,

	[1007] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("炼丹道士的证词\n", 0) .. self.ColorText("有一位姓林的画师给我银子，让我给他炼制冷石。", 7)
		return szTip
	end,

	[1008] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("罗轩的证词\n", 0) .. self.ColorText("当年武及侵犯了张德的妻子，结果夫妇两被误杀，儿子张白尘失踪。\n武及被害的前天晚上有黑衣人行刺武及未遂，左手受伤。行刺之人极有可能是张白尘。", 7)
		return szTip
	end,

	[1009] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("夜行衣\n", 0) .. self.ColorText("藏在金水镇东北的空宅子里的夜行衣，左袖被划了一道口子，上面还沾着血渍。", 7)
		return szTip
	end,

	[1006] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("焦枯的树枝\n", 0) .. self.ColorText("残留着冷石灰的烧焦的树枝。冷石是炼丹产物。有剧毒。", 7)
		return szTip
	end,

	[1007] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("炼丹道士的证词\n", 0) .. self.ColorText("有一位姓林的画师给我银子，让我给他炼制冷石。", 7)
		return szTip
	end,

	[1008] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("罗轩的证词\n", 0) .. self.ColorText("当年武及侵犯了张德的妻子，结果夫妇两被误杀，儿子张白尘失踪。\n武及被害的前天晚上有黑衣人行刺武及未遂，左手受伤。行刺之人极有可能是张白尘。", 7)
		return szTip
	end,

	[1009] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("夜行衣\n", 0) .. self.ColorText("藏在金水镇东北的空宅子里的夜行衣，左袖被划了一道口子，上面还沾着血渍。", 7)
		return szTip
	end,

	[1010] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("武及的验尸报告\n", 0) .. self.ColorText("死亡时间大概是昨日入夜戌时；死亡原因是有一根绣花针刺入脑门要害处。", 7)
		return szTip
	end,

	[1011] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("凶器·绣花针\n", 0) .. self.ColorText("这根绣花针有点特别，半银半铜所制，上半部分是银色，下半部分是金色。", 7)
		return szTip
	end,

	[1012] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("武晖的证词\n", 0) .. self.ColorText("罗轩急匆匆地从外头跑回来进房子里和爹说了什么，然后就出来带一群人往贡橘林去了。之后爹呆在房间里一直没什么动静，第二天起来发现爹爹已死去多时。", 7)
		return szTip
	end,

	[1013] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("小叫花的证词\n", 0) .. self.ColorText("那个人是个左撇子！嗯，没错！他给我冷石，付我银两都是用的左手，从来就没见他动过右手，这点我记得很清楚！我当时还纳闷的，金水镇我没见过有左撇子的啊！", 7)
		return szTip
	end,

	[1014] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("武晴的证词一\n", 0) .. self.ColorText("当天我吃完晚饭就买绣花针去了。我的绣花针被罗轩叔叔借去挑刺给弄丢了。", 7)
		return szTip
	end,

	[1015] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("武晴的证词二\n", 0) .. self.ColorText("罗轩叔叔右手被刺伤了，流了好多血！大夫说都伤到筋了。说不定，说不定右手就给废了。", 7)
		return szTip
	end,

	[1016] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("鉴定过的凶器\n", 0) .. self.ColorText("这正是被罗轩借去的武晴的绣花针。", 7)
		return szTip
	end,

	[1017] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("林白轩的画\n", 0) .. self.ColorText("林白轩作的画，上面白色的云雾皆是用冷石粉所图，吸入过多冷石粉便会中毒而死。", 7)
		return szTip
	end,

	[1010] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("武及的验尸报告\n", 0) .. self.ColorText("死亡时间大概是昨日入夜戌时；死亡原因是有一根绣花针刺入脑门要害处。", 7)
		return szTip
	end,

	[1011] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("凶器·绣花针\n", 0) .. self.ColorText("这根绣花针有点特别，半银半铜所制，上半部分是银色，下半部分是金色。", 7)
		return szTip
	end,

	[1012] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("武晖的证词\n", 0) .. self.ColorText("罗轩急匆匆地从外头跑回来进房子里和爹说了什么，然后就出来带一群人往贡橘林去了。之后爹呆在房间里一直没什么动静，第二天起来发现爹爹已死去多时。", 7)
		return szTip
	end,

	[1013] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("小叫花的证词\n", 0) .. self.ColorText("那个人是个左撇子！嗯，没错！他给我冷石，付我银两都是用的左手，从来就没见他动过右手，这点我记得很清楚！我当时还纳闷的，金水镇我没见过有左撇子的啊！", 7)
		return szTip
	end,

	[1014] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("武晴的证词一\n", 0) .. self.ColorText("当天我吃完晚饭就买绣花针去了。我的绣花针被罗轩叔叔借去挑刺给弄丢了。", 7)
		return szTip
	end,

	[1015] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("武晴的证词二\n", 0) .. self.ColorText("罗轩叔叔右手被刺伤了，流了好多血！大夫说都伤到筋了。说不定，说不定右手就给废了。", 7)
		return szTip
	end,

	[1016] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("鉴定过的凶器\n", 0) .. self.ColorText("这正是被罗轩借去的武晴的绣花针。", 7)
		return szTip
	end,

	[1017] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("林白轩的画\n", 0) .. self.ColorText("林白轩作的画，上面白色的云雾皆是用冷石粉所图，吸入过多冷石粉便会中毒而死。", 7)
		return szTip
	end,

	[1010] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("武及的验尸报告\n", 0) .. self.ColorText("死亡时间大概是昨日入夜戌时；死亡原因是有一根绣花针刺入脑门要害处。", 7)
		return szTip
	end,

	[1011] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("凶器·绣花针\n", 0) .. self.ColorText("这根绣花针有点特别，半银半铜所制，上半部分是银色，下半部分是金色。", 7)
		return szTip
	end,

	[1012] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("武晖的证词\n", 0) .. self.ColorText("罗轩急匆匆地从外头跑回来进房子里和爹说了什么，然后就出来带一群人往贡橘林去了。之后爹呆在房间里一直没什么动静，第二天起来发现爹爹已死去多时。", 7)
		return szTip
	end,

	[1013] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("小叫花的证词\n", 0) .. self.ColorText("那个人是个左撇子！嗯，没错！他给我冷石，付我银两都是用的左手，从来就没见他动过右手，这点我记得很清楚！我当时还纳闷的，金水镇我没见过有左撇子的啊！", 7)
		return szTip
	end,

	[1014] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("武晴的证词一\n", 0) .. self.ColorText("当天我吃完晚饭就买绣花针去了。我的绣花针被罗轩叔叔借去挑刺给弄丢了。", 7)
		return szTip
	end,

	[1015] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("武晴的证词二\n", 0) .. self.ColorText("罗轩叔叔右手被刺伤了，流了好多血！大夫说都伤到筋了。说不定，说不定右手就给废了。", 7)
		return szTip
	end,

	[1016] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("鉴定过的凶器\n", 0) .. self.ColorText("这正是被罗轩借去的武晴的绣花针。", 7)
		return szTip
	end,

	[1017] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("林白轩的画\n", 0) .. self.ColorText("林白轩作的画，上面白色的云雾皆是用冷石粉所图，吸入过多冷石粉便会中毒而死。", 7)
		return szTip
	end,

	[1001] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("成步堂的证词\n", 0) .. self.ColorText("将案件相关的证据出示给对方，用以引出新的话题或者指明矛盾等。", 7)
		return szTip
	end,

	[1001] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("成步堂的证词\n", 0) .. self.ColorText("将案件相关的证据出示给对方，用以引出新的话题或者指明矛盾等。", 7)
		return szTip
	end,

	[1001] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("成步堂的证词\n", 0) .. self.ColorText("将案件相关的证据出示给对方，用以引出新的话题或者指明矛盾等。", 7)
		return szTip
	end,

	[1028] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("封仵作的验尸报告\n", 0) .. self.ColorText("尸体被发现的时候是躺在床上，死亡时间大概是丑时三刻，致命死因是脖子上的刀伤，伤口极深，应该是蓄意杀人，凶器是胡府厨房的解腕尖刀。陈福生的遗体则是被发现悬吊在镇外的一颗大树上，口眼开，手散发乱，喉下血脉不行，痕迹浅淡，也不抵齿，项肉上有指爪痕，实为被人勒死再假作自缢。", 7)
		return szTip
	end,

	[1040] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("胡相仁的证词\n", 0) .. self.ColorText("那晚我把醉了的老爷扶回他的卧室后，便吩咐丫鬟金焕儿好生伺候，自己便回去继续喝酒直到喝醉。", 7)
		return szTip
	end,

	[1031] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("刻有“贺”字的玉佩\n", 0) .. self.ColorText("我在凶案现场捡到一个刻有“贺”字的玉佩，整个胡府我就只见过大奶奶贺玉琼戴过这种样式的。", 7)
		return szTip
	end,

	[1032] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("鉴定过的玉佩\n", 0) .. self.ColorText("这个玉佩我已经送给表哥章闻京了。", 7)
		return szTip
	end,

	[1042] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("贺玉琼的证词一\n", 0) .. self.ColorText("章闻京表哥前天晚上来见我的时候，身上还戴着我送给他的玉佩。", 7)
		return szTip
	end,

	[1041] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("贺玉琼的证词二\n", 0) .. self.ColorText("章闻京表哥说，他很快就能让我永远摆脱那可恶的胡唯年。", 7)
		return szTip
	end,

	[1028] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("封仵作的验尸报告\n", 0) .. self.ColorText("尸体被发现的时候是躺在床上，死亡时间大概是丑时三刻，致命死因是脖子上的刀伤，伤口极深，应该是蓄意杀人，凶器是胡府厨房的解腕尖刀。陈福生的遗体则是被发现悬吊在镇外的一颗大树上，口眼开，手散发乱，喉下血脉不行，痕迹浅淡，也不抵齿，项肉上有指爪痕，实为被人勒死再假作自缢。", 7)
		return szTip
	end,

	[1040] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("胡相仁的证词\n", 0) .. self.ColorText("那晚我把醉了的老爷扶回他的卧室后，便吩咐丫鬟金焕儿好生伺候，自己便回去继续喝酒直到喝醉。", 7)
		return szTip
	end,

	[1031] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("刻有“贺”字的玉佩\n", 0) .. self.ColorText("我在凶案现场捡到一个刻有“贺”字的玉佩，整个胡府我就只见过大奶奶贺玉琼戴过这种样式的。", 7)
		return szTip
	end,

	[1032] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("鉴定过的玉佩\n", 0) .. self.ColorText("这个玉佩我已经送给表哥章闻京了。", 7)
		return szTip
	end,

	[1042] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("贺玉琼的证词一\n", 0) .. self.ColorText("章闻京表哥前天晚上来见我的时候，身上还戴着我送给他的玉佩。", 7)
		return szTip
	end,

	[1041] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("贺玉琼的证词二\n", 0) .. self.ColorText("章闻京表哥说，他很快就能让我永远摆脱那可恶的胡唯年。", 7)
		return szTip
	end,

	[1028] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("封仵作的验尸报告\n", 0) .. self.ColorText("尸体被发现的时候是躺在床上，死亡时间大概是丑时三刻，致命死因是脖子上的刀伤，伤口极深，应该是蓄意杀人，凶器是胡府厨房的解腕尖刀。陈福生的遗体则是被发现悬吊在镇外的一颗大树上，口眼开，手散发乱，喉下血脉不行，痕迹浅淡，也不抵齿，项肉上有指爪痕，实为被人勒死再假作自缢。", 7)
		return szTip
	end,

	[1040] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("胡相仁的证词\n", 0) .. self.ColorText("那晚我把醉了的老爷扶回他的卧室后，便吩咐丫鬟金焕儿好生伺候，自己便回去继续喝酒直到喝醉。", 7)
		return szTip
	end,

	[1031] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("刻有“贺”字的玉佩\n", 0) .. self.ColorText("我在凶案现场捡到一个刻有“贺”字的玉佩，整个胡府我就只见过大奶奶贺玉琼戴过这种样式的。", 7)
		return szTip
	end,

	[1032] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("鉴定过的玉佩\n", 0) .. self.ColorText("这个玉佩我已经送给表哥章闻京了。", 7)
		return szTip
	end,

	[1042] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("贺玉琼的证词一\n", 0) .. self.ColorText("章闻京表哥前天晚上来见我的时候，身上还戴着我送给他的玉佩。", 7)
		return szTip
	end,

	[1041] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("贺玉琼的证词二\n", 0) .. self.ColorText("章闻京表哥说，他很快就能让我永远摆脱那可恶的胡唯年。", 7)
		return szTip
	end,

	[1035] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("乐逵的无声指证\n", 0) .. self.ColorText("乐逵表示，他打伤了凶手的右肩。", 7)
		return szTip
	end,

	[1036] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("景飞燕的珠钗\n", 0) .. self.ColorText("莫方毅在案发现场捡到这根珠钗，并认出是他妻子景飞燕的。", 7)
		return szTip
	end,

	[1043] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("景飞燕的证词\n", 0) .. self.ColorText("这支珠钗的确是我的，但半个月前它就被慕容芳菲借走了，她如今正在聚贤山庄做客。", 7)
		return szTip
	end,

	[1039] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("慕容芳菲的证词\n", 0) .. self.ColorText("我那不孝女儿钟颖抢走了这支珠钗，说是要拿去献给她师父公治菱。九天前钟颖说要去一趟灵蛇谷那边，我估计就是去莫家堡那边干些见不得光的事！", 7)
		return szTip
	end,

	[1035] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("乐逵的无声指证\n", 0) .. self.ColorText("乐逵表示，他打伤了凶手的右肩。", 7)
		return szTip
	end,

	[1036] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("景飞燕的珠钗\n", 0) .. self.ColorText("莫方毅在案发现场捡到这根珠钗，并认出是他妻子景飞燕的。", 7)
		return szTip
	end,

	[1043] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("景飞燕的证词\n", 0) .. self.ColorText("这支珠钗的确是我的，但半个月前它就被慕容芳菲借走了，她如今正在聚贤山庄做客。", 7)
		return szTip
	end,

	[1039] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("慕容芳菲的证词\n", 0) .. self.ColorText("我那不孝女儿钟颖抢走了这支珠钗，说是要拿去献给她师父公治菱。九天前钟颖说要去一趟灵蛇谷那边，我估计就是去莫家堡那边干些见不得光的事！", 7)
		return szTip
	end,

	[1035] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("乐逵的无声指证\n", 0) .. self.ColorText("乐逵表示，他打伤了凶手的右肩。", 7)
		return szTip
	end,

	[1036] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("景飞燕的珠钗\n", 0) .. self.ColorText("莫方毅在案发现场捡到这根珠钗，并认出是他妻子景飞燕的。", 7)
		return szTip
	end,

	[1043] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("景飞燕的证词\n", 0) .. self.ColorText("这支珠钗的确是我的，但半个月前它就被慕容芳菲借走了，她如今正在聚贤山庄做客。", 7)
		return szTip
	end,

	[1039] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("慕容芳菲的证词\n", 0) .. self.ColorText("我那不孝女儿钟颖抢走了这支珠钗，说是要拿去献给她师父公治菱。九天前钟颖说要去一趟灵蛇谷那边，我估计就是去莫家堡那边干些见不得光的事！", 7)
		return szTip
	end,

	[1044] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("祖合拉的验伤报告\n", 0) .. self.ColorText("尼罗身上的伤疑为枪戟造成的。", 7)
		return szTip
	end,

	[1046] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("萨比尔的证词\n", 0) .. self.ColorText("尼罗昏迷中尼尔的伤势是被并不娴熟的天策枪法所伤。", 7)
		return szTip
	end,

	[1047] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("训练弟子的证词\n", 0) .. self.ColorText("训练弟子目击了尼尔被从天鹅坪抬回，虽然昏迷了手上还紧紧的拽着某样东西。", 7)
		return szTip
	end,

	[1045] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("碎布\n", 0) .. self.ColorText("尼罗昏迷中还紧紧抓住的一块碎布，应该是偷袭者之物。", 7)
		return szTip
	end,

	[1048] = function(rect)
		local nIconID, szCategory, szName = 0, "默认分类", "默认名字"
		local szTip = self.ColorText("萨莱曼的证词\n", 0) .. self.ColorText("尼罗手中的破布应该是少林僧袍。", 7)
		return szTip
	end,
}

-------------------------------- 消息定义 --------------------------------
GameWorldTipData.Event = {}
GameWorldTipData.Event.XXX = "GameWorldTipData.Msg.XXX"

function GameWorldTipData.Init()
    
end

function GameWorldTipData.UnInit()
    
end

function GameWorldTipData.OnLogin()
    
end

function GameWorldTipData.OnFirstLoadEnd()
    
end

function GameWorldTipData.ColorText(szText, nColorIndex)
	if not nColorIndex or nColorIndex > 14 or nColorIndex < 0 then nColorIndex = 7 end
	local tbColor = UIDialogueColorTab[COLOR_TABLE[nColorIndex]]
	local szColor = tbColor and tbColor.Color or "#E2F6FB"
	-- szText = UIHelper.EncodeComponentsString(szText)
	local szColoredText = string.format("<color=%s>%s</c>", szColor, szText)
	return szColoredText
end

function GameWorldTipData.GetTipByTipID(nTipID)
	return g_aGameWorldTip[nTipID]()
end
