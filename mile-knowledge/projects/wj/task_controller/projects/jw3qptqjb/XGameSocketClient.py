# -*- coding: utf-8 -*-
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
    C2S_set_capture_optick=17,
    C2S_get_pixel_checker_status=18,
    C2S_set_pixel_checker=19,
    C2S_protocol_total = 20,


list_EngineOption=[
    "EO_unknow",
    # Basic
    "EO_basic_set_fps_limit_enable",
    "EO_basic_set_fog_enable",
    "EO_basic_set_debug_info_enable",
    "EO_basic_set_occlude_culling_enable",
    "EO_basic_set_descriptorset_A_B_enable", # 采用交换方式更新DescriptorSet
    "EO_basic_set_only_bake_shadowmap_enable",
    "EO_basic_set_multi_thread_render_enable",
    "EO_basic_set_camera_farsee_float",# [20000.f, 200000.f](单位：厘米)
    "EO_basic_set_scene_entity_load_radius_float",# [40000.f, 200000.f](单位：厘米)
    "EO_basic_set_shadow_quality_int",# [0, 3] EX3DShadowMapLevel
    "EO_basic_set_max_shadow_cascade_int",# [0, 3]
    "EO_basic_set_view_probe_type_int",# [0, 3] EX3DViewProbeMask
    "EO_basic_set_terrain_bake_level_int",# [0, 3] EX3DTerrainRuntimeBakeLevel
    "EO_basic_set_terrain_bake_range_int", # [0, 1] EX3DTerrainRuntimeBakeRange
    "EO_basic_set_angle_cull_float", # [0.0f, 0.1f]
    "EO_basic_set_roughness_scale_float", # [0.0f, 1.0f]
    "EO_basic_set_resolution_percent_scale_int", # 设置画面分辨率[10, 400]
    "EO_basic_set_specific_resolution_percent_scale_int", # 设置特定的画面分辨率 "720p", "640p", "540p", "1vs1"
    "EO_basic_set_AA_plan_int", # [0, 1] "FSR+TAA", "CAS+FXAA"
    "EO_basic_set_main_camera_cascade_radius_int",# [0, 40000]
    # Debug
    "EO_debug_set_terrain_enable",
    "EO_debug_set_apex_clothing_enable",
    "EO_debug_set_not_rom_enbale",
    "EO_debug_set_framewire_enable",
    "EO_debug_set_debug_bake_terrain_enable",
    "EO_debug_set_foliage_enable",
    "EO_debug_set_skybox_enable",
    "EO_debug_set_pause_compute_thread_enable",
    "EO_debug_set_stop_culling_enable",
    "EO_debug_set_water_enable",
    "EO_debug_set_point_light_enable",
    "EO_debug_set_scene_containerbox_enable",
    "EO_debug_set_render_decal_enable",
    "EO_debug_set_model_enable",
    "EO_debug_set_skin_model_enable",
    "EO_debug_set_scene_actor_model_enable",
    "EO_debug_set_gameplay_model_enable",
    "EO_debug_set_model_stbox_enable",
    "EO_debug_set_model_box_enable",
    "EO_debug_set_camera_light_enable",
    "EO_debug_set_occluded_box_enable",
    "EO_debug_set_shader_file_cache_enable",
    "EO_debug_set_cpu_profile_enable",
    "EO_debug_set_sss_enable",
    "EO_debug_set_sfx_enable",
    "EO_debug_set_oit_enable",
    "EO_debug_set_offlinegi_enable",
    "EO_debug_set_render_all_paricle_enable",
    "EO_debug_set_gpu_time_stamp_enable",
    "EO_debug_set_job_system_enable",
    "EO_debug_set_save_scene_depth_to_file_enable",
    "EO_debug_set_spot_light_oit_shadow_enable",
    "EO_debug_set_spot_light_opaque_shadow_enable",
    "EO_debug_set_load_bake_mesh_enable",
    "EO_debug_set_spot_light_enable",
    "EO_debug_set_deferred_specular_enable",
    "EO_debug_set_soft_shadow_mask_enable",
    "EO_debug_set_shadow_mask_blur_enable",
    "EO_debug_set_point_light_effect_character_enable",
    "EO_debug_set_merge_particle_enable",
    "EO_debug_set_support_dynamic_UBO_enable",
    "EO_debug_set_support_dynamic_SSBO_enable",
    "EO_debug_set_shadow_cull_size_float",
    "EO_debug_set_shadow_cull_angle_float", # [0.0f, 100000.0f]
    "EO_debug_set_point_cloud_quality_int",  # [0.0f, 1.0f]
    "EO_debug_set_output_resourepool_info_enable",# [0, 2] "POINT_CLOUD_OFF", "POINT_CLOUD_LOW_VS_LEVEL", "POINT_CLOUD_HIGH_FS_LEVEL"
    "EO_debug_set_output_vma_info_enable",
    # TexStream
    "EO_texstream_set_texture_stream_enable",
    "EO_texstream_set_texture_mip_bias_int",# [0, 6]
    "EO_texstream_set_min_game_model_texture_size_int",  # [6, 10]
    "EO_texstream_set_max_texture_resolution_int", # [0, 9]
    # Foliage
    "EO_foliage_set_shadow_enable",
    "EO_foliage_set_render_tree_enable",
    "EO_foliage_set_render_grass_enable",
    "EO_foliage_set_wind_enable",
    "EO_foliage_set_tree_lod_bias_int", # [0, 2]
    "EO_foliage_set_grass_lod_bias_int",  # [0, 2]
    "EO_foliage_set_brush_tree_load_radius_int",  # [20000.f, 60000.f] 20000.0f 200米
    "EO_foliage_set_brush_grass_load_radius_int", # [10000.0f, 20000.f]
    "EO_foliage_set_angle_cull_grass_float",  # [0.0f, 0.1f]
    "EO_foliage_set_angle_cull_tree_float",  # [0.0f, 0.5f]
    "EO_foliage_set_protect_grass_density_int",  # [0, 100]
    "EO_foliage_set_grass_density_int", # [0, 100]
    "EO_foliage_set_tree_density_int",  # [0, 100]
    "EO_foliage_set_important_size_in_radius_int", # [0, 10000]
    "EO_foliage_set_protect_inner_radius_int",  # [0, GetFoliageProtectOuterRadius]
    "EO_foliage_set_protect_outer_radius_int",  # [protect_inner_radius, 10000.f]
    "EO_foliage_set_high_detail_lod_distance_int",  # [1, low_detail - 1]
    "EO_foliage_set_low_detail_lod_distance_int",  # [low_detail, 50000]
    # LOD
    "EO_lod_set_lod_switch_enable",
    "EO_lod_set_mesh_model_start_lod_bias_int",  # [-3, 3] EX3DMeshLodLevel
    "EO_lod_set_model_lod0_distance_int",  # [1000, lod1]
    "EO_lod_set_model_lod1_distance_int",  # [lod0, 30000]
    "EO_lod_set_model_lod2_distance_int", # [1000, 80000]
    # Apex
    "EO_apex_local_wind_enable",
    # PostRender
        # Common
    "EO_post_common_set_post_render_enable",
    "EO_post_common_set_post_render_dof_enable",
    "EO_post_common_set_post_render_bloom_enable",
    "EO_post_common_set_rc_post_render_bloom_enable",
    "EO_post_common_set_light_occlusion_enable",
    "EO_post_common_set_rc_light_occlusion_enable",
    "EO_post_common_set_light_shaft_bloom_enable",
    "EO_post_common_set_rc_light_shaft_bloom_enable",
    "EO_post_common_set_ao_enable",
    "EO_post_common_set_ssgi_enable",
    "EO_post_common_set_sspr_enable",
    "EO_post_common_set_render_shock_wave_enable",
    "EO_post_common_set_height_fog_enable",
    "EO_post_common_set_rc_height_fog_enable",
    "EO_post_common_set_taa_enable",
    "EO_post_common_set_fxaa_enable",
    "EO_post_common_set_cas_enable",
    "EO_post_common_set_rc_cas_enable",
    "EO_post_common_set_fsr_enable",
    "EO_post_common_set_shock_wave_enable",
    "EO_post_common_set_vignette_enable",
    "EO_post_common_set_dithering_enable",
    "EO_post_common_set_grain_enable",
    "EO_post_common_set_chromatic_aberration_enable",
    "EO_post_common_set_ray_march_fog_enable",
    "EO_post_common_set_rc_ray_march_fog_enable",
        # Vignette
    "EO_post_set_vignette_intensity_float", # [0.0f, 1.0f]
    "EO_post_set_vignette_factor_float",# [0.0f, 1.0f]
        # Tonemapping
    "EO_post_set_tonemapping_exposure_float",  # [-2.0f, 2.0f]
    "EO_post_set_grain_intensity_float",  # [0.0f, 1.0f]
    "EO_post_set_grain_scale_size_float",  # [0.3f, 3.0f]
    "EO_post_set_luminance_contribute_float",  # [0.0f, 1.0f]
        # Dof
    "EO_post_set_dof_front_near_float",  # [0.0f, 1000.0f]
    "EO_post_set_dof_front_far_float",  # [front_near, 1000.0f]
    "EO_post_set_dof_back_near_float",  # [0.0f, 1000.0f]
    "EO_post_set_dof_back_far_float",  # [back_near, 1000.0f]
    "EO_post_set_dof_blur_size_float", # [1.0f, 50.0f]
    "EO_post_set_dof_intensity_float", # [0.1f, 10.0f]
        # Bloom
    "EO_post_set_bloom_threshold_float",  # [0.0f, 2.0f]
    "EO_post_set_bloom_power_float", # [0.0f, 2.0f]
    "EO_post_set_bloom_dirty_intensity_float", # [0.0f, 1.0f]
        # CAS
    "EO_post_set_cas_sharpness_float",# [0.0f, 1.0f]
    "EO_post_set_taa_sharp_enable",
    "EO_post_set_fsr_sharpness_float",  # [0.0f, 1.0f]
        # HeightFog
    "EO_post_set_heightfog_density_float",  # [0.0f, 1.0f]
    "EO_post_set_heightfog_height_falloff_float", # [0.0f, 1.0f]
    "EO_post_set_heightfog_min_fog_opacity_float",  # [0.0f, 1.0f]
    "EO_post_set_heightfog_start_distance_float",  # [0.0f, 40000.0f]
    "EO_post_set_heightfog_cutoff_distance_float", # [0.0f, 200000.0f]
    "EO_post_set_heightfog_height_float", # [0.0f, 40000.0f]
    "EO_post_set_heightfog_diret_inscattering_exponent_float",  # [0.0f, 50.0f]
    "EO_post_set_heightfog_diret_inscattering_start_distance_float",  # [0.0f, 40000.0f]
    "EO_post_set_heightfog_scene_fade_enable",
    "EO_post_set_heightfog_scene_fade_start_float", # [0.0f, 200000.0f]
    "EO_post_set_heightfog_scene_fade_end_float",  # [0.0f, 200000.0f]
        # RayMarchFogtodo: 2024.1.15
        # HBAO
    "EO_post_set_hbao_max_distance_floa",  # [10.0f, 400.0f]
    "EO_post_set_hbao_distance_falloff_float", # [0.0f, max_distance]
    "EO_post_set_hbao_radius_float",  # [0.3f, 5.0f]
    "EO_post_set_hbao_max_radius_pixels_int", # [16, 256]
    "EO_post_set_hbao_angle_bias_float", # [0.0f, 0.5f]
    "EO_post_set_hbao_blur_sharpness_float", # [0.0f, 16.0f]
    "EO_post_set_hbao_only_ao_enable",
    "EO_post_set_hbao_enable",
    "EO_post_set_hbao_use_deinterleave_tex_enable",
    "EO_post_set_hbao_only_ssgi_enable",
    "EO_post_set_hbao_ssgi_enable",
    "EO_post_set_hbao_ssgi_max_distance_float", # [100.0f, 400.0f]
    "EO_post_set_hbao_ssgi_intensity_float",  # [1.0f, 10.0f]
        # Reflection
    "EO_post_set_reflection_intensity_float", # [0.0f, 1.0f]
    "EO_post_set_reflection_water_ibl_intensity_float", # [0.0f, 2.0f]
        # ColorGradetodo: 2024.1.15
    # Environment
        # SunLight
    "EO_post_set_env_sunlight_heading_angle_float", # [-180.f, 180.f]
    "EO_post_set_env_sunlight_altitude_angle_float", # [-90.f, 90.f]
    "EO_post_set_env_sunlight_diffuse_color_float4",# [0, 1]
    "EO_post_set_env_sunlight_diffuse_intensity_float", # [0.f, 100.f]
    "EO_post_set_env_sunlight_ambient_color_float4",# [0, 1]
    "EO_post_set_env_sunlight_sky_light_color_float4", # [0, 1]
    "EO_post_set_env_sunlight_sky_light_intensity_float", # [0.f, 100.f]
    "EO_post_set_env_sunlight_common_light_color_float4", # [0, 1]
    "EO_post_set_env_sunlight_common_light_intensity_float", # [0.f, 100.f]
        # Env Map
    "EO_post_set_env_map_intensity_float",# [0.f, 10.f]
    "EO_post_set_env_map_saturation_float", # [0.f, 10.f]
        # Camera Light
    "EO_post_set_env_camera_light_color_float4", # [0, 1]
    "EO_post_set_env_camera_light_intensity_float", # [0.0f, 10.0f]
    "EO_post_set_env_camera_light_radius_float", # [0.0f, 1000.0f]
    "EO_post_set_env_camera_light_length_float", # [0.0f, 1000.0f]
    "EO_post_set_env_camera_light_radial_attenuation_start_float", # [0.0f, 1000.0f]
    "EO_post_set_env_camera_light_axial_attenuation_start_float",# [0.0f, 1000.0f]
        # Character Light
    "EO_post_set_env_character_light_diffuse_color_float4",# [0, 1]
    "EO_post_set_env_character_light_diffuse_intensity_float", # [0.f, 100.f]
    "EO_post_set_env_character_light_sky_light_color_float4", # [0, 1]
    "EO_post_set_env_character_light_sky_light_intensity_float", # [0.f, 100.f]
    "EO_post_set_env_character_light_common_light_color_float4",# [0, 1]
    "EO_post_set_env_character_light_common_light_intensity_float", # [0.f, 100.f]
    "EO_post_set_env_character_light_ambient_color_float4", # [0, 1]
        # Character Env Map
    "EO_post_set_character_env_map_intensity_float", # [0.f, 10.f]
    "EO_post_set_character_env_map_saturation_float", # [0.f, 10.f]
    "EO_post_set_character_env_map_rotation_axis_y_float",  # [0.f, 360.f]
        # Character Env Probe [info]
        # Weather
    "EO_post_set_env_weather_enable",
    "EO_post_set_env_weather_render_top_depth_enable",
    "EO_post_set_env_weather_screen_rain_drop_enable",
    "EO_post_set_env_weather_fall_enable",
    "EO_post_set_env_weather_cover_enable",
    "EO_post_set_env_weather_splash_enable",
    "EO_post_set_env_weather_fall_total_count_scale_float4",
    "EO_post_set_env_weather_splash_quality_int",
    "EO_post_set_env_weather_rain_surfaceWater_enable",
    "EO_post_set_env_weather_snow_cover_range_int",
    "EO_post_set_env_weather_cover_map_update_cell_xz_int",
    "EO_post_set_env_weather_cover_map_update_cell_y_int",
    "EO_post_set_env_weather_cover_map_cull_object_min_size_int",
    "EO_post_set_env_weather_cover_map_cull_object_min_size_homeland_int",
    "EO_post_set_env_weather_delay_cull_frame_count_int",
    # Performance
    "EO_performance_set_simplify_user_shader_enable",
    "EO_performance_set_simplify_pbr_enable",
    "EO_performance_set_disable_alpha_test_enable",
    "EO_performance_set_disable_frag_shader_enable",
    "EO_performance_set_lod_display_enable",
    "EO_performance_set_pbr_channal_int",# [0, 12] DebugPBRMask
    # GPU Driven
    "EO_gpu_driven_set_stop_cull_enable",
    "EO_gpu_driven_set_enable_hiz_oc_enable",
    "EO_gpu_driven_set_enable_cluster_oc_enable",
    "EO_gpu_driven_set_enable_shadow_enable",
    "EO_gpu_driven_set_tri_cluster_display_enable",
    "EO_gpu_driven_set_draw_cluster_box_enable",
    "EO_gpu_driven_set_enable_skip_compute_enable",
    # Animation
    "EO_animation_set_extract_frame_enable",
    "EO_animation_set_second_order_smooth_enable",
    "EO_animation_set_position_smooth_enable",
    "EO_animation_set_rotation_smooth_enable",
    "EO_animation_set_frequency_float", # [0.0f, 10.0f]
    "EO_animation_set_damping_float", # [0.0f, 5.0f]
    "EO_animation_set_initial_response_float", # [-5.0f, 5.0f]
    "EO_animation_set_animation_update_callback_enable",
    "EO_animation_set_animation_fusion_enable",
    # CharacterFollowLight todo: 2024.1.15
    "EO_count"
]


def Enum_option(strEngineOption):
    return list_EngineOption.index(strEngineOption)


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
    EO_debug_set_apex_clothing_enable=22,
    EO_debug_set_not_rom_enbale = 23,
    EO_debug_set_framewire_enable = 24,
    EO_debug_set_debug_bake_terrain_enable = 25,
    EO_debug_set_foliage_enable = 26,
    EO_debug_set_skybox_enable=27,
    EO_debug_set_pause_compute_thread_enable=28,
    EO_debug_set_stop_culling_enable = 29,
    EO_debug_set_water_enable = 30,
    EO_debug_set_point_light_enable = 31,
    EO_debug_set_scene_containerbox_enable = 32,
    EO_debug_set_render_decal_enable = 33,
    EO_debug_set_model_enable = 34,
    EO_debug_set_skin_model_enable = 35,
    EO_debug_set_scene_actor_model_enable = 36,
    EO_debug_set_gameplay_model_enable = 37,
    EO_debug_set_model_stbox_enable = 38,
    EO_debug_set_model_box_enable = 39,
    EO_debug_set_camera_light_enable = 40,
    EO_debug_set_occluded_box_enable = 41,
    EO_debug_set_shader_file_cache_enable=42,
    EO_debug_set_cpu_profile_enable = 43,
    EO_debug_set_sss_enable = 44,
    EO_debug_set_sfx_enable = 45,
    EO_debug_set_oit_enable = 46,
    EO_debug_set_offlinegi_enable=47,
    EO_debug_set_render_all_paricle_enable = 48,
    EO_debug_set_gpu_time_stamp_enable = 49,
    EO_debug_set_job_system_enable=50,
    EO_debug_set_save_scene_depth_to_file_enable = 51,
    EO_debug_set_spot_light_oit_shadow_enable = 52,
    EO_debug_set_spot_light_opaque_shadow_enable = 53,
    EO_debug_set_load_bake_mesh_enable = 54,
    EO_debug_set_spot_light_enable = 55,
    EO_debug_set_deferred_specular_enable = 56,
    EO_debug_set_soft_shadow_mask_enable = 57,
    EO_debug_set_shadow_mask_blur_enable=58,
    EO_debug_set_point_light_effect_character_enable=59,
    EO_debug_set_merge_particle_enable=60,
    EO_debug_set_support_dynamic_UBO_enable=61,
    EO_debug_set_support_dynamic_SSBO_enable=62,
    EO_debug_set_shadow_cull_size_float = 63,  # [0.0f, 100000.0f]
    EO_debug_set_shadow_cull_angle_float = 64,  # [0.0f, 1.0f]
    EO_debug_set_point_cloud_quality_int = 65,  # [0, 2] "POINT_CLOUD_OFF", "POINT_CLOUD_LOW_VS_LEVEL", "POINT_CLOUD_HIGH_FS_LEVEL"
    EO_debug_set_output_resourepool_info_enable = 66,
    EO_debug_set_output_vma_info_enable = 67,
    # TexStream
    EO_texstream_set_texture_stream_enable = 68,
    EO_texstream_set_texture_mip_bias_int = 69,  # [0, 6]
    EO_texstream_set_min_game_model_texture_size_int = 70,  # [6, 10]
    EO_texstream_set_max_texture_resolution_int = 71,  # [0, 9]
    # Foliage
    EO_foliage_set_shadow_enable = 72,
    EO_foliage_set_render_tree_enable = 73,
    EO_foliage_set_render_grass_enable = 74,
    EO_foliage_set_tree_lod_bias_int = 75,  # [0, 2]
    EO_foliage_set_grass_lod_bias_int = 76,  # [0, 2]
    EO_foliage_set_brush_tree_load_radius_int = 77,  # [20000.f, 60000.f] 20000.0f 200米
    EO_foliage_set_brush_grass_load_radius_int = 78,  # [10000.0f, 20000.f]
    EO_foliage_set_angle_cull_grass_float = 79,  # [0.0f, 0.1f]
    EO_foliage_set_angle_cull_tree_float = 80,  # [0.0f, 0.5f]
    EO_foliage_set_protect_grass_density_int = 81,  # [0, 100]
    EO_foliage_set_grass_density_int = 82,  # [0, 100]
    EO_foliage_set_tree_density_int = 83,  # [0, 100]
    EO_foliage_set_important_size_in_radius_int = 84,  # [0, 10000]
    EO_foliage_set_protect_inner_radius_int = 85,  # [0, GetFoliageProtectOuterRadius]
    EO_foliage_set_protect_outer_radius_int = 86,  # [protect_inner_radius, 10000.f]
    EO_foliage_set_high_detail_lod_distance_int = 87,  # [1, low_detail - 1]
    EO_foliage_set_low_detail_lod_distance_int = 88,  # [low_detail, 50000]
    # LOD
    EO_lod_set_lod_switch_enable = 89,
    EO_lod_set_mesh_model_start_lod_bias_int = 90,  # [-3, 3] EX3DMeshLodLevel
    EO_lod_set_model_lod0_distance_int = 91,  # [1000, lod1]
    EO_lod_set_model_lod1_distance_int = 92,  # [lod0, 30000]
    EO_lod_set_model_lod2_distance_int = 93,  # [1000, 80000]
    # PostRender
        # Common
    EO_post_common_set_post_render_enable = 94,
    EO_post_common_set_post_render_dof_enable = 95,
    EO_post_common_set_post_render_bloom_enable = 96,
    EO_post_common_set_rc_post_render_bloom_enable = 97,
    EO_post_common_set_light_occlusion_enable = 98,
    EO_post_common_set_rc_light_occlusion_enable = 99,
    EO_post_common_set_light_shaft_bloom_enable = 100,
    EO_post_common_set_rc_light_shaft_bloom_enable = 101,
    EO_post_common_set_ao_enable = 102,
    EO_post_common_set_ssgi_enable = 103,
    EO_post_common_set_sspr_enable = 104,
    EO_post_common_set_render_shock_wave_enable = 105,
    EO_post_common_set_height_fog_enable = 106,
    EO_post_common_set_rc_height_fog_enable = 107,
    EO_post_common_set_taa_enable = 108,
    EO_post_common_set_fxaa_enable = 109,
    EO_post_common_set_cas_enable = 110,
    EO_post_common_set_rc_cas_enable = 111,
    EO_post_common_set_fsr_enable = 112,
    EO_post_common_set_shock_wave_enable = 113,
    EO_post_common_set_vignette_enable = 114,
    EO_post_common_set_dithering_enable = 115,
    EO_post_common_set_grain_enable = 116,
    EO_post_common_set_chromatic_aberration_enable = 117,
    EO_post_common_set_ray_march_fog_enable = 118,
    EO_post_common_set_rc_ray_march_fog_enable = 119,
        # Vignette
    EO_post_set_vignette_intensity_float = 120,  # [0.0f, 1.0f]
    EO_post_set_vignette_factor_float = 121,  # [0.0f, 1.0f]
        # Tonemapping
    EO_post_set_tonemapping_exposure_float = 122,  # [-2.0f, 2.0f]
    EO_post_set_grain_intensity_float = 123,  # [0.0f, 1.0f]
    EO_post_set_grain_scale_size_float = 124,  # [0.3f, 3.0f]
    EO_post_set_luminance_contribute_float = 125,  # [0.0f, 1.0f]
        # Dof
    EO_post_set_dof_front_near_float = 126,  # [0.0f, 1000.0f]
    EO_post_set_dof_front_far_float = 127,  # [front_near, 1000.0f]
    EO_post_set_dof_back_near_float = 128,  # [0.0f, 1000.0f]
    EO_post_set_dof_back_far_float = 129,  # [back_near, 1000.0f]
    EO_post_set_dof_blur_size_float = 130,  # [1.0f, 50.0f]
    EO_post_set_dof_intensity_float = 131,  # [0.1f, 10.0f]
        # Bloom
    EO_post_set_bloom_threshold_float = 132,  # [0.0f, 2.0f]
    EO_post_set_bloom_power_float = 133,  # [0.0f, 2.0f]
    EO_post_set_bloom_dirty_intensity_float = 134,  # [0.0f, 1.0f]
        # CAS
    EO_post_set_cas_sharpness_float = 135,  # [0.0f, 1.0f]
    EO_post_set_taa_sharp_enable = 136,
    EO_post_set_fsr_sharpness_float = 137,  # [0.0f, 1.0f]
        # HeightFog
    EO_post_set_heightfog_density_float = 138,  # [0.0f, 1.0f]
    EO_post_set_heightfog_height_falloff_float = 139,  # [0.0f, 1.0f]
    EO_post_set_heightfog_min_fog_opacity_float = 140,  # [0.0f, 1.0f]
    EO_post_set_heightfog_start_distance_float = 141,  # [0.0f, 40000.0f]
    EO_post_set_heightfog_cutoff_distance_float = 142,  # [0.0f, 200000.0f]
    EO_post_set_heightfog_height_float = 143,  # [0.0f, 40000.0f]
    EO_post_set_heightfog_diret_inscattering_exponent_float = 144,  # [0.0f, 50.0f]
    EO_post_set_heightfog_diret_inscattering_start_distance_float = 145,  # [0.0f, 40000.0f]
    EO_post_set_heightfog_scene_fade_enable = 146,
    EO_post_set_heightfog_scene_fade_start_float = 147,  # [0.0f, 200000.0f]
    EO_post_set_heightfog_scene_fade_end_float = 148,  # [0.0f, 200000.0f]
        # RayMarchFogtodo: 2024.1.15
        # HBAO
    EO_post_set_hbao_max_distance_float = 149,  # [10.0f, 400.0f]
    EO_post_set_hbao_distance_falloff_float = 150,  # [0.0f, max_distance]
    EO_post_set_hbao_radius_float = 151,  # [0.3f, 5.0f]
    EO_post_set_hbao_max_radius_pixels_int = 152,  # [16, 256]
    EO_post_set_hbao_angle_bias_float = 153,  # [0.0f, 0.5f]
    EO_post_set_hbao_blur_sharpness_float = 154,  # [0.0f, 16.0f]
    EO_post_set_hbao_only_ao_enable = 155,
    EO_post_set_hbao_enable = 156,
    EO_post_set_hbao_use_deinterleave_tex_enable = 157,
    EO_post_set_hbao_only_ssgi_enable = 158,
    EO_post_set_hbao_ssgi_enable = 159,
    EO_post_set_hbao_ssgi_max_distance_float = 160,  # [100.0f, 400.0f]
    EO_post_set_hbao_ssgi_intensity_float = 161,  # [1.0f, 10.0f]
        # Reflection
    EO_post_set_reflection_intensity_float = 162,  # [0.0f, 1.0f]
    EO_post_set_reflection_water_ibl_intensity_float = 163,  # [0.0f, 2.0f]
        # ColorGradetodo: 2024.1.15
    # Environment
        # SunLight
    EO_post_set_env_sunlight_heading_angle_float = 164,  # [-180.f, 180.f]
    EO_post_set_env_sunlight_altitude_angle_float = 165,  # [-90.f, 90.f]
    EO_post_set_env_sunlight_diffuse_color_float4 = 166,  # [0, 1]
    EO_post_set_env_sunlight_diffuse_intensity_float = 167,  # [0.f, 100.f]
    EO_post_set_env_sunlight_ambient_color_float4 = 168,  # [0, 1]
    EO_post_set_env_sunlight_sky_light_color_float4 = 169,  # [0, 1]
    EO_post_set_env_sunlight_sky_light_intensity_float = 170,  # [0.f, 100.f]
    EO_post_set_env_sunlight_common_light_color_float4 = 171,  # [0, 1]
    EO_post_set_env_sunlight_common_light_intensity_float = 172,  # [0.f, 100.f]
        # Env Map
    EO_post_set_env_map_intensity_float = 173,  # [0.f, 10.f]
    EO_post_set_env_map_saturation_float = 174,  # [0.f, 10.f]
        # Camera Light
    EO_post_set_env_camera_light_color_float4 = 175,  # [0, 1]
    EO_post_set_env_camera_light_intensity_float = 176,  # [0.0f, 10.0f]
    EO_post_set_env_camera_light_radius_float = 177,  # [0.0f, 1000.0f]
    EO_post_set_env_camera_light_length_float = 178,  # [0.0f, 1000.0f]
    EO_post_set_env_camera_light_radial_attenuation_start_float = 179,  # [0.0f, 1000.0f]
    EO_post_set_env_camera_light_axial_attenuation_start_float = 180,  # [0.0f, 1000.0f]
        # Character Light
    EO_post_set_env_character_light_diffuse_color_float4 = 181,  # [0, 1]
    EO_post_set_env_character_light_diffuse_intensity_float = 182,  # [0.f, 100.f]
    EO_post_set_env_character_light_sky_light_color_float4 = 183,  # [0, 1]
    EO_post_set_env_character_light_sky_light_intensity_float = 184,  # [0.f, 100.f]
    EO_post_set_env_character_light_common_light_color_float4 = 185,  # [0, 1]
    EO_post_set_env_character_light_common_light_intensity_float = 186,  # [0.f, 100.f]
    EO_post_set_env_character_light_ambient_color_float4 = 187,  # [0, 1]
        # Character Env Map
    EO_post_set_character_env_map_intensity_float = 188,  # [0.f, 10.f]
    EO_post_set_character_env_map_saturation_float = 189,  # [0.f, 10.f]
    EO_post_set_character_env_map_rotation_axis_y_float = 190,  # [0.f, 360.f]
        # Character Env Probe [info]
    # Performance
    EO_performance_set_simplify_user_shader_enable = 191,
    EO_performance_set_simplify_pbr_enable = 192,
    EO_performance_set_disable_alpha_test_enable = 193,
    EO_performance_set_disable_frag_shader_enable = 194,
    EO_performance_set_lod_display_enable = 195,
    EO_performance_set_pbr_channal_int = 196,  # [0, 12] DebugPBRMask
    # GPU Driven
    EO_gpu_driven_set_stop_cull_enable = 197,
    EO_gpu_driven_set_enable_hiz_oc_enable = 198,
    EO_gpu_driven_set_enable_cluster_oc_enable = 199,
    EO_gpu_driven_set_enable_shadow_enable = 200,
    EO_gpu_driven_set_tri_cluster_display_enable = 201,
    EO_gpu_driven_set_draw_cluster_box_enable = 202,
    EO_gpu_driven_set_enable_skip_compute_enable = 203,
    # Animation
    EO_animation_set_extract_frame_enable=204,
    EO_animation_set_second_order_smooth_enable = 205,
    EO_animation_set_position_smooth_enable = 206,
    EO_animation_set_rotation_smooth_enable = 207,
    EO_animation_set_frequency_float = 208,  # [0.0f, 10.0f]
    EO_animation_set_damping_float = 209,  # [0.0f, 5.0f]
    EO_animation_set_initial_response_float = 210,  # [-5.0f, 5.0f]
    EO_animation_set_animation_update_callback_enable = 211,
    EO_animation_set_animation_fusion_enable = 212,
    # CharacterFollowLight todo: 2024.1.15
    EO_count = 213


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

class C2S_SET_CAPTURE_OPTICK(PROTOCOL_HEADER):
    _fields_ = [
        ("bEnable", c_bool),
        ("uFrameLimit", c_uint),
        ("uTimeLimit", c_uint),
        ("uSpikeLimitMs", c_uint),
        ("uMemoryLimitMb", c_uint)
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

#像素采集工具数据
class KPixelCheckerStatus(Structure):
    _fields_ = [
        ("byProtocolID", c_uint),
        ("uiStatus", c_uint)
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
    def __init__(self, strDllPath, strIP, nPort, strMachineTag='Android',bTestFlag=False):
        print(strDllPath)
        self.initLogger()
        self.conn = None
        self.strIP = strIP
        self.nPort = nPort
        self.strDllPath = strDllPath
        self.list_SocketClients = []
        self.dll = CDLL(self.strDllPath)
        self.dic_dataList = {"datalist": []}
        self.dic_data={} #存放最近一次的有效数据
        self.bFirstGetData = True
        self.nFirstGetTime = 0
        self.bCollectionFlag = False
        self.t_Perf = None
        self.list_CommandRetCode = []
        self.t_CmdAndMsgRetCode = None
        self.dic_MessageRetCode = {}
        self.nErrorDataCnt = 0
        self.bStopSDK=False #是否结束SDK
        self.bPerfExceptionFlag = False
        self.bTestFlag=bTestFlag #调试模式

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
        self.nSocketIndex=0
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
        self.bStopSDK=False
        # mobile_start_app('com.seasun.jx3','730d71fc')
        bFlag = False
        # 等待连接服务器
        self.log.info("SDK connect server start")
        while not bFlag:
            bFlag = self.CreateSocketClient(self.strIP, self.nPort)
            time.sleep(1)
        self.bConnectState = True
        self.log.info("SDK connect server end")
        time.sleep(1)

    def SDK_Stop(self):
        self.bStopSDK=True
        self.__UnInit()
        time.sleep(1)

    def PerfDataCreate(self):
        # 连接服务器成功后 就可以向服务端发送
        self.SocketClientSetCollectState(self.list_SocketClients[self.nSocketIndex], True)
        time.sleep(1)
        # 发送请求后需要等待一段时间才能得到响应
        # 确保第一次获取数据成功
        ''''''
        dic_data = {}
        bFlag = False
        # IOS端现在可以采集函数耗时
        ''''''

        if self.strMachineTag == "Test":
            while not bFlag:
                #防止登录界面采集不到数据报错
                try:
                    self.SocketClientSend_GetAllPerfData_Request(self.list_SocketClients[self.nSocketIndex])
                    # 取深度性能数据
                    bFlag = self.ProcessPerfData(self.list_SocketClients[self.nSocketIndex], dic_data)
                    # 取函数耗时 ios端取不到还是要消耗对队列中的请求
                    bFlag = self.ProcessPerfData(self.list_SocketClients[self.nSocketIndex], dic_data)
                    time.sleep(1)
                except:
                    time.sleep(5)
                    pass
                # bFlag = self.ProcessPerfData(self.list_SocketClients[self.nSocketIndex], dic_data)
        else:
            getRequest = PROTOCOL_HEADER()
            getRequest.byProtocolID = C2SNetCmd.C2S_get_function_name_data.value[0]
            # print('getRequest.byProtocolID:', getRequest.byProtocolID)
            self.log.info("PerfData GetFuncionConsume start")
            while not bFlag:
                # 防止登录界面采集不到数据报错
                try:
                    self.SocketClientSend(self.list_SocketClients[self.nSocketIndex], byref(getRequest), sizeof(getRequest))
                    time.sleep(1)
                    bFlag = self.ProcessPerfData(self.list_SocketClients[self.nSocketIndex], dic_data)
                except:
                    time.sleep(5)
                    pass
                #print('test1')
            self.log.info("PerfData GetFuncionConsume end")

        bFlag = False
        # 确保能够取到数据将请求数据清空
        self.log.info("PerfData GetData start")
        while not bFlag or not dic_data:
            # 防止登录界面采集不到数据报错
            try:
                self.SocketClientSend_GetAllPerfData_Request(self.list_SocketClients[self.nSocketIndex])
                time.sleep(1)
                bFlag = self.ProcessPerfData(self.list_SocketClients[self.nSocketIndex], dic_data)
                bFlag = self.ProcessPerfData(self.list_SocketClients[self.nSocketIndex], dic_data)
                self.dic_data = dic_data
            except:
                time.sleep(5)
                pass
            #print('test2')
            #print(dic_data)
        self.log.info("PerfData GetData end")
        self.log.info("PerfDataCreate success")
        #print('GetPerfDataCreate success')

    def PerfException(self):
        # 关闭采集
        self.nErrorDataCnt = 0
        self.log.info('PerfException')
        #while not self.SocketClientSetCollectState(self.list_SocketClients[self.nSocketIndex], False):
            #time.sleep(1)
        ''''''
        self.log.info('PerfException1')
        self.SDK_Stop()
        self.log.info('PerfException2')
        self.SDK_Start()
        self.log.info('PerfException3')
        self.PerfDataCreate()
        self.log.info('PerfException4')
        self.bPerfExceptionFlag=False


    def __PerfDataStart(self, t_parent):
        self.bCollectionFlag = True
        #记录上次的有效数据
        dic_lastData={}
        strErrorInfo='data get start Error'
        self.bPerfExceptionFlag=False
        while t_parent and t_parent.is_alive():
            # 服务端存放数据buffer的大小为300 以队列形式存在 因此第一次获取到的数据为300个需要舍弃 第二次获取到的数据为准确的数据
            if self.bCollectionFlag:
                fTime = time.time()
                if not self.bPerfExceptionFlag:
                    if self.bStopSDK:
                        self.log.info("SDK exit")
                        break
                    self.SocketClientSend_GetAllPerfData_Request(self.list_SocketClients[self.nSocketIndex])
                    # time.sleep(fTime)
                    dic_data = {}
                    # fTime = time.time()
                    # 取深度性能数据
                    bResult = self.ProcessPerfData(self.list_SocketClients[self.nSocketIndex], dic_data)
                    # 取函数耗时
                    bResult = self.ProcessPerfData(self.list_SocketClients[self.nSocketIndex], dic_data)
                    if bResult and dic_data:
                        self.dic_data=dic_data
                        self.dic_dataList['datalist'].append(dic_data)
                        self.nErrorDataCnt=0
                    else:
                        dic_data=self.dic_data
                        self.dic_dataList['datalist'].append(dic_data)
                        strErrorInfo = 'data get SetTimeNode Error'
                        self.nErrorDataCnt += 1
                        if self.nErrorDataCnt >= 10:
                            self.nErrorDataCnt=0
                            strMsg = 'SDK打点后,连续获取10次数据失败'
                            #self.bPerfExceptionFlag = True
                            self.log.info(strMsg)
                            #continue
                            #self.t_Perf = threading.Thread(target=self.PerfException)
                            #self.t_Perf.setDaemon(True)
                            #self.t_Perf.start()
                        #self.log.info(strErrorInfo)
                else:
                    self.log.info("Exception Keep Heart")
                    pass
                # print('-------------------------------------------')
            else:
                # 关闭采集后 需要取出最后一次采集的数据
                self.nFirstGetTime += 1
                time.sleep(1)
                bResult = self.ProcessPerfData(self.list_SocketClients[self.nSocketIndex], dic_data)
                bResult = self.ProcessPerfData(self.list_SocketClients[self.nSocketIndex], dic_data)
                if bResult and dic_data:
                    pass
                else:
                    dic_data=self.dic_data
                self.dic_dataList['datalist'].append(dic_data)
                # print('=======================================')
                break
            # time.sleep(1)
            time.sleep(1 - time.time() + fTime)
            if self.bTestFlag:
            #print(dic_data)
                self.log.info(dic_data)
            #print(dic_data)
        self.SocketClientSetCollectState(self.list_SocketClients[self.nSocketIndex], False)
        # d = json.dumps(self.dic_dataList)
        # file = open("TempFolder/Datas.json", 'w')
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
        print("PerfDataStart success")

    def __PerfDataCreateAndStart(self,t_parent):
        self.PerfDataCreate()
        self.PerfDataStart()
        #防止线程退出 导致self.PerfDataStart()中的线程被动退出
        while t_parent and t_parent.is_alive():
            sleep_heartbeat(2)

    def PerfDataCreateAndStart(self):
        t = threading.Thread(target=self.__PerfDataCreateAndStart, args=(threading.currentThread(),))
        t.setDaemon(True)
        t.start()

    def PerfDataSetTimeNode(self):
        self.dic_dataList["datalist"] = []
        self.log.info('SDK PerfDataSetTimeNode')
        self.nErrorDataCnt=0
        pass


    def PerfDataStop(self):
        self.bCollectionFlag = False
        # 因为perf采集数据是多线程  处理数据需要时间 需要等待数据处理完后 才能结束
        while self.t_Perf and self.t_Perf.is_alive():
            time.sleep(0.5)
        self.t_Perf = None
        #关闭采集
        self.SocketClientSetCollectState(self.list_SocketClients[self.nSocketIndex], False)
        return self.dic_dataList

    def ProcessPerfData(self, nHandle, dic_data):
        nRequestType = c_int(0)
        nDataCount = c_int(0)
        nDataLen = c_int(0)
        pszRecvData = self.SocketClientGetRecvData(nHandle, byref(nRequestType), byref(nDataCount), byref(nDataLen))
        if self.bTestFlag:
            self.log.info(f"nRequestType:{nRequestType}")
            self.log.info(f"nDataLen:{nDataLen}")
            self.log.info(f'nDataCount{nDataCount}')
        # return
        if not nDataCount.value or nDataCount.value == 300:
            if self.bTestFlag:
                self.log.info(f'------------------{nDataCount.value}------------------')
            return False
        if nRequestType.value == C2SNetCmd.C2S_get_pid.value[0]:
            pData = cast(pszRecvData, POINTER(c_uint))
        if nRequestType.value == C2SNetCmd.C2S_get_pixel_checker_status.value[0]:
            pData = cast(pszRecvData, POINTER(c_uint))
            print("C2SNetCmd.C2S_get_pixel_checker_status:", pData.contents.value)
        elif nRequestType.value == C2SNetCmd.C2S_get_performance_data.value[0]:
            pData = cast(pszRecvData, POINTER(KEnginePerformance))
            dic_data['absTime'] = 0
            #if self.strMachineTag == "PC":
                #dic_data["FPS"] = 0
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
                #if self.strMachineTag == "PC":
                    #dic_data["FPS"] += pData[i].nFPS
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
            #print(dic_data)

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
                # print(f"KEnginePerformance:[{i}],uiFrameID:{pData[i].uiFrameID},uiNameID:{self.list_functionName[pData[i].uiNameID]},fDuration:{pData[i].fDuration}")
                dic_TempFuncConsumeTimeData[self.list_functionName[pData[i].uiNameID]] += pData[i].fDuration
                # #print(pData[i].fDuration)
            nLen = nDataCount.value / len(self.list_functionName)
            for strFunctionName in dic_TempFuncConsumeTimeData:
                list_FuncConsumeTimeData.append({'FuncName': strFunctionName, 'ConsumeTime': round(
                    dic_TempFuncConsumeTimeData[strFunctionName] / nLen, 6)})
                # #print('source',dic_TempFuncConsumeTimeData[strFunctionName])
                # #print(round(dic_TempFuncConsumeTimeData[strFunctionName]/nLen,6))
            #list_FuncConsumeTimeData.append({'FuncName':'KSceneRenderVK::RenderParticle','ConsumeTime':5})
            dic_data["FuncConsumeTime"] = list_FuncConsumeTimeData
            ##print(list_FuncConsumeTimeData)
        else:
            if self.bTestFlag:
                self.log.info("no data")
            return False
        if self.bTestFlag:
            self.log.info(dic_data)
        return True

    def __ProcessCmdAndMsgRetCode(self, t_parent):
        nCounter = 5
        nCurCount = 0
        while t_parent and t_parent.is_alive():
            time.sleep(0.1)
            if self.bStopSDK:
                #SDK结束后线程退出
                break
            nCurCount += 1
            # 0.1秒检查一次是否有返回值
            bRet, strInfo = self.ProcessCommandRetCode(self.list_SocketClients[self.nSocketIndex])
            if bRet:
                # print(f"strInfo:{strInfo}")
                dic_info = JsonLoad(strInfo)
                self.log.info(dic_info)
                self.list_CommandRetCode.append(dic_info)
            # 0.5秒检查一次是否有Lua插件发送的信息
            if nCurCount == 5:
                nCurCount = 0
                bRet, strInfo = self.ProcessMessageRetCode(self.list_SocketClients[self.nSocketIndex])
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

    def SetEngineOption(self, nEngineOption, nCount=0, *args):

        setRequest = C2S_SET_ENGINE_OPTION()
        # 设置请求协议类型
        setRequest.byProtocolID = C2SNetCmd.C2S_set_engine_option.value[0]
        # print(type(setRequest.byProtocolID))

        # 设置引擎开关枚举类型
        setRequest.nEngineOption=nEngineOption
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
        bRetCode = self.SocketClientSend(self.list_SocketClients[self.nSocketIndex], byref(setRequest), sizeof(setRequest))
        print(f"result {bRetCode}")

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
        bRetCode = self.SocketClientSendString(self.list_SocketClients[self.nSocketIndex], C2SNetCmd.C2S_execute_auto_test_command,c_string, len(c_string.value))
        if not self.t_CmdAndMsgRetCode:
            self.t_CmdAndMsgRetCode=threading.Thread(target=self.__ProcessCmdAndMsgRetCode,args=(threading.currentThread(),))
            self.t_CmdAndMsgRetCode.setDaemon(True)
            self.t_CmdAndMsgRetCode.start()
        self.log.info(f"{strCommand} :result {bRetCode}")
        print(f"{strCommand} :result {bRetCode}")
        return bRetCode

    def SetCaptureOptick_Start(self,nFrameLimit=0,nTimeLimit=0,nSpikeLimitMs=50,nMemoryLimitMb=0):
        setRequest = C2S_SET_CAPTURE_OPTICK()
        # 设置请求协议类型
        setRequest.byProtocolID = C2SNetCmd.C2S_set_capture_optick.value[0]
        # print(type(setRequest.byProtocolID))
        '''
        ("bEnable", c_bool),
        ("uFrameLimit", c_uint),
        ("uTimeLimit", c_uint),
        ("uSpikeLimitMs", c_uint),
        ("uMemoryLimitMb", c_uint)
        '''
        # 设置引擎开关枚举类型
        setRequest.bEnable=True
        setRequest.uFrameLimit=nFrameLimit
        setRequest.uTimeLimit =nTimeLimit
        setRequest.uSpikeLimitMs =nSpikeLimitMs
        setRequest.uMemoryLimitMb =nMemoryLimitMb
        bRetCode = self.SocketClientSend(self.list_SocketClients[self.nSocketIndex], byref(setRequest),sizeof(setRequest))
        self.log.info(f"SetCaptureOptick_Start : {bRetCode}")

    def SetCaptureOptick_Stop(self):
        setRequest = C2S_SET_CAPTURE_OPTICK()
        # 设置请求协议类型
        setRequest.byProtocolID = C2SNetCmd.C2S_set_capture_optick.value[0]
        # print(type(setRequest.byProtocolID))
        # 设置引擎开关枚举类型
        setRequest.bEnable=False
        setRequest.uFrameLimit=0
        setRequest.uTimeLimit =0
        setRequest.uSpikeLimitMs =0
        setRequest.uMemoryLimitMb =0
        bRetCode = self.SocketClientSend(self.list_SocketClients[self.nSocketIndex], byref(setRequest),sizeof(setRequest))
        self.log.info(f"SetCaptureOptick_Stop : {bRetCode}")

    def SetStartPixelChecker(self):
        setRequest = PROTOCOL_HEADER()
        # 设置请求协议类型
        setRequest.byProtocolID = C2SNetCmd.C2S_set_pixel_checker.value[0]
        bRetCode = self.SocketClientSend(self.list_SocketClients[self.nSocketIndex], byref(setRequest),sizeof(setRequest))
        self.log.info(f"SetStartPixelChecker : {bRetCode}")
        pass

    def GetPixelCheckerStatus(self):
        setRequest = PROTOCOL_HEADER()
        # 设置请求协议类型
        setRequest.byProtocolID = C2SNetCmd.C2S_get_pixel_checker_status.value[0]
        bRetCode = self.SocketClientSend(self.list_SocketClients[self.nSocketIndex], byref(setRequest),sizeof(setRequest))
        self.log.info(f"SetStartPixelChecker : {bRetCode}")
        pass



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
        #self.nSocketIndex+=1
        ''''''
        for nSocket in self.list_SocketClients:
            bResult = self.DestorySocketClient(nSocket)
        self.list_SocketClients=[]
        self.m_fnUnInitSocketClientFactory()
        # print("Unint")
        #del self.dll
        return bResult


    def initLogger(self):
        try:
            #initLog(self.__class__.__name__)
            self.log = logging.getLogger(str(os.getpid()))
        except Exception:
            info = traceback.format_exc()
            # print(info)
            raise Exception('initLogger ERROR!!')


if __name__ == '__main__':

    # 自己填入设备ID
    deviceId = '4722bd5b'
    #deviceId = '00008110-000930A414D9801E'
    ''''''
    # 给游戏客户端安装执行cmd命令服务
    if '-' in deviceId:
        strClientPath = r'/Documents/mui/Lua/Logic/Login/LoginMgr.lua'
        package = 'com.jx3.mobile'
    else:
        strClientPath = r'/sdcard/Android/data/com.seasun.jx3/files/mui/Lua/Logic/Login/LoginMgr.lua'
        package = 'com.seasun.jx3'
    strServicePath = os.path.join(SERVER_PATH, 'XGame', 'LoginMgrNew.lua')
    strLocalPath = os.path.join('TempFolder', 'LoginMgr.lua')
    # filecontrol_copyFileOrFolder(strServicePath, strLocalPath)
    # filecontrol_copyFileOrFolder(strLocalPath, strClientPath, deviceId, package)
    # 游戏客户端是否在运行
    '''
    bRet=mobile_determine_runapp(package, deviceId)
    if not bRet:
        raise Exception("no app run ")'''

    # IP地址
    deviceId='4722bd5b'
    #strIpAddress = '10.11.248.156'
    #strIpAddress = '10.11.240.228'
    #strIpAddress='10.11.224.222'
    #strIpAddress='10.11.228.54'
    strIpAddress='10.11.176.102'
    #strIpAddress='10.11.254.131'
    strIpAddress='10.11.240.149'
    strIpAddress = '10.11.240.133'
    strIpAddress = '10.11.180.112'
    strIpAddress = '10.11.146.117'
    #d="7a04353e"
    #strIpAddress=adb_get_address(d)
    #strIpAddress='10.11.250.146'
    #strIpAddress=mobile_get_address(deviceID=deviceId)
    #strIpAddress='10.11.240.133'
    print(strIpAddress)
    # 初始化SDK
    strPath='E:\XGame相关\Qsocket\Bin\SocketClientDLL.dll'
    strPathD = 'E:\XGame相关\Qsocket\Bin\SocketClientDLLd.dll'
    strPath=os.path.join(os.path.dirname(os.path.abspath(__file__)),"SocketClientDLL.dll")
    SDK = XGameSocketClient(strPath,strIpAddress, 1112, strMachineTag='Android',bTestFlag=True)

    # SDK
    #SDK.SetStartPixelChecker()
    SDK.PerfDataCreateAndStart()
    time.sleep(30)
    SDK.PerfDataStop()
    time.sleep(1)
    SDK.SDK_Stop()

    #SDK.SetCaptureOptick_Start()
    #time.sleep(20)
    #SDK.SetCaptureOptick_Stop()
    #time.sleep(2)
    #SDK.SDK_Stop()
    '''
    SDK.PerfDataCreate()
    SDK.PerfDataStart()
    time.sleep(20)
    SDK.SetEngineOption(Enum_option("EO_debug_set_sfx_enable"), 0, True)
    SDK.SDK_Stop()'''''


    #strCMD = '/gm player.SwitchMap(718,65489,102718,1066752)'
    #strCMD='/cmd UINodeControl.BtnTriggerByLable("BtnNext","完成创建")'
    #strCMD='/cmd OutputMessage("MSG_ANNOUNCE_YELLOW", "需要重启游戏, 如果已经重启请忽略")'
    #strCMD='/cmd UINodeControl.PrintBtnNode()'
    #strCMD='/cmd ReloadScript.Reload("Lua/Interface/SearchPanel/UINodeControl.lua")'
    #strCMD = '/cmd OutputMessage("MSG_ANNOUNCE_YELLOW", " node can not visable")'
    #SDK.SendCommandToSDK(strCMD)
    #time.sleep(1)
    '''
    nCnt=8
    nTime=1
    nCicleCnt=5
    for i in range(nCicleCnt):
        for i in range(1,nCnt+1):
            strCMD=f'/cmd UINodeControl.SliderSlidingInSec("SliderCount",{i},{nTime})'
            SDK.SendCommandToSDK(strCMD)
        time.sleep(nTime*4)
            #time.sleep(0.2)'''

    #strCMD='/cmd UINodeControl.BtnTriggerByLable("BtnClose","GM")'
    #strCMD = '/cmd UINodeControl.tbUINodeData[EventType.OnClick][34].node:isVisible())'
    #strCMD='/cmd OutputMessage("MSG_ANNOUNCE_YELLOW", tostring(UINodeControl.tbUINodeData[EventType.OnClick][13].node:isVisible()))'
    #strCMD='/cmd OutputMessage("MSG_ANNOUNCE_YELLOW", tostring(UINodeControl.tbUINodeData[EventType.OnClick][13].node:getParent():getName()))'
    #SendGMCommand("")
    #strCMD = '/cmd SetCameraStatus(2000, 1, -4.72, -0.217)'
    #strCMD='/gm player.SetPosition(21731, 65654, 1141056)'
    #SDK.SendCommandToSDK(strCMD)
    #SDK.SetEngineOption(Enum_option("EO_post_set_env_weather_rain_surfaceWater_enable"), 0, False)
    #SDK.SetEngineOption(Enum_option("EO_post_set_env_weather_screen_rain_drop_enable"), 0, False)
    #SDK.SetEngineOption(Enum_option("EO_post_set_env_weather_fall_enable"), 0, False)
    #SDK.SetEngineOption(Enum_option("EO_post_set_env_weather_splash_quality_int"),1,2)
    #time.sleep(2)
    #SDK.PerfDataStop()
    #SDK.SDK_Stop()
    d="00008110-001C60A40CA0401E"
    #copyPerfeye("Perfeye-2.3.10-release",d)

    nKungfu = 38
    nSkillID = 0
    # nSkillID = 0
    strMapCopyIndex = 8
    # strMapCopyIndex = 8
    # url = f"http://10.11.65.138:5006/logoutRobot?mapCopyIndex={strMapCopyIndex}"
    # response = requests.request("GET", url)
    '''
    #OnUseSkill(24990,1)
    url = f"http://10.11.65.138:5007/SwitchSkill?kungfu={nKungfu}&skillID={nSkillID}&mapCopyIndex={strMapCopyIndex}"
    print(url)
    response = requests.request("GET", url)
    dic_res = json.loads(response.text)
    print(dic_res)
    if dic_res['state'] == 1:
        pass
    else:
        raise Exception('http SwitchSkill fail')
    s = ''
    print(s.split(','))


    numbers = [20837, 19737, 20641, 20281, 20049, 20065, 20715, 20053
    ]

    list_map = [3, 4, 5, 6, 8]
    for id in numbers:
        for nIndex in list_map:
            nKungfu = 39
            nSkillID = id
            strMapCopyIndex = nIndex
            url = f"http://10.11.65.138:5007/SwitchSkill?kungfu={nKungfu}&skillID={nSkillID}&mapCopyIndex={strMapCopyIndex}"
            print(url)
            response = requests.request("GET", url)
            dic_res = json.loads(response.text)
            print(dic_res)
            if dic_res['state'] == 1:
                pass
            else:
                raise Exception('http SwitchSkill fail')
            s = ''
            print(s.split(','))
            time.sleep(1)
        time.sleep(60)'''