import GSL_jll # For shared libraries and header files
import PackageCompiler as PC # For finding cc/c++ compiler and utils

const _PACKAGE_DIR = dirname(dirname(pathof(SampleShots)))
const _SRC_NAME = "levs_sampler"
const _SAMPLE_LIB_PATH = joinpath(_PACKAGE_DIR, "lib", "$_SRC_NAME." * Libc.Libdl.dlext)

function ensure_cpp_lib_compiled()
    isfile(_SAMPLE_LIB_PATH) && return
    @warn "$_SAMPLE_LIB_PATH not found."
    compile_cpp_lib()
end

function fpic_flag()
    return Sys.isunix() ? "-fPIC" : ""
end

function compile_cpp_lib()
    # Escaping is probably not done correctly here
    sample_src_path = joinpath(_PACKAGE_DIR, "src", "$_SRC_NAME.cc")
    include_path = Base.shell_split(PC.shell_escape(joinpath(GSL_jll.artifact_dir, "include")))
    lib_path = PC.shell_escape(joinpath(GSL_jll.artifact_dir, "lib"))
    libs = Base.shell_split("-L $lib_path -lgsl  -lgslcblas")
    cflags = Base.shell_split("-Wall -march=native -O3")
    cmd = `$(PC.bitflag()) $(cflags) $(fpic_flag()) -I$include_path $(libs) -shared -rdynamic  -o $_SAMPLE_LIB_PATH $sample_src_path  -Wl,-rpath,$lib_path`
    println(cmd)
    @info "Compiling C++ code."
    try
        PC.run_compiler(cmd; cplusplus=true)
    catch
        nothing
    end
    if isfile(_SAMPLE_LIB_PATH)
        @info "C++ successfully compiled."
    else
        @warn """Compilation of C++ code failed. Only native Julia code will be available for testing.
         Command line arguments to compiler were: $cmd
                """
    end
end
