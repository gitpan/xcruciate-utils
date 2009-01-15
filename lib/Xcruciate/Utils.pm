#! /usr/bin/perl -w

package Xcruciate::Utils;
use Exporter;
@ISA = ('Exporter');
@EXPORT = qw();
our $VERSION = 0.05;

use Time::gmtime;

=head1 NAME

Xcruciate::Utils - Utilities for Xcruciate

=head1 SYNOPSIS

check_path('A very nice path',$path,'rw');

=head1 DESCRIPTION

Provides utility functions Xcruciate ( F<http://www.xcruciate.co.uk>). You shouldn't need
to use these directly.

=head1 AUTHOR

Mark Howe, E<lt>melonman@cpan.orgE<gt>

=head2 EXPORT

None

=head1 FUNCTIONS

=head2 check_path(option,path,permissions)

Checks that the path exists, and that it has the appropriate
permissions, where permissions contains some combination of r, w and x. If not,
it dies, using the value of option to produce a semi-intelligable error message.

=cut

sub check_path {
    my $option = shift;
    my $path = shift;
    my $permissions = shift;
    die "No file corrsponding to path for '$option'" unless -e $path;
    die "File '$path' for '$option' option is not readable" if ($permissions =~/r/ and (not -r $path));
    die "File '$path' for '$option' option is not writable" if ($permissions =~/w/ and (not -w $path));
    die "File '$path' for '$option' option is not executable" if ($permissions =~/x/ and (not -x $path));
}

=head2 check_absolute_path(option,path,permissions)

A lot like &check_path (which it calls), but also checks that the path is
absolute (ie is starts with a /).

=cut

sub check_absolute_path {
    my $option = shift;
    my $path = shift;
    my $permissions = shift;
    die "Path for '$option' must be absolute" unless $path =~ m!^/!;
    check_path($option,$path,$permissions);
}

=head2 type_check(selfhash,name,value,record)

Returns errors on typechecking value against record. Name is provided for error messages. Selfhash might be useful one day. Note that selfhash is not yet blessed.

=cut

sub type_check {
    my $self = shift;
    my $name = shift;
    my $value = shift;
    my $record = shift;
    $value =~s/^\s*(.*?)\s*$/$1/s;
    my @errors = ();
    my $list_name = '';
    $list_name = "Item $_[0] of" if defined $_[0];
    my $datatype = $record->[2];
    if ($datatype eq 'integer') {
	push @errors,sprintf("$list_name Entry called %s should be an integer",$name) unless $value=~/^\d+$/;
	push @errors,sprintf("$list_name Entry called %s is less than minimum permitted value of $record->[3]",$name) if ($value=~/^\d+$/ and (defined $record->[3]) and ($record->[3] > $value));
	push @errors,sprintf("$list_name Entry called %s exceeds permitted value of $record->[4]",$name) if ($value=~/^\d+$/ and (defined $record->[4]) and ($record->[4] < $value));
    } elsif ($datatype eq 'float') {
	push @errors,sprintf("$list_name Entry called %s should be a number",$name) unless $value=~/^-?\d+(\.\d+)$/;
	push @errors,sprintf("$list_name Entry called %s is less than minimum permitted value of $record->[3]",$name) if ($value=~/^-?\d+(\.\d+)$/ and (defined $record->[3]) and ($record->[3] > $value));
	push @errors,sprintf("$list_name Entry called %s exceeds permitted value of $record->[4]",$name) if ($value=~/^-?\d+(\.\d+)$/ and (defined $record->[4]) and ($record->[4] < $value));
    } elsif ($datatype eq 'ip') {
	push @errors,sprintf("$list_name Entry called %s should be an ip address",$name) unless $value=~/^\d\d?\d?\.\d\d?\d?\.\d\d?\d?\.\d\d?\d?$/;
    } elsif ($datatype eq 'cidr') {
	push @errors,sprintf("$list_name Entry called %s should be a CIDR ip range",$name) unless $value=~m!^\d\d?\d?\.\d\d?\d?\.\d\d?\d?\.\d\d?\d?/\d\d?$!;
    } elsif ($datatype eq 'xml_leaf') {
	push @errors,sprintf("$list_name Entry called %s should be an xml filename",$name) unless $value=~/^[A-Za-z0-9_-]+\.xml$/;
    } elsif ($datatype eq 'xsl_leaf') {
	push @errors,sprintf("$list_name Entry called %s should be an xsl filename",$name) unless $value=~/^[A-Za-z0-9_-]+\.xsl$/;
    } elsif ($datatype eq 'yes_no') {
	push @errors,sprintf("$list_name Entry called %s should be 'yes' or 'no'",$name) unless $value=~/^(yes)|(no)$/;
    } elsif ($datatype eq 'word') {
	push @errors,sprintf("$list_name Entry called %s should be a word (ie no whitespace)",$name) unless $value=~/^\S+$/;
    } elsif ($datatype eq 'function_name') {
	push @errors,sprintf("$list_name Entry called %s should be an xpath function name",$name) unless $value=~/^[^\s:]+(:\S+)?$/;
    } elsif ($datatype eq 'path') {
	push @errors,sprintf("$list_name Entry called %s should be a path",$name) unless $value=~/^\S+$/;
    } elsif ($datatype eq 'email') {
	push @errors,sprintf("$list_name Entry called %s should be an email address",$name) unless $value=~/^[^\s@]+\@[^\s@]+$/;
    } elsif (($datatype eq 'abs_file') or ($datatype eq 'abs_dir')) {
	push @errors,sprintf("$list_name Entry called %s should be absolute (ie it should start with /)",$name) unless $value=~/^\//;
	push @errors,sprintf("No file or directory corresponds to $list_name entry called %s",$name) unless -e $value;
	if (-e $value) {
	    push @errors,sprintf("$list_name Entry called %s should be a file, not a directory",$name) if ((-d $value) and ($datatype eq 'abs_file'));
	    push @errors,sprintf("$list_name Entry called %s should be a directory, not a file",$name) if ((-f $value) and ($datatype eq 'abs_dir'));
	    push @errors,sprintf("$list_name Entry called %s must be readable",$name) if ($record->[3]=~/r/ and not -r $value);
	    push @errors,sprintf("$list_name Entry called %s must be writable",$name) if ($record->[3]=~/w/ and not -w $value);
	    push @errors,sprintf("$list_name Entry called %s must be executable",$name) if ($record->[3]=~/x/ and not -x $value);
	}
    } elsif ($datatype eq 'abs_create'){
	$value=~m!^(.*/)?([^/]+$)!;
	my $dir = $1;
	push @errors,sprintf("$list_name Entry called %s should be absolute (ie it should start with /)",$name) unless $value=~/^\//;
	push @errors,sprintf("$list_name No file or directory corresponds to entry called %s, and insufficient rights to create one",$name) if ((not -e $value) and ((not $dir) or (-d $dir) and ((not -r $dir) or (not -w $dir) or (not -x $dir))));
	push @errors,sprintf("$list_name Entry called %s must be readable",$name) if ($record->[3]=~/r/ and -e $value and not -r $value);
	push @errors,sprintf("$list_name Entry called %s must be writable",$name) if ($record->[3]=~/w/ and -e $value and  not -w $value);
	push @errors,sprintf("$list_name Entry called %s must be executable",$name) if ($record->[3]=~/x/ and -e $value and not -x $value);
    } elsif ($datatype eq 'debug_list') {
	if ($value!~/,/) {
	    push @errors,sprintf("$list_name Entry called %s cannot include '%s'",$name,$value) unless $value=~/^((none)|(all)|(timer-io)|(non-timer-io)|(io)|(show-wrappers)|(connections)|(doc-cache)|(channels)|(stack)|(update))$/;
	} else {
	    foreach my $v (split /\s*,\s*/,$value) {
	    push @errors,sprintf("$list_name Entry called %s cannot include 'all' or 'none' in a comma-separated list",$name) if $v=~/^((none)|(all))$/;
	    push @errors,sprintf("$list_name Entry called %s cannot include '%s'",$name,$v) unless $v=~/^((none)|(all)|(timer-io)|(non-timer-io)|(io)|(show-wrappers)|(connections)|(doc-cache)|(channels)|(stack)|(update))$/;
	    }
	}
    } else {
	die sprintf("Unknown unit config datatype %s",$datatype);
    }
    return @errors;
}

=head2 apache_time(epoch_time)

Produces an apache-style timestamp from an epoch time.

=cut

sub apache_time {
    my $epoch_time = shift;
    my $time = gmtime($epoch_time);
    my @days = qw(Sun Mon Tue Wed Thu Fri Sat);
    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    return sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT",
		   $days[$time->wday],
		   $time->mday,
		   $months[$time->mon],
		   $time->year+1900,
		   $time->hour,
		   $time->min,
		   $time->sec);
}

=head2 datetime(epoch_time)

Converts GMT epoch time to the format expected by XSLT date functions.

=cut

sub datetime {#Converts GMT epoch time to the format expected by XSLT date functions
    my $epoch_time = shift;
    my $time = gmtime($epoch_time);
    return sprintf("%04d-%02d-%02dT%02d:%02d:%02d+00:00",
		   $time->year+1900,
		   $time->mon+1,
		   $time->mday,
		   $time->hour,
		   $time->min,
		   $time->sec)
}

=head1 BUGS

The best way to report bugs is via the Xcruciate bugzilla site (F<http://www.xcruciate.co.uk/bugzilla>).

=head1 COMING SOON

A lot more code that is currently spread across assorted scripts, probably split into several modules.

=head1 PREVIOUS VERSIONS

B<0.01>: First upload

B<0.03>: First upload containing module

B<0.04> Changed minimum perl version to 5.8.8

B<0.05> Added debug_list data type, fixed uninitialised variable error when numbers aren't.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 - 2009 by SARL Cyberporte/Menteith Consulting

This library is distributed under BSD licence (F<http://www.xcruciate.co.uk/licence-code>).

=cut

1;
