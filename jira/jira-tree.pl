#!/usr/bin/perl -w

# If your target responds with
#	500 Can't verify SSL peers without knowing which Certificate Authorities to trust
# You can turn off verification of SSL peers using
#	setenv PERL_LWP_SSL_VERIFY_HOSTNAME=0
# e.g.
#	PERL_LWP_SSL_VERIFY_HOSTNAME=0 perl jira-tree.pl STSMACOM-59

use strict;
use warnings;
use Getopt::Std;
use LWP::UserAgent;
use JSON::XS;

my %opts = (
    v => 0,
    b => 'https://issues.folio.org/',
);

if (!getopts('vb:', \%opts) || @ARGV != 1) {
    print STDERR "\
Usage: $0 [options] <issue-number>
	-v		Verbose mode
	-b <baseURL>	Look in Jira API at specified <baseURL>
";
    exit 1;
}

my $ua = new LWP::UserAgent();
my $issue = make_issue(\%opts, $ua, $ARGV[0]);
my $verbose = $opts{v};
if ($verbose) {
    my $coder = new JSON::XS()->pretty();
    print STDERR "ISSUE: ", $coder->encode($issue), "\n";
};

print_tree(0, $issue);


sub make_issue {
    my($opts, $ua, $key) = @_;

    my $verbose = $opts->{v};
    my $baseURL = $opts->{b};
    $baseURL =~ s/\/$//;

    my $url = $baseURL . '/rest/api/latest/issue/' . $key;
    print STDERR "URL: $url\n" if $verbose;

    my $req = HTTP::Request->new(GET => $url);
    my $res = $ua->request($req);
    if (!$res->is_success()) {
	print STDERR "$0: ", $res->status_line(), "\n";
	exit 1;
    }

    my $json = $res->content();
    my $obj = decode_json($json);
    if ($verbose > 1) {
	my $coder = new JSON::XS()->pretty();
	print STDERR "JSON: ", $coder->encode($obj), "\n";
    }

    my $links = $obj->{fields}->{issuelinks};
    my @blockers = ();
    foreach my $link (@$links) {
	if (($link->{inwardIssue} &&
	     $link->{type}->{inward} eq 'is blocked by') ||
	    ($link->{outwardIssue} &&
	     $link->{type}->{outward} eq 'is blocked by')) {
	    my $linked = $link->{inwardIssue} || $link->{outwardIssue};
	    push @blockers, make_issue($opts, $ua, $linked->{key});
	}
    }

    return {
	id => $obj->{id},
	key => $obj->{key},
	title => $obj->{fields}->{summary},
	status => $obj->{fields}->{status}->{name},
	blockers => \@blockers,
    };
}


sub print_tree {
    my($level, $issue) = @_;

    print '  ' x $level, $issue->{key}, ' (', $issue->{status}, '): ', $issue->{title}, "\n";
    foreach my $sub (@{ $issue->{blockers} }) {
	print_tree($level + 1, $sub);
    }
}
