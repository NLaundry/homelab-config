#!/usr/bin/env bash

require_smb_tools() {
	if [[ $(uname -s) != Darwin ]] || ! command -v smbutil >/dev/null ||
		[[ ! -x /sbin/mount_smbfs || ! -x /sbin/umount ]]; then
		printf 'SMB verification requires macOS with smbutil, mount_smbfs, and umount.\n' >&2
		return 1
	fi
}

new_guest_namespace() {
	local token
	token=$(od -An -N16 -tx1 /dev/urandom | tr -d '[:space:]')
	[[ $token =~ ^[0-9a-f]{32}$ ]] || {
		printf 'failed to generate a 128-bit guest verifier namespace token\n' >&2
		return 1
	}
	printf '.homelab-verify-%s\n' "$token"
}

cleanup_guest_resources() {
	trap - EXIT INT TERM
	GUEST_CLEANUP_ERROR=''
	if [[ ${GUEST_NAMESPACE_CREATED:-false} == true ]]; then
		rm -f -- "$GUEST_FIXTURE" || GUEST_CLEANUP_ERROR='guest fixture cleanup failed'
		rmdir -- "$GUEST_MOUNTPOINT/$GUEST_NAMESPACE" ||
			GUEST_CLEANUP_ERROR="${GUEST_CLEANUP_ERROR:+$GUEST_CLEANUP_ERROR; }guest namespace cleanup failed"
	fi
	if [[ ${GUEST_MOUNT_ATTEMPTED:-false} == true ]]; then
		/sbin/umount "$GUEST_MOUNTPOINT" ||
			GUEST_CLEANUP_ERROR="${GUEST_CLEANUP_ERROR:+$GUEST_CLEANUP_ERROR; }guest unmount failed"
	fi
	if [[ -n ${GUEST_MOUNTPOINT:-} && -d $GUEST_MOUNTPOINT ]]; then
		rmdir "$GUEST_MOUNTPOINT" ||
			GUEST_CLEANUP_ERROR="${GUEST_CLEANUP_ERROR:+$GUEST_CLEANUP_ERROR; }local mountpoint cleanup failed"
	fi
	[[ -z $GUEST_CLEANUP_ERROR ]]
}
