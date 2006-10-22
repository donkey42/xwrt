#!/bin/sh
if [ $# -lt 1 ]; then
	echo "Usage: $0 USERNAME"
	exit 1
fi
export SCP_USER="$1"
echo "Uploading webif ..."
scp \
	bin/packages/web* \
	$SCP_USER@shell.berlios.de:/home/groups/ftp/pub/xwrt/packages/
echo "Uploading webif version info ..."
scp \
	build_mipsel/webif-0.3/ipkg/webif/www/.version \
	$SCP_USER@shell.berlios.de:/home/groups/ftp/pub/xwrt/
echo "Uploading xwrt web pages ..."
scp \
	/mnt/whale/xwrt/xwrt.htm \
	/mnt/whale/xwrt/xwrt.asp \
	$SCP_USER@shell.berlios.de:/home/groups/xwrt/htdocs/
echo "Uploading package repository ..."
scp \
	bin/packages/* \
	$SCP_USER@shell.berlios.de:/home/groups/ftp/pub/xwrt/packages/
echo "Uploading X-Wrt patches ..."
scp \
	patches/* \
	$SCP_USER@shell.berlios.de:/home/groups/ftp/pub/xwrt/patches/
echo "Uploading firmware images ..."
scp \
	bin/*.rar \
	$SCP_USER@shell.berlios.de:/home/groups/ftp/pub/xwrt/images/early_raw_alpha/default
echo "Uploading SDk and image builder ..."
scp \
	bin/*.tar.bz2 \
	$SCP_USER@shell.berlios.de:/home/groups/ftp/pub/xwrt/images/early_raw_alpha/default
