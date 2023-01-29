# Spt3GSoftwareBuilder.jl

A Julia package which compiles spt3g_software linked to Julia's own Boost, GSL, FFTW, FLAC, HDF5, and NetCDF libraries. 

This way, you don't need to install any of these by hand, and spt3g_software easily builds anywhere you can run Julia. 

## Usage

Add this package to any Julia package environment:
```
pkg> add Spt3GSoftwareBuilder
```

Then build spt3g_software like:
```bash
git clone https://github.com/SouthPoleTelescope/spt3g_software.git
mkdir spt_3gsoftware/build
cd spt3g_software/build
cmake $(julia -e "using Spt3GSoftwareBuilder; print(Spt3GSoftwareBuilder.cmake_flags())") ..
make
```

Note, you may need `julia --project=/path/to/environment ...` above to activate the environment where you installed Spt3GSoftwareBuilder, if its not active by default. 

Now from Julia:

```julia
julia> using PyCall, Spt3GSoftwareBuilder # order is important here
julia> py"""
       import spt3g
       """
```

## Notes

The Dockerfile in this repo is a demonstration.