#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
use File::Basename;

###################################################
# sub to mount devices
# check to see if device is mounted in correct place.
# if not umount then mount
# else mount device
# parameters: LABEL, mountpoint, optional options like -o loop,ro etc
# options are a string and optional and of form ro,loop etc
###################################################
sub mountdevice {
	# parameters
	my $label = shift @_;
	my $mtpt = shift @_;
	my $options = shift @_;

	# check if device is mounted at the correct place
	my @target;
	@target = `findmnt --source LABEL=$label -o TARGET`;
	chomp(@target);

	# return codes
	my $rc;

	# flag for indicating if a correct mount is found
	my $correctmountpoint = "false";
	
	#@target = ("TARGET", mountpoint)
	# check if device is mounted
	# it may be mounted at multiple locations
	# one of the locations may or may not be correct
	if (@target) {
		# device is mounted

		#get rid of first element which is TARGET
		shift @target;

		# check mountpoint and if only mounted once
		if (@target == 1) {
			if ("$target[0]" eq "$mtpt") {
				# correctly mounted in one place only
				print "$label is mounted at $mtpt\n";
				return;
			} else {
				# mounted in wrong place and only mounted once
				# un mount and remount
				$rc = system("umount $target[0]");
				die "Could not umount $label at $target[0]: $!\n" unless $rc == 0;
				# device is now un mounted
				print "umounted $label from $target[0]\n";
			}
		} else {
			# @target > 1
			# umount all wrong mount points
			# mark if one of the mounts is correct
			foreach my $item (@target) {
				if ("$item" ne "$mtpt") {
					# wrong mount point, umount it
					$rc = system("umount -v $item");
					die "Could not umount $label from $item: $!\n" unless $rc == 0;
				} else {
					# correct mount point
					# set a flag to indicate
					# a mount point is correct
					$correctmountpoint = "true";
					print "$label is mounted multiple times, also at $item\n";
				}
			}
		} # end of if target == 1

	} # end of if target

	# if a correct mount point was found , return.
	# all other mount points would have been umounted
	return if "$correctmountpoint" eq "true";

	# now mount the device and make directory if it does not exist
	mkdir $mtpt unless -d $mtpt;
	if (defined $options) {
		# options are defined
		$rc = system("mount -L $label $mtpt -o $options");
		die "Could not mount $label at $mtpt: $!\n" unless $rc == 0;
		print "mounted $label at $mtpt with options $options\n";
	} else {
		# no options were defined
		$rc = system("mount -L $label $mtpt");
		die "Could not mount $label at $mtpt: $!\n" unless $rc == 0;
		print "mounted $label at $mtpt\n";
	}
	
		
}
	
mountdevice("ad64", "/mnt/ad64", "ro");		
