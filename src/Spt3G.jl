module Spt3G

using boost_jll
using boostpython_jll
using CMake_jll
using FFTW_jll
using FLAC_jll
using GSL_jll
using HDF5_jll
using NetCDF_jll
using Python_jll


# We set these relevant variables:
# 
#  * PYTHON: the path to the Python executable used by
#    Pkg.build("PyCall")
#  * PYCALL_JL_RUNTIME_PYTHON/JULIA_PYTHONCALL_EXE: the path to the
#    Python executable used by PyCall/PythonCall at runtime (even for
#    Pycall can be different from the PYTHON it got built with but it
#    must link to the same libpython.so, which ours does)
#  * LD_LIBRARY_PATH: shared library search paths for linking
# 
# None of these are actually needed if all we care about is calling
# spt3g_software from Julia (the main use case for this package).
# That's handled by the much more robust linking that Julia does when
# we load the JLLs above. 
# 
# But setting these here is still nice because it makes
# Pkg.build("PyCall") work without having to set any environment
# variables by hand, and it also allows spt3g_software to be used from
# Python without Julia at all. 
# 
# Variables are set by writing them to a .env file which is sourced
# (thanks to the poetry dotenv plugin) whenever we activate the
# environment, and Julia runtime in __init__. This is redundant if we
# run Julia with the environment active, but e.g. Jupyter kernels
# don't do that, so it's still useful in both places. 
# 
# Note setting LD_LIBRARY_PATH in __init__ will have no effect on the
# already-running process, but will have an effect on any spawned
# subprocesses (e.g. the one spawned by Pkg.build("PyCall"))

function __init__()
    try
        ENV["PYCALL_JL_RUNTIME_PYTHON"] = ENV["JULIA_PYTHONCALL_EXE"] = poetry_python_executable()
    catch
    end
    ENV["JULIA_CONDAPKG_BACKEND"] = "Null"
    ENV["PYTHON"] = Python_jll.python_path
    ENV["LD_LIBRARY_PATH"] = Python_jll.LIBPATH[] * ":" * get(ENV, "LD_LIBRARY_PATH", "")
end

function install_dot_env_file()
    projdir = dirname(Base.active_project())
    if any(occursin(path, projdir) for path in DEPOT_PATH)
        error("install_dot_env_file() should be called from a project environment, not the global one")
    else
        open(joinpath(projdir, ".env"), "w") do io
            println(io, "PYTHON=", Python_jll.python_path)
            _poetry_python_executable = try
                poetry_python_executable()
            catch
                " # error calling `poetry env info`, run `julia -e 'using Spt3G; Spt3G.poetry_python_executable(stderr)'` to see the error"
            end
            println(io, "JULIA_PYTHONCALL_EXE=", _poetry_python_executable)
            println(io, "PYCALL_JL_RUNTIME_PYTHON=", _poetry_python_executable)
            println(io, "LD_LIBRARY_PATH=", join(libpath(),":"), raw":${LD_LIBRARY_PATH}")
            println(io, "JULIA_CONDAPKG_BACKEND=", "Null")
        end
    end
end

function poetry_python_executable(stderr=devnull)
    projdir = dirname(Base.active_project())
    # remove everything we've added since `poetry` below is outside the virtual environment
    LD_LIBRARY_PATH = replace(get(ENV, "LD_LIBRARY_PATH", ""), [p => "" for p in libpath()]...)
    cmd = pipeline(addenv(Cmd(`poetry env info -p`, dir=projdir), "PYTHONHOME" => nothing, "LD_LIBRARY_PATH" => LD_LIBRARY_PATH); stderr)
    return joinpath(strip(read(cmd, String)), "bin/python")
end

function python()
    run(addenv(`$(Python_jll.python()) $(ARGS)`, "SSL_CERT_DIR" => get(ENV, "SSL_CERT_DIR", "/etc/ssl/certs")))
end

function cmake_flags()
    join(["-D$(k)=$(v)" for (k, v) in pairs(cmake_flags_dict())], " ")
end

function cmake_flags_dict(prefer_no_cray_wrappers=true)

    # Julia has a separate boostpython_jll package for Boost python
    # bindings, but cmake can only take a single boost lib
    # directory, so copy it into the main boost_jll directory
    libboost_python = joinpath(boost_jll.artifact_dir,  "lib/libboost_python310.so")
    if !isfile(libboost_python)
        symlink(joinpath(boostpython_jll.artifact_dir,  "lib/libboost_python310.so"), libboost_python)
    end

    flags = Dict(
        
        # CONFIG-mode find_package may find user-compiled
        # *config.cmake files in any of a number of places (e.g.
        # $HOME/lib would be standard for Boost), so use MODULE-mode
        # instead, which respects the manual paths we specify below
        # always pointing to JLLs
        :CMAKE_FIND_PACKAGE_PREFER_CONFIG => "FALSE",

        :Python_EXECUTABLE     => Python_jll.python_path,

        :BOOST_ROOT            => boost_jll.artifact_dir,        
        :BOOST_INCLUDEDIR      => joinpath(boost_jll.artifact_dir,  "include"),
        :BOOST_LIBRARYDIR      => joinpath(boost_jll.artifact_dir,  "lib"),
        :Boost_PYTHON_TYPE     => "python310",
        # Julia's boost_jll package is built without bzip2 support,
        # spt3g_software has this override in that case:
        :WITH_BZIP2            => "FALSE",
        
        :GSL_INCLUDES          => joinpath(GSL_jll.artifact_dir,    "include"),
        :GSL_LIB               => joinpath(GSL_jll.artifact_dir,    "lib/libgsl.so"),
        :GSL_CBLAS_LIB         => joinpath(GSL_jll.artifact_dir,    "lib/libgslcblas.so"),
        
        :FFTW_INCLUDES         => joinpath(FFTW_jll.artifact_dir,   "include"),
        :FFTW_LIBRARIES        => joinpath(FFTW_jll.artifact_dir,   "lib/libfftw3.so"),
        :FFTW_THREADS_LIBRARY  => joinpath(FFTW_jll.artifact_dir,   "lib/libfftw3.so"),
        
        :NETCDF_INCLUDES       => joinpath(NetCDF_jll.artifact_dir, "include"),
        :NETCDF_LIBRARIES      => joinpath(NetCDF_jll.artifact_dir, "lib/libnetcdf.so"),
        
        :HDF5_INCLUDES         => joinpath(HDF5_jll.artifact_dir,   "include"),
        :HDF5_LIBRARIES        => joinpath(HDF5_jll.artifact_dir,   "lib/libhdf5.so"),
        :HDF5_HL_LIBRARIES     => joinpath(HDF5_jll.artifact_dir,   "lib/libhdf5_hl.so"),

        :FLAC_INCLUDE_DIR      => joinpath(FLAC_jll.artifact_dir,   "include"),
        :FLAC_LIBRARIES        => joinpath(FLAC_jll.artifact_dir,   "lib/libFLAC.so"),

        # cmake only knows about the "top-level" dependencies listed
        # above. while compiling, transitive dependencies (deps of
        # deps) wouldn't be found, so we encode the entire tree of
        # JLL-based dependencies in the RPATH, and tell cmake to build
        # with this RPATH. this doesn't matter at Julia runtime, since
        # the JLLs will load everything correctly first, so this is
        # just needed at compile-time. however, it does also make the
        # build usable from Python, which is convenient.
        :CMAKE_BUILD_WITH_INSTALL_RPATH => "TRUE",
        :CMAKE_INSTALL_RPATH => "'\$ORIGIN:$(join(libpath(), ";"))'",

        # this links with RPATH instead of RUNPATH. only RPATH also
        # handles transitive dependencies (this seems buggy in testing
        # tbh, but this is not needed for the Julia functionality, but
        # at least it makes it more likely to also work directly from
        # Python)
        :CMAKE_SHARED_LINKER_FLAGS => "-Wl,--disable-new-dtags",

    )

    # on Cray systems, the default compilers would be Cray wrappers of
    # GNU compilers but these add extra libraries which we dont need
    # and which are more brittle, so instead use the GNU compilers directly
    if prefer_no_cray_wrappers
        if get(ENV, "CC", "") == "" && success(run(pipeline(`which gcc`, stderr=devnull, stdout=devnull), wait=false))
            flags[:CMAKE_C_COMPILER] = "gcc"
        end
        if get(ENV, "CXX", "") == "" && success(run(pipeline(`which g++`, stderr=devnull, stdout=devnull), wait=false))
            flags[:CMAKE_CXX_COMPILER] = "g++"
        end
    end

    flags

end

# this is every .julia/artifacts/<hash>/lib directory of every JLL we
# need and for all of their transitive dependencies
function libpath()
    Set(vcat(
        Python_jll.LIBPATH_list,
        [joinpath(Python_jll.artifact_dir, "lib/python3.10/lib-dynload")],
        boost_jll.LIBPATH_list, 
        GSL_jll.LIBPATH_list, 
        FFTW_jll.LIBPATH_list, 
        NetCDF_jll.LIBPATH_list, 
        HDF5_jll.LIBPATH_list, 
        FLAC_jll.LIBPATH_list
    ))
end


function cmake()
    `$(CMake_jll.cmake()) $(["-D$(k)=$(v)" for (k, v) in pairs(cmake_flags_dict())])`
end

end