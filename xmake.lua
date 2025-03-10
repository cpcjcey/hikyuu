set_xmakever("2.5.4")

-- project
set_project("hikyuu")

add_rules("mode.debug", "mode.release")
if not is_plat("windows") then 
    add_rules("mode.coverage", "mode.asan", "mode.msan", "mode.tsan", "mode.lsan")
end

-- version
set_version("1.2.7", {build="%Y%m%d%H%M"})
set_configvar("LOG_ACTIVE_LEVEL", 0)  -- 激活的日志级别 
--if is_mode("debug") then
--    set_configvar("LOG_ACTIVE_LEVEL", 0)  -- 激活的日志级别 
--else 
--    set_configvar("LOG_ACTIVE_LEVEL", 2)  -- 激活的日志级别 
--end
set_configvar("USE_SPDLOG_LOGGER", 1) -- 是否使用spdlog作为日志输出
set_configvar("USE_SPDLOG_ASYNC_LOGGER", 0) -- 使用异步的spdlog
set_configvar("CHECK_ACCESS_BOUND", 1)
if is_plat("macosx") then 
    set_configvar("SUPPORT_SERIALIZATION", 0)
else
    set_configvar("SUPPORT_SERIALIZATION", is_mode("release") and 1 or 0)
end
set_configvar("SUPPORT_TEXT_ARCHIVE", 0)
set_configvar("SUPPORT_XML_ARCHIVE", 1)
set_configvar("SUPPORT_BINARY_ARCHIVE", 1)
set_configvar("HKU_DISABLE_ASSERT", 0)

-- set warning all as error
if is_plat("windows") then
    set_warnings("all", "error")
else
    set_warnings("all")
end

-- set language: C99, c++ standard
set_languages("cxx17", "C99")

local hdf5_version = "1.12.2"
local mysql_version = "8.0.31"
if is_plat("windows") then
    mysql_version = "8.0.21"
end

add_repositories("project-repo hikyuu_extern_libs")
if is_plat("windows") then
    -- add_repositories("project-repo hikyuu_extern_libs")
    if is_mode("release") then
        add_requires("hdf5 " .. hdf5_version)
    else
        add_requires("hdf5_D " .. hdf5_version)
    end
    add_requires("mysql " .. mysql_version)
elseif is_plat("linux") then
    add_requires("hdf5 " .. hdf5_version, {system = false})
    add_requires("mysql " .. mysql_version, {system = false})
elseif is_plat("macosx") then
    add_requires("brew::hdf5") 
end

-- add_requires("fmt 8.1.1", {system=false, configs = {header_only = true}})
add_requires("spdlog", {system=false, configs = {header_only = true, fmt_external=true, vs_runtime = "MD"}})
add_requireconfs("spdlog.fmt", {override = true, version = "8.1.1", configs = {header_only = true}})
add_requires("sqlite3", {system=false, configs = {shared=true, vs_runtime="MD", cxflags="-fPIC"}})
add_requires("flatbuffers", {system=false, configs = {vs_runtime="MD"}})
add_requires("nng", {system=false, configs = {vs_runtime="MD", cxflags="-fPIC"}})
add_requires("nlohmann_json", {system=false})
add_requires("cpp-httplib", {system=false})
add_requires("zlib", {system=false})

add_defines("SPDLOG_DISABLE_DEFAULT_LOGGER")  -- 禁用 spdlog 默认 logger

set_objectdir("$(buildir)/$(mode)/$(plat)/$(arch)/.objs")
set_targetdir("$(buildir)/$(mode)/$(plat)/$(arch)/lib")

add_includedirs("$(env BOOST_ROOT)")
add_linkdirs("$(env BOOST_LIB)")

-- modifed to use boost static library, except boost.python, serialization
--add_defines("BOOST_ALL_DYN_LINK")
add_defines("BOOST_SERIALIZATION_DYN_LINK")

-- is release now
if is_mode("release") then
    if is_plat("windows") then
        --Unix-like systems hidden symbols will cause the link dynamic libraries to failed!
        set_symbols("hidden") 
    end
end

-- for the windows platform (msvc)
if is_plat("windows") then 
    -- add some defines only for windows
    add_defines("NOCRYPT", "NOGDI")
    add_cxflags("-EHsc", "/Zc:__cplusplus", "/utf-8")
    add_cxflags("-wd4819")  --template dll export warning
    add_defines("WIN32_LEAN_AND_MEAN")
    if is_mode("release") then
        add_cxflags("-MD") 
    elseif is_mode("debug") then
        add_cxflags("-Gs", "-RTC1", "/bigobj") 
        add_cxflags("-MDd")
    end
end 

if not is_plat("windows") then
    -- disable some compiler errors
    add_cxflags("-Wno-error=deprecated-declarations", "-fno-strict-aliasing")
    add_cxflags("-ftemplate-depth=1023", "-pthread")
    add_shflags("-pthread")
    add_ldflags("-pthread")
end

--add_vectorexts("sse", "sse2", "sse3", "ssse3", "mmx", "avx")

add_subdirs("./hikyuu_cpp/hikyuu")
add_subdirs("./hikyuu_pywrap")
add_subdirs("./hikyuu_cpp/unit_test")
add_subdirs("./hikyuu_cpp/demo")
add_subdirs("./hikyuu_cpp/hikyuu_server")

before_install("scripts.before_install")
on_install("scripts.on_install")
before_run("scripts.before_run")
