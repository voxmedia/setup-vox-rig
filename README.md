This bash script will setup the development environment and tools necessary for working on Storytelling
Rig projects. It's made to run on Mac OS only, and usually needs updates for every new version of Mac OS.

To run this script, enter this into your terminal:

```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/voxmedia/setup-vox-rig/master/setup-vox-middleman.sh)"
```

This script can be run repeatedly and will update your environment if necessary and will correct some
common problems in your environment.

The environment that is setup by this script can coexist with most tools and other environment setups.

**Things this script does:**
- checks for github ssh setup and warns if it is missing
- makes sure xcode tools are installed
- Makes sure rvm is not installed
- Makes sure brew is installed
- Makes sure git and other important command line tools and libraries are installed through brew
- Adds itself as a command to your environment, so you can run `setup-vox-middleman` to update
- Makes sure rbenv and ruby-build are installed and up-to-date
- Deletes errant .ruby-version file in your home directory
- Fixes permissions on ~/.rbenv
- Installs a favorite ruby version, which matches the version used on Vox Media servers (currently 2.5.5)
- Installs bundler and configures it to properly install rubyracer, a requirement for Middleman
- Adds environment variables needed for connecting to Rig services like Autotune and Kinto
