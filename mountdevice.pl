#!/usr/bin/perl

use strict;
use warnings;

###################################################
# sub to mount devices
# simple script to mount a device
# if mounted , umount all locations.
# then mount with the options
# finish and klaar
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
		
	#@target = ("TARGET", mountpoint)
	# it may be mounted at multiple locations
	# one of the locations may or may not be correct
	if (@target) {
		# device is mounted at lease once

		#get rid of header TARGET
		shift @target;

		# umount all mounts
		foreach my $item (@target) {
			# umount 
			$rc = system("umount -v $item");
			die "Could not umount $label from $item: $!\n" unless $rc == 0;
		}
		# all mounts now un mounted for the device
	}

	# mount the device
	$rc = system("mount -v -L $label -o $options $mtpt");
	die "Could not mount $label at $mtpt -o $options: $!\n" unless $rc == 0;
}
if ($ARGV[0]) {	
	mountdevice("ad64", "/mnt/ad64", "$ARGV[0]");
} else {
	mountdevice("ad64", "/mnt/ad64");
}
