#! perl -w

warn 'This is $Revision$ of $Date$ 
Check for newer version at http://dev.w3.org/cvsweb/~checkout~/2002/scribe/

';


# Generate minutes in HTML from a text IRC/chat Log.
#
# Author: David Booth <dbooth@w3.org> 
#
# Take a raw W3C IRC log, tidy it up a bit, and put it into HTML
# to create meeting minutes.  Reads stdin, writes stdout.
# Several input formats are accepted (see below).
# Input must follow certain conventions (see below).
#
# USAGE: 
#	perl scribe.perl [options] ircLogFile.txt > minutesFile.htm
#	perl scribe.perl -sampleInput
#	perl scribe.perl -sampleOutput
#	perl scribe.perl -sampleTemplate
#
# Options:
#	-sampleInput		Show me some sample input, so I can
#				learn how to use this program.
#
#	-sampleOutput		Show me some sample output.
#
#	-scribeOnly		Only keep scribe statements.  (Otherwise
#				everyone's statements are kept.)
#
#	-template tfile		Use tfile as the template file for
#				generating the HTML.  Without this option,
#				the program will default to an embedded
#				template, which you can see by using
#				the "-sampleTemplate" option.
#
#	-sampleTemplate		Show me a sample template file.
#				(The default template.)
#
#	-public			Use a template that is formatted
#				for public access.  DEFAULT.
#				(Search for "sub PublicTemplate" below.)
#
#	-member			Use a template that is formatted 
#				for W3C member-only access.
#				(Search for "sub PublicTemplate" below.)
#
#	-team			Use a template that is formatted
#				for W3C team-only access.
#				(Search for "sub PublicTemplate" below.)
#
#	-mit			Use a template that is formatted for
#				W3C MIT style.
#				(Search for "sub PublicTemplate" below.)
#
#	-trustRRSAgent		Don't try to be smart about action items.
#				Just trust what RRSAgent says
#
#
# The best way to use this program is:
#	1. Make a backup of your IRC log.
#	2. Modify the IRC log to conform to the scribe conventions that this
#	   program expects (described below).
#	3. Run this program as described above.
#	4. View the output in a browser.
#	5. Go back to step 2 to make modifications, and repeat.
#	   Once the output looks good enough, then . . .
#	6. Manually edit the resulting HTML for any remaining fixes.
#
# SCRIBE CONVENTIONS:
# This program expects certain conventions in the IRC log as follows.
# Identify the IRC name of the scribe (Note that names must not contain spaces):
#	<dbooth> Scribe: dbooth
# Identify the meeting chair:
#	<dbooth> Chair: Jonathan
# Identify the meeting itself:
#	<dbooth> Meeting: Weekly Baking Club Meeting
# Fix the meeting date (default is auto set from IRC log name or today if 
# there is no "Date:" line):
#	<dbooth> Date: 05 Dec 2002
# Identify the current topic.  You should insert one of
# these lines before the start of EACH topic:
#	<dbooth> Topic: Review of Action Items
# Record an action item:
#	<dbooth> ACTION: dbooth to send a message to himself about action items
# Record an incomplete action item (either syntax):
#	<Philippe> PENDING ACTION: Barbara to bake 3 pies 
#	<Philippe> ACTION: Barbara to bake 3 pies  -- PENDING
# Record a completed action item (either syntax):
#	<Philippe> DONE ACTION: Barbara to bake 3 pies 
#	<Philippe> ACTION: Barbara to bake 3 pies  -- DONE
# Scribe someone's statements:
#	<dbooth> Joseph: I think that we should all eat cake
#	<dbooth> ... with ice creme.
# Correct a mistake (changes most recent instance):
#	<dbooth> s/creme/cream/
# Correct a mistake globally from this point back in the input:
#	<dbooth> s/Baking/Cooking/g
# Identify the IRC log produced by RRSAGENT (this also sets the date):
#	<dbooth> rrsagent, where am i?
#	<RRSAgent> See http://www.w3.org/2002/11/07-ws-arch-irc#T13-59-36
# or:
#	<dbooth> Log: http://www.w3.org/2002/11/07-ws-arch-irc
# Separator (at least 4 dashes):
#	<dbooth> ----
#
# INPUT FORMATS ACCEPTED
# These formats are auto detected.  The best match wins.
#   MIRC buffer style:
#	<ericn> Where is our next F2F?
#	<dbooth> Rennes France.
#   RRSAgent Text style:
#	20:41:27 <ericn> Where is our next F2F?
#	20:41:37 <dbooth> Rennes France.
#   RRSAgent HTML style:
#	<dt id="T20-41-27">20:41:27 [ericn]</dt><dd>Where is our next F2F? </dd>
#	<dt id="T20-41-37">20:41:37 [dbooth]</dt><dd>Rennes France. </dd>
#   RRSAgent HTML Text style (text copied and pasted from the browser):
#	20:41:27 [ericn]
#	     Where is our next F2F?
#	20:41:37 [dbooth]
#	     Rennes France.
#   Yahoo IM style:
#	ericn: Where is our next F2F?
#	dbooth: Rennes France.
#
# WARNING: The code is a horrible mess.  (Sorry!)  Please hold your nose if 
# you look at it.  If you have something better, or make improvements
# to this (and please do!), please let me know.  Perhaps it's a good 
# example of Fred Brooke's advice in Mythical Man Month: "Plan to throw 
# one away". 
#
######################################################################

my $scribeName = "UNKNOWN"; # Default

# Formatting:
# my $preSpeakerHTML = "<strong>";
# my $postSpeakerHTML = "</strong> <br />";
my $preSpeakerHTML = "<b>";
my $postSpeakerHTML = "</b>";
my $preParagraphHTML = "<p>";
my $postParagraphHTML = "</p>";
my $preTopicHTML = "<h3";
my $postTopicHTML = "</h3>";

# Get options/args
my $all = "";			# Input
my $canonicalizeNames = 0;	# Convert all names to their canonical form?
my $useTeamSynonyms = 0; 	# Accept any short synonyms for team members?
my $scribeOnly = 0;		# Only select scribe lines
my $trustRRSAgent = 0;		# Trust RRSAgent?

@ARGV = map {glob} @ARGV;	# Expand wildcards in arguments
my @args = ();
my $template = &DefaultTemplate();
while (@ARGV)
	{
	my $a = shift @ARGV;
	if (0) {}
	elsif ($a eq "-sampleInput") 
		{ print STDOUT &SampleInput(); exit 0; }
	elsif ($a eq "-sampleOutput") 
		{ $all = &SampleInput(); }
	elsif ($a eq "-sampleTemplate") 
		{ print STDOUT &DefaultTemplate(); exit 0; }
	elsif ($a eq "-scribeOnly") 
		{ $scribeOnly = 1; }
	elsif ($a eq "-canon") 
		{ $canonicalizeNames = 1; }
	elsif ($a eq "-trustRRSAgent") 
	        { $trustRRSAgent = 1; }
	elsif ($a eq "-teamSynonyms") 
		{ $useTeamSynonyms = 1; }
	elsif ($a eq "-mit") 
		{ $template = &MITTemplate(); }
	elsif ($a eq "-team") 
		{ $template = &TeamTemplate(); }
	elsif ($a eq "-member") 
		{ $template = &MemberTemplate(); }
	elsif ($a eq "-world") 
		{ $template = &PublicTemplate(); }
	elsif ($a eq "-public") 
		{ $template = &PublicTemplate(); }
	elsif ($a eq "-template") 
		{ 
		my $templateFile = shift @ARGV; 
		die "ERROR: Template file not found: $templateFile\n"
			if !-e $templateFile;
		my $t = &GetTemplate($templateFile);
		if (!$t)
			{
			die "ERROR: Empty template: $templateFile\n";
			}
		$template = $t;
		}
	elsif ($a =~ m/\A\-/)
		{ die "ERROR: Unknown option: $a\n"; }
	else	
		{ push(@args, $a); }
	}
@ARGV = @args;

# Get input:
$all =  join("",<>) if !$all;
if (!$all)
	{
	warn "WARNING: Empty input.\n";
	}
# Delete control-M's if any.
$all =~ s/\r//g;

# Normalize input format.  To do so, we need to guess the input format.
# Try each known formats, and see which one matches best.
my $bestScore = 0;
my $bestAll = "";
my $bestName = "";
# These are the normalizer functions we'll be calling.
# Each one is defined below.
# Just add another to the list if you want to recognize another format.
# Each function takes $all (the input text) as input and returns
# a pair: ($score, $newAll). 
#	$score is a value [0,1] indicating how well it matched.
#	$newAll is the normalized input.
foreach my $f (qw(
		NormalizerMircTxt
		NormalizerRRSAgentText 
		NormalizerRRSAgentHtml 
		NormalizerRRSAgentHTMLText
		NormalizerYahoo
		NormalizerPlainText
		))
	{
	my ($score, $newAll) = &$f($all);
	# warn "$f: $score\n";
	if ($score > $bestScore)
		{
		$bestScore = $score;
		$bestAll = $newAll;
		$bestName = $f;
		}
	}
my $bestScoreString = sprintf("%4.2f", $bestScore);
warn "Input format (score $bestScoreString): $bestName\n";
die "ERROR: Could not guess input format.\n" if $bestScore == 0;
warn "WARNING: Low confidence ($bestScoreString) on guessing input format: $bestName\n"
	if $bestScore < 0.7;
$all = $bestAll;


# Perform s/old/new/ substitutions.
while($all =~ m/\n\<[^\>]+\>\s*s\/([^\/]+)\/([^\/]*?)((\/(g))|\/?)(\s*)\n/i)
	{
	my $old = $1;
	my $new = $2;
	my $global = $5;
	my $pre = $`;
	my $match = $&;
	my $post = $';
	my $oldp = quotemeta($old);
	# warn "Found match: $match\n";
	my $told = $old;
	$told = $& . "...(truncated)...." if ($old =~ m/\A.*\n/);
	my $tnew = $new;
	$tnew = $& . "...(truncated)...." if ($old =~ m/\A.*\n/);
	my $succeeded = 0;
	if (($global  && $pre =~ s/$oldp/$new/g)
	|| ((!$global) && $pre =~ s/\A((.|\n)*)($oldp)((.|\n)*?)\Z/$1$new$4/))
		{
		warn "SUBSTITUTION: s/$told/$tnew/\n";
		warn "(global substitution)\n" if $global;
		$all = $pre . "\n" . $post;
		}
	else	{
		warn "s/$told/$tnew/  FAILED\n";
		$match =~ s/\A\s+//;
		$match =~ s/\s+\Z//;
		$all = $pre . "\n[Auto substitution failed:] " . $match . "\n" . $post;
		}
	warn "WARNING: Multiline substitution!!! (Is this correct?)\n" if $tnew ne $new || $told ne $old;
	}

# Strip -home from names.  (Convert alan-home to alan, for example.)
$all =~ s/(\w+)\-home\b/$1/ig;
# Strip -lap from names.  (Convert alan-lap to alan, for example.)
$all =~ s/(\w+)\-lap\b/$1/ig;
# Strip -iMac from names.  (Convert alan-iMac to alan, for example.)
$all =~ s/(\w+)\-iMac\b/$1/ig;

# Determine scribe name if possible:
$scribeName = $3 if $all =~ s/\s+scribe\s+((today\s+)?)is\s+([\w\-]+)//i;
$scribeName = $1 if $all =~ s/\s+scribe\s*\:\s*([\w\-]+)//i;
$scribeName = $1 if $all =~ s/\s([\w\-]+)\s+is\s+scribe//i;
$scribeName = $1 if $all =~ s/\s([\w\-]+)\s+is\s+scribing//i;
$scribeName = $1 if $all =~ s/\<([^\>\ ]+)\>\s*I\s+am\s+scribe\s+.*//i;
$scribeName = $1 if $all =~ s/\<([^\>\ ]+)\>\s*I\s+will\s+scribe\s+.*//i;
$scribeName = $1 if $all =~ s/\<([^\>\ ]+)\>\s*I\s+am\s+scribing.*//i;
warn "Scribe: $scribeName\n";

# Get attendee list, and normalize names within the document:
my $namePattern = '([\\w]([\\w\\d\\-]*))';
# warn "namePattern: $namePattern\n";
my @uniqNames = ();
my $allNameRefsRef;
($all, $scribeName, $allNameRefsRef, @uniqNames) = &GetNames($all, $scribeName);
my @allNames = map { ${$_} } @{$allNameRefsRef};
my $scribePattern = quotemeta($scribeName);
$all =~ s/\<$scribePattern\>/\<Scribe\>/ig;
$scribePattern = "Scribe";
push(@allNames,"Scribe");
my @allSpeakerPatterns = map {quotemeta($_)} @allNames;
my $speakerPattern = "((" . join(")|(", @allSpeakerPatterns) . "))";
# warn "speakerPattern: $speakerPattern\n";

# Escape &
$all =~ s/\&/\&amp\;/g;

# Normalize Scribe continuation lines so that the speaker's name is on every line:
#	<Scribe> SusanW: We had a mtg on July 16.
#	<DanC_> pointer to minutes?
#	<Scribe> SusanW: I'm looking.
#	<Scribe> ... The minutes are on the admin timeline page.
my @allLines = split(/\n/, $all);
my $currentSpeaker = "UNKNOWN_SPEAKER";
for (my $i=0; $i<@allLines; $i++)
	{
	# warn "$allLines[$i]\n";
	if ($allLines[$i] =~ m/\A\<Scribe\>\s*($speakerPattern)\s*\:/i)
		{
		$currentSpeaker = $1;
		# warn "SET SPEAKER: $currentSpeaker\n";
		}
	elsif ($allLines[$i] =~ s/\A\<Scribe\>\s*\.\.+\s*/\<Scribe\> $currentSpeaker: /i)
		{
		# warn "Scribe NORMALIZED: $& --> $allLines[$i]\n";
		warn "WARNING: UNKNOWN SPEAKER: $allLines[$i]\nPossibly need to add line; <Zakim> +someone\n" if $currentSpeaker eq "UNKNOWN_SPEAKER";
		}
	elsif ($allLines[$i] =~ m/\A\<Scribe\>\s*($namePattern)\s*\:/i)
		{
		# This doesn't work right.  It matches "Topic:" and known names.
		# warn "Possibly need to add speaker \"$1\" by adding line:\n<Zakim> +$1\n";
		}
	}
$all = "\n" . join("\n", @allLines) . "\n";

# Get the list of people present:
my @possiblyPresent = @uniqNames;	# People present at the meeting
my @present = ();			# People present at the meeting
while ($all =~ s/\s+Present\s*\:\s*(.*)//i)
	{
	my $present = $1;
	my @p = ();
	if ($present =~ m/\,/)
		{
		# Comma-separated list
		@p = grep {$_ && $_ ne "and"} 
				map {s/\A\s+//; s/\s+\Z//; s/\s+/_/g; $_} 
				split(/\,/,$present);
		}
	else	{
		# Space-separated list
		@p = grep {$_} split(/\s+/,$present);
		}
	if (scalar(@p) < scalar(@present))
		{
		warn "\nWARNING: Combining \"$present\"
with previous list of people present.\n\n";
		my %seen = map {($_,$_)} @present;
		my @newp = grep {!exists($seen{$_})} @p;
		push(@present, @newp);
		}
	else	{
		warn "\nWARNING: Replacing previous list of people present.\n\n" if @present;
		@present = @p;
		}
	warn "Present: @present\n"; 
	}
if (@present < 3) 
	{ 
	if (@present > 0)  { warn "WARNING: Fewer than 3 people found present!\n\n"; }
	else	{
		warn "\nWARNING: No \"Present: ... \" found!\n";
		warn "Possibly Present: @possiblyPresent\n"; 
		warn "You can indicate the people present like this:
<scribe> Present: dbooth jonathan mary\n\n";
		}
	}

# Get the list of regrets:
my @regrets = ();	# People who sent regrets
if ($all =~ s/\s+Regrets\s*\:\s*(.*)//i)
	{
	my $regrets = $1;
	if ($regrets =~ m/\,/)
		{
		# Comma-separated list
		@regrets = grep {$_ && $_ ne "and"} 
				map {s/\As+//; s/s\+\Z//; $_} 
				split(/\,/,$regrets);
		}
	else	{
		# Space-separated list
		@regrets = grep {$_} split(/\s+/,$regrets);
		}
	}
warn "Regrets: @regrets\n" if @regrets;

# Grab meeting name:
my $title = "SV_MEETING_TITLE";
if ($all =~ s/\n\<$namePattern\>\s*(Meeting|Title)\s*\:\s*(.*)\n/\n/i)
	{ $title = $4; }
else 	{ 
	warn "\nWARNING: No meeting title found!
You should specify the meeting title like this:
<scribe> Meeting: Weekly Baking Club Meeting\n\n";
	}

# Grab Previous meeting URL:
my $previousURL = "SV_PREVIOUS_MEETING_URL";
if ($all =~ s/\n\<$namePattern\>\s*(Previous|PreviousMeeting|Previous Meeting)\s*\:\s*(.*)\n/\n/i)
	{ $previousURL = $4; }

# Grab Chair:
my $chair = "SV_MEETING_CHAIR";
if ($all =~ s/\n\<$namePattern\>\s*(Chair(s?))\s*\:\s*(.*)\n/\n/i)
	{ $chair = $5; }
else 	{ 
	warn "\nWARNING: No meeting chair found!
You should specify the meeting chair like this:
<scribe> Chair: dbooth\n\n";
	}

# Grab IRC Log URL.  Do this before looking for the date, because
# we can figure out the date from the IRC log name.
my $logURL = "SV_MEETING_IRC_URL";
# <RRSAgent>   recorded in http://www.w3.org/2002/04/05-arch-irc#T15-46-50
$logURL = $3 if $all =~ m/\n\<(RRSAgent|Zakim)\>\s*(recorded|logged)\s+in\s+(http\:([^\s\#]+))/i;
$logURL = $6 if $all =~ s/\n\<$namePattern\>\s*(IRC|Log|(IRC(\s*)Log))\s*\:\s*(.*)\n/\n/i;
$logURL = $3 if $all =~ m/\n\<(RRSAgent|Zakim)\>\s*(see|recorded\s+in)\s+(http\:([^\s\#]+))/i;

# Grab and remove date from $all
my ($day0, $mon0, $year, $monthAlpha) = &GetDate($all, $namePattern, $logURL);

# Grab all ACTION items (whether new, done, pending, or dropped):
# <dbooth> ACTION: MSM to report back on XMLP IPR policy after W3M mtg.
# <dbooth> ACTION: MSM to report back on XMLP IPR policy after W3M mtg. [4]
# <dbooth> DONE ACTION: MSM to report back on XMLP IPR policy after W3M mtg.
# <dbooth> PENDING ACTION: MSM to report back on XMLP IPR policy after W3M mtg.
# <dbooth> ACTION: MSM to report back on XMLP IPR policy after W3M mtg. -- DONE
# <dbooth> ACTION: MSM to report back on XMLP IPR policy after W3M mtg. -- PENDING
# <dbooth> ACTION: MSM to report back on XMLP IPR policy after W3M mtg. * DONE *
# <dbooth> ACTION: MSM to report back on XMLP IPR policy after W3M mtg. * PENDINGa *
my %actions = ();	# Key: action Value: (NEW|DONE|PENDING|DROPPED)
# warn "ALL ACTIONs:\n";
$t = "\n" . $all;
# $t .= "<dbooth> [PENDING] ACTION: My fake action text1\n";	# Test
# $t .= "<dbooth> *PENDING* ACTION: My fake action text2\n";	# Test
# $t .= "<dbooth> PENDING ACTION: My fake action text3\n";	# Test
# $t .= "<dbooth> ACTION: My fake action text4 (PENDING)\n";	# Test
# $t .= "<dbooth> ACTION: My fake action text5 PENDING\n";	# Test
# $t .= "<dbooth> ACTION: My fake action text6 *PENDING*\n";	# Test
if ($trustRRSAgent) {
    my @lines = split(/\n/, $all);
    for (my $i = 0; $i <= $#lines; $i++) {
	$_ = $lines[$i];
	next unless (m/^<RRSAgent>/);
	if (m/^<RRSAgent> I see \d+ open action items:$/) {
	    # RRSAgent is giving us a new list of action items
	    # Forget the list that we had until now
	    %actions = ();
	    next;
	}
	next unless (m/<RRSAgent> ACTION: (.*)$/);
	my $action = "$1";
	$action =~ s/\s+\Z//;
	$action =~ s/\s*\[\d+\]\Z//;
	next if exists($actions{$action});
	$actions{$action} = "UNKNOWN";
    }
} else {
while ($t =~ s/(.|\n)*?\n\<[^\>]+\>\s*[\[\(\-\*\s]*(((NEW)}(DONE)|(PENDING)|(DROPPED))[\]\)\-\*\s]*\s+)?ACTION\s*\:\s*(.*?)\s*\n/\n/)
	{
	my $action = $8;
	my $status = $3 ? $3 : "NEW";
	# warn "action: $action status: $status\n";
	$action =~ s/\A\s+//;
	$action =~ s/\s+\Z//;
	$action =~ s/\s*\[\d+\]\Z//;	# Remove action numbers: [4]
	$status = $1 if $action =~ s/[\[\(\-\*\s]+((NEW)|(DONE)|(PENDING)|(DROPPED))[\]\)\-\*\s]*\Z//i;
	next if exists($actions{$action});
	$actions{$action} = $status;
	# warn "ACTION: '$action' STATUS: '$status'\n";
	}
}

# Get a list of people who have action items:
my %actionPeople = ();
foreach my $a ((keys %actions))
	{
	# warn "action:$a:\n";
	if ($a =~ m/\s+(to)\s+/i)
		{
		my $pre = $`;
		my @names = split(/[^a-zA-Z0-9\-\_]+/,$pre);
		# warn "names: @names\n";
		foreach my $n (@names)
			{
			next if $n eq "";
			next if $n eq "and";
			$actionPeople{$n} = $n;
			}
		}
	elsif ($a =~ m/\A([a-zA-Z0-9\-\_]+)/)
		{
		my $n = $1;
		$actionPeople{$n} = $n;
		}
	else	{
		warn "NO PERSON FOUND FOR ACTION: $a\n";
		}
	}
warn "People with action items: ",join(" ", keys %actionPeople), "\n";

# Format the resulting action items:
# warn "ACTIONS:\n";
# my $actionTemplate = "<strong>ACTION:</strong> \$action <strong>[\$status]</strong> <br />\n";
my $actionTemplate = "<strong>[\$status]</strong> <strong>ACTION:</strong> \$action <br />\n";
my $formattedActions = "";
foreach my $status (qw(UNKNOWN PENDING NEW DROPPED DONE))
	{
	foreach my $action (keys %actions)
		{
		next if $actions{$action} ne $status;
		my $s = $actionTemplate;
		$s =~ s/\$action/$action/;
		if ($status ne 'UNKNOWN') {
		    $s =~ s/\$status/$status/;
		} else {
		    $s =~ s/^.+? //;
		}
		$formattedActions .= $s;
		delete($actions{$action});
		}
	$formattedActions .= "<br />\n\n";
	}
foreach my $status (qw(DONE DROPPED))
	{
	foreach my $action (keys %actions)
		{
		next if $actions{$action} ne $status;
		# Don't need to do anything for the done or dropped actions.
		delete($actions{$action});
		}
	}
# There shouldn't be any more kinds of actions, but if there are, format them
# $actions{'FAKE ACTION TEXT'} = 'OTHER_STATUS';	# Test
foreach my $status (sort values %actions)
	{
	foreach my $action (keys %actions)
		{
		next if $actions{$action} ne $status;
		my $s = $actionTemplate;
		$s =~ s/\$action/$action/;
		$s =~ s/\$status/$status/;
		$formattedActions .= $s;
		delete($actions{$action});
		}
	$formattedActions .= "<br />\n\n";
	}

# Ignore off-record lines and other lines that should not be minuted.
my @lines = split(/\n/, $all);
my $nLines = scalar(@lines);
warn "Lines found: $nLines\n";
my @scribeLines = ();
foreach my $line (@lines)
	{
	# Ignore /me lines
	next if $line =~ m/\A\s*\*/;
	# Select only <speaker> lines
	next if $line !~ m/\A\<$namePattern\>/i;
	# Ignore empty lines
	next if $line =~ m/\A\<$namePattern\>\s*\Z/i;
	# Ignore join/leave lines:
	next if $line =~ m/\A\s*\<($namePattern)\>\s*\1\s+has\s+(joined|left|departed|quit)\s*((\S+)?)\s*\Z/i;
	next if $line =~ m/\A\s*\<(Scribe)\>\s*$namePattern\s+has\s+(joined|left|departed|quit)\s*((\S+)?)\s*\Z/i;
	# Ignore topic change lines:
	# <geoff_a> geoff_a has changed the topic to: Trout Mask Replica
	next if $line =~ m/\A\s*\<($namePattern)\>\s*\1\s+(has\s+changed\s+the\s+topic\s+to\s*\:.*)\Z/i;
	# Ignore zakim lines
	next if $line =~ m/\A\<Zakim\>/i;
	next if $line =~ m/\A\<$namePattern\>\s*zakim\s*\,/i;
	next if $line =~ m/\A\<$namePattern\>\s*agenda\s*\d*\s*[\+\-\=\?]/i;
	next if $line =~ m/\A\<$namePattern\>\s*close\s+agend(a|(um))\s+\d+\Z/i;
	next if $line =~ m/\A\<$namePattern\>\s*open\s+agend(a|(um))\s+\d+\Z/i;
	next if $line =~ m/\A\<$namePattern\>\s*take\s+up\s+agend(a|(um))\s+\d+\Z/i;
	next if $line =~ m/\A\<$namePattern\>\s*q\s*[\+\-\=\?]/i;
	next if $line =~ m/\A\<$namePattern\>\s*ack\s+$namePattern\s*\Z/i;
	# Ignore RRSAgent lines
	next if $line =~ m/\A\<RRSAgent\>/i;
	next if $line =~ m/\A\<$namePattern\>\s*RRSAgent\s*\,/i;
	# Remove off the record comments:
	next if $line =~ m/\A\<$namePattern\>\s*\[\s*off\s*\]/i;
	# Select only <scribe> lines?
	next if $scribeOnly && $line !~ m/\A\<Scribe\>/i;
	# warn "KEPT: $line\n";
	push(@scribeLines, $line);
	}
my $nScribeLines = scalar(@scribeLines);
warn "Minuted lines found: $nScribeLines\n";
@lines = @scribeLines;

# Verify that we axed all join/leave lines:
{
my $all = join("\n", @lines);
my @matches = ($all =~ m/.*has joined.*\n/g);
warn "WARNING: Possible join/leave lines remaining: \n\t" . join("\t", @matches)
 	if @matches;
}

# Convert from:
#	<Scribe> DanC: something
#	<Scribe> DanC: something
#	<DanC> something
#	<DanC> something
#	<Scribe> DanC: something
#	<Scribe> ----
#	<Scribe> Whatever
# to:
#	DanC: something
#	 ... something
#	<DanC> something
#	 ... something
#	DanC: something
#	----------------------------------------
#	<Scribe> Whatever

my $prevSpeaker = "UNKNOWN_SPEAKER:";	# "DanC:" or "<DanC>"
my $prevPattern = quotemeta($prevSpeaker);
foreach my $line (@lines)
	{
	# warn "$line";
	if ($line =~ m/\A\<$namePattern\>\s*Topic\s*\:/i )
		{
		# New topic.
		# Force the speaker name to be repeated next time
		$prevSpeaker = "UNKNOWN_SPEAKER:";	# "DanC:" or "<DanC>"
		$prevPattern = quotemeta($prevSpeaker);
		}
	# Separator:
	#	<Scribe> ----
	elsif ($line =~ m/\A(\<$namePattern\>)\s*\-\-\-\-+\s*\Z/i)
		{
		my $dashes = '-' x 30;
		$line = $dashes;
		}
	# Separator:
	#	<Scribe> ====
	elsif ($line =~ m/\A(\<$namePattern\>)\s*\=\=\=\=+\s*\Z/i)
		{
		my $dashes = '=' x 30;
		$line = $dashes;
		}
	elsif ($line =~ s/\A\<Scribe\>\s*($prevPattern)\s*/ ... /i )
		{
		}
	elsif ($line =~ s/\A\<Scribe\>\s*($speakerPattern\:)\s*/$1 /i )
		{
		# New speaker
		$prevSpeaker = "$1";
		$prevPattern = quotemeta($prevSpeaker);
		}
	elsif ($line =~ s/\A$prevPattern\s*/ ... /i)
		{
		}
	elsif ($line =~ s/\A(\<Scribe\>)\s*/Scribe\: /i )
		{
		# Scribe speaks
		$prevSpeaker = $1;
		$prevPattern = quotemeta($prevSpeaker);
		}
	elsif ($line =~ m/\A(\<$namePattern\>)/i)
		{
		$prevSpeaker = $1;
		$prevPattern = quotemeta($prevSpeaker);
		}
	else	{
		die "DIED FROM UNKNOWN LINE FORMAT: $line\n";
		}
	}

$all = join("\n", @lines);
$all = "\n" . $all . "\n";	# Easier pattern matching

##############  Escape < > as &lt; &gt; ################
# Escape < and >:
$all =~ s/\</\&lt\;/g;
$all =~ s/\>/\&gt\;/g;

# Format topic titles (i.e., collect agenda):
my %agenda = ();
my $itemNum = "item01";
while ($all =~ s/\n(\&lt\;$namePattern\&gt\;\s+)?Topic\:\s*(.*)\n/\n$preTopicHTML id\=\"$itemNum\"\>$4$postTopicHTML\n/i)
	{
	$agenda{$itemNum} = $4;
	$itemNum++;
	}
if (!scalar(keys %agenda)) 	# No "Topic:"s found?
	{
	warn "\nWARNING: No \"Topic: ...\" lines found!  \nResulting HTML may have an empty (invalid) <ol>...</ol>.\n\nExplanation: \"Topic: ...\" lines are used to indicate the start of \nnew discussion topics or agenda items, such as:\n<dbooth> Topic: Review of Amy's report\n\n";
	}
my $agenda = "";
foreach my $item (sort keys %agenda)
	{
	$agenda .= '<li><a href="#' . $item . '">' . $agenda{$item} . "</a></li>\n";
	}

# Break into paragraphs:
$all =~ s/\n(([^\ \.\<].*)(\n\ *\.\.+.*)*)/\n$preParagraphHTML\n$1\n$postParagraphHTML\n/g;

# Highlight in-line ACTION items:
$all =~ s/(\n)ACTION\:/$1\<strong\>ACTION\:\<\/strong\>/g;
$all =~ s/(\n\&lt\;$namePattern\&gt\;\ +)ACTION\:/$1\<strong\>ACTION\:\<\/strong\>/g;

# Bold or <strong> speaker name:
# Change "<speaker> ..." to "<b><speaker><b> ..."
my $preUniq = "PreSpEaKerHTmL";
my $postUniq = "PostSpEaKerHTmL";
$all =~ s/\n(\&lt\;($namePattern)\&gt\;)\s*/\n\&lt\;$preUniq$2$postUniq\&gt\; /ig;
# Change "speaker: ..." to "<b>speaker:<b> ..."
$all =~ s/\n($speakerPattern)\:\s*/\n$preUniq$1\:$postUniq /ig;
$all =~ s/$preUniq/$preSpeakerHTML/g;
$all =~ s/$postUniq/$postSpeakerHTML/g;

# Add <br /> before continuation lines:
$all =~ s/\n(\ *\.)/ <br \/>\n$1/g;
# Collapse multiple <br />s:
$all =~ s/<br \/>((\s*<br \/>)+)/<br \/>/g;
# Standardize continuation lines:
# $all =~ s/\n\s*\.+/\n\.\.\./g;
# Make links:
$all =~ s/(http\:([^\)\]\}\<\>\s\"\']+))/<a href=\"$1\">$1<\/a>/g;

# Put into template:
# $all =~ s/\A\s*<\/p>//;
# $all .= "\n<\/p>\n";
my $presentAttendees = join(", ", @present);
my $regrets = join(", ", @regrets);

my $result = $template;
$result =~ s/SV_MEETING_DAY/$day0/g;
$result =~ s/SV_MEETING_MONTH_ALPHA/$monthAlpha/g;
$result =~ s/SV_MEETING_YEAR/$year/g;
$result =~ s/SV_MEETING_MONTH_NUMERIC/$mon0/g;
$result =~ s/SV_PREVIOUS_MEETING_URL/$previousURL/g;
$result =~ s/SV_MEETING_CHAIR/$chair/g;
$result =~ s/SV_MEETING_SCRIBE/$scribeName/g;
$result =~ s/SV_MEETING_AGENDA/$agenda/g;
$result =~ s/SV_TEAM_PAGE_LOCATION/SV_TEAM_PAGE_LOCATION/g;

$result =~ s/SV_REGRETS/$regrets/g;
$result =~ s/SV_PRESENT_ATTENDEES/$presentAttendees/g;
if ($result !~ s/SV_ACTION_ITEMS/$formattedActions/)
	{
	if ($result =~ s/SV_NEW_ACTION_ITEMS/$formattedActions/)
		{ warn "WARNING: Template format has changed.  SV_NEW_ACTION_ITEMS should now be SV_ACTION_ITEMS\n"; }
	else { warn "WARNING: SV_ACTION_ITEMS marker not found in template!\n"; } 
	}
$result =~ s/SV_AGENDA_BODIES/$all/;
$result =~ s/SV_MEETING_TITLE/$title/g;

my $formattedLogURL = '<p>See also: <a href="SV_MEETING_IRC_URL">IRC log</a></p>';
if ($logURL eq "SV_MEETING_IRC_URL")
	{
	warn "**** Missing IRC LOG!!!! ****\n";
	$formattedLogURL = "";
	}
$formattedLogURL = "" if $logURL =~ m/\ANone\Z/i;
$result =~ s/SV_FORMATTED_IRC_URL/$formattedLogURL/g;
$result =~ s/SV_MEETING_IRC_URL/$logURL/g;
	

print $result;
exit 0;

##################################################################
########################## NormalizerMircTxt #########################
##################################################################
# Format from saving MIRC buffer.
sub NormalizerMircTxt
{
die if @_ != 1;
my ($all) = @_;
# Join continued lines:
$all =~ s/\n\ \ //g;
# Fix split URLs:
# 	<RalphS> -> http://lists.w3.org/Archives/Team/w3t-mit/2002Mar/00
# 	  46.html Simon's two minutes
# while ($all =~ s/(http\:[^\ ]+)\n\ \ /$1/ig) {}
# while ($all =~ s/(http\:[^\ ]+)\n\ /$1/ig) {}
# Count the number of recognized lines
my @lines = split(/\n/, $all);
my $n = 0;
my $namePattern = '([\\w\\-]([\\w\\d\\-]*))';
foreach my $line (@lines)
	{
	# * unlogged comment
	if ($line =~ m/\A\s*\*\s/) { $n++; }
	# <ericn> Discussion on how to progress
	elsif ($line =~ m/\A\<$namePattern\>\s/) { $n++; }
	# warn "LINE: $line\n";
	}
# warn "NormalizerMircTxt n matches: $n\n";
my $score = $n / @lines;
return($score, $all);
}

##################################################################
########################## NormalizerRRSAgentText #########################
##################################################################
# Example: http://www.w3.org/2003/03/03-ws-desc-irc.txt
sub NormalizerRRSAgentText
{
die if @_ != 1;
my ($all) = @_;
# Join continued lines:
$all =~ s/\n\ \ //g;
# Count the number of recognized lines
my @lines = split(/\n/, $all);
my $n = 0;
my $namePattern = '([\\w\\-]([\\w\\d\\-]*))';
my $timePattern = '((\s|\d)\d\:(\s|\d)\d\:(\s|\d)\d)';
foreach my $line (@lines)
	{
	# 20:41:27 <ericn> Review of minutes 
	$n++ if $line =~ s/\A$timePattern\s+(\<$namePattern\>\s)/$5/;
	# warn "LINE: $line\n";
	}
$all = join("\n", @lines);
# warn "NormalizerRRSAgentText n matches: $n\n";
my $score = $n / @lines;
return($score, $all);
}

##################################################################
########################## NormalizerRRSAgentHtml #########################
##################################################################
# Example: http://www.w3.org/2003/03/03-ws-desc-irc.html
sub NormalizerRRSAgentHtml
{
die if @_ != 1;
my ($all) = @_;
my @lines = split(/\n/, $all);
my $n = 0;
my $namePattern = '([\\w\\-]([\\w\\d\\-]*))';
my $timePattern = '((\s|\d)\d\:(\s|\d)\d\:(\s|\d)\d)';
foreach my $line (@lines)
	{
	# <dt id="T14-35-34">14:35:34 [scribe]</dt><dd>Gudge: why not sufficient?</dd>
	$n++ if $line =~ s/\A\<dt\s+id\=\"($namePattern)\"\>$timePattern\s+\[($namePattern)\]\<\/dt\>\s*\<dd\>(.*)\<\/dd\>\s*\Z/\<$8\> $11/;
	# warn "LINE: $line\n";
	}
$all = join("\n", @lines);
# warn "NormalizerRRSAgentHtml n matches: $n\n";
my $score = $n / @lines;
# Unescape &entity;
$all =~ s/\&amp\;/\&/g;
$all =~ s/\&lt\;/\</g;
$all =~ s/\&gt\;/\>/g;
$all =~ s/\&quot\;/\"/g;
return($score, $all);
}

##################################################################
########################## NormalizerRRSAgentHTMLText #########################
##################################################################
# This is for the format that is displayed in the browser from HTML.
# I.e., when you display the HTML in a browser, and then copy and paste
# the text from the browser window.
sub NormalizerRRSAgentHTMLText
{
die if @_ != 1;
my ($all) = @_;
my $n = 0;
my $namePattern = '([\\w\\-]([\\w\\d\\-]*))';
my $timePattern = '((\s|\d)\d\:(\s|\d)\d\:(\s|\d)\d)';
my $done = "";
while($all =~ s/\A((.*\n)(.*\n))//)	# Grab next two lines
	{
	my $linePair = $1;
	my $line1 = $2;
	my $line2 = $3;
	# This format uses line pairs:
	# 	14:43:30 [Arthur]
	# 	If it's abstract, it goes into portType 
	if ($linePair =~ s/\A($timePattern)\s+\[($namePattern)\][\ \t]*\n/\<$6\> /)
		{
		$n++;
		# warn "LINE: $line\n";
		$done .= $linePair;
		}
	else	{
		$done .= $line1;
		$all = $line2 . $all;
		}
	}
$done .= $all;
$all = $done;
# warn "NormalizerRRSAgentHTMLText n matches: $n\n";
my @lines = split(/\n/, $all);
my $score = $n / @lines;
return($score, $all);
}

##################################################################
########################## NormalizerYahoo #########################
##################################################################
sub NormalizerYahoo
{
die if @_ != 1;
my ($all) = @_;
my @lines = split(/\n/, $all);
my $n = 0;
my $namePattern = '([\\w\\-]([\\w\\d\\-]*))';
foreach my $line (@lines)
	{
	$n++ if $line =~ s/\A($namePattern)\:\s/\<$1\> /;
	# warn "LINE: $line\n";
	}
$all = join("\n", @lines);
# warn "NormalizerYahoo n matches: $n\n";
my $score = $n / @lines;
return($score, $all);
}

##################################################################
########################## NormalizerPlainText #########################
##################################################################
# This is just a plain text file of notes made by the scribe.
# This format does NOT use timestamps, nor does it use <speakerName>
# at the beginning of each line.  It does still use the "dbooth: ..."
# convention to indicate what someone said.
sub NormalizerPlainText
{
die if @_ != 1;
my ($all) = @_;
# Join continued lines:
# Count the number of recognized lines
my @lines = split(/\n/, $all);
my $n = 0;
my $timePattern = '((\s|\d)\d\:(\s|\d)\d\:(\s|\d)\d)';
my $namePattern = '([\\w\\-]([\\w\\d\\-]*))';
for (my $i=0; $i<@lines; $i++)
	{
	# Lines should NOT have timestamps:
	# 	20:41:27 <ericn> Review of minutes 
	next if $lines[$i] =~ m/\A$timePattern\s+/;
	# Lines should NOT start with <speakerName>:
	# 	<ericn> Review of minutes 
	next if $lines[$i] =~ m/\A(\<$namePattern\>\s)/;
	# warn "LINE: $lines[$i]\n";
	$n++;
	}
# Now add "<scribe> " to the beginning of each line, to make it like
# the standard format.
for (my $i=0; $i<@lines; $i++)
	{
	$lines[$i] = "<scribe> " . $lines[$i];
	}
$all = join("\n", @lines);
# warn "NormalizerPlainText n matches: $n\n";
my $score = $n / @lines;
return($score, $all);
}

##################################################################
##################### GetTemplate ####################
##################################################################
sub GetTemplate
{
@_ == 1 || die;
my ($templateFile) = @_;
open($templateFile,"<$templateFile") || return "";
my $template = join("",<$templateFile>);
$template =~ s/\r//g;
close($templateFile);
return $template;
}

##################################################################
######################## GetDate ####################
##################################################################
# Grab date from $all or IRC log name or default to today's date.
sub GetDate
{
@_ == 3 || die;
my ($all, $namePattern, $logURL) = @_;
my @days = qw(Sun Mon Tue Wed Thu Fri Sat); 
@days == 7 || die;
my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
@months == 12 || die;
my %monthNumbers = map {($months[$_], $_+1)} (0 .. 11);
# warn "GetDate monthNumbers: ",join(" ",%monthNumbers),"\n";
my @date = ();
# Look for Date: 12 Sep 2002
if ($all =~ s/\n\<$namePattern\>\s*(Date)\s*\:\s*(.*)\n/\n/i)
	{
	# Parse date from input.
	# I should have used a library function for this, but I wrote
	# this without net access, so I couldn't get one.
	my $d = $4;
	$d =~ s/\A\s+//;
	$d =~ s/\s+\Z//;
	warn "Found Date: $d\n";
	my @words = split(/\s+/, $d);
	die "ERROR: Date not understood: $d\n" if @words != 3;
	my ($mday, $tmon, $year) = @words;
	exists($monthNumbers{$tmon}) || die;
	my $mon = $monthNumbers{$tmon};
	($mon > 0 && $mon < 13) || die;
	($mday > 0 && $mday < 32) || die;
	($year > 2000 && $year < 2100) || die;
	my $day0 = sprintf("%0d", $mday);
	my $mon0 = sprintf("%0d", $mon);
	@date = ($day0, $mon0, $year, $tmon);
	}
# Figure out date from IRC log name:
elsif ($logURL =~ m/\Ahttp\:\/\/(www\.)?w3\.org\/(\d+)\/(\d+)\/(\d+).+\-irc/)
	{
	my $year = $2;
	my $mon = $3;
	my $mday = $4;
	($mon > 0 && $mon < 13) || die;
	($year > 2000 && $year < 2100) || die;
	($mday > 0 && $mday < 32) || die;
	my $day0 = sprintf("%0d", $mday);
	my $mon0 = sprintf("%0d", $mon);
	@date = ($day0, $mon0, $year, $months[$mon-1]);
	warn "Got date from IRC log name: $day0 " . $months[$mon-1] . " $year\n";
	}
else
	{
	warn "WARNING: No date found!  Assuming today.  (Hint: Specify\n";
	warn "the IRC log, and the date will be determined from that.)\n";
	warn "Or specify the date like this:\n";
	warn "<dbooth> Date: 12 Sep 2002\n\n";
	# Assume today's date by default.
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$mon++;	# put in range [1..12] instead of [0..11].
	($mon > 0 && $mon < 13) || die;
	$year += 1900;
	($year > 2000 && $year < 2100) || die;
	($mday > 0 && $mday < 32) || die;
	my $day0 = sprintf("%0d", $mday);
	my $mon0 = sprintf("%0d", $mon);
	@date = ($day0, $mon0, $year, $months[$mon-1]);
	}
# warn "GetDate Returning date info: @date\n";
return @date;
}



##################################################################
###################### GetNames ######################
##################################################################
# Look for people in IRC log.
sub GetNames
{
@_ == 2 || die;
my($all, $scribe) = @_;

# Some important data/constants:
my @rooms = qw(MIT308 SophiaSofa DISA);

my @stopList = qw(a q on Re items Zakim Topic muted and agenda Regrets http the
	RRSAgent Loggy Zakim2 ACTION Chair Meeting DONE PENDING WITHDRAWN
	Scribe 00AM 00PM P IRC Topics Keio DROPPED ger-logger
	yes no abstain Consensus Participants Question RESOLVED strategy
	AGREED Date speaker queue no one in XachBot got it WARNING);
@stopList = (@stopList, @rooms);
@stopList = map {tr/A-Z/a-z/; $_} @stopList;	# Make stopList lower case
my %stopList = map {($_,$_)} @stopList;

my %synonyms = ();
%synonyms = qw(
	alan-home	Alan
	amymtg		Amy
	caribou		Carine
        Chaals		Charles
        chaalsGVA	Charles
        chaalsNCE	Charles
	Dave		DaveRaggett
	DaveR		DaveRaggett
	DaveRagget	DaveRaggett
	dbooth		dbooth
	David		dbooth
	DB		dbooth
	DavidB		dbooth
        danbri		DanBri
	danc_		DanC
	danc		DanC
	dand		DanielD
	EM		EricM
	Eric		EricM
	ericP-WA	EricP
	ericP-air	EricP
	ger		Gerald
	HT		Henry
	HH		Hugo
	hugo		Hugo
	ivan		Ivan
	janSeaTac	Janet
	karl		Karl
	reagle-tu	JosephR
	reagleMIT	JosephR
	Joseph		JosephR
	judy		Judy
	MaxF		MaxF
	MCF		Marie-Claire
	MC		Marie-Claire
	marie		Marie-Claire
	mari		Marisol
	MSM		MichaelSM
	MSMbot		MichaelSM
	Michael		MichaelSM
	MJDuesrst	Martin
	olivier		Olivier
	plh		Philippe
	plh-sjc		Philippe
	Ralph		RalphS
	rigo		Rigo
	sandro		Sandro
	sim		Simon
	simHOME		Simon
	Hernandez	Simon
	SB		Steve
	SusanL		SusanLesch
	Ted		Ted
	Tim		TimBL
	VQ		VincentQ
	) if $useTeamSynonyms;
foreach my $n (values %synonyms)
	{
	$synonyms{$n} = $n;	# Make TimBL --> TimBL
	}

# Easier pattern matching:
$all = "\n" . $all . "\n";

# Now start collecting names.
my %names =  ();
my $t; # Temp

# 	  ...something.html Simon's two minutes
$t = $all;
my $namePattern = '([\\w\\-]([\\w\\d\\-]*))';
# warn "namePattern: $namePattern\n";
while($t =~ s/\b($namePattern)\'s\s+(2|two)\s+ minutes/ /)
	{
	my $n = $1;
	$names{$n} = $n;
	}

#	<dbooth> MC: I have integrated most of the coments i received 
$t = $all;
while($t =~ s/\n\<((\w|\-)+)\>(\ +)((\w|\-)+)\:/\n/i)
	{
	my $n = $4;
	next if exists($names{$n});
	# warn "Matched #	<dbooth> $n" . ": ...\n";
	$names{$n} = $n;
	}
# warn "names: ",join(" ",keys %names),"\n";

#	<Steven> Hello 
$t = $all;
while($t =~ s/\n\<((\w|\-)+)\>/\n/)
	{
	my $n = $1;
	next if exists($names{$n});
	# warn "Matched #	<$n>\n";
	$names{$n} = $n;
	# warn "Found name: $n\n";
	}

#	Zakim sees 4 items remaining on the agenda
$t = $all;
while ($t =~ s/\n\s*((\<Zakim\>)|(\*\s*Zakim\s)).*\b(agenda|agendum)\b.*\n/\n/)
	{
	my $match = $&;
	$match =~ s/\A\s+//;
	$match =~ s/\s+\Z//;
	# warn "DELETED: $match\n";
	}

#	<Zakim> I see no one on the speaker queue
#	<Zakim> I see Hugo, Yves, Philippe on the speaker queue
#	<Zakim> I see MIT308, Ivan, Marie-Claire, Steven, Janet, EricM
#	<Zakim> On the phone I see Joseph, m3mSEA, MIT308, Marja
#	<Zakim> On IRC I see Nobu, SusanL, RRSAgent, ht, Ian, ericP
#	<Zakim> ... simonMIT, XachBot
#	<Zakim> I see MIT308, Ivan, Marie-Claire, Steven, Janet, EricM
#	<Zakim> MIT308 has Martin, Ted, Ralph, Alan, EricP, Vivien
#	<Zakim> +Carine, Yves, Hugo; got it
#
# The stopList will later eliminate "no one" or "on the speaker queue",
# so we don't need to worry about them here.
while($t =~ s/\n\<Zakim\>\s+((([\w\d\_][\w\d\_\-]+) has\s+)|(I see\s+)|(On the phone I see\s+)|(On IRC I see\s+)|(\.\.\.\s+)|(\+))(.*)\n/\n/)
	{
	my $list = $9;
	$list =~ s/\A\s+//;
	$list =~ s/\s+\Z//;
	my @names = split(/[^\w\-]+/, $list);
	@names = map {s/\A\s+//; s/\s+\Z//; $_} @names;
	@names = grep {$_} @names;
	# warn "Matched #       <Zakim> I see: @names\n";
	foreach my $n (@names)
		{
		next if exists($names{$n});
		$names{$n} = $n;
		}
	}

# Make the keys all lower case, so that they'll match:
%synonyms = map {my $oldn = $_; tr/A-Z/a-z/; ($_, $synonyms{$oldn})} keys %synonyms;
%names = map {my $oldn = $_; tr/A-Z/a-z/; ($_, $names{$oldn})} keys %names;
# warn "Lower case name keys:\n";
foreach my $n (sort keys %names)
	{
	# warn "	$n	$names{$n}\n";
	}

# Map synonyms to standardize spellings and expand abbreviations.
%names = map 	{
		exists($synonyms{$_}) 
			? ($_, $synonyms{$_}) 
			: ($_, $names{$_})
		} keys %names;
# At this point different keys may map to the same value.
# warn "After applying synonyms:\n";
foreach my $n (keys %names)
	{
	# warn "	$n	$names{$n}\n";
	}

# Eliminate non-names
foreach my $n (keys %names)
	{
	# Filter out names in stopList
	if (exists($stopList{$n})) { delete $names{$n}; }
	# Filter out names less than two chars in length:
	elsif (length($n) < 2) { delete $names{$n}; }
	# Filter out names not starting with a letter
	elsif ($names{$n} !~ m/\A[a-zA-Z]/) { delete $names{$n}; }
	}

# Make a list of unique names for the attendee list:
my %uniqNames = ();
foreach my $n (values %names)
	{
	$uniqNames{$n} = $n;
	}

# Make a list of all names seen (all variations) in lower case:
my %allNames = ();
foreach my $n (%names, %synonyms)
	{
	my $name = $n;
	$name =~ tr/A-Z/a-z/;
	$allNames{$name} = $name;
	}
@allNames = sort keys %allNames;
# warn "allNames: @allNames\n";
my @allNameRefs = map { \$_ } @allNames;

# Canonicalize (normalize) the names in the IRC:
my $expandedIRC = $all;
my $nExpanded = 0;
foreach my $n (keys %synonyms)
	{
	next if !$canonicalizeNames;
	my $v = $synonyms{$n};
	next if $v eq $n;
	my $qn = quotemeta($n);
	if ($expandedIRC =~ s/([^\w\-])($qn)([^\w\-])/$1$v$3/ig)
		{
		$nExpanded++;
		# warn "============ START ============\n";
		# warn "	$expandedIRC\n";
		# warn "============ STOP ============\n";
		}
	}
# warn "nExpanded: $nExpanded\n";

my $lcScribe = $scribe;
$lcScribe =~ tr/A-Z/a-z/;
$scribe = $synonyms{$lcScribe} if exists($synonyms{$lcScribe});
my @sortedUniqNames = sort values %uniqNames;
return($expandedIRC, $scribe, \@allNameRefs, @sortedUniqNames);
}

##################################################################
################ DefaultTemplate ####################
##################################################################
sub DefaultTemplate
{
return &PublicTemplate();
}

##################################################################
####################### SampleInput ##############################
##################################################################
sub SampleInput
{
my $sampleInput = <<'SampleInput-EOF'
<dbooth> Scribe: dbooth
<dbooth> Chair: Jonathan
<dbooth> Meeting: Weekly Baking Club Meeting
<dbooth> Date: 05 Dec 2002
<dbooth> Topic: Review of Action Items
<Philippe> PENDING ACTION: Barbara to bake 3 pies 
<Philippe> ----
<Philippe> DONE ACTION: David to make ice cream 
<Philippe> ACTION: David to make frosting -- DONE
<Philippe> ACTION: David to make candles  *DONE*
<Philippe> ACTION: David to make world peace  *PENDING*
<dbooth> Topic: What to Eat for Dessert
<dbooth> Joseph: I think that we should all eat cake
<dbooth> ... with ice creme.
<dbooth> s/creme/cream/
<Philippe> That's a good idea
<dbooth> ACTION: dbooth to send a message to himself about action items
<dbooth> Topic: Next Week's Meeting
<Philippe> I think we should do this again next week.
<Jonathan> Sounds good to me.
<dbooth> rrsagent, where am i?
<RRSAgent> I am logging.
<RRSAgent> See http://www.w3.org/2002/11/07-ws-arch-irc#T13-59-36
SampleInput-EOF
;
return $sampleInput;
}

##################################################################
###################### PublicTemplate ############################
##################################################################
sub PublicTemplate
{
my $template = <<'PublicTemplate-EOF'
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
  <title>SV_MEETING_TITLE -- SV_MEETING_DAY SV_MEETING_MONTH_ALPHA SV_MEETING_YEAR</title>
  <LINK rel="STYLESHEET" href="http://www.w3.org/StyleSheets/base.css">
  <LINK rel="STYLESHEET" href="http://www.w3.org/StyleSheets/public.css">
  <meta content="SV_MEETING_TITLE" lang="en" name="Title">  
  <meta content="text/html; charset=iso-8859-1" http-equiv="Content-Type">
</head>

<body>
<p><a href="http://www.w3.org/"><img src="http://www.w3.org/Icons/WWW/w3c_home" alt="W3C" border="0"
height="48" width="72"></a> 

</p>

<h1>SV_MEETING_TITLE<br>
SV_MEETING_DAY SV_MEETING_MONTH_ALPHA SV_MEETING_YEAR</h1>

<!-- Old:
<p>See also: <a href="SV_MEETING_IRC_URL">IRC log</a></p>
-->
SV_FORMATTED_IRC_URL

<h2><a name="attendees">Attendees</a></h2>

<div class="intro">
<p>Present: SV_PRESENT_ATTENDEES</p>
<p>Regrets: SV_REGRETS</p>
<p>Chair: SV_MEETING_CHAIR </p>
<p>Scribe: SV_MEETING_SCRIBE</p>
</div>

<h2>Contents</h2>
<ul>
  <li><a href="#agenda">Topics</a>
	<ol>
	SV_MEETING_AGENDA
	</ol>
  </li>
  <li><a href="#newActions">Summary of Action Items</a></li>
</ul>
<hr>


<!--  We don't need the agenda items listed twice.
<h2><a name="agenda">Topics</a></h2>
<ul>
  SV_MEETING_AGENDA
</ul>
-->

SV_AGENDA_BODIES
<!--
<h3 id="item1">Item name (owner)</h3>
<p>... text of discussion ...</p>

<h3 id="item2">Item name (owner)</h3>
<p>... text of discussion ...</p>
-->


<h2><a name="newActions">Summary of Action Items</a></h2>
<!-- Action Items -->
SV_ACTION_ITEMS

<hr>

<address>
  <!--
  <a href="http://validator.w3.org/check/referer"><img border="0"
  src="http://validator.w3.org/images/vh40.gif" alt="Valid HTML 4.0!"
  height="31" width="88" align="right">
  </a> 
  -->
  <!-- <a href="/Team/SV_TEAM_PAGE_LOCATION">David Booth</a> <br /> -->
  Minutes formatted by David Booth's perl script: 
  <a href="http://dev.w3.org/cvsweb/~checkout~/2002/scribe/">http://dev.w3.org/cvsweb/~checkout~/2002/scribe/</a><br>
  $Date$ 
</address>
</body>
</html>
PublicTemplate-EOF
;
return $template;
}

##################################################################
###################### MemberTemplate ############################
##################################################################
sub MemberTemplate
{
my $template = <<'MemberTemplate-EOF'
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
  <title>SV_MEETING_TITLE -- SV_MEETING_DAY SV_MEETING_MONTH_ALPHA SV_MEETING_YEAR</title>
  <LINK rel="STYLESHEET" href="http://www.w3.org/StyleSheets/base.css">
  <LINK rel="STYLESHEET" href="http://www.w3.org/StyleSheets/member.css">
  <link rel="STYLESHEET" href="http://www.w3.org/StyleSheets/member-minutes.css">
  <meta content="SV_MEETING_TITLE" lang="en" name="Title">  
  <meta content="text/html; charset=iso-8859-1" http-equiv="Content-Type">
</head>

<body>
<p><a href="http://www.w3.org/"><img src="http://www.w3.org/Icons/WWW/w3c_home" alt="W3C" border="0"
height="48" width="72"></a> 
</p>

<h1>SV_MEETING_TITLE<br>
SV_MEETING_DAY SV_MEETING_MONTH_ALPHA SV_MEETING_YEAR</h1>

<!-- Old:
<p>See also: <a href="SV_MEETING_IRC_URL">IRC log</a></p>
-->
SV_FORMATTED_IRC_URL

<h2><a name="attendees">Attendees</a></h2>

<div class="intro">
<p>Present: SV_PRESENT_ATTENDEES</p>
<p>Regrets: SV_REGRETS</p>
<p>Chair: SV_MEETING_CHAIR </p>
<p>Scribe: SV_MEETING_SCRIBE</p>
</div>

<h2>Contents</h2>
<ul>
  <li><a href="#agenda">Topics</a>
	<ol>
	SV_MEETING_AGENDA
	</ol>
  </li>
  <li><a href="#newActions">Summary of Action Items</a></li>
</ul>
<hr>


<!--  We don't need the agenda items listed twice.
<h2><a name="agenda">Topics</a></h2>
<ul>
  SV_MEETING_AGENDA
</ul>
-->

SV_AGENDA_BODIES
<!--
<h3 id="item1">Item name (owner)</h3>
<p>... text of discussion ...</p>

<h3 id="item2">Item name (owner)</h3>
<p>... text of discussion ...</p>
-->


<h2><a name="newActions">Summary of Action Items</a></h2>
<!-- Done Action Items -->
SV_DONE_ACTION_ITEMS
<!-- Pending Action Items -->
SV_PENDING_ACTION_ITEMS
<!-- New Action Items -->
SV_ACTION_ITEMS

<hr>

<address>
  <!--
  <a href="http://validator.w3.org/check/referer"><img border="0"
  src="http://validator.w3.org/images/vh40.gif" alt="Valid HTML 4.0!"
  height="31" width="88" align="right">
  </a> 
  -->
  <!-- <a href="/Team/SV_TEAM_PAGE_LOCATION">David Booth</a> <br /> -->
  Minutes formatted by David Booth's perl script: 
  <a href="http://dev.w3.org/cvsweb/~checkout~/2002/scribe/">http://dev.w3.org/cvsweb/~checkout~/2002/scribe/</a><br>
  $Date$ 
</address>
</body>
</html>
MemberTemplate-EOF
;
return $template;
}

##################################################################
###################### TeamTemplate ############################
##################################################################
sub TeamTemplate
{
my $template = <<'TeamTemplate-EOF'
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
  <title>SV_MEETING_TITLE -- SV_MEETING_DAY SV_MEETING_MONTH_ALPHA SV_MEETING_YEAR</title>
  <LINK rel="STYLESHEET" href="http://www.w3.org/StyleSheets/base.css">
  <LINK rel="STYLESHEET" href="http://www.w3.org/StyleSheets/team.css">
  <link rel="STYLESHEET" href="http://www.w3.org/StyleSheets/team-minutes.css">
  <meta content="SV_MEETING_TITLE" lang="en" name="Title">  
  <meta content="text/html; charset=iso-8859-1" http-equiv="Content-Type">
</head>

<body>
<p><a href="http://www.w3.org/"><img src="http://www.w3.org/Icons/WWW/w3c_home" alt="W3C" border="0"
height="48" width="72"></a> 

</p>

<h1>SV_MEETING_TITLE<br>
SV_MEETING_DAY SV_MEETING_MONTH_ALPHA SV_MEETING_YEAR</h1>

<!-- Old:
<p>See also: <a href="SV_MEETING_IRC_URL">IRC log</a></p>
-->
SV_FORMATTED_IRC_URL

<h2><a name="attendees">Attendees</a></h2>

<div class="intro">
<p>Present: SV_PRESENT_ATTENDEES</p>
<p>Regrets: SV_REGRETS</p>
<p>Chair: SV_MEETING_CHAIR </p>
<p>Scribe: SV_MEETING_SCRIBE</p>
</div>

<h2>Contents</h2>
<ul>
  <li><a href="#agenda">Topics</a>
	<ol>
	SV_MEETING_AGENDA
	</ol>
  </li>
  <li><a href="#newActions">Summary of Action Items</a></li>
</ul>
<hr>


<!--  We don't need the agenda items listed twice.
<h2><a name="agenda">Topics</a></h2>
<ul>
  SV_MEETING_AGENDA
</ul>
-->

SV_AGENDA_BODIES
<!--
<h3 id="item1">Item name (owner)</h3>
<p>... text of discussion ...</p>

<h3 id="item2">Item name (owner)</h3>
<p>... text of discussion ...</p>
-->


<h2><a name="newActions">Summary of Action Items</a></h2>
<!-- Done Action Items -->
SV_DONE_ACTION_ITEMS
<!-- Pending Action Items -->
SV_PENDING_ACTION_ITEMS
<!-- New Action Items -->
SV_ACTION_ITEMS

<hr>

<address>
  <!--
  <a href="http://validator.w3.org/check/referer"><img border="0"
  src="http://validator.w3.org/images/vh40.gif" alt="Valid HTML 4.0!"
  height="31" width="88" align="right">
  </a> 
  -->
  <!-- <a href="/Team/SV_TEAM_PAGE_LOCATION">David Booth</a> <br /> -->
  Minutes formatted by David Booth's perl script: 
  <a href="http://dev.w3.org/cvsweb/~checkout~/2002/scribe/">http://dev.w3.org/cvsweb/~checkout~/2002/scribe/</a><br>
  $Date$ 
</address>
</body>
</html>
TeamTemplate-EOF
;
return $template;
}

##################################################################
###################### MITTemplate ############################
##################################################################
sub MITTemplate
{
my $template = <<'MITTemplate-EOF'
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
  <title>SV_MEETING_TITLE -- SV_MEETING_DAY SV_MEETING_MONTH_ALPHA SV_MEETING_YEAR</title>
  <LINK rel="STYLESHEET" href="http://www.w3.org/StyleSheets/base.css">
  <LINK rel="STYLESHEET" href="http://www.w3.org/StyleSheets/team.css">
  <link rel="STYLESHEET" href="http://www.w3.org/StyleSheets/team-minutes.css">
  <meta content="SV_MEETING_TITLE" lang="en" name="Title">  
  <meta content="text/html; charset=iso-8859-1" http-equiv="Content-Type">
</head>

<body>
<p><a href="http://www.w3.org/"><img src="http://www.w3.org/Icons/WWW/w3c_home" alt="W3C" border="0"
height="48" width="72"></a> <a href="http://www.w3.org/Team"><img width="48" height="48"
alt="W3C Team home" border="0" src="http://www.w3.org/Icons/WWW/team"></a> | <a
href="http://www.w3.org/Team/Meeting/MIT-scribes">MIT Meetings</a> | <a href="http://www.w3.org/">SV_MEETING_MONTH_ALPHA
SV_MEETING_YEAR</a></p>

<h1>SV_MEETING_TITLE<br>
SV_MEETING_DAY SV_MEETING_MONTH_ALPHA SV_MEETING_YEAR</h1>

<!-- Old:
<p>See also: <a href="SV_MEETING_IRC_URL">IRC log</a></p>
-->
SV_FORMATTED_IRC_URL

<h2><a name="attendees">Attendees</a></h2>

<div class="intro">
<p>Present: SV_PRESENT_ATTENDEES</p>
<p>Regrets: SV_REGRETS</p>
<p>Chair: SV_MEETING_CHAIR </p>
<p>Scribe: SV_MEETING_SCRIBE</p>
</div>

<h2>Contents</h2>
<ul>
  <li><a href="#agenda">Topics</a>
	<ol>
	SV_MEETING_AGENDA
	</ol>
  </li>
  <li><a href="#newActions">Summary of Action Items</a></li>
</ul>
<hr>


<!--  We don't need the agenda items listed twice.
<h2><a name="agenda">Topics</a></h2>
<ul>
  SV_MEETING_AGENDA
</ul>
-->

SV_AGENDA_BODIES
<!--
<h3 id="item1">Item name (owner)</h3>
<p>... text of discussion ...</p>

<h3 id="item2">Item name (owner)</h3>
<p>... text of discussion ...</p>
-->


<h2><a name="newActions">Summary of Action Items</a></h2>
<!-- Done Action Items -->
SV_DONE_ACTION_ITEMS
<!-- Pending Action Items -->
SV_PENDING_ACTION_ITEMS
<!-- New Action Items -->
SV_ACTION_ITEMS

<hr>

<address>
  <!--
  <a href="http://validator.w3.org/check/referer"><img border="0"
  src="http://validator.w3.org/images/vh40.gif" alt="Valid HTML 4.0!"
  height="31" width="88" align="right">
  </a> 
  -->
  <!-- <a href="/Team/SV_TEAM_PAGE_LOCATION">David Booth</a> <br /> -->
  Minutes formatted by David Booth's perl script: 
  <a href="http://dev.w3.org/cvsweb/~checkout~/2002/scribe/">http://dev.w3.org/cvsweb/~checkout~/2002/scribe/</a><br>
  $Date$ 
</address>
</body>
</html>
MITTemplate-EOF
;
return $template;
}


