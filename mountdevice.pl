#!/usr/bin/perl

use strict;
use warnings;

###################################################
# sub to mount devices
# simple script to mount a device
# if mounted , umount all locations.
# then mount with the options
# finish and klaar
# returns:
# 0 success and was not mounted
# +n success mounted n times including at correct location
# -n success mounted n times and not at correct location
# on failure script will die.
###################################################
sub mountdevice {
	# parameters
	my $label = shift @_;
	my $mtpt = shift @_;
	my $options = shift @_;

	# if no options given, use defaults
	# which is rw
	$options = "rw" unless ($options);

	# check if device is mounted and if mounted multiple times
	my @target = `findmnt --source LABEL=$label -o TARGET`;
	chomp(@target);

	# return codes
	my $rc;

	# flag to indicate it was mounted
	my $wasmounted = "false";

	# indicates no of mounts
	my $noofmounts = 0;
			
	#@target = ("TARGET", mountpoint)
	# it may be mounted at multiple locations
	# one of the locations may or may not be correct
	if (@target) {
		# device is mounted at lease once

		#get rid of header TARGET
		shift @target;

		# umount all mounts
		foreach my $item (@target) {
			# umount label
			$rc = system("umount -v $item");
			die "Could not umount $label from $item: $!\n" unless $rc == 0;
			$noofmounts++;
			
			# if label was mounted at correct mountpoint
			# set flag to enable return status
			$wasmounted = "true" if "$item" eq "$mtpt";
		}
		# all mounts now un mounted for the device
	}

	# mount the device
	$rc = system("mount -L $label -o $options $mtpt");
	die "Could not mount $label at $mtpt -o $options: $!\n" unless $rc == 0;
	print "mounted $label at $mtpt options: $options\n";

	if ("$wasmounted" eq "true") {
		return $noofmounts;
	} else {
		return $noofmounts * -1;
	}
}
my $rc;

if ($ARGV[0]) {	
	$rc = mountdevice("ad64", "/mnt/ad64", "$ARGV[0]");
} else {
	$rc = mountdevice("ad64", "/mnt/ad64");
}

print "mounted $rc time(s), positive/negative means ad64 was/not mouted at /mnt/ad64\n";
