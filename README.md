# Spt3G.jl

Build spt3g_software linked to Julia's own Python, Boost, GSL, FFTW, FLAC, HDF5, and NetCDF binary libraries. 

This removes the need to install any of these libraries by-hand, and also produces an spt3g_software package which is binary-compatible with Julia and its libraries. 

## Requirements

The only requirements on the system are:

* Julia
* Python
* C++ compilers
* Make and CMake

Note that Python is only needed to manage virtual environments (via Poetry), spt3g_software will use Julia's internal Python package and all spt3g_software Python dependencies are installed automatically. 

The following spt3g_software binary dependencies are also _not_ needed. Its fine to have them, but if you have system versions of them, they will not be used:

* Boost, GSL, FFTW, FLAC, HDF5, and NetCDF


## Usage

First, ensure you have Poetry installed, which we will use to manage the Python virtual environment housing spt3g_software and its Python dependencies:

```bash
curl -sSL https://install.python-poetry.org | python3 -
export PATH=$HOME/.local/bin:$PATH # if not already in your bashrc
poetry self add poetry-dotenv-plugin
``` 

Now, build spt3g_software and set up PyCall to use it:

```bash
# recommend having this in your bashrc, but if you dont:
export JULIA_PROJECT=@.

# make empty folder which will serve as the Julia and Poetry environments
mkdir temp && cd temp
julia --startup-file=no --project=. -e 'using Pkg; Pkg.add(url="https://github.com/marius311/Spt3G.jl")'

# clone and build spt3g_software
git clone https://github.com/SouthPoleTelescope/spt3g_software.git -b spt3g_jl
mkdir spt3g_software/build && pushd spt3g_software/build
julia -e 'using Spt3G; run(`$(Spt3G.cmake()) $ARGS`)' -- ../spt3g_software
make -j 8 # or however many processors you want
popd

# set up a Python virtual environment to install the built spt3g_software into
# (any other PEP517-compatible thing would work too)
poetry init -n --python ^3.8
poetry env use $(julia -e "using Spt3G; print(Spt3G.Python_jll.python_path)")
poetry add -e spt3g_software/build
poetry run julia -e 'using Spt3G; Spt3G.install_dot_env_file()'
poetry run julia -e 'using Pkg; Pkg.add("PyCall")'
poetry run julia -e 'using Pkg; Pkg.build("PyCall")'
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

* If you had previously installed Poetry with `pip install poetry`, turns out thats wrong and causes `poetry self add poetry-dotenv-plugin` to fail. Do a `pip uninstall poetry` then install it with the command above. 

* To use spt3g_software directly from Python, you need to have the Poetry environment active (`poetry shell` or `poetry run python ...`). You can use everything from Julia regardless if the environment is active, as long as you do you `using Spt3G` before `using PyCall`.

* Right now you need the spt3g_software `spt3g_jl` branch but hopefully this can get merged then any later spt3g_software commit will be fine.

* The Dockerfile in this repo is a demonstration of everything working if curious. 