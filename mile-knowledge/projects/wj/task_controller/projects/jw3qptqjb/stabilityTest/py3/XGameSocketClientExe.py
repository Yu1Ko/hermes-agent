# -*- coding: utf-8 -*-
import json
import time
import threading
import traceback

from ctypes import *
from enum import Enum
from BaseToolFunc import *


class C2SNetCmd(Enum):
    C2S_set_collect_enable = 8,
    C2S_set_buffer_size = 9,
    C2S_set_engine_option = 10,
    C2S_get_pid = 11,
    C2S_get_performance_data = 12,
    C2S_get_function_elapse_data = 13,
    C2S_get_function_name_data = 14,
    C2S_get_auto_test_msg_ret_code = 15,
    C2S_execute_auto_test_command = 16,
    C2S_protocol_total = 17,


class EngineOption(Enum):
    EO_unknow = 0,
    # Basic
    EO_basic_set_fps_limit_enable = 1,
    EO_basic_set_fog_enable = 2,
    EO_basic_set_debug_info_enable = 3,
    EO_basic_set_occlude_culling_enable = 4,
    EO_basic_set_descriptorset_A_B_enable = 5,  # 采用交换方式更新DescriptorSet
    EO_basic_set_only_bake_shadowmap_enable = 6,
    EO_basic_set_multi_thread_render_enable = 7,
    EO_basic_set_camera_farsee_float = 8,  # [20000.f, 200000.f](单位：厘米)
    EO_basic_set_scene_entity_load_radius_float = 9,  # [40000.f, 200000.f](单位：厘米)
    EO_basic_set_shadow_quality_int = 10,  # [0, 3] EX3DShadowMapLevel
    EO_basic_set_max_shadow_cascade_int = 11,  # [0, 3]
    EO_basic_set_view_probe_type_int = 12,  # [0, 3] EX3DViewProbeMask
    EO_basic_set_terrain_bake_level_int = 13,  # [0, 3] EX3DTerrainRuntimeBakeLevel
    EO_basic_set_terrain_bake_range_int = 14,  # [0, 1] EX3DTerrainRuntimeBakeRange
    EO_basic_set_angle_cull_float = 15,  # [0.0f, 0.1f]
    EO_basic_set_roughness_scale_float = 16,  # [0.0f, 1.0f]
    EO_basic_set_resolution_percent_scale_int = 17,  # 设置画面分辨率[10, 400]
    EO_basic_set_specific_resolution_percent_scale_int = 18,  # 设置特定的画面分辨率 "720p", "640p", "540p", "1vs1"
    EO_basic_set_AA_plan_int = 19,  # [0, 1] "FSR+TAA", "CAS+FXAA"
    EO_basic_set_main_camera_cascade_radius_int = 20,  # [0, 40000]
    # Debug
    EO_debug_set_terrain_enable = 21,
    EO_debug_set_not_rom_enbale = 22,
    EO_debug_set_framewire_enable = 23,
    EO_debug_set_debug_bake_terrain_enable = 24,
    EO_debug_set_foliage_enable = 25,
    EO_debug_set_stop_culling_enable = 26,
    EO_debug_set_water_enable = 27,
    EO_debug_set_point_light_enable = 28,
    EO_debug_set_scene_containerbox_enable = 29,
    EO_debug_set_render_decal_enable = 30,
    EO_debug_set_model_enable = 31,
    EO_debug_set_skin_model_enable = 32,
    EO_debug_set_scene_actor_model_enable = 33,
    EO_debug_set_gameplay_model_enable = 34,
    EO_debug_set_model_stbox_enable = 35,
    EO_debug_set_model_box_enable = 36,
    EO_debug_set_camera_light_enable = 37,
    EO_debug_set_occluded_box_enable = 38,
    EO_debug_set_cpu_profile_enable = 39,
    EO_debug_set_sss_enable = 40,
    EO_debug_set_sfx_enable = 41,
    EO_debug_set_oit_enable = 42,
    EO_debug_set_offlinegi_enable=43,
    EO_debug_set_render_all_paricle_enable = 44,
    EO_debug_set_gpu_time_stamp_enable = 45,
    EO_debug_set_save_scene_depth_to_file_enable = 46,
    EO_debug_set_spot_light_oit_shadow_enable = 47,
    EO_debug_set_spot_light_opaque_shadow_enable = 48,
    EO_debug_set_load_bake_mesh_enable = 49,
    EO_debug_set_spot_light_enable = 50,
    EO_debug_set_deferred_specular_enable = 51,
    EO_debug_set_soft_shadow_mask_enable = 52,
    EO_debug_set_shadow_cull_size_float = 53,  # [0.0f, 100000.0f]
    EO_debug_set_shadow_cull_angle_float = 54,  # [0.0f, 1.0f]
    EO_debug_set_point_cloud_quality_int = 55,  # [0, 2] "POINT_CLOUD_OFF", "POINT_CLOUD_LOW_VS_LEVEL", "POINT_CLOUD_HIGH_FS_LEVEL"
    EO_debug_set_output_resourepool_info_enable = 56,
    EO_debug_set_output_vma_info_enable = 57,
    # TexStream
    EO_texstream_set_texture_stream_enable = 58,
    EO_texstream_set_texture_mip_bias_int = 59,  # [0, 6]
    EO_texstream_set_min_game_model_texture_size_int = 60,  # [6, 10]
    EO_texstream_set_max_texture_resolution_int = 61,  # [0, 9]
    # Foliage
    EO_foliage_set_shadow_enable = 62,
    EO_foliage_set_render_tree_enable = 63,
    EO_foliage_set_render_grass_enable = 64,
    EO_foliage_set_tree_lod_bias_int = 65,  # [0, 2]
    EO_foliage_set_grass_lod_bias_int = 66,  # [0, 2]
    EO_foliage_set_brush_tree_load_radius_int = 67,  # [20000.f, 60000.f] 20000.0f 200米
    EO_foliage_set_brush_grass_load_radius_int = 68,  # [10000.0f, 20000.f]
    EO_foliage_set_angle_cull_grass_float = 69,  # [0.0f, 0.1f]
    EO_foliage_set_angle_cull_tree_float = 70,  # [0.0f, 0.5f]
    EO_foliage_set_protect_grass_density_int = 71,  # [0, 100]
    EO_foliage_set_grass_density_int = 72,  # [0, 100]
    EO_foliage_set_tree_density_int = 73,  # [0, 100]
    EO_foliage_set_important_size_in_radius_int = 74,  # [0, 10000]
    EO_foliage_set_protect_inner_radius_int = 75,  # [0, GetFoliageProtectOuterRadius]
    EO_foliage_set_protect_outer_radius_int = 76,  # [protect_inner_radius, 10000.f]
    EO_foliage_set_high_detail_lod_distance_int = 77,  # [1, low_detail - 1]
    EO_foliage_set_low_detail_lod_distance_int = 78,  # [low_detail, 50000]
    # LOD
    EO_lod_set_lod_switch_enable = 79,
    EO_lod_set_mesh_model_start_lod_bias_int = 80,  # [-3, 3] EX3DMeshLodLevel
    EO_lod_set_model_lod0_distance_int = 81,  # [1000, lod1]
    EO_lod_set_model_lod1_distance_int = 82,  # [lod0, 30000]
    EO_lod_set_model_lod2_distance_int = 83,  # [1000, 80000]
    # PostRender
        # Common
    EO_post_common_set_post_render_enable = 84,
    EO_post_common_set_post_render_dof_enable = 85,
    EO_post_common_set_post_render_bloom_enable = 86,
    EO_post_common_set_rc_post_render_bloom_enable = 87,
    EO_post_common_set_light_occlusion_enable = 88,
    EO_post_common_set_rc_light_occlusion_enable = 89,
    EO_post_common_set_light_shaft_bloom_enable = 90,
    EO_post_common_set_rc_light_shaft_bloom_enable = 91,
    EO_post_common_set_ao_enable = 92,
    EO_post_common_set_ssgi_enable = 93,
    EO_post_common_set_sspr_enable = 94,
    EO_post_common_set_render_shock_wave_enable = 95,
    EO_post_common_set_height_fog_enable = 96,
    EO_post_common_set_rc_height_fog_enable = 97,
    EO_post_common_set_taa_enable = 98,
    EO_post_common_set_fxaa_enable = 99,
    EO_post_common_set_cas_enable = 100,
    EO_post_common_set_rc_cas_enable = 101,
    EO_post_common_set_fsr_enable = 102,
    EO_post_common_set_shock_wave_enable = 103,
    EO_post_common_set_vignette_enable = 104,
    EO_post_common_set_dithering_enable = 105,
    EO_post_common_set_grain_enable = 106,
    EO_post_common_set_chromatic_aberration_enable = 107,
    EO_post_common_set_ray_march_fog_enable = 108,
    EO_post_common_set_rc_ray_march_fog_enable = 109,
        # Vignette
    EO_post_set_vignette_intensity_float = 110,  # [0.0f, 1.0f]
    EO_post_set_vignette_factor_float = 111,  # [0.0f, 1.0f]
        # Tonemapping
    EO_post_set_tonemapping_exposure_float = 112,  # [-2.0f, 2.0f]
    EO_post_set_grain_intensity_float = 113,  # [0.0f, 1.0f]
    EO_post_set_grain_scale_size_float = 114,  # [0.3f, 3.0f]
    EO_post_set_luminance_contribute_float = 115,  # [0.0f, 1.0f]
        # Dof
    EO_post_set_dof_front_near_float = 116,  # [0.0f, 1000.0f]
    EO_post_set_dof_front_far_float = 117,  # [front_near, 1000.0f]
    EO_post_set_dof_back_near_float = 118,  # [0.0f, 1000.0f]
    EO_post_set_dof_back_far_float = 119,  # [back_near, 1000.0f]
    EO_post_set_dof_blur_size_float = 120,  # [1.0f, 50.0f]
    EO_post_set_dof_intensity_float = 121,  # [0.1f, 10.0f]
        # Bloom
    EO_post_set_bloom_threshold_float = 122,  # [0.0f, 2.0f]
    EO_post_set_bloom_power_float = 123,  # [0.0f, 2.0f]
    EO_post_set_bloom_dirty_intensity_float = 124,  # [0.0f, 1.0f]
        # CAS
    EO_post_set_cas_sharpness_float = 125,  # [0.0f, 1.0f]
    EO_post_set_taa_sharp_enable = 126,
    EO_post_set_fsr_sharpness_float = 127,  # [0.0f, 1.0f]
        # HeightFog
    EO_post_set_heightfog_density_float = 128,  # [0.0f, 1.0f]
    EO_post_set_heightfog_height_falloff_float = 129,  # [0.0f, 1.0f]
    EO_post_set_heightfog_min_fog_opacity_float = 130,  # [0.0f, 1.0f]
    EO_post_set_heightfog_start_distance_float = 131,  # [0.0f, 40000.0f]
    EO_post_set_heightfog_cutoff_distance_float = 132,  # [0.0f, 200000.0f]
    EO_post_set_heightfog_height_float = 133,  # [0.0f, 40000.0f]
    EO_post_set_heightfog_diret_inscattering_exponent_float = 134,  # [0.0f, 50.0f]
    EO_post_set_heightfog_diret_inscattering_start_distance_float = 135,  # [0.0f, 40000.0f]
    EO_post_set_heightfog_scene_fade_enable = 136,
    EO_post_set_heightfog_scene_fade_start_float = 137,  # [0.0f, 200000.0f]
    EO_post_set_heightfog_scene_fade_end_float = 138,  # [0.0f, 200000.0f]
        # RayMarchFogtodo: 2024.1.15
        # HBAO
    EO_post_set_hbao_max_distance_float = 139,  # [10.0f, 400.0f]
    EO_post_set_hbao_distance_falloff_float = 140,  # [0.0f, max_distance]
    EO_post_set_hbao_radius_float = 141,  # [0.3f, 5.0f]
    EO_post_set_hbao_max_radius_pixels_int = 142,  # [16, 256]
    EO_post_set_hbao_angle_bias_float = 143,  # [0.0f, 0.5f]
    EO_post_set_hbao_blur_sharpness_float = 144,  # [0.0f, 16.0f]
    EO_post_set_hbao_only_ao_enable = 145,
    EO_post_set_hbao_enable = 146,
    EO_post_set_hbao_use_deinterleave_tex_enable = 147,
    EO_post_set_hbao_only_ssgi_enable = 148,
    EO_post_set_hbao_ssgi_enable = 149,
    EO_post_set_hbao_ssgi_max_distance_float = 150,  # [100.0f, 400.0f]
    EO_post_set_hbao_ssgi_intensity_float = 151,  # [1.0f, 10.0f]
        # Reflection
    EO_post_set_reflection_intensity_float = 152,  # [0.0f, 1.0f]
    EO_post_set_reflection_water_ibl_intensity_float = 153,  # [0.0f, 2.0f]
        # ColorGradetodo: 2024.1.15
    # Environment
        # SunLight
    EO_post_set_env_sunlight_heading_angle_float = 154,  # [-180.f, 180.f]
    EO_post_set_env_sunlight_altitude_angle_float = 155,  # [-90.f, 90.f]
    EO_post_set_env_sunlight_diffuse_color_float4 = 156,  # [0, 1]
    EO_post_set_env_sunlight_diffuse_intensity_float = 157,  # [0.f, 100.f]
    EO_post_set_env_sunlight_ambient_color_float4 = 158,  # [0, 1]
    EO_post_set_env_sunlight_sky_light_color_float4 = 159,  # [0, 1]
    EO_post_set_env_sunlight_sky_light_intensity_float = 160,  # [0.f, 100.f]
    EO_post_set_env_sunlight_common_light_color_float4 = 161,  # [0, 1]
    EO_post_set_env_sunlight_common_light_intensity_float = 162,  # [0.f, 100.f]
        # Env Map
    EO_post_set_env_map_intensity_float = 163,  # [0.f, 10.f]
    EO_post_set_env_map_saturation_float = 164,  # [0.f, 10.f]
        # Camera Light
    EO_post_set_env_camera_light_color_float4 = 165,  # [0, 1]
    EO_post_set_env_camera_light_intensity_float = 166,  # [0.0f, 10.0f]
    EO_post_set_env_camera_light_radius_float = 167,  # [0.0f, 1000.0f]
    EO_post_set_env_camera_light_length_float = 168,  # [0.0f, 1000.0f]
    EO_post_set_env_camera_light_radial_attenuation_start_float = 169,  # [0.0f, 1000.0f]
    EO_post_set_env_camera_light_axial_attenuation_start_float = 170,  # [0.0f, 1000.0f]
        # Character Light
    EO_post_set_env_character_light_diffuse_color_float4 = 171,  # [0, 1]
    EO_post_set_env_character_light_diffuse_intensity_float = 172,  # [0.f, 100.f]
    EO_post_set_env_character_light_sky_light_color_float4 = 173,  # [0, 1]
    EO_post_set_env_character_light_sky_light_intensity_float = 174,  # [0.f, 100.f]
    EO_post_set_env_character_light_common_light_color_float4 = 175,  # [0, 1]
    EO_post_set_env_character_light_common_light_intensity_float = 176,  # [0.f, 100.f]
    EO_post_set_env_character_light_ambient_color_float4 = 177,  # [0, 1]
        # Character Env Map
    EO_post_set_character_env_map_intensity_float = 178,  # [0.f, 10.f]
    EO_post_set_character_env_map_saturation_float = 179,  # [0.f, 10.f]
    EO_post_set_character_env_map_rotation_axis_y_float = 180,  # [0.f, 360.f]
        # Character Env Probe [info]
    # Performance
    EO_performance_set_simplify_user_shader_enable = 181,
    EO_performance_set_simplify_pbr_enable = 182,
    EO_performance_set_disable_alpha_test_enable = 183,
    EO_performance_set_disable_frag_shader_enable = 184,
    EO_performance_set_lod_display_enable = 185,
    EO_performance_set_pbr_channal_int = 186,  # [0, 12] DebugPBRMask
    # GPU Driven
    EO_gpu_driven_set_stop_cull_enable = 187,
    EO_gpu_driven_set_enable_hiz_oc_enable = 188,
    EO_gpu_driven_set_enable_cluster_oc_enable = 189,
    EO_gpu_driven_set_enable_shadow_enable = 190,
    EO_gpu_driven_set_tri_cluster_display_enable = 191,
    EO_gpu_driven_set_draw_cluster_box_enable = 192,
    EO_gpu_driven_set_enable_skip_compute_enable = 193,
    # Animation
    EO_animation_set_second_order_smooth_enable = 194,
    EO_animation_set_position_smooth_enable = 195,
    EO_animation_set_rotation_smooth_enable = 196,
    EO_animation_set_frequency_float = 197,  # [0.0f, 10.0f]
    EO_animation_set_damping_float = 198,  # [0.0f, 5.0f]
    EO_animation_set_initial_response_float = 199,  # [-5.0f, 5.0f]
    EO_animation_set_animation_update_callback_enable = 200,
    EO_animation_set_animation_fusion_enable = 201,
    # CharacterFollowLight todo: 2024.1.15
    EO_count = 202


class PROTOCOL_HEADER(Structure):
    _fields_ = [
        ("byProtocolID", c_uint)
    ]


class C2S_SET_COLLECT_ENABLE(PROTOCOL_HEADER):
    _fields_ = [
        ("bEnable", c_bool)
    ]


class C2S_SET_BUFFER_SIZE(PROTOCOL_HEADER):
    _fields_ = [
        ("nBufferSize", c_uint)
    ]


class MyUnion(Union):
    _fields_ = [
        ("bEnable", c_bool),
        ("fValue", c_float * 4)
    ]


class C2S_SET_ENGINE_OPTION(PROTOCOL_HEADER):
    _fields_ = [
        ("nEngineOption", c_uint),
        ("nCount", c_int),
        ("uionData", MyUnion)
    ]


# 接受数据格式
class KEnginePerformance(Structure):
    _fields_ = [
        ("uiFrameID", c_uint),
        ("uiDrawCallCnt", c_uint),
        ("uiFaceCnt", c_uint),
        ("nFPS", c_int),
        ("nLogicFPS", c_int),
        ("nResTask", c_int),
        ("nMatTask", c_int),
        ("nMainTask", c_int),
        ("nStreamTask", c_int),
        ("uiUIDrawCall", c_uint),
        ("uiUIFaceCnt", c_uint),
        ("uiUIbk", c_uint),
        ("uiUIubk", c_uint),
        ("nSetPass", c_int),
        ("uiTextureCnt", c_uint),
        ("uiMeshCnt", c_uint),
        ("fVulkanMemory", c_float),
        ("fRenderTargetSize", c_float),
        ("uiRenderTargetCount", c_uint),
        ("uiErrorShaderCnt", c_uint),
        ("uiAllErrorShaderCnt", c_uint),
        ("uiMissingMaterialDefCount", c_uint),
        ("uiAllMissingMaterialDefCount", c_uint),
        ("fGpuUsage", c_float),
        ("bSupportGpuUsage", c_bool)
    ]


class PerData_Header(Structure):
    _fields_ = [
        ("byProtocolID", c_uint),
        ("nCount", c_int)
    ]


# 进程ID
class KGetPidData(Structure):
    _fields_ = [
        ("byProtocolID", c_uint),
        ("uiPid", c_uint)
    ]


KPERFSERVER_MAX_FUNCTION_NAME_LEN = 128


class FunctionName(Structure):
    _fields_ = [
        ("szFuncName", c_char * KPERFSERVER_MAX_FUNCTION_NAME_LEN)
    ]


class FunctionCostData(Structure):
    _fields_ = [
        ("uiFrameID", c_uint),
        ("uiNameID", c_uint),
        ("fDuration", c_double)
    ]


class KAutoTestRetCode(PROTOCOL_HEADER):
    _fields_ = [
        ("uiStrLen", c_uint),
        ("pszMsg", c_char_p)
    ]


class XGameSocketClient(object):
    def __init__(self, strDllPath, strIP, nPort,strDataPath,strMachineTag='Android'):
        self.initLogger()
        self.conn = None
        self.strIP = strIP
        self.nPort = nPort
        self.strDllPath = strDllPath
        self.list_SocketClients = []
        self.dll = CDLL(self.strDllPath)
        self.dic_dataList = {"datalist": []}
        self.bFirstGetData = True
        self.nFirstGetTime = 0
        self.bCollectionFlag = False
        self.t_Perf = None
        self.list_CommandRetCode = []
        self.t_CmdAndMsgRetCode = None
        self.dic_MessageRetCode = {}
        self.nErrorDataCnt = None
        self.strDataPath=strDataPath
        self.bExitSwitch=False

        # PC端需要使用SDK采集FPS
        # Ios Android PC
        self.strMachineTag = strMachineTag
        # print("dll:", self.dll)
        self.dll.InitSocketClientFactory.restype = c_bool
        self.m_fnInitSocketClientFactory = self.dll.InitSocketClientFactory

        self.dll.CreateSocketClient.argtypes = [c_char_p, c_int]
        self.dll.CreateSocketClient.restype = c_int
        self.m_fnCreateSocketClient = self.dll.CreateSocketClient

        self.dll.DestorySocketClient.argtype = c_int
        self.dll.DestorySocketClient.restype = c_bool
        self.m_fnDestorySocketClient = self.dll.DestorySocketClient

        self.dll.SocketClientSend.argtypes = [c_int, c_void_p, c_size_t]
        self.dll.SocketClientSend.restype = c_bool
        self.m_fnSocketClientSend = self.dll.SocketClientSend

        self.dll.SocketClientSendString.argtypes = [c_int, c_int, c_void_p, c_size_t]
        self.dll.SocketClientSendString.restype = c_bool
        self.m_fnSocketClientSendString = self.dll.SocketClientSendString

        self.dll.SocketFactorySendToAll.argtypes = [c_void_p, c_size_t]
        self.dll.SocketFactorySendToAll.restype = c_bool
        self.m_fnSocketFactorySendToAll = self.dll.SocketFactorySendToAll

        self.dll.SocketClientSend_GetAllPerfData_Request.argtype = c_int
        self.dll.SocketClientSend_GetAllPerfData_Request.restype = c_bool
        self.m_fnSocketClientSend_GetAllPerfData_Request = self.dll.SocketClientSend_GetAllPerfData_Request

        self.dll.SocketClientSetCollectState.argtypes = [c_int, c_bool]
        self.dll.SocketClientSetCollectState.restype = c_bool
        self.m_fnSocketClientSetCollectState = self.dll.SocketClientSetCollectState

        self.dll.SocketClientGetRecvData.argtypes = [c_int, POINTER(c_int), POINTER(c_int), POINTER(c_int)]
        self.dll.SocketClientGetRecvData.restype = POINTER(c_char)  # 不用c_char_p 原因：会造成访问数据混乱
        self.m_fnSocketClientGetRecvData = self.dll.SocketClientGetRecvData

        self.dll.SocketClientGetRevcCommandRetCode.argtypes = [c_int, POINTER(c_int), POINTER(c_int), POINTER(c_int)]
        self.dll.SocketClientGetRevcCommandRetCode.restype = POINTER(c_char)  # 不用c_char_p 原因：会造成访问数据混乱
        self.m_fnSocketClientGetRevcCommandRetCode = self.dll.SocketClientGetRevcCommandRetCode

        self.dll.SocketClientGetRevcMessageRetCode.argtypes = [c_int, POINTER(c_int), POINTER(c_int), POINTER(c_int)]
        self.dll.SocketClientGetRevcMessageRetCode.restype = POINTER(c_char)  # 不用c_char_p 原因：会造成访问数据混乱
        self.m_fnSocketClientGetRevcMessageRetCode = self.dll.SocketClientGetRevcMessageRetCode

        self.dll.UnInitSocketClientFactory.restype = c_bool
        self.m_fnUnInitSocketClientFactory = self.dll.UnInitSocketClientFactory

        self.SDK_Start()

    def __Init(self):

        if self.m_fnInitSocketClientFactory():
            self.log.info('InitSocketClientFactory success')
        else:
            self.log.info('InitSocketClientFactory fail')
            raise Exception("InitSocketClientFactory fail")

        self.list_functionName = []

    # bRet=self.dll.m_fnInitSocketClientFactory()

    def GetState(self):
        bFlag = False
        while not bFlag:
            # print(f"start {time.time()}")
            bFlag = self.CreateSocketClient(self.strIP, self.nPort)
            # print(bFlag)
        # print(f"end {time.time()}")

    def SDK_Start(self):
        self.__Init()
        self.bConnectState = False
        # mobile_start_app('com.seasun.jx3','730d71fc')
        bFlag = False
        # 等待连接服务器 10秒钟还未连上 代表网段不通畅
        nTimeOut=10
        nCounter=1
        while not bFlag:
            bFlag = self.CreateSocketClient(self.strIP, self.nPort)
            if nCounter==nTimeOut:
                #超时
                with open(os.path.join(self.strDataPath, "ConnectError"), 'w') as f:
                    pass
                raise Exception("Connenct Error")
            nCounter+=1
            time.sleep(1)
        self.bConnectState = True
        time.sleep(1)

    def SDK_Stop(self):
        self.__UnInit()
        time.sleep(1)

    def PerfDataCreate(self):
        # 连接服务器成功后 就可以向服务端发送
        self.SocketClientSetCollectState(self.list_SocketClients[0], True)
        time.sleep(1)
        # 发送请求后需要等待一段时间才能得到响应
        # 确保第一次获取数据成功
        ''''''
        dic_data = {}
        bFlag = False
        # IOS端现在可以采集函数耗时
        ''''''
        nTimeOut = 10
        nCounter = 1
        if self.strMachineTag=="Test":
            while not bFlag:
                self.SocketClientSend_GetAllPerfData_Request(self.list_SocketClients[0])
                # 取深度性能数据
                bFlag = self.ProcessPerfData(self.list_SocketClients[0], dic_data)
                # 取函数耗时 ios端取不到还是要消耗对队列中的请求
                bFlag = self.ProcessPerfData(self.list_SocketClients[0], dic_data)
                print('test')
                time.sleep(1)
                if nCounter == nTimeOut:
                    # 超时
                    with open(os.path.join(self.strDataPath, "DataError"), 'w') as f:
                        pass
                nCounter+=1
                # bFlag = self.ProcessPerfData(self.list_SocketClients[0], dic_data)
        else:
            getRequest = PROTOCOL_HEADER()
            getRequest.byProtocolID = C2SNetCmd.C2S_get_function_name_data.value[0]
            # print('getRequest.byProtocolID:', getRequest.byProtocolID)
            while not bFlag:
                self.SocketClientSend(self.list_SocketClients[0], byref(getRequest), sizeof(getRequest))
                time.sleep(1)
                bFlag = self.ProcessPerfData(self.list_SocketClients[0], dic_data)
                if nCounter == nTimeOut:
                    # 超时
                    with open(os.path.join(self.strDataPath, "DataError"), 'w') as f:
                        pass
                nCounter += 1

        bFlag = False
        # 确保能够取到数据将请求数据清空
        nCounter = 1
        while not bFlag:
            self.SocketClientSend_GetAllPerfData_Request(self.list_SocketClients[0])
            time.sleep(1)
            bFlag = self.ProcessPerfData(self.list_SocketClients[0], dic_data)
            bFlag = self.ProcessPerfData(self.list_SocketClients[0], dic_data)
            if nCounter == nTimeOut:
                # 超时
                with open(os.path.join(self.strDataPath, "DataError"), 'w') as f:
                    pass
            nCounter += 1
        self.log.info("PerfDataCreate success")
        # print('GetPerfDataCreate success')


    def __PerfDataStart(self, t_parent):
        self.bCollectionFlag = True
        #记录上次的有效数据
        dic_lastData={}
        strErrorInfo='data get start Error'
        nDataSaveCount=0
        while t_parent.is_alive():
            # 服务端存放数据buffer的大小为300 以队列形式存在 因此第一次获取到的数据为300个需要舍弃 第二次获取到的数据为准确的数据
            if self.bCollectionFlag:
                self.SocketClientSend_GetAllPerfData_Request(self.list_SocketClients[0])
                fTime = time.time()
                # time.sleep(fTime)
                dic_data = {}
                # fTime = time.time()
                # 取深度性能数据
                bResult = self.ProcessPerfData(self.list_SocketClients[0], dic_data)
                # 取函数耗时
                bResult = self.ProcessPerfData(self.list_SocketClients[0], dic_data)
                if bResult:
                    '''
                    nDataSaveCount += 1
                    if nDataSaveCount>=5:
                        self.SaveDataToFile()
                        nDataSaveCount=0'''
                    dic_lastData=dic_data
                    self.dic_dataList['datalist'].append(dic_data)
                    if self.nErrorDataCnt != None:
                        self.nErrorDataCnt=0
                else:
                    self.dic_dataList['datalist'].append(dic_lastData)
                    if self.nErrorDataCnt!=None:
                        strErrorInfo = 'data get SetTimeNode Error'
                        self.nErrorDataCnt+=1
                        if self.nErrorDataCnt>=10:
                            strMsg = 'SDK打点后,连续获取10次数据失败'
                            raise Exception(strMsg)
                    self.log.info(strErrorInfo)
                # print('-------------------------------------------')
            else:
                # 关闭采集后 需要取出最后一次采集的数据
                self.nFirstGetTime += 1
                time.sleep(1)
                bResult = self.ProcessPerfData(self.list_SocketClients[0], dic_data)
                bResult = self.ProcessPerfData(self.list_SocketClients[0], dic_data)
                if bResult:
                    self.dic_dataList['datalist'].append(dic_data)
                # print('=======================================')
                break
            # time.sleep(1)
            time.sleep(1 - time.time() + fTime)
            #print(dic_data)
        self.SaveDataToFile()
        self.SocketClientSetCollectState(self.list_SocketClients[0], False)
        # d = json.dumps(self.dic_dataList)
        # file = open("TempFolder/Data.json", 'w')
        # file.write(d)
        # file.close()
        # print('=========================')
        # print(self.dic_dataList)
        self.bCollectionFlag = True

    def PerfDataStart(self):
        self.t_Perf = threading.Thread(target=self.__PerfDataStart, args=(threading.currentThread(),))
        self.t_Perf.setDaemon(True)
        self.t_Perf.start()
        self.log.info('PerfDataStart success')

    def PerfDataSetTimeNode(self):
        self.dic_dataList["datalist"] = []
        self.nErrorDataCnt=0
        pass

    def PerfDataStop(self):
        self.bCollectionFlag = False
        # 因为perf采集数据是多线程  处理数据需要时间 需要等待数据处理完后 才能结束
        while self.t_Perf.is_alive():
            time.sleep(0.5)
        self.t_Perf = None
        self.SocketClientSetCollectState(self.list_SocketClients[0], False)
        self.log.info("SDK PerfDataStop")
        return self.dic_dataList

    def ProcessPerfData(self, nHandle, dic_data):
        nRequestType = c_int(0)
        nDataCount = c_int(0)
        nDataLen = c_int(0)
        pszRecvData = self.SocketClientGetRecvData(nHandle, byref(nRequestType), byref(nDataCount), byref(nDataLen))
        #print("nRequestType:", nRequestType)
        #print("nDataLen:", nDataLen)
        #print('nDataCount', nDataCount)
        # return
        if not nDataCount.value or nDataCount.value == 300:
            #print(f'------------------{nDataCount.value}------------------')
            return False
        if nRequestType.value == C2SNetCmd.C2S_get_pid.value[0]:
            pData = cast(pszRecvData, POINTER(c_uint))
            # print("C2SNetCmd.C2S_get_pid:", pData.contents.value)
        elif nRequestType.value == C2SNetCmd.C2S_get_performance_data.value[0]:
            pData = cast(pszRecvData, POINTER(KEnginePerformance))
            dic_data['absTime'] = 0
            if self.strMachineTag == "PC":
                dic_data["FPS"] = 0
            dic_data["SetPass"] = 0
            dic_data["TextureCount"] = 0
            dic_data["MeshCount"] = 0
            dic_data["VulkanMemory"] = 0
            dic_data["Drawcall"] = 0
            dic_data["DrawTriangles"] = 0
            dic_data["DrawcallUI"] = 0
            dic_data["UIDrawTriangles"] = 0
            dic_data["CustomDataFloat"]={"uiErrorShaderCnt":0,"uiAllErrorShaderCnt":0,"uiMissingMaterialDefCount":0,"uiAllMissingMaterialDefCount":0}
            for i in range(nDataCount.value):
                # #print(f"KEnginePerformance:[{i}],uiFrameID:{pData[i].uiFrameID},uiDrawCallCnt:{pData[i].uiDrawCallCnt},uiFaceCnt:{pData[i].uiFaceCnt},nFPS:{pData[i].nFPS},uiVulkanMemory:{pData[i].uiVulkanMemory}")
                if self.strMachineTag == "PC":
                    dic_data["FPS"] += pData[i].nFPS
                dic_data["SetPass"] += pData[i].nSetPass
                dic_data["TextureCount"] += pData[i].uiTextureCnt
                dic_data["MeshCount"] += pData[i].uiMeshCnt
                dic_data["VulkanMemory"] += pData[i].fVulkanMemory
                dic_data["Drawcall"] += pData[i].uiDrawCallCnt
                dic_data["DrawTriangles"] += pData[i].uiFaceCnt
                dic_data["DrawcallUI"] += pData[i].uiUIDrawCall
                dic_data["UIDrawTriangles"] += pData[i].uiUIFaceCnt
                dic_data["CustomDataFloat"]["uiErrorShaderCnt"] += pData[i].uiErrorShaderCnt
                dic_data["CustomDataFloat"]["uiAllErrorShaderCnt"] += pData[i].uiAllErrorShaderCnt
                dic_data["CustomDataFloat"]["uiMissingMaterialDefCount"] += pData[i].uiMissingMaterialDefCount
                dic_data["CustomDataFloat"]["uiAllMissingMaterialDefCount"] += pData[i].uiAllMissingMaterialDefCount
            for strKey in dic_data:
                if type(dic_data[strKey]) != list:
                    # 自定义数据特殊处理
                    if strKey == "CustomDataFloat":
                        for strK in dic_data[strKey]:
                            dic_data[strKey][strK] = dic_data[strKey][strK] / nDataCount.value
                    else:
                        dic_data[strKey] = dic_data[strKey] / nDataCount.value

            ##print(f"uiErrorShaderCnt:{dic_data['uiErrorShaderCnt']}")
            ##print(f"uiAllErrorShaderCnt:{dic_data['uiAllErrorShaderCnt']}")
            dic_data['absTime'] = self.nFirstGetTime * 1000
            ##print(dic_data)

        elif nRequestType.value == C2SNetCmd.C2S_get_function_name_data.value[0]:
            if not len(self.list_functionName):
                pData = cast(pszRecvData, POINTER(FunctionName))
                for i in range(nDataCount.value):
                    print(f"KEnginePerformance:[{i}],szFuncName:{pData[i].szFuncName}")
                    strTempFunctionName=str(pData[i].szFuncName, encoding='utf8')
                    #临时处理 函数耗时名称 只有函数名称取错了
                    #if strTempFunctionName.find('gfx::KVulkanGraphicDevice::QueuePresent') !=-1:
                        #strTempFunctionName='KVulkanGraphicDevice::QueuePresent'
                    self.list_functionName.append(strTempFunctionName)

        elif nRequestType.value == C2SNetCmd.C2S_get_function_elapse_data.value[0]:
            pData = cast(pszRecvData, POINTER(FunctionCostData))
            list_FuncConsumeTimeData = []
            dic_TempFuncConsumeTimeData = {}
            for strFunctionName in self.list_functionName:
                dic_TempFuncConsumeTimeData[strFunctionName] = 0.0
            for i in range(nDataCount.value):
                #print(f"KEnginePerformance:[{i}],uiFrameID:{pData[i].uiFrameID},uiNameID:{self.list_functionName[pData[i].uiNameID]},fDuration:{pData[i].fDuration}")
                dic_TempFuncConsumeTimeData[self.list_functionName[pData[i].uiNameID]] += pData[i].fDuration
                # #print(pData[i].fDuration)
            nLen = nDataCount.value / len(self.list_functionName)
            for strFunctionName in dic_TempFuncConsumeTimeData:
                list_FuncConsumeTimeData.append({'FuncName': strFunctionName, 'ConsumeTime': round(
                    dic_TempFuncConsumeTimeData[strFunctionName] / nLen, 6)})
                # #print('source',dic_TempFuncConsumeTimeData[strFunctionName])
                # #print(round(dic_TempFuncConsumeTimeData[strFunctionName]/nLen,6))
            dic_data["FuncConsumeTime"] = list_FuncConsumeTimeData
            ##print(list_FuncConsumeTimeData)
        else:
            # print("no data")
            return False
        # print(dic_data)
        return True

    def SaveDataToFile(self):
        with open(os.path.join(self.strDataPath,"Data.json"), 'w') as f:
            f.write(json.dumps(self.dic_dataList))

    def __ProcessCmdAndMsgRetCode(self, t_parent):
        nCounter = 5
        nCurCount = 0
        while t_parent.is_alive():
            time.sleep(0.1)
            nCurCount += 1
            # 0.1秒检查一次是否有返回值
            bRet, strInfo = self.ProcessCommandRetCode(self.list_SocketClients[0])
            if bRet:
                # print(f"strInfo:{strInfo}")
                dic_info = JsonLoad(strInfo)
                self.log.info(dic_info)
                self.list_CommandRetCode.append(dic_info)
            # 0.5秒检查一次是否有Lua插件发送的信息
            if nCurCount == 5:
                nCurCount = 0
                bRet, strInfo = self.ProcessMessageRetCode(self.list_SocketClients[0])
                if bRet:
                    dic_info = JsonLoad(strInfo)
                    # self.log.info(dic_info)
                    for key, value in dic_info.items():
                        self.dic_MessageRetCode[key] = value
        self.log.info('thread __ProcessCmdAndMsgRetCode exit')

    def GetCmdRetCode(self, strCmd):
        bRet = False
        res = None
        for dic_info in self.list_CommandRetCode:
            if type(dic_info)!=dict:
                continue
            if strCmd in dic_info.keys():
                bRet = True
                res = dic_info[strCmd]
                self.list_CommandRetCode.remove(dic_info)
                break
        self.log.info(self.list_CommandRetCode)
        return bRet, res

    def ProcessCommandRetCode(self, nHandle):
        nRequestType = c_int(0)
        nDataCount = c_int(0)
        nDataLen = c_int(0)
        pszRecvData = self.SocketClientGetRevcCommandRetCode(nHandle, byref(nRequestType), byref(nDataCount), byref(nDataLen))
        ##print("nRequestType:", nRequestType)
        ##print("nDataLen:", nDataLen.value)
        ##print('nDataCount', nDataCount.value)
        # nDataLen.value==1  是错误情况需要查问题
        if not nDataLen.value or nDataLen.value == 1:
            ##print(f'------------------{nDataCount.value}------------------')
            return False, ''
        elif nRequestType.value == C2SNetCmd.C2S_execute_auto_test_command.value[0]:
            pData = cast(pszRecvData, POINTER(c_char))
            ##print('C2SNetCmd.C2S_execute_auto_test_command')
            ##print(string_at(pData).decode())
            ##print("nRequestType:", nRequestType)
            ##print("nDataLen:", nDataLen)
            ##print('nDataCount', nDataCount)
            ##print(JsonLoad(string_at(pData).decode()))
            # print(type(pData.contents))
            # print(f"string_at(pData):{string_at(pData,nDataLen.value-1)}")
            # print(pData.contents.value)
            return True, string_at(pData).decode('utf8')
        else:
            # print("no data")
            return False, 'no data'

    def ProcessMessageRetCode(self, nHandle):
        nRequestType = c_int(0)
        nDataCount = c_int(0)
        nDataLen = c_int(0)
        pszRecvData = self.SocketClientGetRevcMessageRetCode(nHandle, byref(nRequestType), byref(nDataCount), byref(nDataLen))
        #self.log.info(f"nRequestType:{nRequestType.value}")
        #self.log.info(f"nDataLen:{nDataLen.value}")
        ##print("nRequestType:", nRequestType)
        ##print("nDataLen:", nDataLen)
        ##print('nDataCount', nDataCount)
        if not nDataLen.value:
            ##print(f'------------------{nDataCount.value}------------------')
            return False, ''
        elif nRequestType.value == C2SNetCmd.C2S_get_auto_test_msg_ret_code.value[0]:
            pData = cast(pszRecvData, POINTER(c_char))
            ##print('C2SNetCmd.C2S_get_auto_test_msg_ret_code')
            ##print(JsonLoad(string_at(pData).decode()))
            # self.log.info(f"C2SNetCmd.C2S_get_auto_test_msg_ret_code")
            # print(string_at(pData))
            # self.log.info(JsonLoad(string_at(pData).decode()))
            # 返回数据少一个字节待修复  修复了
            strErrorData = string_at(pData).decode('utf8')
            # self.log.info(strErrorData)
            return True, strErrorData
        else:
            # print("no data")
            return False, ''

    def SetEngineOption(self, Enum_option, nCount=0, *args):

        setRequest = C2S_SET_ENGINE_OPTION()
        # 设置请求协议类型
        setRequest.byProtocolID = C2SNetCmd.C2S_set_engine_option.value[0]
        # print(type(setRequest.byProtocolID))

        # 设置引擎开关枚举类型
        print(Enum_option.value[0])
        setRequest.nEngineOption = Enum_option.value[0]
        # 设置引擎开关枚举类型的参数个数  例如 设置开关0个参数  设置LOD2个参数
        print(nCount)
        setRequest.nCount = nCount
        if nCount == 0:
            setRequest.uionData.bEnable = args[0]
        elif nCount == 1:
            setRequest.uionData.fValue[0] = args[0]
        elif nCount == 4:
            for i in len(args):
                setRequest.uionData.fValue[i] = args[i]
        else:
            self.log.info(f"nCount:{nCount} error ")

        # print(type(setRequest.nCount))
        # print(sizeof(setRequest))
        '''
        if nCount==0:

        elif nCount==1:

        elif nCount==4:

        else:
            #print(f"count error {nCount}")'''
        # 发送消息
        bRetCode = self.SocketClientSend(self.list_SocketClients[0], byref(setRequest), sizeof(setRequest))
        # print(f"result {bRetCode}")

    def SendCommandToSDK(self, strCommand):
        # 检测cmd头部是否为 /gm或/cmd
        if strCommand[:3] != '/gm' and strCommand[:4] != '/cmd':
            self.log.info(f"Command head error:{strCommand}")
        ##print(f"SendCommandToClient --{strCommand}")
        # 中文编码字节缺失
        c_string = c_char_p(strCommand.encode('utf8'))
        ##print(strCommand.encode('utf8'))
        ##print(c_string.value)
        ##print(len(c_string.value))
        ##print(len(strCommand))
        # 发送消息
        bRetCode = self.SocketClientSendString(self.list_SocketClients[0], C2SNetCmd.C2S_execute_auto_test_command,c_string, len(c_string.value))
        if not self.t_CmdAndMsgRetCode:
            self.t_CmdAndMsgRetCode=threading.Thread(target=self.__ProcessCmdAndMsgRetCode,args=(threading.currentThread(),))
            self.t_CmdAndMsgRetCode.setDaemon(True)
            self.t_CmdAndMsgRetCode.start()
        self.log.info(f"{strCommand} :result {bRetCode}")
        return bRetCode

    def CreateSocketClient(self, strIPAddr, nPort):
        bResult = False
        # bufferIPAddr=create_string_buffer(strIPAddr.encode())
        pszIPAddr = c_char_p(strIPAddr.encode())
        # print("pszIPAddr:", pszIPAddr.value)
        nSocket = self.m_fnCreateSocketClient(pszIPAddr, nPort)
        if nSocket != -1:
            bResult = True
            self.list_SocketClients.append(nSocket)
        # print("nSocket：", nSocket)
        return bResult

    def DestorySocketClient(self, nHandle):
        bResult = self.m_fnDestorySocketClient(nHandle)
        if bResult:
            # print('DestorySocketClient success')
            pass
        else:
            pass
            # print('DestorySocketClient faile')
        return bResult

    def SocketClientSend(self, nHandle, pvData, nSize):

        bResult = self.m_fnSocketClientSend(nHandle, pvData, nSize)
        #print(f"SocketClientSend:{bResult}")
        return bResult

    def SocketClientSendString(self, nHandle, enum_type, pvData, nSize):

        # #print(f"{type(enum_type.value[0])} :{enum_type.value[0]}")
        bResult = self.m_fnSocketClientSendString(nHandle, enum_type.value[0], pvData, nSize)
        return bResult

    def SocketFactorySendToAll(self, pvData, nSize):

        bResult = self.m_fnSocketFactorySendToAll(pvData, nSize)
        return bResult

    # 获取函数耗时和PerfData的请求
    def SocketClientSend_GetAllPerfData_Request(self, nHandle):
        bResult = self.m_fnSocketClientSend_GetAllPerfData_Request(nHandle)
        # print(f'SocketClientSend_GetAllPerfData_Request:{bResult}')
        if self.bFirstGetData:
            self.nFirstGetTime = int(time.time())
            self.bFirstGetData = False
        else:
            self.nFirstGetTime += 1
        return bResult

    def SocketClientSetCollectState(self, nHandle, bEnable):

        bResult = self.m_fnSocketClientSetCollectState(nHandle, bEnable)
        # print(f'SocketClientSetCollectState ', bResult)
        self.log.info(f"SocketClientSetCollectState:{bResult}")
        return bResult

    # pn代表引用传递int类型
    # 获取引擎性能相关数据
    def SocketClientGetRecvData(self, nHandle, pnRetRequestType, pnRetDataCount, pnRetDataLen):
        pszResult = self.m_fnSocketClientGetRecvData(nHandle, pnRetRequestType, pnRetDataCount, pnRetDataLen)
        return pszResult

    def SocketClientGetRevcCommandRetCode(self, nHandle, pnRetRequestType, pnRetDataCount, pnRetDataLen):
        pszResult = self.m_fnSocketClientGetRevcCommandRetCode(nHandle, pnRetRequestType, pnRetDataCount, pnRetDataLen)
        return pszResult

    def SocketClientGetRevcMessageRetCode(self, nHandle, pnRetRequestType, pnRetDataCount, pnRetDataLen):
        pszResult = self.m_fnSocketClientGetRevcMessageRetCode(nHandle, pnRetRequestType, pnRetDataCount, pnRetDataLen)
        return pszResult

    def _SetFunction(self):
        self.m_fnInitSocketClientFactory = None
        self.m_fnCreateSocketClient = None
        self.m_fnDestorySocketClient = None
        self.m_fnSocketClientSend = None
        self.m_fnSocketFactorySendToAll = None
        self.m_fnSocketClientSend_GetAllPerfData_Request = None
        self.m_fnSocketClientSetCollectState = None
        self.m_fnSocketClientGetRecvData = None
        self.m_fnUnInitSocketClientFactory = None

    def __UnInit(self):
        bResult = False
        for nSocket in self.list_SocketClients:
            bResult = self.DestorySocketClient(nSocket)
        self.m_fnUnInitSocketClientFactory()
        # print("Unint")
        #del self.dll
        self.log.info("SDK UnInit")
        return bResult

    def initLogger(self):
        try:
            initLog(self.__class__.__name__)
            self.log = logging.getLogger(str(os.getpid()))
        except Exception:
            info = traceback.format_exc()
            # print(info)
            raise Exception('initLogger ERROR!!')


if __name__ == '__main__':
    #获取传入main函数的参数
    ''''''
    strIpAddress=sys.argv[1]
    strDataPath=sys.argv[2]
    
    if not filecontrol_existFileOrFolder(strDataPath):
        filecontrol_createFolder(strDataPath)
    else:
        list_dataFile=['PerfeyeStop','Data.json','ConnectError','DataError']
        for strFileName in list_dataFile:
            filecontrol_deleteFileOrFolder(os.path.join(strDataPath, strFileName))
    strPerfStopPath=os.path.join(strDataPath, 'PerfeyeStop')
    #strDataFilePath=r'E:\test'
    #strDataPath=r'E:\test'
    #strIpAddress='10.11.240.228'
    SDK = XGameSocketClient(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'SocketClientDLL.dll'),strIpAddress, 1112,strDataPath,strMachineTag='Android')
    # SDK
    SDK.PerfDataCreate()
    SDK.PerfDataStart()
    '''
    time.sleep(20)
    SDK.PerfDataStop()
    SDK.SDK_Stop()
    time.sleep(2)'''
    ''''''
    while True:
        time.sleep(0.5)
        if filecontrol_existFileOrFolder(strPerfStopPath):
            SDK.PerfDataStop()
            SDK.SDK_Stop()
            break