#!/bin/bash
#
# To run this script, enter this into your terminal:
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/voxmedia/setup-vox-rig/master/setup-vox-middleman.sh)"
set -e

FAVORITE_RUBY=2.5.5

echo Setting up Vox Media Middleman rig.
echo

trap "exit 1" SIGINT;

if [ ! -f ~/.ssh/id_rsa ]; then
  echo
  echo
  echo Missing ssh private key ~/.ssh/id_rsa. Please setup github access
  echo for both HTTPS and SSH. Instructions here:
  echo '  https://help.github.com/articles/set-up-git/#setting-up-git'
  echo
  echo After you setup github, please run setup-vox-middleman to finish
  echo setting up your computer.
  exit 1
fi

if ! grep 'github.com' ~/.ssh/known_hosts >/dev/null; then
  ssh-keyscan github.com >> ~/.ssh/known_hosts
fi

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

if xcode-select --install >/dev/null 2>&1; then
  echo
  echo "Once you've completed the Xcode install, press any key to continue"
  read -n 1 -s
fi

# make sure we have rbenv, and not rvm
if hash rvm 2>/dev/null; then
  echo ''
  echo 'DANGER!!! DANGER!!!'
  echo 'Please uninstall rvm in order to continue'
  echo ''
  exit 1
fi

if ! hash brew 2>/dev/null; then
  echo
  echo Installing brew...
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

  echo 'export PATH=/usr/local/bin:/usr/local/sbin:$PATH' >> ~/.bash_profile
  export PATH=/usr/local/bin:/usr/local/sbin:$PATH

  brew install imagemagick --with-openexr --with-webp
  brew install openssl git aspell jq editorconfig ctags node libevent libsass python heroku libffi libyaml
else
  echo
  echo Update brew...
  brew update

  if ! hash jq 2>/dev/null; then
    echo
    echo Install jq...
    brew install jq
  fi

  # make sure we have node
  if ! hash node 2>/dev/null; then
    echo
    echo Installing node...
    brew install node
  fi
fi

if ! hash setup-vox-middleman 2>/dev/null; then
  echo "#!/bin/bash" >/usr/local/bin/setup-vox-middleman
  echo 'exec bash -c "$(curl -fsSL https://raw.githubusercontent.com/voxmedia/setup-vox-rig/master/setup-vox-middleman.sh)"' >>/usr/local/bin/setup-vox-middleman
  chmod +x /usr/local/bin/setup-vox-middleman

  echo
  echo Added command setup-vox-middleman
fi

if ! hash rbenv 2>/dev/null; then
  echo
  echo Installing rbenv...
  brew install rbenv
fi

if [ ! -d ~/.rbenv ]; then
  echo
  echo Initialize rbenv...
  echo >> ~/.bash_profile
  echo "# Load rbenv stuff" >> ~/.bash_profile
  echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
fi

echo
echo Load rbenv...
eval "$(rbenv init -)"

# make sure we don't have a .ruby-version in our home
if [ -f ~/.ruby-version ]; then
  echo
  echo Found .ruby-version in your home dir, removing it...
  rm ~/.ruby-version
fi

# make sure we have the correct ruby installed
if ! rbenv versions|grep $FAVORITE_RUBY >/dev/null; then
  echo
  echo Upgrade ruby-build...
  set +e
  brew upgrade ruby-build
  set -e

  echo
  echo "Installing our favorite Ruby ($FAVORITE_RUBY). This may take 15 - 30 minutes..."
  rbenv install $FAVORITE_RUBY

  echo
  echo Making sure we have bundler...
  rbenv global $FAVORITE_RUBY
  rbenv shell $FAVORITE_RUBY
  gem install bundler -v "< 2"
  rbenv rehash
fi

# make sure rbenv permissions are sorted
echo
echo 'Fixing permissions...'
sudo chown -R $USER $HOME/.rbenv

echo
echo Setting default ruby to $FAVORITE_RUBY
rbenv global $FAVORITE_RUBY
rbenv shell $FAVORITE_RUBY

if ! hash bundle 2>/dev/null || ! bundle 2>/dev/null; then
  echo Installing bundler...
  gem install bundler -v "< 2"
  rbenv rehash
fi

# make sure bundler is configured properly
echo
echo Configuring bundler...
bundle config path '.bundle' > /dev/null
bundle config --delete build.openssl
#bundle config build.openssl "--with-cppflags=-I/usr/local/opt/openssl/include --with-ldflags=-L/usr/local/opt/openssl/lib" > /dev/null
bundle config --delete build.eventmachine
#bundle config build.eventmachine "--with-cppflags=-I/usr/local/opt/openssl/include --with-ldflags=-L/usr/local/opt/openssl/lib" > /dev/null
bundle config --delete build.libv8
#bundle config build.libv8 "--with-system-v8" > /dev/null
bundle config --delete build.therubyracer
#bundle config build.therubyracer "--with-cppflags=-I/usr/local/opt/v8@3.15/include --with-ldflags=-L/usr/local/opt/v8@3.15/lib" > /dev/null
bundle config --delete build.puma
#bundle config build.puma "--with-cppflags=-I/usr/local/opt/openssl/include --with-ldflags=-L/usr/local/opt/openssl/lib" > /dev/null
bundle config --delete build.nokogiri

echo
echo Installing gems...
# make gem specific_install URL work
gem install bundler -v "< 2"
gem install specific_install octokit kinto_box rubocop
gem specific_install https://github.com/voxmedia/autotune-client.git
gem specific_install https://github.com/voxmedia/autotune-client-vox.git

gem uninstall middleman middleman-cli middleman-core

rbenv rehash

echo
echo

if [ -d ~/.middleman/voxmedia ]; then
  echo
  echo Removing old middleman template...
  rm -Rf ~/.middleman
fi

if [ -z "$KINTO_API_TOKEN" ] ; then
  # set up kinto token
  echo
  echo Setting up your Kinto account.
  echo To create a new account, enter a username and password of your choosing.
  echo To use an existing account, enter your existing username and password.
  echo "If you don't need kinto or want to setup your account later, just hit enter"
  echo "Don't forget your username and password, there is no password reset!"
  read -p 'Enter username for Kinto: ' kinto_uname
  read -p 'Enter password: ' kinto_pwd
  kinto_token=`echo -n $kinto_uname:$kinto_pwd| openssl base64| tr -d '\n'`
  echo "export KINTO_API_TOKEN=$kinto_token" >> ~/.bash_profile
  if [[ "$(basename $SHELL)" != 'bash' ]]; then
    echo 'Please add this to your shell profile config'
    echo "    export KINTO_API_TOKEN=$kinto_token"
  fi
fi

# Add Autotune settings
if [ -z "$AUTOTUNE_API_SERVER" ] ; then
  # Set Autotune server
  autotune_server='https://autotune.voxmedia.com'
  echo "export AUTOTUNE_API_SERVER=$autotune_server" >> ~/.bash_profile
  # Manual prompt for non-bash shells
  if [[ "$(basename $SHELL)" != 'bash' ]] ; then
    echo 'Please add these to your shell config:'
    echo "    export AUTOTUNE_API_SERVER=$autotune_server"
  fi
fi

# display instructions
echo
echo
echo You must start a new terminal session for changes to take effect.
echo
echo You should be all set. To start a new editorial app, enter the following
echo and follow the instructions.
echo '    autotune vox new my-new-app'
echo
echo Run setup-vox-middleman again at any time to update your install.
echo
