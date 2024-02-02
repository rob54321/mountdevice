#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
use File::Basename;

my @ARGv;

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

	# list for mounted options
	# to compare to requested options
	my @mountedoptions;
		
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
				# mounted at correct location and no multiple mounts
				# check the mounted options are the same as requested options
				# get the mounted options
				@mountedoptions = `findmnt --source LABEL=$label -o OPTIONS`;

				# remove header
				shift @mountedoptions;
				chomp @mountedoptions;

				# only check for rw or ro options
				# if requested options is undefined
				# then options are rw
				if (! defined($options)) {
					# no options requested
					# defaults are rw
					if ($mountedoptions[0] =~ /rw/) {
						# requested options and mounted options are the same
						print "$label is mounted rw at $mtpt\n";
						return;
					} else {
						# mounted options are different to requested options
						$rc = system("umount $mtpt");
						die "Could not umount $label from $mtpt, $mountedoptions[0] are different to requested options: $!\n" unless $rc == 0;
						print "umounted $label from $mtpt, mounted options $mountedoptions[0], should be rw\n";
					}
				} else {
					# requested options are defined,
					# could be rw or ro. not interested in others
					# can only be ro or rw
					# if mounted options are the same as requested options
					# then return else umount.
					
					if (($options =~ /ro/ and $mountedoptions[0] =~ /ro/) or ($options =~ /rw/ and $mountedoptions[0] =~ /rw/)) {
						print "$label is mounted with options $mountedoptions[0] at $mtpt\n";
						return;
					}

					# at this point requested options do not match
					# mounted options. umount
					$rc = system("umount $mtpt");
					die "Could not umount $label from $mtpt, $mountedoptions[0] are different to requested options: $!\n" unless $rc == 0;
					print "umounted $label from $mtpt, mounted options $mountedoptions[0], requested options $options\n";

				} # end of if not defined options
				
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
			# flag to indicate if correctly mounted
			my $correctlymounted = "false";

			foreach my $item (@target) {
				if ("$item" ne "$mtpt") {
					# wrong mount point, umount it
					$rc = system("umount -v $item");
					die "Could not umount $label from $item: $!\n" unless $rc == 0;
				} else {
					# correct mount point
					# compare mounted options and requested options
					# if they are the same set flag to true
					# if the are different do not set the flag
					# if options not defined the option is rw
					@mountedoptions = `findmnt --source LABEL=$label -o OPTIONS`;
					shift @mountedoptions;
					chomp @mountedoptions;

					if (! defined($options)) {
						# requested option is rw
						# check mounted option
						if ($mountedoptions[0] =~ /rw/) {
							# correctly mounted with correct rw or ro
							print "$label is mounted with options $mountedoptions[0] at $mtpt\n";
							$correctlymounted = "true";
						} else {
							# mounted options and requested options are different
							$rc = system("umount -v $mtpt");
							die "Could not umount $label from $mtpt: $!\n" unless $rc == 0;
							print "umounting $label from $mtpt mounted options = $mountedoptions[0], requested options = rw\n";
						}
					} else {
						# options is defined
						# compare mounted options to requested options
						if (($options =~ /ro/ and $mountedoptions[0] =~ /ro/) or ($options =~ /rw/ and $mountedoptions[0] =~ /rw/)) {
							print "$label is mounted with options $mountedoptions[0] at $mtpt\n";
							$correctlymounted = "true";
						} else {
							# mounted options and requested options are different
							$rc = system("umount -v $mtpt");
							die "Could not umount $label from $mtpt: $!\n" unless $rc == 0;
							print "umounting $label from $mtpt mounted options = $mountedoptions[0], requested options = $options\n";
						}
					} # end of if not defined options
				}
			}
			# if device is correctly mounted return
			# all umounts of wrong locations already done
			return if "$correctlymounted" eq "true";
		} # end of if target == 1

	} # end of if target

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
		print "mounted $label at $mtpt with options rw\n";
	}
	
		
}
if ($ARGV[0]) {	
	mountdevice("ad64", "/mnt/ad64", "$ARGV[0]");
} else {
	mountdevice("ad64", "/mnt/ad64");
}
