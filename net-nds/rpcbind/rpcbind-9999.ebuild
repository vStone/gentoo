# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit flag-o-matic systemd

if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="git://linux-nfs.org/~steved/rpcbind.git"
	inherit autotools git-r3
else
	SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"
	KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
fi

DESCRIPTION="portmap replacement which supports RPC over various protocols"
HOMEPAGE="https://sourceforge.net/projects/rpcbind/"

LICENSE="BSD"
SLOT="0"
IUSE="debug remotecalls selinux systemd tcpd warmstarts"
REQUIRED_USE="systemd? ( warmstarts )"

CDEPEND=">=net-libs/libtirpc-0.2.3:=
	systemd? ( sys-apps/systemd:= )
	tcpd? ( sys-apps/tcp-wrappers )"
DEPEND="${CDEPEND}
	net-libs/libnsl
	sys-fs/quota[rpc]
	virtual/pkgconfig"
RDEPEND="${CDEPEND}
	selinux? ( sec-policy/selinux-rpcbind )"

src_prepare() {
	default
	[[ ${PV} == "9999" ]] && eautoreconf
}

src_configure() {
	local myeconfargs=(
		--bindir="${EPREFIX}"/sbin
		--sbindir="${EPREFIX}"/sbin
		--with-statedir="${EPREFIX}"/run/${PN}
		--with-systemdsystemunitdir=$(usex systemd "$(systemd_get_systemunitdir)" "no")
		$(use_enable debug)
		$(use_enable remotecalls rmtcalls)
		$(use_enable warmstarts)
		$(use_enable tcpd libwrap)
	)

	# Allow configure to find /usr/include/rpc/rpc.h in rpcsvc/mount.h
	# https://bugs.gentoo.org/665222
	append-cppflags "$($(tc-getPKG_CONFIG) --cflags libtirpc)"

	econf "${myeconfargs[@]}"
}

src_install() {
	default

	newinitd "${FILESDIR}"/${PN}.initd ${PN}
	newconfd "${FILESDIR}"/${PN}.confd ${PN}
}
