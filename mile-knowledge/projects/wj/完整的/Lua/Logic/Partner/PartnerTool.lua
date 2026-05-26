--- note:   Tool_GetAssistedScore 搬运自 scripts/Map/ACT_助战npc/include/助战npc副本特殊指令.lua ，后面若这部分功能挪到了vk和dx都能读取的地方，就可以删掉了
---         tHeroDataList数据     scripts/NpcAssisted/include/侠缘data.lua
PartnerTool         = PartnerTool or { className = "PartnerTool" }
local self = PartnerTool


--- @class PartnerDataInfo
---@field id number 侠客id
---@field dwTemplateID number npc模板id
---@field dwUse number 1dps2T3奶
---@field name string 名称
---@field bTry boolean 是否是单人侠客
---@field item table FieldDesc
---@field unlockPoint number 碰瓷次数保底
---@field strengthItem table 目前填了后世界boss摸翔有概率出，无其他逻辑功能，真正的消耗申请填在ui/Scheme/Case/Partner/PartnerGiftInfo.txt
---@field questList table --0为前置，1~6表示好感度任务,没有的填nil
---@field achi table {解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil
---@field nTryScore number 试用的分，用于战斗力计算
---@field bExtraCof number 额外系数
---@field nSpecialStage table 特殊命座，3命，额外分数

--dwTipsID为此表中的ID：/ui/Scheme/Case/Partner/PartnerMessage.txt，用于在玩家登录时弹出任务地点提示。格式同活动文本，可暂时用活动编辑器编辑文本。
--英雄信息，修改的strengthItem话记得同步修改UI表ui/Scheme/Case/Partner/PartnerGiftInfo.txt
--- @type PartnerDataInfo[]
local tHeroDataList = {
	{id = 1,
		dwTemplateID = 108914,
		dwUse = 2, --枚举型，1dps2T3奶
		name = GetEditorString(22, 3551), --康宴别
		unlockPoint = 120, --碰瓷次数保底
		tTeaList = {{5, 45838}, {5, 45839}}, --碰瓷喝茶消耗道具和优先级，同步改表ui/Scheme/Case/Partner/PartnerNpcInfo.txt
		strengthItem = {[45798] = 5000}, --消耗指定道具，提升一命（5000经验/命），同步改表ui/Scheme/Case/Partner/PartnerGiftInfo.txt
		questList = {	--0为前置，1~6表示好感度任务,没有的填nil,			
			[0] = {before = 24860, list = {24867, 24868, 24869, }}, --前置任务，before=解锁前置，list的进行中的任务列表，以便查询哪一环断了或者续接
			[1] = {before = 24861, dwTipsID = 7, list = {24870, 24871, }}, --好感度1
			[2] = {before = 24862, dwTipsID = 8, list = {24872, 24873, }}, --好感度2
			[3] = {before = 24863, dwTipsID = 9, list = {24874, 24875, 24876, 24877, 24878, }}, --好感度3
			[4] = {before = 24865, dwTipsID = 10, list = {24881, 24882, }}, --好感度4
			[5] = {before = 24864, dwTipsID = 11, list = {24879, 24880, }}, --好感度5
			[6] = {before = 24866, dwTipsID = 12, list = {24883, 24884, }}, --好感度6
		},
		achi = {unLock = 10221, lv60 = 10232, lv90 = 10243, fs1 = 10254, fs3 = nil, fs6 = 10258, star1 = 10262, star2 = nil, star3 = nil, star4 = 10274, perfect = 10278}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil
		bExtraCof = 1.1, --计算战斗力时的倍率
		nTravelLv = 4, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4		
	},
	{id = 2,
		dwTemplateID = 108915,
		dwUse = 1, --枚举型，1dps2T3奶
		name = GetEditorString(23, 2040), --唐小珂
		unlockPoint = 120,
		tTeaList = {{5, 45838}, {5, 45839}}, --碰瓷喝茶消耗道具和优先级，同步改表ui/Scheme/Case/Partner/PartnerNpcInfo.txt
		strengthItem = {[45800] = 5000}, --消耗指定道具，提升一命（5000经验/命），同步改表ui/Scheme/Case/Partner/PartnerGiftInfo.txt
		questList = {	--0为前置，1~6表示好感度任务,没有的填nil,			
			[0] = {before = 24886, list = {25014, 24888, 24889, 24890, 24891, 24901, 24926, }}, --前置任务，before=解锁前置，list的进行中的任务列表，以便查询哪一环断了或者续接
			[1] = {before = 24887, dwTipsID = 13, list = {24902, 24903, 24904, }}, --好感度1
			[2] = {before = 24892, dwTipsID = 14, list = {24905, 24907, 24908, 24909, 24910}}, --好感度2
			[3] = {before = 24893, dwTipsID = 15, list = {24911, 24912, 24913, }}, --好感度3
			[4] = {before = 24894, dwTipsID = 16, list = {24897, 24898, 24899, }}, --好感度4
			[5] = {before = 24895, dwTipsID = 17, list = {24919, 24920, }}, --好感度5
			[6] = {before = 24896, dwTipsID = 18, list = {24914, 24915, 24916, 24917, 24918}}, --好感度6
		},
		achi = {unLock = 10222, lv60 = 10233, lv90 = 10244, fs1 = 10255, fs3 = nil, fs6 = 10259, star1 = 10263, star2 = nil, star3 = nil, star4 = 10275, perfect = 10279}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil
		bExtraCof = 1.05, --计算战斗力时的倍率
		nTravelLv = 4, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4		
	},
	{id = 3,
		dwTemplateID = 108916,
		dwUse = 3, --枚举型，1dps2T3奶
		name = GetEditorString(23, 1732), --沐晴柔
		unlockPoint = 120,
		tTeaList = {{5, 45838}, {5, 45839}}, --碰瓷喝茶消耗道具和优先级，同步改表ui/Scheme/Case/Partner/PartnerNpcInfo.txt
		strengthItem = {[45802] = 5000}, --消耗指定道具，提升一命（5000经验/命），同步改表ui/Scheme/Case/Partner/PartnerGiftInfo.txt
		questList = {	--0为前置，1~6表示好感度任务,没有的填nil,			
			[0] = {before = 24953, list = {25012, 24836, 24837, }}, --前置任务，before=解锁前置，list的进行中的任务列表，以便查询哪一环断了或者续接
			[1] = {before = 24838, dwTipsID = 1, list = {24839, }}, --好感度1
			[2] = {before = 24840, dwTipsID = 2, list = {24841, 24842, }}, --好感度2
			[3] = {before = 24843, dwTipsID = 3, list = {24844, 24845, 24846, 24847, 24848, }}, --好感度3
			[4] = {before = 24849, dwTipsID = 4, list = {24850, 24851, }}, --好感度4
			[5] = {before = 24852, dwTipsID = 5, list = {24853, 24854, 24855, 24856, }}, --好感度5
			[6] = {before = 24857, dwTipsID = 6, list = {24858, }}, --好感度6
		},
		achi = {unLock = 10223, lv60 = 10234, lv90 = 10245, fs1 = 10256, fs3 = nil, fs6 = 10260, star1 = 10264, star2 = nil, star3 = nil, star4 = 10276, perfect = 10280}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil
		bExtraCof = 1.1, --计算战斗力时的倍率
		nTravelLv = 4, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4		
	},
	{id = 4,
		dwTemplateID = 109906,
		dwUse = 1, --枚举型，1dps2T3奶
		name = GetEditorString(6, 3495), --沈剑心
		unlockPoint = 1,
		tTeaList = {{5, 45838}, {5, 45839}}, --碰瓷喝茶消耗道具和优先级，同步改表ui/Scheme/Case/Partner/PartnerNpcInfo.txt
		dwShadowID = 24, --原英雄id
		strengthItem = {[45804] = 5000}, --消耗指定道具，提升一命（5000经验/命），同步改表ui/Scheme/Case/Partner/PartnerGiftInfo.txt
		questList = {	--0为前置，1~6表示好感度任务,没有的填nil,			
			[0] = {before = 24922, list = {24923, }}, --前置任务，before=解锁前置，list的进行中的任务列表，以便查询哪一环断了或者续接
			[1] = {before = 27120, list = {19667, 19726, 19727, 19730, 19731, 19728, 19729, 19732, 19756, 19733, }}, --好感度1
			--[2] = {before = 24838, list = {24953, 24836, 24837, }},--好感度2
			--[3] = {before = 24838, list = {24953, 24836, 24837, }},--好感度3
			--[4] = {before = 24838, list = {24953, 24836, 24837, }},--好感度4
			--[5] = {before = 24838, list = {24953, 24836, 24837, }},--好感度5
			--[6] = {before = 24838, list = {24953, 24836, 24837, }},--好感度6
		},
		achi = {unLock = 10224, lv60 = 10235, lv90 = 10246, fs1 = 10257, fs3 = nil, fs6 = 10261, star1 = 10265, star2 = nil, star3 = nil, star4 = 10277, perfect = 10281}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil
		bExtraCof = 1.05, --计算战斗力时的倍率
		nTravelLv = 4, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4		
	},
	{id = 5,
		dwTemplateID = 110322,
		dwUse = 1, --枚举型，1dps2T3奶
		name = GetEditorString(16, 5366), --温折枝
		unlockPoint = 9999,
		nArchitecture = 160000, --雇佣消耗的园宅币
		dwShadowID = 25, --原英雄id
		strengthItem = {nil},
		questList = {}, --前置任务始末
		achi = {unLock = nil, lv60 = 10225, lv90 = 10236, fs1 = nil, fs3 = 7871, fs6 = 10247, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil	
		nTravelLv = 1, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4		
	},
	{id = 6,
		dwTemplateID = 110323,
		dwUse = 1, --枚举型，1dps2T3奶
		name = GetEditorString(16, 5365), --年小鹿
		dwShadowID = 20, --原英雄id
		unlockPoint = 9999,
		nArchitecture = 40000, --雇佣消耗的园宅币
		strengthItem = {nil},
		questList = {}, --前置任务始末
		achi = {unLock = nil, lv60 = 10226, lv90 = 10237, fs1 = nil, fs3 = 7869, fs6 = 10248, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil	
		nTravelLv = 1, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4		
	},
	{id = 7,
		dwTemplateID = 110326,
		dwUse = 1, --枚举型，1dps2T3奶
		name = GetEditorString(21, 6742), --阮归云
		dwShadowID = 19, --原英雄id
		unlockPoint = 9999,
		nArchitecture = 300000, --雇佣消耗的园宅币
		strengthItem = {nil},
		questList = {}, --前置任务始末
		achi = {unLock = nil, lv60 = 10227, lv90 = 10238, fs1 = nil, fs3 = 9690, fs6 = 10249, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil	
		nTravelLv = 1, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4	
	},
	{id = 8,
		dwTemplateID = 110321,
		dwUse = 3, --枚举型，1dps2T3奶
		name = GetEditorString(16, 6194), --温辞秋
		unlockPoint = 9999,
		nArchitecture = 160000, --雇佣消耗的园宅币
		dwShadowID = 26, --原英雄id
		strengthItem = {nil},
		questList = {}, --前置任务始末
		achi = {unLock = nil, lv60 = 10228, lv90 = 10239, fs1 = nil, fs3 = 7872, fs6 = 10250, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil	
		nTravelLv = 1, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4	
	},
	{id = 9,
		dwTemplateID = 110324,
		dwUse = 3, --枚举型，1dps2T3奶
		name = GetEditorString(16, 5364), --年小熊
		unlockPoint = 9999,
		nArchitecture = 40000, --雇佣消耗的园宅币
		dwShadowID = 27, --原英雄id
		strengthItem = {nil},
		questList = {}, --前置任务始末
		achi = {unLock = nil, lv60 = 10229, lv90 = 10240, fs1 = nil, fs3 = 7870, fs6 = 10251, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil	
		nTravelLv = 1, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4	
	},
	{id = 10,
		dwTemplateID = 110327,
		dwUse = 3, --枚举型，1dps2T3奶
		name = GetEditorString(21, 6743), --阮闲舟
		dwShadowID = 21, --原英雄id
		unlockPoint = 9999,
		nArchitecture = 300000, --雇佣消耗的园宅币
		strengthItem = {nil},
		questList = {}, --前置任务始末
		achi = {unLock = nil, lv60 = 10230, lv90 = 10241, fs1 = nil, fs3 = 9691, fs6 = 10252, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil	
		nTravelLv = 1, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4	
	},
	{id = 11,
		dwTemplateID = 110325,
		dwUse = 2, --枚举型，1dps2T3奶
		name = GetEditorString(16, 5368), --茸茸
		dwShadowID = 18, --原英雄id
		unlockPoint = 9999,
		nArchitecture = 300000, --雇佣消耗的园宅币
		strengthItem = {nil},
		questList = {}, --前置任务始末
		achi = {unLock = nil, lv60 = 10231, lv90 = 10242, fs1 = nil, fs3 = 7868, fs6 = 10253, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil	
		nTravelLv = 1, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4	
	},
	{id = 12,
		dwTemplateID = 120617,
		dwUse = 3, --枚举型，1dps2T3奶
		name = GetEditorString(24, 6988), --燕子娘
		unlockPoint = 9999,
		strengthItem = {nil},
		questList = {}, --前置任务始末
		achi = {unLock = nil, lv60 = nil, lv90 = nil, fs1 = nil, fs3 = nil, fs6 = nil, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil	
		nTravelLv = 3, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4	
	},
	{id = 13,
		dwTemplateID = 120618,
		dwUse = 2, --枚举型，1dps2T3奶
		name = GetEditorString(24, 6985), --刀马
		unlockPoint = 9999,
		strengthItem = {nil},
		questList = {}, --前置任务始末
		achi = {unLock = nil, lv60 = nil, lv90 = nil, fs1 = nil, fs3 = nil, fs6 = nil, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil	
		nTravelLv = 3, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4	
	},
	{id = 14,
		dwTemplateID = 120906,
		dwUse = 1, --枚举型，1dps2T3奶
		name = GetEditorString(25, 1832), --李星云
		unlockPoint = 120, --碰瓷次数保底
		tTeaList = {{5, 45838}, {5, 45839}}, --碰瓷喝茶消耗道具和优先级，同步改表ui/Scheme/Case/Partner/PartnerNpcInfo.txt
		bUnLockNow = true, --喝茶喝到直接解锁
		strengthItem = {[50598] = 5000}, --消耗指定道具，提升一命（5000经验/命），同步改表ui/Scheme/Case/Partner/PartnerGiftInfo.txt
		questList = {	--0为前置，1~6表示好感度任务,没有的填nil,
		},
		achi = {unLock = 10841, lv60 = 10842, lv90 = 10843, fs1 = 10844, fs3 = nil, fs6 = 10845, star1 = 10846, star2 = nil, star3 = nil, star4 = 10849, perfect = 10850}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil
		bExtraCof = 1.15, --计算战斗力时的倍率
		nSpecialStage = {1, 1.05,bMultiply=true}, --特殊命座，1命，额外分数
		nTravelLv = 4, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4	
	},
	{id = 15,
		dwTemplateID = 122730,
		dwUse = 1, --枚举型，1dps2T3奶
		name = GetEditorString(25, 3721), --月嘉禾
		unlockPoint = 120, --碰瓷次数保底
		tTeaList = {{5, 45838}, {5, 45839}}, --碰瓷喝茶消耗道具和优先级，同步改表ui/Scheme/Case/Partner/PartnerNpcInfo.txt
		strengthItem = {[45792] = 5000}, --消耗指定道具，提升一命（5000经验/命），同步改表ui/Scheme/Case/Partner/PartnerGiftInfo.txt
		questList = {	--0为前置，1~6表示好感度任务,没有的填nil,			
			[0] = {before = 25797, list = {25822, 25823, 25824, 25825, }}, --前置任务，before=解锁前置，list的进行中的任务列表，以便查询哪一环断了或者续接
			[1] = {before = 25798, dwTipsID = 19, list = {25826, 25827, 25828, }}, --好感度1
			[2] = {before = 25799, dwTipsID = 20, list = {25829, 25830, 25831}}, --好感度2
			[3] = {before = 25800, dwTipsID = 21, list = {25832, 25833, 25834, }}, --好感度3
			[4] = {before = 25801, dwTipsID = 22, list = {25835, 25836, 25837, }}, --好感度4
			[5] = {before = 25802, dwTipsID = 23, list = {25838, 25839, 25840, 25841, 25842}}, --好感度5
			[6] = {before = 25803, dwTipsID = 24, list = {25843, 25844}}, --好感度6
		},
		achi = {unLock = 10983, lv60 = 10984, lv90 = 10985, fs1 = 10986, fs3 = nil, fs6 = 10987, star1 = 10988, star2 = nil, star3 = nil, star4 = 10989, perfect = 10990}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil
		bExtraCof = 1.15,
		nSpecialStage = {2, 0.2}, --特殊命座，2命，额外分数
		nTravelLv = 4, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4	
	},
	{id = 16,
		dwTemplateID = 123965,
		dwUse = 1, --枚举型，1dps2T3奶
		name = GetEditorString(27, 9594), --贺闲
		unlockPoint = 120, --碰瓷次数保底
		tTeaList = {{5, 45838}, {5, 45839}}, --碰瓷喝茶消耗道具和优先级，同步改表ui/Scheme/Case/Partner/PartnerNpcInfo.txt
		strengthItem = {[53899] = 5000}, --消耗指定道具，提升一命（5000经验/命），同步改表ui/Scheme/Case/Partner/PartnerGiftInfo.txt
		questList = {
			[0] = {before = 26001, list = {26002, 26199, 26003, 26004, 26005, 26006}},
			[1] = {before = 26007, dwTipsID = 25, list = {26008, 26009, 26010}},
			[2] = {before = 26011, dwTipsID = 26, list = {26012}},
			[3] = {before = 26013, dwTipsID = 27, list = {26014, 26015, 26016, }},
			[4] = {before = 26017, dwTipsID = 28, list = {26018, 26019, 26020, }},
			[5] = {before = 26021, dwTipsID = 29, list = {26022, 26023, 26024, 26025, 26026, }},
			[6] = {before = 26027, dwTipsID = 30, list = {26028, 26029, 26030, 26031, }}
		},
		achi = {unLock = 11068, lv60 = 11069, lv90 = 11070, fs1 = 11071, fs3 = nil, fs6 = 11072, star1 = 11073, star2 = nil, star3 = nil, star4 = 11074, perfect = 11075}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil
		bExtraCof = 1.25,
		nTravelLv = 4, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4	
	},
	{id = 17,
		dwTemplateID = 124038,
		dwUse = 2, --枚举型，1dps2T3奶
		name = GetEditorString(28, 4917), --费大劲
		unlockPoint = 9999,
		strengthItem = {nil},
		questList = {}, --前置任务始末
		achi = {unLock = 11219, lv60 = 11220, lv90 = 11221, fs1 = nil, fs3 = nil, fs6 = 11222, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil	
		nTravelLv = 2, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4	
	},
	{id = 18,
		dwTemplateID = 126852,
		dwUse = 2, --枚举型，1dps2T3奶
		name = GetEditorString(16, 5368), --试用
		bTry = true,
		dwShadowID = 11, --原英雄id
		unlockPoint = 9999,
		strengthItem = {nil},
		questList = {}, --前置任务始末
		achi = {unLock = nil, lv60 = nil, lv90 = nil, fs1 = nil, fs3 = nil, fs6 = nil, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil
		nTryScore = 600, --试用的分，用于战斗力计算
	},
	{id = 19,
		dwTemplateID = 126853,
		dwUse = 1, --枚举型，1dps2T3奶
		name = GetEditorString(21, 6742), --试用
		bTry = true,
		dwShadowID = 7, --原英雄id
		unlockPoint = 9999,
		strengthItem = {nil},
		questList = {}, --前置任务始末
		achi = {unLock = nil, lv60 = nil, lv90 = nil, fs1 = nil, fs3 = nil, fs6 = nil, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil
		nTryScore = 430, --试用的分，用于战斗力计算
	},
	{id = 20,
		dwTemplateID = 126854,
		dwUse = 1, --枚举型，1dps2T3奶
		name = GetEditorString(16, 5365), --试用
		bTry = true,
		dwShadowID = 6, --原英雄id
		unlockPoint = 9999,
		strengthItem = {nil},
		questList = {}, --前置任务始末
		achi = {unLock = nil, lv60 = nil, lv90 = nil, fs1 = nil, fs3 = nil, fs6 = nil, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil
		nTryScore = 430, --试用的分，用于战斗力计算
	},
	{id = 21,
		dwTemplateID = 126855,
		dwUse = 3, --枚举型，1dps2T3奶
		name = GetEditorString(21, 6743), --试用
		bTry = true,
		dwShadowID = 10, --原英雄id
		unlockPoint = 9999,
		strengthItem = {nil},
		questList = {}, --前置任务始末
		achi = {unLock = nil, lv60 = nil, lv90 = nil, fs1 = nil, fs3 = nil, fs6 = nil, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil
		nTryScore = 605, --试用的分，用于战斗力计算
	},
	{id = 22,
		dwTemplateID = 123965, --需要换成白鹊的
		dwUse = 1, --枚举型，1dps2T3奶
		name = GetEditorString(29, 1387), --白鹊
		unlockPoint = 120, --碰瓷次数保底
		tTeaList = {{5, 45838}, {5, 45839}}, --碰瓷喝茶消耗道具和优先级，同步改表ui/Scheme/Case/Partner/PartnerNpcInfo.txt
		strengthItem = {[44431] = 5000}, --消耗指定道具，提升一命（5000经验/命），同步改表ui/Scheme/Case/Partner/PartnerGiftInfo.txt
		questList = {	--0为前置，1~6表示好感度任务,没有的填nil,			
			[0] = {before = 26738, list = {26840, 26739, }}, --前置任务，before=解锁前置，list的进行中的任务列表，以便查询哪一环断了或者续接
			[1] = {before = 26740, dwTipsID = 31, list = {26747, }}, --好感度1
			[2] = {before = 26741, dwTipsID = 32, list = {26749, }}, --好感度2
			[3] = {before = 26742, dwTipsID = 33, list = {26750, 26751, }}, --好感度3
			[4] = {before = 26743, dwTipsID = 34, list = {26752, }}, --好感度4
			[5] = {before = 26744, dwTipsID = 35, list = {26753, 26754, 26755, 26756, 26757, 26758, 26759, 26748, }}, --好感度5
			[6] = {before = 26745, dwTipsID = 36, list = {26760, }}, --好感度6
		},
		achi = {unLock = 11446, lv60 = 11447, lv90 = 11448, fs1 = 11449, fs3 = nil, fs6 = 11450, star1 = 11451, star2 = nil, star3 = nil, star4 = 11452, perfect = 11453}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil
		bExtraCof = 1.35,
		nSpecialStage = {3, 0.1}, --特殊命座，3命，额外分数
		nTravelLv = 4, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4	
	},
	{id = 23,
		dwTemplateID = 128081,
		dwUse = 1, --枚举型，1dps2T3奶
		name = GetEditorString(18, 5267), --试用
		bTry = true,
		unlockPoint = 9999,
		strengthItem = {nil},
		questList = {}, --前置任务始末
		achi = {unLock = nil, lv60 = nil, lv90 = nil, fs1 = nil, fs3 = nil, fs6 = nil, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil
		nTryScore = 510, --试用的分，用于战斗力计算
	},
	{id = 24,
		dwTemplateID = 128082,
		dwUse = 1, --枚举型，1dps2T3奶
		name = GetEditorString(6, 3495), --试用
		bTry = true,
		dwShadowID = 4, --原英雄id
		unlockPoint = 9999,
		strengthItem = {nil},
		questList = {}, --前置任务始末
		achi = {unLock = nil, lv60 = nil, lv90 = nil, fs1 = nil, fs3 = nil, fs6 = nil, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil
		nTryScore = 510, --试用的分，用于战斗力计算
	},
	{id = 25,
		dwTemplateID = 128083,
		dwUse = 1, --枚举型，1dps2T3奶
		name = GetEditorString(16, 5366), --试用
		bTry = true,
		dwShadowID = 5, --原英雄id
		unlockPoint = 9999,
		strengthItem = {nil},
		questList = {}, --前置任务始末
		achi = {unLock = nil, lv60 = nil, lv90 = nil, fs1 = nil, fs3 = nil, fs6 = nil, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil
		nTryScore = 430, --试用的分，用于战斗力计算
	},
	{id = 26,
		dwTemplateID = 128084,
		dwUse = 3, --枚举型，1dps2T3奶
		name = GetEditorString(16, 6194), --试用
		bTry = true,
		dwShadowID = 8, --原英雄id
		unlockPoint = 9999,
		strengthItem = {nil},
		questList = {}, --前置任务始末
		achi = {unLock = nil, lv60 = nil, lv90 = nil, fs1 = nil, fs3 = nil, fs6 = nil, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil
		nTryScore = 605, --试用的分，用于战斗力计算
	},
	{id = 27,
		dwTemplateID = 128085,
		dwUse = 3, --枚举型，1dps2T3奶
		name = GetEditorString(16, 5364), --试用
		bTry = true,
		dwShadowID = 9, --原英雄id
		unlockPoint = 9999,
		strengthItem = {nil},
		questList = {}, --前置任务始末
		achi = {unLock = nil, lv60 = nil, lv90 = nil, fs1 = nil, fs3 = nil, fs6 = nil, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil
		nTryScore = 600, --试用的分，用于战斗力计算
	},
	{id = 28,
		dwTemplateID = 128086,
		dwUse = 1, --枚举型，1dps2T3奶
		name = GetEditorString(18, 5271), --试用
		bTry = true,
		unlockPoint = 9999,
		strengthItem = {nil},
		questList = {}, --前置任务始末
		achi = {unLock = nil, lv60 = nil, lv90 = nil, fs1 = nil, fs3 = nil, fs6 = nil, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil
		nTryScore = 510, --试用的分，用于战斗力计算
	},
	{id = 29,
		dwTemplateID = 131038, --需要换成盖聂的
		dwUse = 1, --枚举型，1dps2T3奶
		name = GetEditorString(30, 9238), --盖聂
		unlockPoint = 120, --碰瓷次数保底
		tTeaList = {{5, 71080}, {5, 45838}, {5, 71094}}, --碰瓷喝茶消耗道具和优先级，同步改表ui/Scheme/Case/Partner/PartnerNpcInfo.txt
		EndDate= DateToTime(2025, 11, 23, 24, 0, 0),--就这个写法 谁想改谁自己去写
		tTeaList2 = { {5, 71080}, {5, 71094}, }, 
		bUnLockNow = true, --喝茶喝到直接解锁
		strengthItem = {[44432] = 5000}, --消耗指定道具，提升一命（5000经验/命），同步改表ui/Scheme/Case/Partner/PartnerGiftInfo.txt
		questList = {},	--0为前置，1~6表示好感度任务,没有的填nil,	
		achi = {unLock = nil, lv60 = nil, lv90 = nil, fs1 = nil, fs3 = nil, fs6 = nil, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil
		bExtraCof = 1.35,
		--nSpecialStage = {3, 0.1}, --特殊命座，3命，额外分数
		nTravelLv = 4, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4
	},
	{id = 30,
		dwTemplateID = 131039, --需要换成卫庄的
		dwUse = 1, --枚举型，1dps2T3奶
		name = GetEditorString(30, 9239), --卫庄
		unlockPoint = 120, --碰瓷次数保底
		tTeaList = {{5, 71080}, {5, 45838}, {5, 71094}},
		EndDate= DateToTime(2025, 11, 23, 24, 0, 0),--就这个写法 谁想改谁自己去写
		tTeaList2 = { {5, 71080}, {5, 71094}, }, --碰瓷喝茶消耗道具和优先级，同步改表ui/Scheme/Case/Partner/PartnerNpcInfo.txt
		bUnLockNow = true, --喝茶喝到直接解锁
		strengthItem = {[44433] = 5000}, --消耗指定道具，提升一命（5000经验/命），同步改表ui/Scheme/Case/Partner/PartnerGiftInfo.txt
		questList = {},	--0为前置，1~6表示好感度任务,没有的填nil		
		achi = {unLock = nil, lv60 = nil, lv90 = nil, fs1 = nil, fs3 = nil, fs6 = nil, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil
		bExtraCof = 1.35,
		nSpecialStage = {2, 0.1}, --特殊命座，3命，额外分数
		nTravelLv = 4, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4	
	},
	{id = 31,
		dwTemplateID = 132050, --需要换成李逍遥的
		dwUse = 1, --枚举型，1dps2T3奶
		name = GetEditorString(31, 3117), --李逍遥
		unlockPoint = 120, --碰瓷次数保底
		tWithoutItem={5,78423,GetEditorString(31, 3976)},--有蜀山令牌能直接获得侠客，不让喝
		tTeaList = {{5, 45838}, {5, 78564}}, --碰瓷喝茶消耗道具和优先级，同步改表ui/Scheme/Case/Partner/PartnerNpcInfo.txt
		EndDate= DateToTime(2026, 4, 17, 7, 0, 0),--不样产出了
		tTeaList2 = { {5, 78564}, }, --碰瓷喝茶消耗道具和优先级，同步改表ui/Scheme/Case/Partner/PartnerNpcInfo.txt		
		--2025.5.15之前暂时不让喝
		bUnLockNow = true, --喝茶喝到直接解锁
		strengthItem = {[44434] = 5000}, --消耗指定道具，提升一命（5000经验/命），同步改表ui/Scheme/Case/Partner/PartnerGiftInfo.txt
		questList = {},	--0为前置，1~6表示好感度任务,没有的填nil,	
		achi = {unLock = nil, lv60 = nil, lv90 = nil, fs1 = nil, fs3 = nil, fs6 = nil, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil
		bExtraCof = 1.45,
		--nSpecialStage = {3, 0.1}, --特殊命座，3命，额外分数
		nTravelLv = 4, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4
	},
	{id = 32,
		dwTemplateID = 132051, --需要换成赵灵儿的
		dwUse = 3, --枚举型，1dps2T3奶
		name = GetEditorString(31, 3118), --赵灵儿
		unlockPoint = 120, --碰瓷次数保底
		tTeaList = {{5, 45838}, {5, 78564}}, --碰瓷喝茶消耗道具和优先级，同步改表ui/Scheme/Case/Partner/PartnerNpcInfo.txt
		EndDate= DateToTime(2026, 4, 17, 7, 0, 0),--不样产出了
		tTeaList2 = { {5, 78564}, }, --碰瓷喝茶消耗道具和优先级，同步改表ui/Scheme/Case/Partner/PartnerNpcInfo.txt		
		bUnLockNow = true, --喝茶喝到直接解锁
		strengthItem = {[44435] = 5000}, --消耗指定道具，提升一命（5000经验/命），同步改表ui/Scheme/Case/Partner/PartnerGiftInfo.txt
		questList = {},	--0为前置，1~6表示好感度任务,没有的填nil		
		achi = {unLock = nil, lv60 = nil, lv90 = nil, fs1 = nil, fs3 = nil, fs6 = nil, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil
		bExtraCof = 1.45,
		nSpecialStage = {4, 0.05}, --特殊命座，3命，额外分数
		nTravelLv = 4, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4	
	},
	{id = 33,
		dwTemplateID = 135326, 
		dwUse = 1, --枚举型，1dps2T3奶
		name = GetEditorString(32, 2840), --姜棠
		unlockPoint = 120, --碰瓷次数保底
		tTeaList = {{5, 45838}, {5, 45839}}, --碰瓷喝茶消耗道具和优先级，同步改表ui/Scheme/Case/Partner/PartnerNpcInfo.txt
		strengthItem = {[81935] = 5000}, --消耗指定道具，提升一命（5000经验/命），同步改表ui/Scheme/Case/Partner/PartnerGiftInfo.txt
		questList = {	--0为前置，1~6表示好感度任务,没有的填nil,			
			[0] = {before = 28597, list = {28604, 28605,28606,28607 }}, --前置任务，before=解锁前置，list的进行中的任务列表，以便查询哪一环断了或者续接
			[1] = {before = 28598, dwTipsID = 44, list = {28609, 28610, 28611}}, --好感度1
			[2] = {before = 28599, dwTipsID = 45, list = {28600, 28601, 28602}}, --好感度2
			[3] = {before = 28603, dwTipsID = 46, list = {28612, 28613, 28614, 28616, 28617}}, --好感度3
			[4] = {before = 28618, dwTipsID = 47, list = {28619, }}, --好感度4
			[5] = {before = 28621, dwTipsID = 48, list = {28622, 28623,}}, --好感度5
			[6] = {before = 28624, dwTipsID = 49, list = {28625, 28626}}, --好感度6
		},
		------------------------------------------------------
		achi = {unLock = 12534, lv60 = 12535, lv90 = 12536, fs1 = 12537, fs3 = nil, fs6 = 12538, star1 = 12540, star2 = nil, star3 = nil, star4 = 12541, perfect = 12542}, --{解锁，60级，90级，1心，6心，1重，4重，完美成就}}没有填nil
		bExtraCof = 1.5,
		nSpecialStage = {4, 0.1}, --特殊命座，4命，额外分数
		--------------------------------------------------------------------------------------------------
		nTravelLv = 4, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4
	},
	{id = 34,
		dwTemplateID = 136050,
		dwUse = 1, --枚举型，1dps2T3奶
		name = GetEditorString(32, 6184), --刀马
		unlockPoint = 9999,
		strengthItem = {nil},
		questList = {}, --前置任务始末
		achi = {unLock = nil, lv60 = nil, lv90 = nil, fs1 = nil, fs3 = nil, fs6 = nil, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil	
		nTravelLv = 3, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4	
	},
	{id = 35,
		dwTemplateID = 137253,
		dwUse = 3, --枚举型，1dps2T3奶
		name = GetEditorString(33, 530), --景天
		unlockPoint = 9999,
		strengthItem = {nil},
		questList = {}, --前置任务始末
		achi = {unLock = nil, lv60 = nil, lv90 = nil, fs1 = nil, fs3 = nil, fs6 = nil, star1 = nil, star2 = nil, star3 = nil, star4 = nil, perfect = nil}, --{解锁，60级，90级，1心，6心，1重，2重，3重，4重，完美成就}}没有填nil	
		bExtraCof = 1.4,
		nTravelLv = 3, --侠客出行能力档次管家1，名望2，绝版活动3，茶饼4	
	},
}

function Tool_GetAssistedScore(player, nHeroID) --取单个侠客的评分
	local nScore = 0
	local nStandardScore = 0

	if tHeroDataList[nHeroID] then

		--1、装备部分评分（已废弃，固定613分）--装备分=（0.5+0.5*精炼等级/8）*1.2^(装备评分/10+1）*82.5
		nStandardScore = 613

		--2、侠缘等级部分
		local tAssistedInfo = player.GetNpcAssistedInfo(nHeroID)
		local nLevel = tAssistedInfo.nLevel

		if tHeroDataList[nHeroID].unlockPoint ~= 9999 then --茶饼管家
			if tHeroDataList[nHeroID].dwUse == 1 then --枚举型，1dps2T3奶
				nStandardScore = nStandardScore * (1 + 1.25 / 100 * nLevel) * (1 + 0.5 / 100 * nLevel) ^ 0.3
			elseif tHeroDataList[nHeroID].dwUse == 2 then
				nStandardScore = nStandardScore * (1 + 1.25 / 100 * nLevel) * (1 + 0.5 / 100 * nLevel) ^ 0.3
			elseif tHeroDataList[nHeroID].dwUse == 3 then --茶饼侠客，治疗低于51级视为51级
				nStandardScore = nStandardScore * (1 + 1.25 / 100 * math.max(nLevel, 51)) * (1 + 0.5 / 100 * math.max(nLevel, 51)) ^ 0.3
			end
		else --非茶饼管家
			if tHeroDataList[nHeroID].dwUse == 1 then --枚举型，1dps2T3奶
				nStandardScore = nStandardScore * (1 + 0.9 / 100 * nLevel) * (1 + 0.5 / 100 * nLevel) ^ 0.3
			elseif tHeroDataList[nHeroID].dwUse == 2 then
				nStandardScore = nStandardScore * (1 + 0.9 / 100 * nLevel) * (1 + 0.5 / 100 * nLevel) ^ 0.3
			elseif tHeroDataList[nHeroID].dwUse == 3 then
				nStandardScore = nStandardScore * (1 + 0.5 / 100 * nLevel )* 1.39547
			end
		end

		--3、秘籍部分 秘籍分数=1+0.05*秘籍数
		local jj = player.GetNpcAssistedStagePoint(nHeroID)
		local nStage = jj / 5000
		nStandardScore = nStandardScore * (1 + 0.05 * nStage)

		--4、角色加成
		if tHeroDataList[nHeroID] and tHeroDataList[nHeroID].bExtraCof then
			nStandardScore = nStandardScore * tHeroDataList[nHeroID].bExtraCof
		end

		--5、特殊秘籍
		local nScoreSpecial = 800 --标准分数
		if tHeroDataList[nHeroID] then
			local tStage = tHeroDataList[nHeroID].nSpecialStage
			if tStage and nStage >= tStage[1] then --达到需求命座，加额外
				if tStage.bMultiply then
					nStandardScore = nStandardScore * tStage[2]
				else
					nStandardScore = nStandardScore + nScoreSpecial * tStage[2]
				end
			end
		end
	end
	if tHeroDataList[nHeroID] and tHeroDataList[nHeroID].bTry then
	else
		nStandardScore = nStandardScore * 1.15
	end
	--print(nHeroID, nStandardScore)
	return nStandardScore
end