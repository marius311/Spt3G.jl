module Spt3G

using boost_jll
using boostpython_jll
using FFTW_jll
using FLAC_jll
using GSL_jll
using HDF5_jll
using NetCDF_jll
using Python_jll


function __init__()
    # has no effect in the current process, but makes it so spawned
    # subprocesses (like the kind used by PyCall when
    # PYCALL_JL_RUNTIME_PYTHON is set) will find Python shared
    # libraries
    ENV["LD_LIBRARY_PATH"] = Python_jll.LIBPATH[] * ":" * get(ENV, "LD_LIBRARY_PATH", "")
end


function python()
    run(`$(Python_jll.python()) $(ARGS)`)
end

function cmake_flags()
    join(["-D$(k)=$(v)" for (k, v) in pairs(cmake_flags_dict())], " ")
end

function cmake_flags_dict()

    # Julia has a separate boostpython_jll package for Boost python
    # bindings, but cmake can only take a single boost lib
    # directory, so copy it into the main boost_jll directory
    libboost_python = joinpath(boost_jll.artifact_dir,  "lib/libboost_python38.so")
    if !isfile(libboost_python)
        symlink(joinpath(boostpython_jll.artifact_dir,  "lib/libboost_python38.so"), libboost_python)
    end

    Dict(
        
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
        :Boost_PYTHON_TYPE     => "python38",
        
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
        # above. while compiling, _their_ shared-library dependencies
        # wouldn't be found, so we encode the entire tree of JLL-based
        # dependencies in the RPATH, and tell cmake to build with this
        # RPATH. at (Julia) runtime, this doesn't matter since
        # Spt3G.jl will load everything correctly first, so this is
        # just needed at compile-time. however, it does also make the
        # build usable from Python, which is convenient.
        :CMAKE_BUILD_WITH_INSTALL_RPATH => "TRUE",
        :CMAKE_INSTALL_RPATH => "'\$ORIGIN:$(join(Set(vcat(
            boost_jll.LIBPATH_list, 
            GSL_jll.LIBPATH_list, 
            FFTW_jll.LIBPATH_list, 
            NetCDF_jll.LIBPATH_list, 
            HDF5_jll.LIBPATH_list, 
            FLAC_jll.LIBPATH_list)
        ), ";"))'"        
    )

end

end