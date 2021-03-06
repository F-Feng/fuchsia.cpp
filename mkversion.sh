gitver() {
    git -C "$1" describe --tags --abbrev=0 | sed '{s/^[^0-9.-]*//;s/-/./g}'
}

gitid() {
    cidlong=$(git -C "$1" describe --always --abbrev=0 --match '')
    cidshort=$(git -C "$1" describe --always --match '' --dirty=+)
    date=$(git -C "$1" log -1 $cidlong --date=format:'%Y-%m-%d' --format=format:'%cd')
    echo "commit $cidshort from $date"
}

pkgid_rpm() {
    info=$(rpm --queryformat="%{VERSION}-%{RELEASE}\n" -q "$1" 2>/dev/null)
    if [ $? -ne 0 ]; then return 1; fi
    printf "%s" "$info" | head -1
}

pkgid_dpkg() {
    info=$(dpkg -s "$1" 2>/dev/null)
    if [ $? -ne 0 ]; then return 1; fi
    printf "%s" "$info" | sed -n '/Version: /{s/^.* //;p}'
}

pkgid() {
    local pkg
    for pkg in "$@"; do
        pkgid_rpm "$pkg" && return
        pkgid_dpkg "$pkg" && return
    done
    echo "unknown"
}

cat <<EOF
static const char VERSION[] = R"(\
Fuchsia, $(gitid .)
Libraries:
  GiNaC $(gitver "$GINAC"), $(gitid "$GINAC")
  CLN $(gitver "$CLN"), $(gitid "$CLN")
  GMP $(pkgid gmp libgmp-dev)
  glibc $(pkgid glibc libc6)
  libstdc++ $(pkgid libstdc++ libstdc++6)
Compiler:
  $($CXX --version | head -1)
Compressor:
  UPX $(pkgid upx upx-ucl)
)";
EOF
