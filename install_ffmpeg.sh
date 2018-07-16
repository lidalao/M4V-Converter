#!/usr/bin/env bash

installLinux() {
	if [[ $(whoami) != "root" ]]; then
		echo "You must be root to run this script on Linux"
		exit 1
	fi

	manager -y update
	manager -y install ffmpeg

	if [[ $? -ne 0 ]]; then
		echo "This script attempted to install ffmpeg directly from apt/dnf/yum and failed, falling back to manually compiling..."
	else
		exit 0
	fi

	distro=$(cat /etc/*-release | grep -x 'ID=.*' | sed -E 's/ID=|\"//g')

	case "${distro}" in
		ubuntu|debian|linuxmint) depends="autoconf automake build-essential cmake git libfreetype6-dev libfribidi-dev libfontconfig1-dev libtool pkg-config mercurial texinfo zlib1g-dev" ;;
		fedora|centos) depends="autoconf automake cmake fontconfig-devel freetype-devel fribidi-devel gcc gcc-c++ git libtool make mercurial patch pkgconfig wget zlib-devel" ;;
		*) echo "This Linux distribution is unsupported"; exit 2 ;;
	esac

	manager -y install ${depends}

	mkdir ~/ffmpeg_sources

	cd ~/ffmpeg_sources
	wget http://www.nasm.us/pub/nasm/releasebuilds/2.13.03/nasm-2.13.03.tar.bz2
	tar xjvf nasm-2.13.03.tar.bz2
	cd nasm-2.13.03
	./autogen.sh
	PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin"
	make
	make install
	echo

	cd ~/ffmpeg_sources
	wget -O yasm-1.3.0.tar.gz https://github.com/yasm/yasm/archive/v1.3.0.tar.gz
	tar xzvf yasm-1.3.0.tar.gz
	cd yasm-1.3.0
	autoreconf -fiv
	./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin"
	make
	make install
	echo

	cd ~/ffmpeg_sources
	wget https://github.com/libass/libass/releases/download/0.14.0/libass-0.14.0.tar.gz
	tar xzvf libass-0.14.0.tar.gz
	cd libass-0.14.0
	PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --disable-shared
	PATH="$HOME/bin:$PATH" make
	make install
	echo

	cd ~/ffmpeg_sources
	wget -O fdk-aac-0.1.6.tar.gz https://github.com/mstorsjo/fdk-aac/archive/v0.1.6.tar.gz
	tar xzvf fdk-aac-0.1.6.tar.gz
	cd fdk-aac-0.1.6
	autoreconf -fiv
	./configure --prefix="$HOME/ffmpeg_build" --disable-shared
	make
	make install
	echo

	cd ~/ffmpeg_sources
	wget http://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz
	tar xzvf lame-3.100.tar.gz
	cd lame-3.100
	./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-nasm --disable-shared
	make
	make install
	echo

	cd ~/ffmpeg_sources
	wget http://downloads.xiph.org/releases/opus/opus-1.2.1.tar.gz
	tar xzvf opus-1.2.1.tar.gz
	cd opus-1.2.1
	PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure --prefix="$HOME/ffmpeg_build" --disable-shared
	make
	make install
	echo

	cd ~/ffmpeg_sources
	wget http://downloads.xiph.org/releases/ogg/libogg-1.3.3.tar.gz
	tar xzvf libogg-1.3.3.tar.gz
	cd libogg-1.3.3
	./configure --prefix="$HOME/ffmpeg_build" --disable-shared
	make
	make install
	echo

	cd ~/ffmpeg_sources
	wget http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.gz
	tar xzvf libtheora-1.1.1.tar.gz
	cd libtheora-1.1.1
	./configure --prefix="$HOME/ffmpeg_build" --with-ogg="$HOME/ffmpeg_build" --disable-shared
	make
	make install
	echo

	cd ~/ffmpeg_sources
	wget http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.6.tar.gz
	tar xzvf libvorbis-1.3.6.tar.gz
	cd libvorbis-1.3.6
	./configure --prefix="$HOME/ffmpeg_build" --with-ogg="$HOME/ffmpeg_build" --disable-shared
	make
	make install
	echo

	cd ~/ffmpeg_sources
	wget -O libvpx-1.7.0.tar.gz https://github.com/webmproject/libvpx/archive/v1.7.0.tar.gz
	tar xzvf libvpx-1.7.0.tar.gz
	cd libvpx-1.7.0
	PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --disable-examples --disable-unit-tests
	PATH="$HOME/bin:$PATH" make
	make install
	echo

	cd ~/ffmpeg_sources
	git clone https://git.videolan.org/git/x264.git
	cd x264
	PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static --enable-pic
	PATH="$HOME/bin:$PATH" make
	make install
	echo

	cd ~/ffmpeg_sources
	hg clone https://bitbucket.org/multicoreware/x265
	cd ~/ffmpeg_sources/x265/build/linux
	PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED:bool=off ../../source
	PATH="$HOME/bin:$PATH" make
	make install
	echo

	cd ~/ffmpeg_sources
	wget -O ffmpeg-snapshot.tar.bz2 http://www.ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
	tar xjvf ffmpeg-snapshot.tar.bz2
	cd ffmpeg

	PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
		--prefix="$HOME/ffmpeg_build" \
		--pkg-config-flags="--static" \
		--extra-cflags="-I$HOME/ffmpeg_build/include" \
		--extra-ldflags="-L$HOME/ffmpeg_build/lib" \
		--extra-libs="-lpthread -lm" \
		--bindir="$HOME/bin" \
		--enable-gpl \
		--enable-libass \
		--enable-libfdk-aac \
		--enable-libfreetype \
		--enable-libmp3lame \
		--enable-libopus \
		--enable-libtheora \
		--enable-libvorbis \
		--enable-libvpx \
		--enable-libx264 \
		--enable-libx265 \
		--enable-nonfree
	PATH="$HOME/bin:$PATH" make
	make install
	hash -r

	cp "$HOME"/bin/* /usr/local/bin/
	cp "$HOME"/ffmpeg_build/bin/* /usr/local/bin/

	rm -rf "$HOME"/bin
	rm -rf "$HOME"/ffmpeg_build
	rm -rf "$HOME"/ffmpeg_sources
}

installMac() {
	if ! hash brew 2>/dev/null; then
		echo "You must install Homebrew from http://brew.sh/ for this script to assist in installing ffmpeg"
		exit 10
	fi
	brew install ffmpeg --with-tools --with-fdk-aac --with-freetype --with-fontconfig --with-libass --with-libvorbis --with-libvpx --with-opus --with-x265 --HEAD
}
manager() {
	if hash apt-get 2>/dev/null; then
		apt "${@}"
	elif hash dnf 2>/dev/null; then
		if [[ "${@}" == "-y update" ]]; then
			dnf -y check-update
		else
			dnf "${@}"
		fi
	elif hash yum 2>/dev/null; then
		if [[ "${@}" == "-y update" ]]; then
			yum -y check-update
		else
			yum "${@}"
		fi
	fi
}

case "${OSTYPE}" in
	linux*) installLinux ;;
	darwin*) installMac ;;
esac

exit 0
