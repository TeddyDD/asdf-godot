#!/bin/sh

if [ -n "${DEBUG:-}" ]
then
	set -x
fi

die() {
	echo "$1"
	exit 1
}

get_versions_url() {
	url=${GODOT_VERSIONS_URL:-"https://asdf-godot.netlify.com/godot-versions.txt"}
	echo "$url"
}

get_platform() {
	platform="$(uname | tr '[:upper:]' '[:lower:]')"

	case "$platform" in
	linux)
		platform="x11"
		;;
	*)
		echo "Platform '${platform}' not supported!" >&2
		exit 1
		;;
	esac

	echo $platform
}

get_arch() {
	arch=""

	case "$(uname -m)" in
	x86_64 | amd64) arch="64" ;;
	i686 | i386) arch="32" ;;
	*)
		echo "Arch '$(uname -m)' not supported!" >&2
		exit 1
		;;
	esac

	echo $arch
}

get_url() {
	version="$1"
	platform="$(get_platform)"
	arch="$(get_arch)"
	temp=$(mktemp "${TMPDIR:-/tmp}/godotversions.XXXXXX")
	curl -sL "$(get_versions_url)" -o "$temp" || die "Can't download versions info"
	case $platform in
	x11)
		grep "Godot_${version}_${platform}.${arch}" "${temp}" | cut -f 3 ||
			die "Can't find Godot version $version for $platform $arch"
		;;
	osx)
		grep "Godot_${version}_${platform}.${arch}" "${temp}" | cut -f 3 ||
			grep "Godot_${version}_${platform}.fat" "${temp}" | cut -f 3 ||
			die "Can't find Godot version $version for $platform $arch"
		;;
	*)
		die "Unsuported platform $platform $arch"
		;;
	esac
}

download_godot() {
	version="$1"
	url="$(get_url "$version")"
	tmp="$(mktemp -d "${TMPDIR:-/tmp}"/godot.XXXXXX)"
	curl "$url" -o "$tmp/archive.zip"
	unzip -o "$tmp/archive.zip" -d "$ASDF_DOWNLOAD_PATH"
	rm -rf "$tmp"
}

install_godot() {
	version="$1"
	godot_bin_src=$(find "$ASDF_DOWNLOAD_PATH" -type f -name "Godot*$(get_platform).$(get_arch)")
	mkdir -p "$ASDF_INSTALL_PATH/bin"
	cp -r "$(dirname "$godot_bin_src")/"* "$ASDF_INSTALL_PATH/bin/"

	# rename binary
	find "$ASDF_INSTALL_PATH/bin" \
		-type f \
		-name "Godot*$(get_platform).$(get_arch)" \
		-exec chmod +x {} \; \
		-exec mv {} "$ASDF_INSTALL_PATH"/bin/godot \; ||
		die "unable to find installed binary"
}
