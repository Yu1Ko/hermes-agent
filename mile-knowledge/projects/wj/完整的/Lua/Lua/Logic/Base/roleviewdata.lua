local aCameraTop =
{
	[1] = {32, 158, -150, -48, 187, 180,  0.185}, --rtStandardMale,     // 标准男
	[2] = { 27, 125, -147, -48, 187, 162,  0.185}, --rtStandardFemale,   // 标准女
	[5] = {2, 116, -148, -2, 80, 25579, 0.185},   --rtLittleBoy,        // 小男孩
	[6] = {2, 114, -142, -2, 80, 25579, 0.185},  --rtLittleGirl,       // 小孩女
}

local aDefault =
{
	[1] =  0, --rtStandardMale,     // 标准男
	[2] =  0, --rtStandardFemale,   // 标准女
	[5] =  0, --rtLittleBoy,        // 小男孩
	[6] =  0, --rtLittleGirl,       // 小孩女
}

local function createYawData(...)
	local aArg = {...}
	return
	{
		[1] = aArg[1] or 0, --rtStandardMale,     // 标准男
		[2] = aArg[2] or 0, --rtStandardFemale,   // 标准女
		[5] = aArg[3] or 0, --rtLittleBoy,        // 小男孩
		[6] = aArg[4] or 0, --rtLittleGirl,       // 小孩女
	}
end

g_tRoleView =
{
	tCamera=
	{
		Face   = aCameraTop,
		Hair   = {
			[1] = {142, 145, -125, -3.5, 173, 2, 0.240}, --rtStandardMale,     // 标准男
			[2] = {106, 156, -128, -7.4, 154, -4.3, 0.280}, --rtStandardFemale,   // 标准女
			[5] = {-160, 99, -91, 2.5, 116, -4, 0.240},--rtLittleBoy,        // 小男孩
			[6] = {-112, 130, -124, 2.1, 114, 2.3, 0.260},  --rtLittleGirl,       // 小孩女
		},
		Bang   = aCameraTop,
		Plait  = {
			[1] = {13, 149, -174, -412, 936, 5830, 0.185}, --rtStandardMale,     // 标准男
			[2] = {29, 128, -155, -48, 191, 156, 0.185}, --rtStandardFemale,   // 标准女
			[5] = {-162.36, 97.17, -5.57, 2.806, 114, -4.4, 0.185},--rtLittleBoy,        // 小男孩
			[6] = {2, 114, -142, -2, 80, 25579, 0.185},  --rtLittleGirl,       // 小孩女
		},
		Dress   = {
			[1] = {-42, 131, -605, 14, 87, 170, 0.185}, --rtStandardMale,     // 标准男
			[2] = {96, 222, -354, -48, 57, 134, 0.185}, --rtStandardFemale,   // 标准女
			[5] = {2, 64, -297, -2, 75, 25579, 0.185}, --rtLittleBoy,        // 小男孩
			[6] = {2, 74, -297, -2, 75, 25579, 0.185}  --rtLittleGirl,       // 小孩女
		},
		Bangle = {
			[1] = {70, 173, -133, -16, 13, 154, 0.185}, --rtStandardMale,     // 标准男
			[2] = {106, 163, -196, -38, 73, 120, 0.185}, --rtStandardFemale,   // 标准女
			[5] = {10, 64, -205, -2, 70, 25579, 0.185}, --rtLittleBoy,        // 小男孩
			[6] = {10, 73, -205, -2, 70, 25579, 0.185} --rtLittleGirl,       // 小孩女
		},
		Waist = {
			[1] = {-34, 163, -219, -18, 136, -116, 0.185}, --rtStandardMale,     // 标准男
			[2] = {30, 109, -187, -40, 116, 140, 0.185}, --rtStandardFemale,   // 标准女
			[5] = {-3, 78, -170, -4, -2160, 25579, 0.185}, --rtLittleBoy,        // 小男孩
			[6] = {4, 89, -125, -4, -2160, 25579, 0.185}  --rtLittleGirl,       // 小孩女
		},
		Boots  = {
			[1] = {43, 37, -301, -8, 16, 66, 0.185}, --rtStandardMale,     // 标准男
			[2] = {56, 28, -271, -28, 18, 160, 0.185}, --rtStandardFemale,   // 标准女
			[5] = {2, 15, -235, -2, 70, 25579, 0.185}, --rtLittleBoy,        // 小男孩
			[6] = {2, 15, -187, -2, 70, 25579, 0.185}  --rtLittleGirl,       // 小孩女
		},
	};

	tYaw =
	{
		Face   = aDefault,
		Hair   = createYawData(-3.14 / 2 , -3.14 / 2),
		Bang   = aDefault,
		Plait  = createYawData(-3.14 / 2 , -3.14 / 2),
		Dress  = createYawData(-3.14 / 8 , -3.14 / 8),
		Boots  = createYawData(0, 0, 0, 3.14 / 8),
		Bangle = createYawData(-3.14 / 8 , -3.14 / 8, nil, 3.14 / 4),
		Waist  = createYawData(-3.14 / 8 , -3.14 / 6),
	};

	 aRadius =
	 {
		[1] = {nMin=200, nMax=550}, --rtStandardMale,     // 标准男
		[2] = {nMin=175, nMax=550}, --rtStandardFemale,   // 标准女
		[5] = {nMin=240, nMax=550}, --rtLittleBoy,        // 小男孩
		[6] = {nMin=175, nMax=550},  --rtLittleGirl,       // 小孩女
	},
};

local tCameraPosDefault=
{
		[1] = {133097, 4250, 35623, 0.6, 80}, --rtStandardMale,     // 标准男
		[2] = {133086, 4250, 35593, 0.7, 80}, --rtStandardFemale,   // 标准女
		[5] = {133003, 4200, 35609, 0.9, 80}, --rtLittleBoy,   		// 小男孩
		[6] = {133013, 4200, 35630, 1.0, 80},  --rtLittleGirl,       // 小孩女
 }

g_tCameraPos =
{
	cy  = tCameraPosDefault,
    wh  = tCameraPosDefault,
    tm  = tCameraPosDefault,
    wd  = tCameraPosDefault,
    tc  = tCameraPosDefault,
    cj  = tCameraPosDefault,
    gb  = tCameraPosDefault,
    qx  = tCameraPosDefault,
    mj  = tCameraPosDefault,
    sl  = tCameraPosDefault,
    cangyun = tCameraPosDefault,
    changge = tCameraPosDefault,
	badao = tCameraPosDefault,
	penglai = tCameraPosDefault,
	lxg = tCameraPosDefault,
	ytz = tCameraPosDefault,
	btyz = tCameraPosDefault,
	dz = tCameraPosDefault,
	wl = tCameraPosDefault,

	init = {133092, 4260, 35627}, --选门派ca_pos
	camera_param =
	{
		fovy    = 3.141593 * 55/ 180.0,
		pos_x  = 133071,
		pos_y  = 4293,
		pos_z  = 35404, --选门派3:ca_pos

		MIN_RADIUS = 150,
		MAX_RADIUS = 500,
		min_ver_angle = -0.2,
		max_ver_angle = 0.1,
	};
};

g_tRolePos =
{	-- x, y, z 		 未选中站着的位置
	-- s_x, s_y, s_z 选中后演示的位置
	[1] = {x=133398.0,y=4127.0,z=36197.4, yaw=0.6, s_x=133335.0, s_y=4127.0, s_z=35921.0, s_yaw=0.6, height=180, in_time=0,   out_time=0}, --rtStandardMale,     // 标准男
	[2] = {x=133483.0,y=4127.0,z=36164.8, yaw=0.6, s_x=133335.0, s_y=4127.0, s_z=35921.0, s_yaw=0.6, height=175, in_time=200, out_time=0}, --rtStandardFemale,   // 标准女
	[5] = {x=133650.1,y=4167.0,z=36026.1, yaw=0.9, s_x=133335.0, s_y=4127.0, s_z=35921.0, s_yaw=0.9, height=130, in_time=800, out_time=520},--rtLittleBoy,        // 小男孩
	[6] = {x=133528.4,y=4127.0,z=36056.1, yaw=0.8, s_x=133335.0, s_y=4127.0, s_z=35921.0, s_yaw=0.8,  height=130, in_time=150, out_time=200},  --rtLittleGirl,       // 小孩女
};

g_tListenerPos =
{
	x=25649, y=604, z=25447, yaw=3.14, s_x=25574, s_y=599, s_z=25762, s_yaw=3.14,
};


local m_SFXDefPos =
{
	[1] = {x=0, y=180, z=0}, --rtStandardMale,     // 标准男
	[2] = {x=0, y=175, z=0}, --rtStandardFemale,   // 标准女
    [5] = {x=0, y=130, z=0}, --rtLittleBoy,   		// 小男孩
	[6] = {x=0, y=130, z=0},  --rtLittleGirl,       // 小孩女
};

g_tSFXPos =
{
	cy  = m_SFXDefPos,
	{
		[1] = {x=0, y=180, z=0}, --rtStandardMale,     // 标准男
		[2] = {x=0, y=175, z=0}, --rtStandardFemale,   // 标准女
	    [5] = {x=0, y=130, z=0}, --rtLittleBoy,   		// 小男孩
		[6] = {x=0, y=130, z=0},  --rtLittleGirl,       // 小孩女
    },
    wh  = m_SFXDefPos,
    tm  = m_SFXDefPos,
    wd  =
    {
		[1] = {x=0, y=185, z=0}, --rtStandardMale,     // 标准男
		[2] = {x=0, y=175, z=0}, --rtStandardFemale,   // 标准女
	    [5] = {x=0, y=130, z=0}, --rtLittleBoy,   		// 小男孩
		[6] = {x=0, y=130, z=0},  --rtLittleGirl,       // 小孩女
    },

    tc  = m_SFXDefPos,
    cj  = m_SFXDefPos,
    gb  =
    {
		[1] = {x=5, y=180, z=0}, --rtStandardMale,     // 标准男
		[2] = {x=-18, y=175, z=0}, --rtStandardFemale,   // 标准女
	    [5] = {x=0, y=130, z=0}, --rtLittleBoy,   		// 小男孩
		[6] = {x=0, y=130, z=0},  --rtLittleGirl,       // 小孩女
    },
    qx  = m_SFXDefPos,
    mj  =
    {
		[1] = {x=4, y=180, z=0}, --rtStandardMale,     // 标准男
		[2] = {x=5, y=175, z=0}, --rtStandardFemale,   // 标准女
	    [5] = m_SFXDefPos[5], --rtLittleBoy,   		// 小男孩
		[6] = m_SFXDefPos[6],  --rtLittleGirl,       // 小孩女
    },
    sl  = m_SFXDefPos,

    cangyun = m_SFXDefPos,
    changge = m_SFXDefPos,
	badao = m_SFXDefPos,
	penglai = m_SFXDefPos,
	lxg = m_SFXDefPos,
	ytz = m_SFXDefPos,
	btyz = m_SFXDefPos,
	dz = m_SFXDefPos,
	wl = m_SFXDefPos,
};

--[[
 	RL_WEAPON_NONE,
    RL_WEAPON_WAND,
    RL_WEAPON_SPEAR,
    RL_WEAPON_SWORD,
    RL_WEAPON_FIST,
    RL_WEAPON_DOUBLE_WEAPON,
    RL_WEAPON_PEN,
    RL_WEAPON_DART,
    RL_WEAPON_HEAVY_SWORD,
    RL_WEAPON_FLUTE,
    RL_WEAPON_BOW,
    RL_WEAPON_KNIFE,
    RL_WEAPON_STICK,
	RL_WEAPON_BLADE_SHIELD,
	RL_WEAPON_HEPTA_CHORD,
	RL_WEAPON_UMBRELLA

	索引是表现的武器类型
]]

--StandardNew 是商城，Standard是外观预览能其他miniscene
g_tRoleAnimations =
{
	[13] = { Idle = 18006 , Standard = 18006, StandardNew = 18006},  -- RL_WEAPON_BLADE_SHIELD  cangyun
	[14] = { Idle = 4207 , Standard = 4207, StandardNew = 4207},  -- RL_WEAPON_HEPTA_CHORD  changge
	[15] = { Idle = 69995 , Standard = 69995, StandardNew = 69995},  -- RL_WEAPON_BROAD_SWORD  badao
	[16] = { Idle = 85011 , Standard = 85011, StandardNew = 7519},  -- RL_WEAPON_UMBRELLA  penglai
	[19] = { Idle = 100 , Standard = 100, StandardNew = 7785},  -- RL_WEAPON_MEDKIT  beitianyaozong
	[20] = { Idle = 7788 , Standard = 7788, StandardNew = 7788},  -- RL_WEAPON_MASTER_BLADE  daozong
	[21] = { Idle = 396, Standard = 396, StandardNew = 396}, -- RL_WEAPON_LongBow  wanling
	[22] = { Idle = 1591, Standard = 1591, StandardNew = 1591}, -- RL_WEAPON_Fan  duanshi
	[23] = { Idle = 2388, Standard = 2388, StandardNew = 2388}, -- RL_WEAPON_PUPPET  wuxiang

	[12]  = { Idle = 100 , Standard = 2201, StandardNew = 7373}, -- RL_WEAPON_STICK  gb
	-- [11]  = { Idle = 1457 , Standard = 1457}, -- RL_WEAPON_KNIFE  mj
	-- [10]  = { Idle = 1141 , Standard = 1141}, -- RL_WEAPON_BOW  tm
	[9]  = { Idle = 100 , Standard = 845, StandardNew = 65018},   -- RL_WEAPON_FLUTE  wd
	-- [8]  = { Idle = 34 , Standard = 34},    -- RL_WEAPON_HEAVY_SWORD  cj
	-- [3]  = { Idle = 33 , Standard = 33},    -- RL_WEAPON_SWORD cy
	-- [5]  = { Idle = 38 , Standard = 38},    -- RL_WEAPON_DOUBLE_WEAPON  qx
	-- [1]  = { Idle = 31 , Standard = 31},    -- RL_WEAPON_WAND  sl
	-- [2]  = { Idle = 32 , Standard = 32},    -- RL_WEAPON_SPEAR  tc
	-- [6] = { Idle = 39, Standard = 39}, -- RL_WEAPON_PEN  wh

	-- [17] = { Idle = 91013, Standard = 91013}, -- RL_WEAPON_CHAIN_BLADE  lx
	-- [18] = { Idle = 74012, Standard = 74012}, -- RL_WEAPON_SOUL_LAMP yt

};

g_tRoleListPos =
{
	x = 0,
	y = 0,
	z = 0,
	yaw = 0,
	tRoleYaw =
	{
		[1] = 0,	--标男
		[2] = -0.16,--标女
		[3] = 0,
		[4] = 0,
		[5] = 0,	--小男孩
		[6] = -0.08	--小女孩
	}
};

g_tRoleListCamera =
{
	szType = "ChoiceRole",
	tbIDs = {
		[ROLE_TYPE.STANDARD_MALE]   = 1, --rtStandardMale,     // 标准男
		[ROLE_TYPE.STANDARD_FEMALE] = 2, --rtStandardFemale,   //标准女
		[ROLE_TYPE.LITTLE_BOY]      = 3, --rtLittleBoy,        //  小男孩
		[ROLE_TYPE.LITTLE_GIRL]     = 4  --rtLittleGirl,       // 小孩女
	},
	fRoleYaw = -0.13,
	tbOffset = {0, 0, 0},
	nDefaultZoomIndex = 1,
	nDefaultZoomValue = 0,
};

g_tBuildFaceCameraStep1 =
{
	szType = "LoginNew",
	tbIDs = {
		[ROLE_TYPE.STANDARD_MALE]   = 1, --rtStandardMale,     // 标准男
		[ROLE_TYPE.STANDARD_FEMALE] = 2, --rtStandardFemale,   //标准女
		[ROLE_TYPE.LITTLE_BOY]      = 3, --rtLittleBoy,        //  小男孩
		[ROLE_TYPE.LITTLE_GIRL]     = 4  --rtLittleGirl,       // 小孩女
	},
	fRoleYaw = 0,
	tbOffset = {0, 0, 0},
	nDefaultZoomIndex = 1,
	nDefaultZoomValue = 0,
};

g_tBuildFaceCameraStep2Face =
{
	szType = "BuildFaceOnlyFace",
	tbIDs = {
		[ROLE_TYPE.STANDARD_MALE]   = 1, --rtStandardMale,     // 标准男
		[ROLE_TYPE.STANDARD_FEMALE] = 2, --rtStandardFemale,   //标准女
		[ROLE_TYPE.LITTLE_BOY]      = 3, --rtLittleBoy,        //  小男孩
		[ROLE_TYPE.LITTLE_GIRL]     = 4  --rtLittleGirl,       // 小孩女
	},
	fRoleYaw = 0,
	tbOffset = {0, 0, 0},
	nDefaultZoomIndex = 1,
	nDefaultZoomValue = 0,
};

g_tBuildFaceCameraStep2Hair =
{
	szType = "LoginNew",
	tbIDs = {
		[ROLE_TYPE.STANDARD_MALE]   = 1, --rtStandardMale,     // 标准男
		[ROLE_TYPE.STANDARD_FEMALE] = 2, --rtStandardFemale,   //标准女
		[ROLE_TYPE.LITTLE_BOY]      = 3, --rtLittleBoy,        //  小男孩
		[ROLE_TYPE.LITTLE_GIRL]     = 4  --rtLittleGirl,       // 小孩女
	},
	fRoleYaw = 0,
	tbOffset = {-1.8, 0, 0},
	nDefaultZoomIndex = 1,
	nDefaultZoomValue = 10,
};

g_tBuildFaceCameraStep2Body =
{
	szType = "LoginBody",
	tbIDs = {
		[ROLE_TYPE.STANDARD_MALE]   = 1, --rtStandardMale,     // 标准男
		[ROLE_TYPE.STANDARD_FEMALE] = 2, --rtStandardFemale,   //标准女
		[ROLE_TYPE.LITTLE_BOY]      = 3, --rtLittleBoy,        //  小男孩
		[ROLE_TYPE.LITTLE_GIRL]     = 4  --rtLittleGirl,       // 小孩女
	},
	fRoleYaw = 0,
	tbOffset = {0, 0, 0},
	nDefaultZoomIndex = 1,
	nDefaultZoomValue = 100,
};

g_tBuildFaceCameraStepShare =
{
	szType = "CreatorModelShow",
	tbIDs = {
		[ROLE_TYPE.STANDARD_MALE]   = 1, --rtStandardMale,     // 标准男
		[ROLE_TYPE.STANDARD_FEMALE] = 2, --rtStandardFemale,   //标准女
		[ROLE_TYPE.LITTLE_BOY]      = 3, --rtLittleBoy,        //  小男孩
		[ROLE_TYPE.LITTLE_GIRL]     = 4  --rtLittleGirl,       // 小孩女
	},
	fRoleYaw = 0,
	tbOffset = {0, 0, 0},
	nDefaultZoomIndex = 1,
	nDefaultZoomValue = 0,
};

g_tBuildFaceCameraStepBuildAll =
{
	szType = "BuildFaceAll",
	tbIDs = {
		[ROLE_TYPE.STANDARD_MALE]   = 1, --rtStandardMale,     // 标准男
		[ROLE_TYPE.STANDARD_FEMALE] = 2, --rtStandardFemale,   //标准女
		[ROLE_TYPE.LITTLE_BOY]      = 3, --rtLittleBoy,        //  小男孩
		[ROLE_TYPE.LITTLE_GIRL]     = 4  --rtLittleGirl,       // 小孩女
	},
	fRoleYaw = 0,
	tbOffset = {0, 0, 0},
	nDefaultZoomIndex = 1,
	nDefaultZoomValue = 0,
};

g_tBuildFaceCameraStepInputName =
{
	szType = "CreateName",
	tbIDs = {
		[ROLE_TYPE.STANDARD_MALE]   = 1, --rtStandardMale,     // 标准男
		[ROLE_TYPE.STANDARD_FEMALE] = 2, --rtStandardFemale,   //标准女
		[ROLE_TYPE.LITTLE_BOY]      = 3, --rtLittleBoy,        //  小男孩
		[ROLE_TYPE.LITTLE_GIRL]     = 4  --rtLittleGirl,       // 小孩女
	},
	fRoleYaw = 0,
	tbOffset = {0, 0, 0},
	nDefaultZoomIndex = 1,
	nDefaultZoomValue = 0,
};

g_tRoleChooseShowCamera =
{
	szType = "RoleChooseShow",
	tbIDs = {
		[ROLE_TYPE.STANDARD_MALE]   = 1, --rtStandardMale,     // 标准男
		[ROLE_TYPE.STANDARD_FEMALE] = 2, --rtStandardFemale,   //标准女
		[ROLE_TYPE.LITTLE_BOY]      = 3, --rtLittleBoy,        //  小男孩
		[ROLE_TYPE.LITTLE_GIRL]     = 4  --rtLittleGirl,       // 小孩女
	},
	fRoleYaw = 0,
	tbOffset = {0, 0, 0},
	nDefaultZoomIndex = 1,
	nDefaultZoomValue = 0,
};

g_tSkillCameraPos =
{
	skill_cd = 2700,
	btyz  =
    {
		[1] =
		{
			{x = 25248, y = 753, z = 26256, frame_num = 10}, --skill 1
			{x = 25548, y = 1040, z = 26373, frame_num = 10}, --skill 2
			{x = 25785, y = 859, z = 26507, frame_num = 10}, --skill 3
			{x = 25909, y = 895, z = 26452, frame_num = 10},  --skill 4
		}, --rtStandardMale,     // 标准男

		[2] =
		{
			{x = 25170, y = 810, z = 26266, frame_num = 10}, --skill 1
			{x = 25271, y = 982, z = 26325, frame_num = 10}, --skill 2
			{x = 25563, y = 837, z = 26540, frame_num = 10}, --skill 3
			{x = 25909, y = 895, z = 26452, frame_num = 10},  --skill 4
		}, --rtStandardFemale,   // 标准女

		[5] =
		{
			{x = 25907, y = 748, z = 26276, frame_num = 10}, --skill 1
			{x = 25954, y = 856, z = 26193, frame_num = 10}, --skill 2
			{x = 26272, y = 902, z = 25468, frame_num = 10}, --skill 3
			{x = 26351, y = 838, z = 25780, frame_num = 10},  --skill 4
		}, --rtLittleBoy,   		// 小男孩

		[6] =
		{
			{x = 26008, y = 769, z = 26163, frame_num = 10}, --skill 1
			{x = 26134, y = 974, z = 26028, frame_num = 10}, --skill 2
			{x = 26323, y = 859, z = 25643, frame_num = 10}, --skill 3
			{x = 26292, y = 852, z = 25468, frame_num = 10},  --skill 4
		}, --rtLittleGirl,       // 小孩女
	},
	ytz  =
    {
		[1] =
		{
			{x = 25248, y = 753, z = 26256, frame_num = 10}, --skill 1
			{x = 25548, y = 1040, z = 26373, frame_num = 10}, --skill 2
			{x = 25785, y = 859, z = 26507, frame_num = 10}, --skill 3
			{x = 25909, y = 895, z = 26452, frame_num = 10},  --skill 4
		}, --rtStandardMale,     // 标准男

		[2] =
		{
			{x = 25170, y = 810, z = 26266, frame_num = 10}, --skill 1
			{x = 25271, y = 982, z = 26325, frame_num = 10}, --skill 2
			{x = 25563, y = 837, z = 26540, frame_num = 10}, --skill 3
			{x = 25909, y = 895, z = 26452, frame_num = 10},  --skill 4
		}, --rtStandardFemale,   // 标准女

		[5] =
		{
			{x = 25907, y = 748, z = 26276, frame_num = 10}, --skill 1
			{x = 25954, y = 856, z = 26193, frame_num = 10}, --skill 2
			{x = 26272, y = 902, z = 25468, frame_num = 10}, --skill 3
			{x = 26351, y = 838, z = 25780, frame_num = 10},  --skill 4
		}, --rtLittleBoy,   		// 小男孩

		[6] =
		{
			{x = 26008, y = 769, z = 26163, frame_num = 10}, --skill 1
			{x = 26134, y = 974, z = 26028, frame_num = 10}, --skill 2
			{x = 26323, y = 859, z = 25643, frame_num = 10}, --skill 3
			{x = 26292, y = 852, z = 25468, frame_num = 10},  --skill 4
		}, --rtLittleGirl,       // 小孩女
	},

	lxg  =
    {
		[1] =
		{
			{x = 25248, y = 753, z = 26256, frame_num = 10}, --skill 1
			{x = 25548, y = 1040, z = 26373, frame_num = 10}, --skill 2
			{x = 25785, y = 859, z = 26507, frame_num = 10}, --skill 3
			{x = 25909, y = 895, z = 26452, frame_num = 10},  --skill 4
		}, --rtStandardMale,     // 标准男

		[2] =
		{
			{x = 25170, y = 810, z = 26266, frame_num = 10}, --skill 1
			{x = 25271, y = 982, z = 26325, frame_num = 10}, --skill 2
			{x = 25563, y = 837, z = 26540, frame_num = 10}, --skill 3
			{x = 25909, y = 895, z = 26452, frame_num = 10},  --skill 4
		}, --rtStandardFemale,   // 标准女

		[5] =
		{
			{x = 25907, y = 748, z = 26276, frame_num = 10}, --skill 1
			{x = 25954, y = 856, z = 26193, frame_num = 10}, --skill 2
			{x = 26272, y = 902, z = 25468, frame_num = 10}, --skill 3
			{x = 26351, y = 838, z = 25780, frame_num = 10},  --skill 4
		}, --rtLittleBoy,   		// 小男孩

		[6] =
		{
			{x = 26008, y = 769, z = 26163, frame_num = 10}, --skill 1
			{x = 26134, y = 974, z = 26028, frame_num = 10}, --skill 2
			{x = 26323, y = 859, z = 25643, frame_num = 10}, --skill 3
			{x = 26292, y = 852, z = 25468, frame_num = 10},  --skill 4
		}, --rtLittleGirl,       // 小孩女
    },


	penglai  =
    {
		[1] =
		{
			{x = 25248, y = 753, z = 26256, frame_num = 10}, --skill 1
			{x = 25548, y = 1040, z = 26373, frame_num = 10}, --skill 2
			{x = 25785, y = 859, z = 26507, frame_num = 10}, --skill 3
			{x = 25909, y = 895, z = 26452, frame_num = 10},  --skill 4
		}, --rtStandardMale,     // 标准男

		[2] =
		{
			{x = 25170, y = 810, z = 26266, frame_num = 10}, --skill 1
			{x = 25271, y = 982, z = 26325, frame_num = 10}, --skill 2
			{x = 25563, y = 837, z = 26540, frame_num = 10}, --skill 3
			{x = 25909, y = 895, z = 26452, frame_num = 10},  --skill 4
		}, --rtStandardFemale,   // 标准女

		[5] =
		{
			{x = 25907, y = 748, z = 26276, frame_num = 10}, --skill 1
			{x = 25954, y = 856, z = 26193, frame_num = 10}, --skill 2
			{x = 26272, y = 902, z = 25468, frame_num = 10}, --skill 3
			{x = 26351, y = 838, z = 25780, frame_num = 10},  --skill 4
		}, --rtLittleBoy,   		// 小男孩

		[6] =
		{
			{x = 26008, y = 769, z = 26163, frame_num = 10}, --skill 1
			{x = 26134, y = 974, z = 26028, frame_num = 10}, --skill 2
			{x = 26323, y = 859, z = 25643, frame_num = 10}, --skill 3
			{x = 26292, y = 852, z = 25468, frame_num = 10},  --skill 4
		}, --rtLittleGirl,       // 小孩女
    },


	badao  =
    {
		[1] =
		{
			{x = 25248, y = 753, z = 26256, frame_num = 10}, --skill 1
			{x = 25548, y = 1040, z = 26373, frame_num = 10}, --skill 2
			{x = 25785, y = 859, z = 26507, frame_num = 10}, --skill 3
			{x = 25909, y = 895, z = 26452, frame_num = 10},  --skill 4
		}, --rtStandardMale,     // 标准男

		[2] =
		{
			{x = 25170, y = 810, z = 26266, frame_num = 10}, --skill 1
			{x = 25271, y = 982, z = 26325, frame_num = 10}, --skill 2
			{x = 25563, y = 837, z = 26540, frame_num = 10}, --skill 3
			{x = 25909, y = 895, z = 26452, frame_num = 10},  --skill 4
		}, --rtStandardFemale,   // 标准女

		[5] =
		{
			{x = 25907, y = 748, z = 26276, frame_num = 10}, --skill 1
			{x = 25954, y = 856, z = 26193, frame_num = 10}, --skill 2
			{x = 26272, y = 902, z = 25468, frame_num = 10}, --skill 3
			{x = 26351, y = 838, z = 25780, frame_num = 10},  --skill 4
		}, --rtLittleBoy,   		// 小男孩

		[6] =
		{
			{x = 26008, y = 769, z = 26163, frame_num = 10}, --skill 1
			{x = 26134, y = 974, z = 26028, frame_num = 10}, --skill 2
			{x = 26323, y = 859, z = 25643, frame_num = 10}, --skill 3
			{x = 26292, y = 852, z = 25468, frame_num = 10},  --skill 4
		}, --rtLittleGirl,       // 小孩女
    },

	 changge  =
    {
		[1] =
		{
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 1
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 2
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 3
			{x = 25114, y = 704, z = 26102, frame_num = 10},  --skill 4
		}, --rtStandardMale,     // 标准男

		[2] =
		{
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 1
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 2
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 3
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 4
		}, --rtStandardFemale,   // 标准女

		[5] =
		{
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 1
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 2
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 3
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 4
		}, --rtLittleBoy,   		// 小男孩

		[6] =
		{
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 1
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 2
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 3
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 4
		}, --rtLittleGirl,       // 小孩女
    },

    cangyun  =
    {
		[1] =
		{
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 1
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 2
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 3
			{x = 25114, y = 704, z = 26102, frame_num = 10},  --skill 4
		}, --rtStandardMale,     // 标准男

		[2] =
		{
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 1
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 2
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 3
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 4
		}, --rtStandardFemale,   // 标准女

		[5] =
		{
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 1
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 2
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 3
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 4
		}, --rtLittleBoy,   		// 小男孩

		[6] =
		{
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 1
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 2
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 3
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 4
		}, --rtLittleGirl,       // 小孩女
    },

        gb  =
    {
		[1] =
		{
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 1
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 2
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 3
			{x = 25114, y = 704, z = 26102, frame_num = 10},  --skill 4
		}, --rtStandardMale,     // 标准男

		[2] =
		{
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 1
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 2
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 3
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 4
		}, --rtStandardFemale,   // 标准女

		[5] =
		{
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 1
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 2
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 3
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 4
		}, --rtLittleBoy,   		// 小男孩

		[6] =
		{
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 1
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 2
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 3
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 4
		}, --rtLittleGirl,       // 小孩女
    },

            mj  =
    {
		[1] =
		{
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 1
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 2
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 3
			{x = 25114, y = 704, z = 26102, frame_num = 10},  --skill 4
		}, --rtStandardMale,     // 标准男

		[2] =
		{
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 1
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 2
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 3
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 4
		}, --rtStandardFemale,   // 标准女

		[5] =
		{
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 1
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 2
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 3
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 4
		}, --rtLittleBoy,   		// 小男孩

		[6] =
		{
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 1
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 2
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 3
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 4
		}, --rtLittleGirl,       // 小孩女
    },

            tm  =
    {
		[1] =
		{
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 1
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 2
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 3
			{x = 25114, y = 704, z = 26102, frame_num = 10},  --skill 4
		}, --rtStandardMale,     // 标准男

		[2] =
		{
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 1
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 2
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 3
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 4
		}, --rtStandardFemale,   // 标准女

		[5] =
		{
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 1
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 2
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 3
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 4
		}, --rtLittleBoy,   		// 小男孩

		[6] =
		{
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 1
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 2
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 3
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 4
		}, --rtLittleGirl,       // 小孩女
    },

            wd  =
    {
		[1] =
		{
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 1
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 2
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 3
			{x = 25114, y = 704, z = 26102, frame_num = 10},  --skill 4
		}, --rtStandardMale,     // 标准男

		[2] =
		{
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 1
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 2
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 3
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 4
		}, --rtStandardFemale,   // 标准女

		[5] =
		{
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 1
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 2
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 3
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 4
		}, --rtLittleBoy,   		// 小男孩

		[6] =
		{
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 1
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 2
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 3
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 4
		}, --rtLittleGirl,       // 小孩女
    },

            cj  =
    {
		[1] =
		{
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 1
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 2
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 3
			{x = 25114, y = 704, z = 26102, frame_num = 10},  --skill 4
		}, --rtStandardMale,     // 标准男

		[2] =
		{
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 1
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 2
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 3
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 4
		}, --rtStandardFemale,   // 标准女

		[5] =
		{
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 1
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 2
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 3
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 4
		}, --rtLittleBoy,   		// 小男孩

		[6] =
		{
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 1
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 2
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 3
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 4
		}, --rtLittleGirl,       // 小孩女
    },

            tc  =
    {
		[1] =
		{
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 1
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 2
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 3
			{x = 25114, y = 704, z = 26102, frame_num = 10},  --skill 4
		}, --rtStandardMale,     // 标准男

		[2] =
		{
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 1
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 2
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 3
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 4
		}, --rtStandardFemale,   // 标准女

		[5] =
		{
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 1
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 2
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 3
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 4
		}, --rtLittleBoy,   		// 小男孩

		[6] =
		{
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 1
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 2
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 3
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 4
		}, --rtLittleGirl,       // 小孩女
    },

            cy  =
    {
		[1] =
		{
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 1
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 2
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 3
			{x = 25114, y = 704, z = 26102, frame_num = 10},  --skill 4
		}, --rtStandardMale,     // 标准男

		[2] =
		{
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 1
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 2
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 3
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 4
		}, --rtStandardFemale,   // 标准女

		[5] =
		{
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 1
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 2
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 3
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 4
		}, --rtLittleBoy,   		// 小男孩

		[6] =
		{
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 1
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 2
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 3
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 4
		}, --rtLittleGirl,       // 小孩女
    },

            sl  =
    {
		[1] =
		{
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 1
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 2
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 3
			{x = 25114, y = 704, z = 26102, frame_num = 10},  --skill 4
		}, --rtStandardMale,     // 标准男

		[2] =
		{
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 1
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 2
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 3
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 4
		}, --rtStandardFemale,   // 标准女

		[5] =
		{
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 1
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 2
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 3
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 4
		}, --rtLittleBoy,   		// 小男孩

		[6] =
		{
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 1
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 2
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 3
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 4
		}, --rtLittleGirl,       // 小孩女
    },

            qx  =
    {
		[1] =
		{
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 1
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 2
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 3
			{x = 25114, y = 704, z = 26102, frame_num = 10},  --skill 4
		}, --rtStandardMale,     // 标准男

		[2] =
		{
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 1
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 2
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 3
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 4
		}, --rtStandardFemale,   // 标准女

		[5] =
		{
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 1
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 2
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 3
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 4
		}, --rtLittleBoy,   		// 小男孩

		[6] =
		{
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 1
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 2
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 3
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 4
		}, --rtLittleGirl,       // 小孩女
    },

            wh  =
    {
		[1] =
		{
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 1
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 2
			{x = 25114, y = 704, z = 26102, frame_num = 10}, --skill 3
			{x = 25114, y = 704, z = 26102, frame_num = 10},  --skill 4
		}, --rtStandardMale,     // 标准男

		[2] =
		{
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 1
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 2
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 3
			{x = 24988, y = 718, z = 25944, frame_num = 10}, --skill 4
		}, --rtStandardFemale,   // 标准女

		[5] =
		{
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 1
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 2
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 3
			{x = 26009, y = 705, z = 26029, frame_num = 10}, --skill 4
		}, --rtLittleBoy,   		// 小男孩

		[6] =
		{
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 1
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 2
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 3
			{x = 25988, y = 711, z = 26043, frame_num = 10}, --skill 4
		}, --rtLittleGirl,       // 小孩女
    },
};

--体型
g_tRoleBodyView =
{
	tCamera=
	{
		[1] = {0, 23, -1150, 0, 100, 0, 0.185}, --rtStandardMale,     // 标准男
		[2] = {0, 63, -1100, 0, 95, 0, 0.185}, --rtStandardFemale,   // 标准女
		[5] = {0, -21, -820, 0, 76, 0, 0.185},--rtLittleBoy,        // 小男孩
		[6] = {0, 50, -820, 2, 73, 0, 0.185},  --rtLittleGirl,       // 小孩女
	},

	tYaw =
	{
		createYawData(-3.14 / 2 , -3.14 / 2, -3.14 / 2, -3.14 / 2),
	},

	 aRadius =
	 {
		[1] = {nMin=200, nMax=550}, --rtStandardMale,     // 标准男
		[2] = {nMin=175, nMax=550}, --rtStandardFemale,   // 标准女
		[5] = {nMin=240, nMax=550}, --rtLittleBoy,        // 小男孩
		[6] = {nMin=175, nMax=550},  --rtLittleGirl,       // 小孩女
	},
};

g_tPuppet_info = {
    [1]  = {
        x = -70, y= 0, z = 0, scale = 0.8, ani = "data\\source\\item\\weapon\\puppet\\puppet_普通待机01.ani",
        path = {
           [1] = "data\\source\\item\\weapon\\Puppet\\Lh_puppet_001_HD.mdl",
           [2] = "data\\source\\item\\weapon\\Puppet\\Lh_puppet_002_HD.mdl",
           [3] = "data\\source\\item\\weapon\\Puppet\\Lh_puppet_003_HD.mdl",
		   [4] = "data\\source\\item\\weapon\\Puppet\\Lh_puppet_004_HD.mdl",
		   [5] = "data\\source\\item\\weapon\\Puppet\\Lh_puppet_005_HD.mdl",
		   [6] = "data\\source\\item\\weapon\\Puppet\\Lh_puppet_006_HD.mdl",
        },
    },
    [2]  = {
        x = -70, y = 0, z = 70, scale = 0.8, ani = "data\\source\\item\\weapon\\puppet\\puppet_普通待机01.ani",
        path = {
           [1] = "data\\source\\item\\weapon\\Puppet\\Lh_puppet_001_HD.mdl",
           [2] = "data\\source\\item\\weapon\\Puppet\\Lh_puppet_002_HD.mdl",
           [3] = "data\\source\\item\\weapon\\Puppet\\Lh_puppet_003_HD.mdl",
		   [4] = "data\\source\\item\\weapon\\Puppet\\Lh_puppet_004_HD.mdl",
		   [5] = "data\\source\\item\\weapon\\Puppet\\Lh_puppet_005_HD.mdl",
		   [6] = "data\\source\\item\\weapon\\Puppet\\Lh_puppet_006_HD.mdl",
        },
    },
    [5]  = {
        x = -70, y = 0, z = 70, scale = 0.8, ani = "data\\source\\item\\weapon\\puppet\\puppet_普通待机01.ani",
        path = {
           [1] = "data\\source\\item\\weapon\\Puppet\\Lh_puppet_001_HD.mdl",
           [2] = "data\\source\\item\\weapon\\Puppet\\Lh_puppet_002_HD.mdl",
           [3] = "data\\source\\item\\weapon\\Puppet\\Lh_puppet_003_HD.mdl",
		   [4] = "data\\source\\item\\weapon\\Puppet\\Lh_puppet_004_HD.mdl",
		   [5] = "data\\source\\item\\weapon\\Puppet\\Lh_puppet_005_HD.mdl",
		   [6] = "data\\source\\item\\weapon\\Puppet\\Lh_puppet_006_HD.mdl",
        },
    },
    [6]  = {
        x = -70, y = 0, z = 70, scale = 0.8, ani = "data\\source\\item\\weapon\\puppet\\puppet_普通待机01.ani",
        path = {
           [1] = "data\\source\\item\\weapon\\Puppet\\Lh_puppet_001_HD.mdl",
           [2] = "data\\source\\item\\weapon\\Puppet\\Lh_puppet_002_HD.mdl",
           [3] = "data\\source\\item\\weapon\\Puppet\\Lh_puppet_003_HD.mdl",
		   [4] = "data\\source\\item\\weapon\\Puppet\\Lh_puppet_004_HD.mdl",
		   [5] = "data\\source\\item\\weapon\\Puppet\\Lh_puppet_005_HD.mdl",
		   [6] = "data\\source\\item\\weapon\\Puppet\\Lh_puppet_006_HD.mdl",
        },
    },
};