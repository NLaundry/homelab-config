#!/usr/bin/env bash

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
	local rm_command=${GUEST_RM_COMMAND:-rm}
	local rmdir_command=${GUEST_RMDIR_COMMAND:-rmdir}
	local umount_command=${GUEST_UMOUNT_COMMAND:-/sbin/umount}

	if [[ ${GUEST_NAMESPACE_CREATED:-false} == true ]]; then
		"$rm_command" -f -- "$GUEST_FIXTURE" || GUEST_CLEANUP_ERROR='guest fixture cleanup failed'
		"$rmdir_command" -- "$GUEST_MOUNTPOINT/$GUEST_NAMESPACE" ||
			GUEST_CLEANUP_ERROR="${GUEST_CLEANUP_ERROR:+$GUEST_CLEANUP_ERROR; }guest namespace cleanup failed"
	fi
	if [[ ${GUEST_MOUNT_ATTEMPTED:-false} == true ]]; then
		"$umount_command" "$GUEST_MOUNTPOINT" ||
			GUEST_CLEANUP_ERROR="${GUEST_CLEANUP_ERROR:+$GUEST_CLEANUP_ERROR; }guest unmount failed"
	fi
	if [[ -n ${GUEST_MOUNTPOINT:-} && -d $GUEST_MOUNTPOINT ]]; then
		"$rmdir_command" "$GUEST_MOUNTPOINT" ||
			GUEST_CLEANUP_ERROR="${GUEST_CLEANUP_ERROR:+$GUEST_CLEANUP_ERROR; }local mountpoint cleanup failed"
	fi
	[[ -z $GUEST_CLEANUP_ERROR ]]
}
