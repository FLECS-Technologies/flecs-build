# Overview
Common build tools, CMake modules, package templates and Docker images used to build FLECS and its extensions.

# flecs-build Docker image
This image is the basis for build flecsd, our FLECS core located at [flecs-public](https://github.com/FLECS-Technologies/flecs-public). It contains all tools and prebuilt dependencies to make building FLECS for all architectures as easy as it can get.

If, however, you want to build everything from scratch, refer to its [Dockerfile](https://github.com/FLECS-Technologies/flecs-build/tree/main/docker/flecs-build/Dockerfile) and let's start breaking down its structure.

## Structure
### stage-1
Docker multi-stage builds are used to ensure fast, reproducible builds as well as incremental builds when single dependencies are updated.

The initial `stage-1` is the common grounds to start form. FLECS uses Debian as base due to its excellent long-term support, the ready availability of cross-toolchains and its reasonably up-to-date package repositories.

`stage-1` contains all (cross-)toolchains, build tools and utilities that will later also be required to build FLECS itself. `stage-1-make` is an extension for 3rd party dependencies built with `make`. As FLECS itself does not require `make` to be built, this is a separate build stage that will be discarded for the final image

### first level dependencies
All 3rd party dependencies that are self-contained, i.e. not depending any of the other externals, are built first. They can be identified by the `FROM stage-1` command in the Dockerfile. Each external follow the same structure:

1. `${external}-downloader` will acquire (and optionally verify) the source code of each external and extract it to `/usr/src`
2. `${external}-build-${arch}` will configure, build and install the dependency to `/usr/local`
3. `external-${external}` will copy out the build artifacts, discarding the intermediate layers required for building

### stage-2
`stage-2` accumulates the `/usr/local` directories of all first-level dependencies to allow building externals that depend on them. Each follows the same structure, only stating `FROM stage-2` as commands.

### stage-n
This process is repeated until all dependencies are resolved and a final stage is ready to be packaged as `flecs-build` image.

## Building
```bash
cd docker/flecs-build
../build-image.sh --image flecs-build --arch amd64
```

will generate a `flecs-build:latest-amd64` image with all dependencies built from source.

## Customization
To build from scratch with your custom toolchain, the least invasive way is to only provide custom toolchain files in `cmake/toolchains/${arch.cmake}`. Therefore, after cloning `flecs-build` in the Dockerfile, `ADD` them to the image to use your toolchain(s) throughout the build.

Also, feel free to simply remove the `${external}-build-${arch}` targets for all architectures you do not need. As of now, this is unfortunately the only way to exclude architectures from the build.

**Careful**

There is currently one additional reference to the compiler in `RUSTFLAGS="-Clinker=` used to build the zenoh-c dependency. Make sure to replace this by the name of your C compiler as well.

Afterwards, trigger the [build](https://github.com/FLECS-Technologies/flecs-build/blob/main/README.md#building) again to receive a Docker image based on your custom toolchain.

## Next steps
Now that you have built the official or your custom version of `flecs-build`, head on to [flecs-public](https://github.com/FLECS-Technologies/flecs-public#the-recommended-way) to use your image to build FLECS.