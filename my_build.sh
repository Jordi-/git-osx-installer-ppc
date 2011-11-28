#!/bin/bash

if [ "`uname`" == "Darwin" ]; then sed_regexp="-E"; else sed_regexp="-r"; fi
# Force GNU's sed
sed_regexp="-r"

GIT_VERSION="${1:-`curl http://git-scm.com/ 2>&1 | grep "<div id=\"ver\">" | sed $sed_regexp 's/^.+>v([0-9.]+)<.+$/\1/'`}"
#PREFIX=/usr/local/git
# Make it local to avoid sudo
PREFIX=$PWD/git
INST_PREFIX=/usr/local/git
# Undefine to not use sudo
SUDO=

# Defined arch
ARCH=ppc

echo "Building GIT_VERSION $GIT_VERSION with arch $ARCH"

[ -d $PREFIX ] && $SUDO mv $PREFIX{,_`date +%s`}

mkdir -p git_build

DOWNLOAD_LOCATION="http://git-core.googlecode.com/files"

pushd git_build
    [ ! -f git-$GIT_VERSION.tar.gz ] && curl -O $DOWNLOAD_LOCATION/git-$GIT_VERSION.tar.gz
    [ ! -d git-$GIT_VERSION ] && tar zxvf git-$GIT_VERSION.tar.gz

    pushd git-$GIT_VERSION

        [ -f Makefile_head ] && rm Makefile_head
        # If you're on PPC, you may need to uncomment this line:
        # echo "MOZILLA_SHA1=1" >> Makefile_head

        # Tell make to use $PREFIX/lib rather than MacPorts:
        echo "NO_DARWIN_PORTS=1" >> Makefile_head
        cat Makefile >> Makefile_head
        mv Makefile_head Makefile

        #CFLAGS="-mmacosx-version-min=10.4 -isysroot /Developer/SDKs/MacOSX10.5.sdk -arch $ARCH"
        #LDFLAGS="-mmacosx-version-min=10.4 -isysroot /Developer/SDKs/MacOSX10.5.sdk -arch $ARCH"
        #make CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" prefix="$PREFIX" all
        #make CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" prefix="$PREFIX" strip

        echo "Configuring ..."
        ./configure --prefix="$INST_PREFIX"
        echo "Compiling ..."
        make all
        echo "Striping ..."
        make strip
        $SUDO make DESTDIR="$PREFIX" install

        # contrib
        echo "Copying completion for bash ..."
        $SUDO mkdir -p $PREFIX/$INST_PREFIX/contrib/completion
        $SUDO cp contrib/completion/git-completion.bash $PREFIX/$INST_PREFIX/contrib/completion/
        #$SUDO cp perl/private-Error.pm $PREFIX/$INST_PREFIX/lib/perl5/site_perl/Error.pm
    popd

    echo "Downloading manpages ..."
    git_man_archive=git-manpages-$GIT_VERSION.tar.gz
    [ ! -f $git_man_archive ] && curl -O $DOWNLOAD_LOCATION/$git_man_archive
    $SUDO mkdir -p $PREFIX/$INST_PREFIX/share/man
    echo "Uncompressing manpages ..."
    if ( ! $SUDO tar zxvo -C $PREFIX/$INST_PREFIX/share/man -f $git_man_archive ); then
      echo "Error extracting manpages!!! Maybe download location has changed / failed? Look at `pwd`/$git_man_archive. Remove it and re-run build to attempt redownload."
      exit 1
    fi
popd

# change hardlinks for symlinks
echo "Changing hardlinks ..."
$SUDO ruby UserScripts/symlink_git_hardlinks.rb

# add .DS_Store to default ignore for new repositories
$SUDO sh -c "echo .DS_Store >> $PREFIX/$INST_PREFIX/share/git-core/templates/info/exclude"

echo "Change ownership ... (don't needed, Git Installer.pmdoc sets permissions"
#echo $SUDO chown -R root:wheel /usr/local/git

#[ -d /etc/paths.d ]    && $SUDO cp etc/paths.d/git /etc/paths.d
#[ -d /etc/manpaths.d ] && $SUDO cp etc/manpaths.d/git /etc/manpaths.d

echo "Now run ./my_build_package.sh"
