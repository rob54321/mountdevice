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
	
	#@target = ("TARGET", mountpoint)
	# check if device is mounted
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
				# mounted in wrong place
				# un mount and remount
				$rc = system("umount $target[0]");
				die "Could not umount $label at $target[0]: $!\n" unless $rc == 0;
				# device is now un mounted
				print "umounted $label from $target[0]\n";
			}
		} # end of if @target == 1

	}

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
