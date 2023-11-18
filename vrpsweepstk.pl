#!/usr/bin/env perl

# sweeps logging program
# - dupes
# - scoring
# - cabrillo v2 output

#use strict;
#use warnings;

use Template;
use lib '.';
use Hamlib;

Hamlib::rig_set_debug($Hamlib::RIG_DEBUG_ERR);
$rig = new Hamlib::Rig($Hamlib::RIG_MODEL_K3);
$rig->set_conf("rig_pathname", "/dev/cuaU0");

$rig->open();

use English;
require Tk;
use Tk;
use Tk::Frame;
use Tk::TextUndo;
use Tk::Text;
use Tk::Scrollbar;
use Tk::Menu;
use Tk::Menubutton;
use Tk::Adjuster;
use Tk::DialogBox;
use Tk::NoteBook;
use Tk::Pane;
use Tk::Optionmenu;
use Tk::BrowseEntry;


use Data::Dumper;

use JSON::PP;
$json = JSON::PP->new->canonical->indent;

use POSIX qw(ceil);

use Getopt::Long qw(GetOptions);
my $civ_enable;
my $civ_debug;
GetOptions(
	'civ' => \$civ_enable,
	'civ-debug' => \$civ_debug
) or die "Usage: $0 --from NAME\n";

use Term::ReadLine;
$term = new Term::ReadLine 'vrpsweeps';

%qsos = ();
%history = ();
$history_used = 0;

$DEBUG = 1;

$message;

$sectMode = 0;
$SECT_LIST_CNT = 4; # how many columns of sections to display

$geom_x ="760";
$geom_y ="640";

# who what where
my $test_year = 1900 + (localtime)[5];
$infofile = "tests/$test_year.config";
my $op_json = do {
  open(my $info_fh, "<encoding(UTF-8)", "tests/$test_year.config")
    or die("Cant open info file: $!\n");
  local $/;
  <$info_fh>
};

#print "$op_json\n";

#my $json = JSON::PP->new->ascii->pretty->allow_nonref;
#my $op_info = $json->decode($op_json);
my $op_info = decode_json $op_json;

#print Dumper($op_info);
#print "$op_info\n";
#print "op_info_call: $op_info->{call}\n";

# swap hardcode with op_info vals for now, evetually swap out for op_info globally
$op_info->{call} = uc($op_info->{call});
$op_info->{precedence} = uc($op_info->{precedence});
$op_info->{section} = uc($op_info->{section});
$op_info->{check} = $op_info->{check};


#
$next_serial = 1;
$last_freq = 0;
$LOGFILE = "tests/$test_year.dat";
$JSONLOG = "tests/$test_year.dat.json";
$CABFILE = "tests/$test_year.cab";
$HISTORYFILE = "tests/$test_year.call-history";
$last_checked;
$last_qso;

$update_call;
$update_given_serial;

my $notebook;
my %Telltale;
my %Inputs;

my %precedences = (
  A => "Single Op Low Power",
  B => "Single Op High Power",
  M => "Multi-Op",
  Q => "Single Op QRP",
  S => "School Club",
  U => "Single Op Unlimited",
);

#my $precedences = [
#  ["A Single Op Low Power" => "A"],
#  ["B Single Op High Power" => "B"],
#  ["M Multi-Op" => "M"],
#  ["Q Single Op QRP" => "Q"],
#  ["S School Club" => "S"],
#  ["U Single Op Unlimited" => "U"],
#];

my %mults = (
CT => { worked => 0, longname => "Connecticut",},
EMA => { worked => 0, longname => "Eastern Massachusetts",},
ME => { worked => 0, longname => "Maine",},
NH => { worked => 0, longname => "New Hampshire",},
RI => { worked => 0, longname => "Rhode Island",},
VT => { worked => 0, longname => "Vermont",},
WMA => { worked => 0, longname => "Western Massachusetts",},
ENY => { worked => 0, longname => "Eastern New York",},
NLI => { worked => 0, longname => "New York City - Long Island",},
NNJ => { worked => 0, longname => "Northern New Jersey",},
NNY => { worked => 0, longname => "Northern New York",},
SNJ => { worked => 0, longname => "Southern New Jersey",},
WNY => { worked => 0, longname => "Western New York",},
DE => { worked => 0, longname => "Delaware",},
EPA => { worked => 0, longname => "Eastern Pennsylvania",},
MDC => { worked => 0, longname => "Maryland-DC",},
WPA => { worked => 0, longname => "Western Pennsylvania",},
AL => { worked => 0, longname => "Alabama",},
GA => { worked => 0, longname => "Georgia",},
KY => { worked => 0, longname => "Kentucky",},
NC => { worked => 0, longname => "North Carolina",},
NFL => { worked => 0, longname => "Northern Florida",},
PR => { worked => 0, longname => "Puerto Rico",},
SC => { worked => 0, longname => "South Carolina",},
SFL => { worked => 0, longname => "Southern Florida",},
TN => { worked => 0, longname => "Tennessee",},
VA => { worked => 0, longname => "Virginia",},
VI => { worked => 0, longname => "Virgin Islands",},
WCF => { worked => 0, longname => "West Central Florida",},
AR => { worked => 0, longname => "Arkansas",},
LA => { worked => 0, longname => "Louisiana",},
MS => { worked => 0, longname => "Mississippi",},
NM => { worked => 0, longname => "New Mexico",},
NTX => { worked => 0, longname => "North Texas",},
OK => { worked => 0, longname => "Oklahoma",},
STX => { worked => 0, longname => "South Texas",},
WTX => { worked => 0, longname => "West Texas",},
EB => { worked => 0, longname => "East Bay",},
LAX => { worked => 0, longname => "Los Angeles",},
ORG => { worked => 0, longname => "Orange",},
PAC => { worked => 0, longname => "Pacific",},
SB => { worked => 0, longname => "Santa Barbara",},
SCV => { worked => 0, longname => "Santa Clara Valley",},
SDG => { worked => 0, longname => "San Diego",},
SF => { worked => 0, longname => "San Francisco",},
SJV => { worked => 0, longname => "San Joaquin Valley",},
SV => { worked => 0, longname => "Sacramento Valley",},
AK => { worked => 0, longname => "Alaska",},
AZ => { worked => 0, longname => "Arizona",},
EWA => { worked => 0, longname => "Eastern Washington",},
ID => { worked => 0, longname => "Idaho",},
MT => { worked => 0, longname => "Montana",},
NV => { worked => 0, longname => "Nevada",},
OR => { worked => 0, longname => "Oregon",},
UT => { worked => 0, longname => "Utah",},
WWA => { worked => 0, longname => "Western Washington",},
WY => { worked => 0, longname => "Wyoming",},
MI => { worked => 0, longname => "Michigan",},
OH => { worked => 0, longname => "Ohio",},
WV => { worked => 0, longname => "West Virginia",},
IL => { worked => 0, longname => "Illinois",},
IN => { worked => 0, longname => "Indiana",},
WI => { worked => 0, longname => "Wisconsin",},
CO => { worked => 0, longname => "Colorado",},
IA => { worked => 0, longname => "Iowa",},
KS => { worked => 0, longname => "Kansas",},
MN => { worked => 0, longname => "Minnesota",},
MO => { worked => 0, longname => "Missouri",},
ND => { worked => 0, longname => "North Dakota",},
NE => { worked => 0, longname => "Nebraska",},
SD => { worked => 0, longname => "South Dakota",},
AB => { worked => 0, longname => "Alberta",},
BC => { worked => 0, longname => "British Columbia",},
GH => { worked => 0, longname => "Ontario Golden Horseshoe",},
MB => { worked => 0, longname => "Manitoba",},
NB => { worked => 0, longname => "New Brunswick",},
NL => { worked => 0, longname => "Newfoundland/Labrador",},
NS => { worked => 0, longname => "Nova Scotia",},
ONE => { worked => 0, longname => "Ontario East",},
ONN => { worked => 0, longname => "Ontario North",},
ONS => { worked => 0, longname => "Ontario South",},
PE => { worked => 0, longname => "Prince Edward Island",},
QC => { worked => 0, longname => "Quebec",},
SK => { worked => 0, longname => "Saskatchewan",},
TER => { worked => 0, longname => "Territories",},
);
# => { worked => 0, longname => "",},
#print Dumper(%mults);

##########

sub logit {

	my $logln = shift(@_);

	open(FH,">>$LOGFILE")
 	  or die "cant open $LOGFILE: $!\n";

  print FH $logln;

  close(FH);
}

sub json_logit {

  local $call_ = shift(@_);
	#local $json_log = $json->encode($qsos{$call_});
	local $json_log = $json->encode(\%qsos);
  #print "$json_log\n";
  #print Dumper($json_log);

  #open(FH,">>$JSONLOG")
 	#  or die "cant open $JSONLOG: $!\n";
#
  #print FH $logln;
  #close(FH);

}

##########

sub loadlog {

 	if( -e $LOGFILE ){
  	open(LL,"<$LOGFILE")
   	or die "cant open $LOGFILE: $!\n";
 	}
  while(<LL>){
   	chomp;
   	my @foo = split;

   	if($foo[0] =~ /del/){
			delete($qsos{$foo[1]});
   	}else{
    	$qsos{$foo[4]} = { action => "add", sserial => $foo[1], rserial => $foo[2], precedence => $foo[3], check => $foo[5],
                      	section => $foo[6], qsotime => $foo[7], freq => $foo[8]};
      json_logit($foo[4]);
    	$last_qso = $foo[4];
    	$Freq = $foo[8];
   	}
  }

  close(LL);

}

sub loadhistory {

  if( -e $HISTORYFILE ){
  	open(LH,"<$HISTORYFILE")
   	or die "cant open $HISTORYFILE: $!\n";
 	}
  while(<LH>){
   	chomp;

   	my @foo = split(',');

   	if($foo[0] =~ /^#/){
			next;
   	}else{
    	$history{$foo[0]} = { section => $foo[1], state => $foo[2], check => $foo[3] };
   	}
  }
  $hsize =  keys %history;
  #print("loaded $hsize keys from $HISTORYFILE\n")
  #print("n0vrp: $history{'N0VRP'}{'section'}\n");
}
##########

sub score {

 	my $m;

 	foreach (keys %mults){
  	if ($mults{$_}{worked}){
   		$m += 1;
  	}
  }

  local $totqso = keys %qsos;

  return ($m * ($totqso*2));

}

##########

sub section_stats {

  my $m;
  my $mm;

  foreach (keys %mults){
    if ($mults{$_}{worked}){
      $m += 1;
    }
    $mm += 1;
  }

  return($m . "/" . $mm);

}

##########

sub cabrillo {

  my $tt = Template->new;

  my $rendered_cab = "";

  my %tpl_data = (
    op_info->{call} => $op_info->{call},
    op_info->{section} => $op_info->{section},
    op_info->{precedence} => $op_info->{precedence},

  );

  $tt->process('templates/sweeps_phone.tpl', $op_info, \$rendered_cab)
    || die $tt->error;

  foreach (keys %qsos){
    $bar[$qsos{$_}{sserial}] = "$_";
  }

  $cab_lst->delete('0.0',"end");

  $cab_lst->insert('end', $rendered_cab);

  foreach $call (@bar){
    unless($call){next;}
    my @ta = localtime(($qsos{$call}{qsotime} + 21600));
    my $cd = ($ta[5] + 1900) . "-" . ($ta[4]+1) . "-$ta[3]";
    my $ct = "$ta[2]$ta[1]";

    my $cab_line = sprintf("QSO: %5s PH %10s %02s%02s %-10s %4s %s %s %3s %-10s %4s %s %s %s\n",
    $qsos{$call}{freq},
    $cd,
    $ta[2],
    $ta[1],
    $op_info->{call},
    $qsos{$call}{sserial},
    $op_info->{precedence},
    $op_info->{check},
    $op_info->{section},
    uc($call),
    $qsos{$call}{rserial},
    uc($qsos{$call}{precedence}),
    $qsos{$call}{check},
    uc($qsos{$call}{section}),
    );

    $cab_lst->insert('end', $cab_line);
  }

}
##########

# to help dry some things up, return a ref to the current version of the entry
# widgets
sub get_entry_refs {

  my %entry_ref_hash;

  if($notebook->raised() eq "entry_page"){
    my %entry_ref_hash = (
      message => \$Message,
      serial => \$Serial,
      precedence => \$Precedence,
      call => \$Call,
      check => \$Check,
      section => \$Section,
      freq => \$Freq,
    );
    return %entry_ref_hash;

  } elsif ($notebook->raised() eq "edit_page"){
    my %entry_ref_hash = (
      message => \$Edit_Message,
      serial => \$Edit_Serial,
      precedence => \$Edit_Precedence,
      call => \$Edit_Call,
      check => \$Edit_Check,
      section => \$Edit_Section,
      freq => \$Edit_Freq,
    );
    return %entry_ref_hash;
  }

}


##########

# this and process_qso_edit could be dry'd out, but they become pretty messy
# with passing refs or conditionaling everything

sub process_qso_entry {

  #print("process_qso $Serial $Precedence $Call $Check $Section\n");
  my $qsotime = time();

  undef($message);

  $Section = uc($Section);
  $Precedence = uc($Precedence);

  if(dupe_qso()){
      reset_qso();
      return;
  }

  # check to see if we have everything
  undef($Message);

  unless(defined($Serial) && $Serial =~ /^\d+$/ ){
    $Message = $Message . "Bad Serial... ";
  }

  unless(defined($Precedence) && exists($precedences{$Precedence})){
    $Message = $Message . "Bad Precedence... $Precedence ";
  }

  unless(defined($Call)){
    $Message = $Message . "Bad Call... ";
  }

  unless(defined($Check) && $Check =~ /^\d+$/){
    $Message = $Message . "Bad Check... ";
  }

  unless(defined($Section)){
    $Message = $Message . "Bad Section... ";
  } else {
    unless(defined($mults{uc($Section)})){
      $Message = $Message . "WRONG SECTION...";
    }
  }

  unless(defined($Freq) && $Freq =~ /^\d/){
    $Message = $Message . "Bad Freq... ";
  }

  if(defined($Message)){
    return;
  }

  local $uc_call = uc($Call);
  local $uc_precedence = uc($Precedence);
  local $uc_section = uc($Section);

  $qsos{$uc_call} = { sserial => $next_serial,
                   rserial => $Serial,
		               precedence => $uc_precedence,
		               check => $Check,
		               section => $uc_section,
		               freq => $Freq,
		               qsotime => $qsotime,
                   action => "add",
                 };


  logit("add $next_serial $Serial $uc_precedence $uc_call $Check $uc_section $qsotime $Freq\n");
  json_logit($Call);
  load_list();
  load_sections();

  reset_qso();
  info();
  $Inputs{Call}->focus();
  #print Dumper(%mults);
}

##########

sub process_qso_edit {

  #print "process_qso $Edit_Serial $Edit_Precedence $Edit_Call $Edit_Check $Edit_Section\n" if $DEBUG;

  undef($Edit_Message);

  $Edit_Section = uc($Edit_Section);
  $Edit_Call = uc($Edit_Call);
  $Edit_Precedence = uc($Edit_Precedence);

  unless(defined($Edit_Serial) && $Edit_Serial =~ /^\d+$/ ){
    $Edit_Message = $Edit_Message . "Bad Serial... ";
  }

  unless(defined($Edit_Precedence) && exists($precedences{$Edit_Precedence})){
    $Edit_Message = $Edit_Message . "Bad Precedence... ";
  }

  unless(defined($Edit_Call)){
    $Edit_Message = $Edit_Message . "Bad Call... ";
  }

  unless(defined($Edit_Check) && $Edit_Check =~ /^\d+$/){
    $Edit_Message = $Edit_Message . "Bad Check... ";
  }

  unless(defined($Edit_Section)){
    $Edit_Message = $Edit_Message . "Bad Section... ";
  } else {
    unless(defined($mults{uc($Edit_Section)})){
      $Edit_Message = $Edit_Message . "WRONG SECTION...";
    }
  }

  unless(defined($Edit_Freq) && $Edit_Freq =~ /^\d+$/){
    $Edit_Message = $Edit_Message . "Bad Freq... ";
  }

  if(defined($Edit_Message)){
    return;
  }

  #if($update_call ne $Edit_Call){
    delete($qsos{$update_call});
    logit("del $update_call\n");
  #}

  logit("add $update_given_serial $Edit_Serial $Edit_Precedence $Edit_Call $Edit_Check $Edit_Section $update_qsotime $Edit_Freq\n");

  $qsos{$Edit_Call}{sserial} = $update_given_serial;
  $qsos{$Edit_Call}{rserial} = $Edit_Serial;
  $qsos{$Edit_Call}{precedence} = $Edit_Precedence;
  $qsos{$Edit_Call}{check} = $Edit_Check;
  $qsos{$Edit_Call}{qsotime} = $update_qsotime;

  $qsos{$Edit_Call}{section} = $Edit_Section;
  $qsos{$Edit_Call}{freq} = $Edit_Freq;

  undef($update_call);
  undef($update_given_serial);
  undef($update_qsotime);

  load_list();
  load_sections();
  reset_qso();
  info();
  $Inputs{Call}->focus();

}

##########

sub dupe_qso {

  if(!defined($Call)){
    $Message = "No Call";
    return;
  }

  if(defined($qsos{uc($Call)})){
    reset_qso();
    $Message = "DUPE";
    return 1;
  }else{
    $Message = "GOOD";
    return 0;
  }

}

##########

sub inline_validate_call {

  my $entry = uc($_[0]);

  if(defined($qsos{$entry})){
    my @ta = localtime(($qsos{$entry}{qsotime} + 21600));
    my $cd = ($ta[5] + 1900) . "-" . ($ta[4]+1) . "-$ta[3]";
    my $ct = "$ta[2]$ta[1]";
    $Message = "DUPE   $qsos{$entry}{sserial} : $ta[2]:$ta[1] $qsos{$entry}{rserial} $qsos{$entry}{precedence} $entry $qsos{$entry}{check} $qsos{$entry}{section} $qsos{$entry}{freq}";
    $Inputs{Call}->configure(-background => red);
  }else{
    if(defined($history{$entry})){
      #print("clearing and setting from history\n");
      $Inputs{Check}->delete(0,'end');
      $Inputs{Section}->delete(0,'end');
      $Inputs{Check}->insert(0, $history{$entry}{'check'});
      $Inputs{Section}->insert(0, $history{$entry}{'section'});
      $history_used = 1;
    }elsif($history_used){
      #print("clearing history\n");
      $Inputs{Check}->delete(0,'end');
      $Inputs{Section}->delete(0,'end');
      $history_used = 0;
    }
    $Message = "GOOD";
    $Inputs{Call}->configure(-background => lightgrey);
  }

  return 1;

}

##########

sub inline_validate_section {
	my $entry = uc(shift);

  my $inputs_ref;
  my $telltale_ref;

  if($notebook->raised() eq "entry_page"){
    $inputs_ref = \$Inputs{Section};
    $telltale_ref = \$Telltale{Section};
  } elsif ($notebook->raised() eq "edit_page"){
    $inputs_ref = \$Edit_Inputs{Section};
    $telltale_ref = \$Edit_Telltale{Section};
  }

	if(exists($mults{$entry}) || !$entry){
	  $$inputs_ref->configure(-background => lightgrey);
		$$telltale_ref->configure(-text => "$mults{$entry}{longname}");
		return 1;
	} else {
		$$inputs_ref->configure(-background => red);
		$$telltale_ref->configure(-text => "Invalid Section");
		return 1;
	}
}

##########
sub inline_validate_check {
  local $entry = (shift);

  my $inputs_ref;
  my $telltale_ref;

  if($notebook->raised() eq "entry_page"){
    $inputs_ref = \$Inputs{Check};
    $telltale_ref = \$Telltale{Check};
  } elsif ($notebook->raised() eq "edit_page"){
    $inputs_ref = \$Edit_Inputs{Check};
    $telltale_ref = \$Edit_Telltale{Check};
  }

  if ($entry =~ /^\d+$/ || !$entry) {
    $$inputs_ref->configure(-background => lightgrey);
		$$telltale_ref->configure(-text => "");
		return 1;
  } else {
    $$inputs_ref->configure(-background => red);
		$$telltale_ref->configure(-text => "Invalid Check");
		return 1;
  }
}

##########

sub inline_validate_serial {
  local $entry = (shift);

  my $inputs_ref;
  my $telltale_ref;

  if($notebook->raised() eq "entry_page"){
    $inputs_ref = \$Inputs{Serial};
    $telltale_ref = \$Telltale{Serial};
  } elsif ($notebook->raised() eq "edit_page"){
    $inputs_ref = \$Edit_Inputs{Serial};
    $telltale_ref = \$Edit_Telltale{Serial};
  }

  if ($entry =~ /^\d+$/ || !$entry) {
    $$inputs_ref->configure(-background => lightgrey);
		$$telltale_ref->configure(-text => "");
		return 1;
  } else {
    $$inputs_ref->configure(-background => red);
		$$telltale_ref->configure(-text => "Invalid Serial");
		return 1;
  }
}

##########

sub inline_validate_precedence {
  local $entry = uc(shift);

  my $inputs_ref;
  my $telltale_ref;

  if($notebook->raised() eq "entry_page"){
    $inputs_ref = \$Inputs{Precedence};
    $telltale_ref = \$Telltale{Precedence};
  } elsif ($notebook->raised() eq "edit_page"){
    $inputs_ref = \$Edit_Inputs{Precedence};
    $telltale_ref = \$Edit_Telltale{Precedence};
  }

  if(defined($precedences{$entry}) || !$entry){
    $$inputs_ref->configure(-background => lightgrey);
		$$telltale_ref->configure(-text => "$precedences{$entry}");
		return 1;
	} else {
		$$inputs_ref->configure(-background => red);
		$$telltale_ref->configure(-text => "");
		return 1;
  }
}
##########

sub sort_by_timestamp{
  $qsos{$a}{qsotime} <=> $qsos{$b}{qsotime};
}

##########
sub info {

  $next_serial = do {
    local $max_serial = 0;
    foreach $k (keys %qsos){
      if ($qsos{$k}{sserial} > $max_serial) {
        $max_serial = $qsos{$k}{sserial};

      }
    }
    $max_serial+1;
  };

  $Info = "Next exchange:    $next_serial  $op_info->{precedence}  $op_info->{call}  $op_info->{check}  $op_info->{section}";

  $Score = "score: " . score() . " sects: " . section_stats();

}

##########

sub reset_qso {

  my $raised_page = $notebook->raised();

  if ($raised_page eq "entry_page"){
    undef($Serial);
    undef($Precedence);
    undef($Call);
    undef($Check);
    undef($Section);
    undef($Message);
    $Inputs{Call}->focus();
  } elsif ($raised_page eq "edit_page"){
    undef($Edit_Serial);
    undef($Edit_Precedence);
    undef($Edit_Call);
    undef($Edit_Check);
    undef($Edit_Section);
    undef($Edit_Message);
    $Edit_Inputs{Call}->focus();
  }
  undef($update_call);

  $doneButtonTxt = "Done";

}

##########
sub load_list {

	$lst->delete(0, 'end');
	$edit_lst->delete(0, 'end');

  foreach $entry (sort sort_by_timestamp keys %qsos ){
    $lst->insert(0,"$qsos{$entry}{sserial} : $qsos{$entry}{rserial} $qsos{$entry}{precedence} $entry $qsos{$entry}{check} $qsos{$entry}{section} $qsos{$entry}{freq}");
    $edit_lst->insert(0,"$qsos{$entry}{sserial} : $qsos{$entry}{rserial} $qsos{$entry}{precedence} $entry $qsos{$entry}{check} $qsos{$entry}{section} $qsos{$entry}{freq}");
  }

}

##########

sub toggle_sections {

  if($sectMode){
    $sectMode = 0;
  } else {
    $sectMode = 1;
  }

  clear_sections();
  load_sections();

}

##########

sub clear_sections {

  for my $list (keys %SectList) {
	  $SectList{$list}->delete(0,"end");
  };

}

##########

sub load_sections {

  my $sect_cnt = keys %mults;
  my $break_point = ceil($sect_cnt / $SECT_LIST_CNT);
  my $cnt = 0;
  my $cur_list = 1;

  # clear qso counts
  foreach $m (sort keys %mults){
    $mults{$m}{worked} = 0;
    #print "$m \n";
  }

  # repopulate multiplier count
  foreach $q (keys %qsos){
    $mults{$qsos{$q}{section}}{worked}++;
    #print $mults{$qsos{$q}{section}}{worked };
  }

  clear_sections();

  foreach $mult (sort keys %mults ){

    unless($mult){
      next;
    }

    #print "$mult $mults{$mult}{worked} \n";
	  # if true, only show needed sections
    if($sectMode){
		  if($mults{$mult}{worked}){
		    next;
		  }
	  }

    $cnt++;
    if($cnt > $break_point){
      $cur_list++;
      $cnt = 1;
		}

    my $qso_cnt = $mults{$mult}{worked};
    my $ln = sprintf("%-4s %s %s", $mult, $mults{$mult}{longname},$qso_cnt);

		$SectList{$cur_list}->insert('end',$ln);
		if($qso_cnt){
			$SectList{$cur_list}->itemconfigure('end', -background => 'lightgreen');
		}

	}

}

##########

# FIX load_list call
sub delete_qso {

  if(defined($Edit_Call)){
    logit("del $Edit_Call\n");
    delete($qsos{$Edit_Call});
    reset_qso();
    info();
    load_list();
    load_sections();
    reset_qso();
  }else{
    $Message = "No qso selected";
  }

}

##########

sub recall_qso {

  # load qso into edit page

  my $which_focus = $notebook->raised();

  # whichever list we click on, get the qso
  if ($which_focus eq 'edit_page'){
    $r_qso = $edit_lst->get($edit_lst->curselection());
  } else {
    $r_qso = $lst->get($lst->curselection());
  }

  # go to edit page
  $notebook->raise('edit_page');

  my @qso_elements = split /\s+/, $r_qso;

  #print $qso_elements[4] . "\n";

  ($foo, $bar, $Edit_Serial,$Edit_Precedence,$Edit_Call,$Edit_Check,$Edit_Section,$Edit_Freq) = split /\s+/, $r_qso;

  $update_qsotime = $qsos{$Edit_Call}{qsotime};
  $update_given_serial = $foo;
  $update_call = $Edit_Call;
  #$update_time =

}

##########

sub get_rig_freq {
  	$rig_freq = $rig->get_freq();
	substr($rig_freq, -3, 0) = '.';
	substr($rig_freq, -7, 0) = '.';

	unless ($Freq){
		$Freq = "no rig data yet"
	}

	if ($rig_freq) {
		if ($Inputs{Freq}){
			$Inputs{Freq}->configure(-background => lightgrey);
		}
		return $rig_freq;
	} else {
		if ($Inputs{Freq}){
			$Inputs{Freq}->configure(-background => yellow);
		}
		return $Freq;

	}
}

##########
sub make_window {

  my $main_window = MainWindow->new();
  $main_window->geometry($geom_x . "x" . $geom_y);
  $main_window->title("VRP sweeps");
  $main_window->configure(-background=>'grey');

  # tabs.... er notebook...

  $notebook = $main_window->NoteBook(-takefocus => 0)->pack(-expand => 1, -fill => 'both');
  $notebook->configure( -takefocus, 0 );

  my $entry_page = $notebook->add('entry_page',
                                  -label => 'Entry',
                                  -raisecmd => sub {$Inputs{Call}->focus()});

  # two frames and adjuster
  my $left_frame = $entry_page->Frame; # left
  my $adjuster = $entry_page->Adjuster(-widget => $left_frame, -side => 'left');
  my $right_frame = $entry_page->Frame; # right
  my $Msg = $entry_page->Frame; # message frame
  my $bottom_frame = $entry_page->Frame; # bottom

  # pack framesa
  $bottom_frame->pack(qw/-side bottom -fill both /);
  $left_frame->pack(qw/-side left -fill y/);
  $adjuster->pack(qw/-side left -fill y/);
  $right_frame->pack(qw/-side right -fill both -expand l/);

  # input text
  #my(@ipl) = qw/-side left -padx 10 -pady 5 -fill x/;
  #my(@lpl) = qw/-side left/;

  $vn = "Call";
  my $if = $right_frame->Frame->pack(qw/-anchor w/);
  $if->Label(-text => $vn, -width => 15)->pack(qw/-side left/);
  $Inputs{$vn} = $if->Entry(-validate        => 'key',
          -validatecommand => [\&inline_validate_call],
          -textvariable => \$$vn)->pack(qw/-side left -padx 10 -pady 5 -fill x/);

  $vn = "Serial";
  my $if = $right_frame->Frame->pack(qw/-anchor w/);
  $if->Label(-text => $vn, -width => 15)->pack(qw/-side left/);
  $Inputs{$vn} = $if->Entry(-validate => 'key',
    -validatecommand => [\&inline_validate_serial],
    -textvariable => \$Serial)->pack(qw/-side left -padx 10 -pady 5 -fill x/);
  $Telltale{$vn} = $if->Label(-text => "", -width => 25)->pack(qw/-side left/);

  # $vn = "Precedence";
  # my $if = $right_frame->Frame->pack(qw/-anchor w/);
  # $if->Label(-text => $vn, -width => 15)->pack(qw/-side left/);
  # $Inputs{$vn} = $if->Optionmenu(
  # #  -options => [[A => "Single Op Low Power"],[jan=>1], [feb=>2], [mar=>3], [apr=>4]],
  #   -options => $precedences,
  #   -variable => \$Precedence
  #   )->pack(qw/-side left -padx 10 -pady 5 -fill x/);

  $vn = "Precedence";
  my $if = $right_frame->Frame->pack(qw/-anchor w/);
  $if->Label(
    -text => $vn,
    -width => 15
  )->pack(qw/-side left/);
  $Inputs{$vn} = $if->Entry(-validate => 'key',
    -width => 2,
    -validatecommand => [\&inline_validate_precedence],
    -textvariable => \$Precedence)->pack(qw/-side left -padx 10 -pady 5 -fill x/);
  $Help{$vn} = $if->Label(
    -text => join(" ", map{ "$_" } keys %precedences),
    -width => 10
  )->pack(qw/-side left/);
  $Telltale{$vn} = $if->Label(
    -text => "",
    -width => 25
  )->pack(qw/-side left/);


  $vn = "Check";
  my $if = $right_frame->Frame->pack(qw/-anchor w/);
  $if->Label(-text => $vn, -width => 15)->pack(qw/-side left/);
  $Inputs{$vn} = $if->Entry(-validate => 'key',
    -validatecommand => [\&inline_validate_check],
    -textvariable => \$Check)->pack(qw/-side left -padx 10 -pady 5 -fill x/);
  $Telltale{$vn} = $if->Label(-text => "", -width => 25)->pack(qw/-side left/);

 	$vn = "Section";
  my $if = $right_frame->Frame->pack(qw/-anchor w/);
  $if->Label(-text => $vn, -width => 15)->pack(qw/-side left/);
	$Inputs{$vn} = $if->Entry(-validate        => 'key',
					-validatecommand => [\&inline_validate_section],
					-textvariable => \$$vn)->pack(qw/-side left -padx 10 -pady 5 -fill x/);
  $Telltale{$vn} = $if->Label(-text => "", -width => 25)->pack(qw/-side left/);

  $vn = "Freq";
	if ( $civ_enable ){
		$Freq = get_rig_freq();
	}
  my $if = $right_frame->Frame->pack(qw/-anchor w/);
  $if->Label(-text => $vn, -width => 15)->pack(qw/-side left/);
  $Inputs{$vn} = $if->Entry(-takefocus => 0, -textvariable => \$Freq)->pack(qw/-side left -padx 10 -pady 5 -fill x/);
  $Telltale{$vn} = $if->Label(-text => "", -width => 25)->pack(qw/-side left/);

  $right_frame->Label(-takefocus => 0, -textvariable => \$Message,
            -borderwidth => 2,
	    -relief => 'groove')->pack(-fill => 'x',
	                                 -anchor => 'w');

  my $if = $right_frame->Frame->pack(-anchor => 'w');

  $if->Label(-takefocus => 0,
                      -textvariable => \$Info,
                      -width => 50,
                      -borderwidth => 2,
	                     -relief => 'groove')->pack(-side => 'left');

  $if->Label(-takefocus => 0,
                      -textvariable => \$Score,
                      -width => 50,
                      -borderwidth => 2,
                      -relief => 'groove')->pack(-side => 'left');

  my $bf = $right_frame->Frame->pack(qw/-anchor w/);

  $bf->Button( -takefocus => 0, -text => "Done <enter>",
              -command => \&process_qso_entry,
              )->pack(qw/-side left -pady 2/);

  $bf->Button( -takefocus => 0, -text => "reset <crtl-c>",
               -command => \&reset_qso,
              )->pack(qw/-side left -pady 2/);

  $bf->Button( -takefocus => 0, -text => "quit <ctrl-q>",
              -command => sub { exit },
 	      )->pack(qw/-side left -pady 2/);

  $bf->Button( -takefocus => 0, -text => "sect toggle",
              -command => \&toggle_sections,
 	      )->pack(qw/-side left -pady 2/);

  $lst = $left_frame->Scrolled(qw/Listbox -takefocus 0 -selectmode single -width 30 -height 18 -scrollbars e/);
  $lst->Subwidget("yscrollbar")->configure(-takefocus => 0);
  $lst->pack(qw/-fill both/);
  $lst->bind('<Double-Button-1>',\&recall_qso);

  for my $sl ( 1 .. $SECT_LIST_CNT ) {
	  $SectList{$sl} = $bottom_frame->Listbox(-takefocus => 0,
	 																				-selectmode => single,
																					-width => 26, -height => 21
																					)->pack(qw/-side left -fill both/);
	  $SectList{$sl}->bind('<Double-Button-1>',
	    sub {
	  		my ($sect,$rest) = split / /,$SectList{$sl}->get($SectList{$sl}->curselection()),2;
	 			$Section = $sect;
	 		}
    );
  };

##########
##########

  my $edit_page = $notebook->add('edit_page', -label => 'Edit');
  my $edit_left_frame = $edit_page->Frame;
  $edit_left_frame->pack(qw/-side left -fill y/);
  my $edit_adjuster = $edit_page->Adjuster(-widget => $edit_left_frame, -side => 'left');
  $edit_adjuster->pack(qw/-side left -fill y/);
  my $edit_right_frame = $edit_page->Frame;
  $edit_right_frame->pack(qw/-side right -fill both -expand l/);

  $edit_lst = $edit_left_frame->Scrolled("Listbox",
 																				-takefocus => 0,
																				-selectmode => "single",
																				-width => 30,
																				-height => $geom_y,
																				-scrollbars => "e")->pack(qw/-fill both/);
  $edit_lst->Subwidget("yscrollbar")->configure(-takefocus => 0);
  $edit_lst->bind('<Double-Button-1>',\&recall_qso);

  $vn = "Serial";
  my $if = $edit_right_frame->Frame->pack(qw/-anchor w/);
  $if->Label(-text => $vn, -width => 15)->pack(qw/-side left/);
  $Edit_Inputs{$vn} = $if->Entry(-textvariable => \$Edit_Serial)->pack(qw/-side left -padx 10 -pady 5 -fill x/);

  $vn = "Precedence";
  my $if = $edit_right_frame->Frame->pack(qw/-anchor w/);
  $if->Label(-text => $vn, -width => 15)->pack(qw/-side left/);
  $Edit_Inputs{$vn} = $if->Entry(-textvariable => \$Edit_Precedence)->pack(qw/-side left -padx 10 -pady 5 -fill x/);

  $vn = "Call";
  my $if = $edit_right_frame->Frame->pack(qw/-anchor w/);
  $if->Label(-text => $vn, -width => 15)->pack(qw/-side left/);
  $Edit_Inputs{$vn} = $if->Entry(
 				 -textvariable => \$Edit_Call)->pack(qw/-side left -padx 10 -pady 5 -fill x/);

  $vn = "Check";
  my $if = $edit_right_frame->Frame->pack(qw/-anchor w/);
  $if->Label(-text => $vn, -width => 15)->pack(qw/-side left/);
  $Edit_Inputs{$vn} = $if->Entry(-textvariable => \$Edit_Check)->pack(qw/-side left -padx 10 -pady 5 -fill x/);

  $vn = "Section";
  my $if = $edit_right_frame->Frame->pack(qw/-anchor w/);
  $if->Label(-text => $vn, -width => 15)->pack(qw/-side left/);
  $Edit_Inputs{$vn} = $if->Entry(-validate        => 'key',
 				 -validatecommand => [\&inline_validate_section],
 				 -textvariable => \$Edit_Section)->pack(qw/-side left -padx 10 -pady 5 -fill x/);
  $Edit_Telltale{$vn} = $if->Label(-text => "", -width => 25)->pack(qw/-side left/);

  $vn = "Edit Freq";
  my $if = $edit_right_frame->Frame->pack(qw/-anchor w/);
  $if->Label(-text => $vn, -width => 15)->pack(qw/-side left/);
  $Edit_Inputs{$vn} = $if->Entry(-textvariable => \$Edit_Freq)->pack(qw/-side left -padx 10 -pady 5 -fill x/);

  $edit_right_frame->Label(-takefocus => 0, -textvariable => \$Edit_Message,
                      -borderwidth => 2,
            	        -relief => 'groove')->pack(-fill => 'x',
            	        -anchor => 'w');
  $edit_right_frame->Label(-takefocus => 0, -textvariable => \$Score,
                      -borderwidth => 2,
                	    -relief => 'groove')->pack(-fill => 'x',
                      -anchor => 'w');

  $edit_right_frame->Button( -takefocus => 0, -text => "Done <enter>",
              -command => \&process_qso_edit,
              )->pack(qw/-side left -pady 2 -anchor n/);
  $edit_right_frame->Button( -takefocus => 0, -text => "delete",
              -command => \&delete_qso,
              )->pack(qw/-side left -pady 2 -anchor n/);
  $edit_right_frame->Button( -takefocus => 0, -text => "Cancel <ctrl-c>",
               -command => \&reset_qso,
              )->pack(qw/-side left -pady 2 -anchor n/);




##########
##########

  $cab_page = $notebook->add('cab_page',
                             -label => 'Cabrillo',
                             -raisecmd => sub {cabrillo()} );

  my $cab_frame = $cab_page->Frame->pack(-side => "left", -fill => "both");
  $cab_lst = $cab_frame->Scrolled("Text",
                                      -takefocus => 0,
                                      -width => $geom_x,
                                      -scrollbars => "se")->pack(-expand => 1,
                                                                -fill => "both",
                                                                );



#####

sub unworked_mults(){

  foreach $q (keys %qsos){
    $mults{$qsos{$q}{section}}{worked}++;
    #print $mults{$qsos{$q}{section}}{worked };
  }

  foreach $mult (sort keys %mults ){

    unless($mult){
      next;
    }

    #print "$mult $mults{$mult}{worked} \n";
	  # if true, only show needed sections
    if($mults{$mult}{worked}){
		    next;
	  }else{
      print("$mult $mults{$mult}{longname}\n");
    }
  }

}
##########
##########

  loadlog();

  loadhistory();

  load_sections();

  load_list();

  info();

  if ( $ARGV[0] eq 'mults' ){
    unworked_mults();
    exit();
  }
  #$Inputs{Serial}->focus();

  $Telltale{Freq}->update();
  sub update_freq {$Freq = get_rig_freq(); $Inputs{"Freq"}->update();}
  $Inputs{"Freq"}->repeat(500,\&update_freq);

  $main_window->bind("<Control-d>",[\&dupe_qso]);
  $main_window->bind("<Control-c>",[\&reset_qso]);
  $main_window->bind("<Control-l>",[\&load_sections]);
  $main_window->bind("<Return>",
    sub {
      my $focused = $notebook->raised();
      if ($focused eq "entry_page"){
        process_qso_entry();
      } elsif ( $focused eq "edit_page"){
        process_qso_edit();
      }
    });
  $main_window->bind("<Control-q>",[sub { exit}]);
  $main_window->bind("<Control-t>",[\&toggle_sections]);
  $main_window->bind("<Shift-Right>",
    sub {
      $notebook->raise($notebook->info("focusnext"));
    });
  $main_window->bind("<Shift-Left>",
    sub {
      $notebook->raise($notebook->info("focusprev"));
    });

  MainLoop();

}

##########

make_window();
