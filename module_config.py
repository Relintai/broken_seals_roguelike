
engine_repository = [ ['https://github.com/godotengine/godot.git', 'git@github.com:godotengine/godot.git'], 'engine', '' ]

module_repositories = [
    [ ['https://github.com/Relintai/entity_spell_system.git', 'git@github.com:Relintai/entity_spell_system.git'], 'entity_spell_system', '' ],
    [ ['https://github.com/Relintai/ui_extensions.git', 'git@github.com:Relintai/ui_extensions.git'], 'ui_extensions', '' ],
    [ ['https://github.com/Relintai/texture_packer.git', 'git@github.com:Relintai/texture_packer.git'], 'texture_packer', '' ],
    [ ['https://github.com/Relintai/godot_fastnoise.git', 'git@github.com:Relintai/godot_fastnoise.git'], 'fastnoise', '' ],
    [ ['https://github.com/Relintai/thread_pool.git', 'git@github.com:Relintai/thread_pool.git'], 'thread_pool', '' ],
]

removed_modules = [
    [ ['https://github.com/Relintai/world_generator.git', 'git@github.com:Relintai/world_generator.git'], 'world_generator', '' ],
]

addon_repositories = [
]

third_party_addon_repositories = [
]

godot_branch = '3.x'

slim_args = 'module_webm_enabled=no module_arkit_enabled=no module_visual_script_enabled=no module_gdnative_enabled=no module_mobile_vr_enabled=no module_theora_enabled=no module_xatlas_unwrap_enabled=no no_editor_splash=yes module_bullet_enabled=no module_camera_enabled=no module_csg_enabled=no module_denoise_enabled=no module_fbx_enabled=no module_gridmap_enabled=no module_hdr_enabled=no module_lightmapper_cpu_enabled=no module_raycast_enabled=no module_recast_enabled=no module_vhacd_enabled=no module_webxr_enabled=no'
