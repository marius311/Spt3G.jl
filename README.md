# Spt3G.jl

Build spt3g_software linked to Julia's own Python, Boost, GSL, FFTW, FLAC, HDF5, and NetCDF binary libraries. 

This removes the need to install any of these libraries by-hand, and also produces an spt3g_software package which is binary-compatible with Julia and its libraries. 

## Requirements

The only requirements on the system are:

* Julia
* C++ compilers
* Make and CMake

The following are _not_ needed. Its fine to have them, but if you have system versions of them, they will not be used:

* Python, Boost, GSL, FFTW, FLAC, HDF5, and NetCDF

## Usage

The following set of commands should build a fully working spt3g_software and allow you to call it from Julia via PyCall:

```bash
# recommend having this in your bashrc, but if you dont:
export JULIA_PROJECT=@.

# make empty folder which will serve as the Julia and Poetry environments
mkdir temp && cd temp
julia --startup-file=no --project=. -e 'using Pkg; Pkg.add(url="https://github.com/marius311/Spt3G.jl")'

# clone and build spt3g_software
git clone https://github.com/SouthPoleTelescope/spt3g_software.git -b install_improvements
mkdir spt3g_software/build && pushd spt3g_software/build
cmake $(julia --startup-file=no -e "using Spt3G; print(Spt3G.cmake_flags())") ..
make -j 8 # or however many processors you want

# if you already have a Python and poetry you can skip these steps
# (the virtual environment will use Python via the Julia package regardless)
alias python="julia --startup-file=no --project=$(pwd) -e \"using Spt3G; Spt3G.python()\" --"
alias poetry="python -m poetry"
python -m ensurepip
python -m pip install poetry

# need this plugin 
poetry self add poetry-dotenv-plugin

# set up a Python virtual environment to install the built spt3g_software into
# (any other venv-compatible thing would work too)
popd
poetry init -n --python ^3.8
poetry env use $(julia -e "using Spt3G; print(Spt3G.Python_jll.python_path)")
poetry add -e spt3g_software/build
poetry run julia -e 'using Spt3G; Spt3G.install_dot_env_file()'
poetry run julia -e 'using Pkg; Pkg.add("PyCall")'
```

Now run `julia --startup-file=no` and you should be able to do:

```julia
julia> using Spt3G, PyCall

julia> py"""
       import spt3g.core
       """
```

(you can remove the `--startup-file=no`, but if it errors when you do, check your startup file for culprits, note you always need to load `Spt3G` _first_ in any session).


## Notes

* The Python in the virtual environment is fully working when called from Julia, but can hit some link errors if called from the command line with certain packages (e.g. `poetry run python -c "import ctypes"` won't work), but you can fix it by running this once from the environment folder:

  ```bash
  echo "export LD_LIBRARY_PATH=\"\$(julia --project=$(pwd) -e \"using Python_jll; print(Python_jll.LIBPATH[])\"):\$LD_LIBRARY_PATH\"" >> $(poetry env info --path)/bin/activate
  ```

* Right now you need the spt3g_software `install_improvements` branch but hopefully this can get merged then any later spt3g_software commit will be fine.

* The Dockerfile in this repo is a demonstration of everything working if curious. 