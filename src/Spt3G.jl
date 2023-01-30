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


function cmake_flags_dict()

    # Julia has a separate boostpython_jll package for Boost python
    # bindings, but cmake can only take a single boost lib
    # directory, so copy it into the main boost_jll directory
    libboost_python = joinpath(boost_jll.artifact_dir,  "lib/libboost_python38.so")
    if !isfile(libboost_python)
        symlink(joinpath(boostpython_jll.artifact_dir,  "lib/libboost_python38.so"), libboost_python)
    end

    Dict(

        :Python_EXECUTABLE     => Python_jll.python_path,

        :BOOST_ROOT            => boost_jll.artifact_dir,        
        :BOOST_INCLUDEDIR      => joinpath(boost_jll.artifact_dir,  "include"),
        :BOOST_LIBRARYDIR      => joinpath(boost_jll.artifact_dir,  "lib"),
        :Boost_NO_SYSTEM_PATHS => "ON",
        
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

function cmake_flags()
    join(map(collect(pairs(cmake_flags_dict()))) do (k, v)
        "-D$(k)=$(v)"
    end, " ")
end

end