#!/Users/csc/perl5/perlbrew/perls/perl-5.16.0/bin/perl

# sweeps logging program
# - dupes
# - scoring
# - cabrillo v2 output

use lib '.';
use ICOM_CIV;
my $socket = icom_civ_setup("/dev/cuau0");

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

use Getopt::Long qw(GetOptions);
my $civ_enable;
GetOptions('from=s' => \$source_address) or die "Usage: $0 --from NAME\n";

use Term::ReadLine;
$term = new Term::ReadLine 'vrpsweeps';

%qsos = ();

$DEBUG = 1;

$message;

$sectMode = 0;

$mycall = "N0VRP";
$myprec = "M";
$mysection = "NTX";
$mycheck = 93;

$last_freq = 0;
$totqso = 0;
$LOGFILE = "sweeps.dat";
$CABFILE = "sweeps.cab";
$last_checked;
$last_qso;

$update_call;
$update_given_serial;

%mults = (
CT => { worked => 0, longname => "Connecticut ",},
EMA => { worked => 0, longname => "Eastern Massachusetts ",},
ME => { worked => 0, longname => "Maine ",},
NH => { worked => 0, longname => "New Hampshire ",},
RI => { worked => 0, longname => "Rhode Island ",},
VT => { worked => 0, longname => "Vermont ",},
WMA => { worked => 0, longname => "Western Massachusetts ",},
ENY => { worked => 0, longname => "Eastern New York ",},
NLI => { worked => 0, longname => "New York City - Long Island ",},
NNJ => { worked => 0, longname => "Northern New Jersey ",},
NNY => { worked => 0, longname => "Northern New York ",},
SNJ => { worked => 0, longname => "Southern New Jersey ",},
WNY => { worked => 0, longname => "Western New York ",},
DE => { worked => 0, longname => "Delaware ",},
EPA => { worked => 0, longname => "Eastern Pennsylvania ",},
MDC => { worked => 0, longname => "Maryland-DC ",},
WPA => { worked => 0, longname => "Western Pennsylvania ",},
AL => { worked => 0, longname => "Alabama ",},
GA => { worked => 0, longname => "Georgia ",},
KY => { worked => 0, longname => "Kentucky ",},
NC => { worked => 0, longname => "North Carolina ",},
NFL => { worked => 0, longname => "Northern Florida ",},
SC => { worked => 0, longname => "South Carolina ",},
SFL => { worked => 0, longname => "Southern Florida ",},
WCF => { worked => 0, longname => "West Central Florida ",},
TN => { worked => 0, longname => "Tennessee ",},
VA => { worked => 0, longname => "Virginia ",},
PR => { worked => 0, longname => "Puerto Rico ",},
VI => { worked => 0, longname => "Virgin Islands ",},
AR => { worked => 0, longname => "Arkansas ",},
LA => { worked => 0, longname => "Louisiana ",},
MS => { worked => 0, longname => "Mississippi ",},
NM => { worked => 0, longname => "New Mexico ",},
NTX => { worked => 0, longname => "North Texas ",},
OK => { worked => 0, longname => "Oklahoma ",},
STX => { worked => 0, longname => "South Texas ",},
WTX => { worked => 0, longname => "West Texas ",},
EB => { worked => 0, longname => "East Bay ",},
LAX => { worked => 0, longname => "Los Angeles ",},
ORG => { worked => 0, longname => "Orange ",},
SB => { worked => 0, longname => "Santa Barbara ",},
SCV => { worked => 0, longname => "Santa Clara Valley ",},
SDG => { worked => 0, longname => "San Diego ",},
SF => { worked => 0, longname => "San Francisco ",},
SJV => { worked => 0, longname => "San Joaquin Valley ",},
SV => { worked => 0, longname => "Sacramento Valley ",},
PAC => { worked => 0, longname => "Pacific ",},
AZ => { worked => 0, longname => "Arizona ",},
EWA => { worked => 0, longname => "Eastern Washington ",},
ID => { worked => 0, longname => "Idaho ",},
MT => { worked => 0, longname => "Montana ",},
NV => { worked => 0, longname => "Nevada ",},
OR => { worked => 0, longname => "Oregon ",},
UT => { worked => 0, longname => "Utah ",},
WWA => { worked => 0, longname => "Western Washington ",},
WY => { worked => 0, longname => "Wyoming ",},
AK => { worked => 0, longname => "Alaska ",},
MI => { worked => 0, longname => "Michigan ",},
OH => { worked => 0, longname => "Ohio ",},
WV => { worked => 0, longname => "West Virginia ",},
IL => { worked => 0, longname => "Illinois ",},
IN => { worked => 0, longname => "Indiana ",},
WI => { worked => 0, longname => "Wisconsin ",},
CO => { worked => 0, longname => "Colorado ",},
IA => { worked => 0, longname => "Iowa ",},
KS => { worked => 0, longname => "Kansas ",},
MN => { worked => 0, longname => "Minnesota ",},
MO => { worked => 0, longname => "Missouri ",},
NE => { worked => 0, longname => "Nebraska ",},
ND => { worked => 0, longname => "North Dakota ",},
SD => { worked => 0, longname => "South Dakota ",},
MAR => { worked => 0, longname => "Maritime ",},
NL => { worked => 0, longname => "Newfoundland/Labrador ",},
QC => { worked => 0, longname => "Quebec ",},
ONE => { worked => 0, longname => "Ontario East ",},
ONN => { worked => 0, longname => "Ontario North ",},
ONS => { worked => 0, longname => "Ontario South ",},
GTA => { worked => 0, longname => "Greater Toronto Area ",},
MB => { worked => 0, longname => "Manitoba ",},
SK => { worked => 0, longname => "Saskatchewan ",},
AB => { worked => 0, longname => "Alberta ",},
BC => { worked => 0, longname => "British Columbia ",},
NT => { worked => 0, longname => "Northern Territories ",},
);


##########

sub logit {

 my $logln = shift(@_);

 open(FH,">>$LOGFILE")
  or die "cant open $LOGFILE: $!\n";

 print FH $logln;

 close(FH);

}

##########

sub prompt {

 return score() . "/$totqso > ";

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
    if($mults{$qsos{$foo[1]}{section}}{worked}){
     $mults{$qsos{$foo[1]}{section}}{worked}--;
    }
    delete($qsos{$foo[1]});
    $totqso--;
   }else{
    $qsos{$foo[4]} = { sserial => $foo[1], rserial => $foo[2], precedence => $foo[3], check => $foo[5],
                       section => $foo[6], qsotime => $foo[7], freq => $foo[8]};
    $mults{$foo[6]}{worked}++;
    $totqso = $foo[1];
    $last_qso = $foo[4];
    $Freq = $foo[8];
   }
  }

  close(LL);

}

##########

sub reloadlog {

}

sub printlog {

 my @bar;

 foreach (keys %qsos){
  $bar[$qsos{$_}{sserial}] = "$qsos{$_}{sserial} - $qsos{$_}{rserial} $qsos{$_}{precedence} $_ $qsos{$_}{check} $qsos{$_}{section} $qsos{$_}{qsotime} $qsos{$_}{freq} \n";
 }

 foreach (@bar){
  print;
 }
}

##########

sub score {

 my $m;

 foreach (keys %mults){
  if ($mults{$_}{worked}){
   $m += 1;
  }
  #print $m . "\n";
 }

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
 foreach (keys %qsos){
   $bar[$qsos{$_}{sserial}] = "$_";
 }
 open(CAB, ">$CABFILE")
  or die "no cabfile workie: $!";

 foreach $call (@bar){
 unless($call){next;}
  my @ta = localtime(($qsos{$call}{qsotime} + 21600));
  my $cd = ($ta[5] + 1900) . "-" . ($ta[4]+1) . "-$ta[3]";
  my $ct = "$ta[2]$ta[1]";

  printf CAB ("QSO: %5s PH %10s %02s%02s %-10s %4s %s %s %3s %-10s %4s %s %s %s\n",
  $qsos{$call}{freq},$cd,$ta[2],$ta[1],"N0VRP",$qsos{$call}{sserial},"A","93","KS ",uc($call),$qsos{$call}{rserial},uc($qsos{$call}{precedence}),$qsos{$call}{check},uc($qsos{$call}{section}));


 }

 close(CAB);

}

##########

sub process_qso {

 #print "process_qso $Serial $Precedence $Call $Check $Section\n" if $DEBUG;
 my $qsotime = time();
 undef($message);

 # check for dupe

 if($doneButtonTxt eq "Done"){
  if(dupe_qso()){
    reset_qso();
    return;
  }
 }

 # check to see if we have everything

 undef($Message);

 unless(defined($Serial)){
  $Message = $Message . "No Serial... ";
 }

 unless(defined($Precedence)){
  $Message = $Message . "No Precedence... ";
 }

 unless(defined($Call)){
  $Message = $Message . "No Call... ";
 }

 unless(defined($Check)){
  $Message = $Message . "No Check... ";
 }

 unless(defined($Section)){
  $Message = $Message . "No Section... ";
 } else {
  unless(defined($mults{uc($Section)})){
   $Message = $Message . "WRONG SECTION...";
  }
 }

 if(defined($Message)){
  return;
 }

 if($doneButtonTxt eq "Done"){
  $totqso++;
 }

 if(defined($update_call)){
  $qsotime = $qsos{$update_call}{qsotime};
 }

 if(($update_call ne $Call) &&  (defined($update_call))){
  #$qsotime = $qsos{$update_call}{qsotime};
  delete($qsos{$update_call});
  logit("del $update_call\n");
  #undef($update_call);
 }

 $Section = uc($Section);
 $Call = uc($Call);
 $Precedence = uc($Precedence);

 if($update_given_serial){
  logit("add $update_given_serial $Serial $Precedence $Call $Check $Section $update_qsotime $Freq\n");
  undef($update_given_serial);

  $qsos{$Call}{rserial} = $Serial;
  $qsos{$Call}{precedence} = $Precedence;
  $qsos{$Call}{check} = $Check;

  if($Section ne $qsos{$Call}{section}){
   $mults{$Section}{worked}++;
   $mults{$qsos{$Call}{section}}{worked}--;
  }
  $qsos{$Call}{section} = $Section;
  $qsos{$Call}{freq} = $Freq;


 }else{
  logit("add $totqso $Serial $Precedence $Call $Check $Section $qsotime $Freq\n");

  $qsos{$Call} = { sserial => $totqso,
                    rserial => $Serial,
		    precedence => $Precedence,
		    check => $Check,
		    section => $Section,
		    freq => $Freq,
		    qsotime => $qsotime};


		    $mults{$Section}{worked}++;
 }

 undef($update_call);
 undef($update_given_serial);
 undef($update_qsotime);
 $doneButtonTxt = "Done";
 load_list();
 load_sections();

 reset_qso();
 info	($totqso);
 $Inputs{Call}->focus();


}

##########

sub dupe_qso {

 # print "dupe_qso $Call\n" if $DEBUG;

 if(!defined($Call)){
  $Message = "No Call";
  return;
 }

 if(defined($qsos{uc($Call)})){
    #print "dupe\n";
   reset_qso();
   $Message = "DUPE";
   return 1;
 }else{
  $Message = "GOOD";
  return 0;
 }

}

##########

sub inline_dupe_qso {

 # print "dupe_qso $Call\n" if $DEBUG;

 #if(!defined($Call)){
 # $Message = "No Call";
 # return;
 #}

 my $entry = uc($_[0]);

 if(defined($qsos{$entry})){
   #print "dupe\n";
   my @ta = localtime(($qsos{$entry}{qsotime} + 21600));
   my $cd = ($ta[5] + 1900) . "-" . ($ta[4]+1) . "-$ta[3]";
   my $ct = "$ta[2]$ta[1]";
   $Message = "$qsos{$entry}{sserial} : $ta[2]:$ta[1] $qsos{$entry}{rserial} $qsos{$entry}{precedence} $entry $qsos{$entry}{check} $qsos{$entry}{section} $qsos{$entry}{freq}";
   $Inputs{Call}->configure(-background => red);
   return 1;
 }else{
  $Message = "GOOD";
  $Inputs{Call}->configure(-background => lightgrey);
  #print $entry . "\n";
  return 1;
 }

}

##########

sub sort_by_timestamp{
  $qsos{$a}{qsotime} <=> $qsos{$b}{qsotime};
}

##########
sub info {

 my $serial = 1 + shift(@_);

 $Info = "$serial  $myprec  $mycall  $mycheck  $mysection";
 $Info = "$Info        score: " . score();
 $Info = "$Info        sects: " . section_stats();

}

##########

sub reset_qso {

 undef($Serial);
 undef($Precedence);
 undef($Call);
 undef($Check);
 undef($Section);

 undef($Message);

 undef($update_call);

 $Inputs{Call}->focus();
 $doneButtonTxt = "Done";

}

##########
sub load_list {

 $lst->delete(0, 'end');

 foreach $entry (sort sort_by_timestamp keys %qsos ){
  $lst->insert(0,"$qsos{$entry}{sserial} : $qsos{$entry}{rserial} $qsos{$entry}{precedence} $entry $qsos{$entry}{check} $qsos{$entry}{section} $qsos{$entry}{freq}");
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

 $sectList1->delete(0,"end");
 $sectList2->delete(0,"end");
 $sectList3->delete(0,"end");
 $sectList4->delete(0,"end");

}

##########

sub load_sections {

 my $breakPoint = 21;
 my $cnt = 0;

 clear_sections();

 foreach $mult (sort keys %mults ){


  if($sectMode){
   if($mults{$mult}{worked}){
    next;
   }
  }

   $cnt++;

  my $status = $mults{$mult}{worked};

  unless($mults{$mult}{worked} > 0){
   $status = $status . " **";
  }


  my $ln = sprintf("%-4s %s %s", $mult, $mults{$mult}{longname},$status );

  if($cnt <= $breakPoint){
   $sectList1->insert('end',$ln);
   next;
  }

  if($cnt > (3 * $breakPoint)){
    $sectList4->insert('end',$ln);
    next;
  }

  if($cnt > (2 * $breakPoint)){
    $sectList3->insert('end',$ln);
    next;
  }

  if($cnt > $breakPoint){
    $sectList2->insert('end',$ln);
    next;
  }

 }

}

##########

sub delete_qso {

 if(defined($Call)){
  logit("del $Call\n");
  $mults{$qsos{$Call}{section}}{worked}--;
  $totqso--;
  delete($qsos{$Call});
  reset_qso();
  info($totqso);
  load_list();
  load_sections();
 }else{
  $Message = "No qso selected";
 }

}

##########

sub recall_qso {

 #print "recalling selected qso \n";

 $doneButtonTxt = "Update";

 my $r_qso = $lst->get($lst->curselection());

 #print $r_qso . "\n";

 my @qso_elements = split /\s+/, $r_qso;

 #print $qso_elements[4] . "\n";

 ($foo, $bar, $Serial,$Precedence,$Call,$Check,$Section,$Freq) = split /\s+/, $r_qso;

 $update_qsotime = $qsos{$Call}{qsotime};
 $update_given_serial = $foo;
 $update_call = $Call;
 #$update_time =

}

##########

sub get_rig_freq {
	$rig_freq = icom_civ_getfreq($socket, 0x66);
	#$rig_freq = "0.000.322.500";
	my($gig,$mhz,$khz,$hz) = split /\./, $rig_freq;
	$mhz =~ s/^0+//;
	unless ($Freq){
		$Freq = "fill me in"
	}
	if ($mhz) {
		return $mhz;
	} else {
		if ($Inputs{Freq}){
			$Inputs{Freq}->configure(-background => yellow);
		}
		return $Freq;
	}
}

##########
sub make_window {

 my $main = MainWindow->new();
 $main->geometry('760x640');
 $main->title("VRP sweeps");
 $main->configure(-background=>'grey');

 # two frames and adjuster
 my $lf = $main->Frame; # left
 my $aj = $main->Adjuster(-widget => $lf, -side => 'left');
 my $rf = $main->Frame; # right
 my $Msg = $main->Frame; # message frame
 my $bframe = $main->Frame; # bottom

 # menu bar
 my $mb = $main->Menu(-menuitems => [[qw/command ~Open -accelerator Ctrl-o/,
 					-command=>[\&OnFileOpen]]] );

 # atach menu to the main window
 $main->configure(-menu => $mb);

  # pack frames
 $bframe->pack(qw/-side bottom -fill both /);
 $lf->pack(qw/-side left -fill y/);
 $aj->pack(qw/-side left -fill y/);
 $rf->pack(qw/-side right -fill both -expand l/);



 # input text
 my(@ipl) = qw/-side left -padx 10 -pady 5 -fill x/;
 my(@lpl) = qw/-side left/;

 foreach $vn ( "Serial", "Precedence"){
  my $if = $rf->Frame->pack(qw/-anchor w/);
  $if->Label(-text => $vn, -width => 15)->pack(qw/-side left/);
  $Inputs{$vn} = $if->Entry(-textvariable => \$$vn)->pack(qw/-side left -padx 10 -pady 5 -fill x/);

 }

 $vn = "Call";
  my $if = $rf->Frame->pack(qw/-anchor w/);
  $if->Label(-text => $vn, -width => 15)->pack(qw/-side left/);
  $Inputs{$vn} = $if->Entry(-validate        => 'key',
			    -validatecommand => [\&inline_dupe_qso],
			    -textvariable => \$$vn)->pack(qw/-side left -padx 10 -pady 5 -fill x/);



 foreach $vn ("Check", "Section" ){
  my $if = $rf->Frame->pack(qw/-anchor w/);
  $if->Label(-text => $vn, -width => 15)->pack(qw/-side left/);
  $Inputs{$vn} = $if->Entry(-textvariable => \$$vn)->pack(qw/-side left -padx 10 -pady 5 -fill x/);

 }

  $vn = "Freq";
	$Freq = get_rig_freq();
  my $if = $rf->Frame->pack(qw/-anchor w/);
  $if->Label(-text => $vn, -width => 15)->pack(qw/-side left/);
  $Inputs{$vn} = $if->Entry(-takefocus => 0, -textvariable => \$Freq)->pack(qw/-side left -padx 10 -pady 5 -fill x/);
  #$Inputs{$vn}->repeat(1000,sub{$Freq = get_rig_freq()});

 $rf->Label(-takefocus => 0, -textvariable => \$Message,
            -borderwidth => 2,
	    -relief => 'groove')->pack(-fill => 'x',
	                                 -anchor => 'w');
 $rf->Label(-takefocus => 0, -textvariable => \$Info,
            -borderwidth => 2,
	    -relief => 'groove')->pack(-fill => 'x',
	                                 -anchor => 'w');

 my $bf = $rf->Frame->pack(qw/-anchor w/);

 $doneButtonTxt = "Done";
 $bf->Button( -takefocus => 0, -textvariable => \$doneButtonTxt,
              -command => \&process_qso,
              )->pack(qw/-side left -pady 2/);

 $bf->Button( -takefocus => 0, -text => "dupe <ctrl-d>",
               -command => \&dupe_qso,
              )->pack(qw/-side left -pady 2/);

 $bf->Button( -takefocus => 0, -text => "reset <crtl-c>",
               -command => \&reset_qso,
              )->pack(qw/-side left -pady 2/);

 $bf->Button( -takefocus => 0, -text => "delete",
               -command => \&delete_qso,
              )->pack(qw/-side left -pady 2/);

 $bf->Button( -takefocus => 0, -text => "quit <ctrl-q>",
              -command => sub { exit },
 	      )->pack(qw/-side left -pady 2/);

 $bf->Button( -takefocus => 0, -text => "sect toggle",
              -command => \&toggle_sections,
 	      )->pack(qw/-side left -pady 2/);


 $lst = $lf->Scrolled(qw/Listbox -takefocus 0 -selectmode single -width 30 -height 18 -scrollbars e/);
 $lst->Subwidget("yscrollbar")->configure(-takefocus => 0);
 $lst->pack(qw/-fill both/);
 $lst->bind('<Double-Button-1>',\&recall_qso);

 $sectList1 = $bframe->Listbox(-takefocus => 0, -selectmode => single, -width => 26, -height => 21);
 $sectList1->pack(qw/-side left -fill both/);
 $sectList1->bind('<Double-Button-1>',
    sub {
 	my ($sect,$rest) = split / /,$sectList1->get($sectList1->curselection()),2;
	$Section = $sect;
	}
 );

 $sectList2 = $bframe->Listbox(-takefocus => 0, -selectmode => single, -width => 26, -height => 21);
 $sectList2->pack(qw/-side left -fill both/);
 $sectList2->bind('<Double-Button-1>',
   sub {
 	my ($sect,$rest) = split / /,$sectList2->get($sectList2->curselection()),2;
	$Section = $sect;
	}
 );

 $sectList3 = $bframe->Listbox(-takefocus => 0, -selectmode => single, -width => 26, -height => 21);
 $sectList3->pack(qw/-side left -fill both/);
 $sectList3->bind('<Double-Button-1>',
    sub {
 	my ($sect,$rest) = split / /,$sectList3->get($sectList3->curselection()),2;
	$Section = $sect;
	}
 );

 #$sectList4 = $bframe->Scrolled(qw/Listbox -selectmode single -height 20 e/);
 #$sectList4->pack(qw/-side left -fill both/);

 $sectList4 = $bframe->Listbox(-takefocus => 0, -selectmode => single, -width => 26, -height => 21);
 $sectList4->pack(qw/-side left -fill both/);
 $sectList4->bind('<Double-Button-1>',
    sub {
 	my ($sect,$rest) = split / /,$sectList4->get($sectList4->curselection()),2;
	$Section = $sect;
	}
 );



 loadlog();

 load_sections();

 load_list();

 info($totqso);

 $Inputs{Serial}->focus();


  #$Freq = "foo";
	sub update_freq {$Freq = get_rig_freq(); $Inputs{"Freq"}->update();}
	$Inputs{"Freq"}->repeat(5000,\&update_freq);


 $main->bind("<Control-d>",[\&dupe_qso]);
 $main->bind("<Control-c>",[\&reset_qso]);
 $main->bind("<Return>",[\&process_qso]);
 $main->bind("<Control-q>",[sub { exit}]);
 $main->bind("<Control-t>",[\&toggle_sections]);

 MainLoop();

}

##########


make_window();
