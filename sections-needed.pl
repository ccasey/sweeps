#!/usr/bin/env perl

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

$LOGFILE = "./tests/2023.dat";

if( -e $LOGFILE ){
    open(LL,"<$LOGFILE")
   	or die "cant open $LOGFILE: $!\n";
}

while(<LL>){
   	chomp;
   	my @foo = split;

   	if($foo[0] =~ /del/){
			next;
   	}else{
#    	$qsos{$foo[4]} = { action => "add", sserial => $foo[1], rserial => $foo[2], precedence => $foo[3], check => $foo[5],
#                     	section => $foo[6], qsotime => $foo[7], freq => $foo[8]};
        $mults{$foo[6]}{worked}++;
   	}
 }

close(LL);

$cnt = 0;
foreach (keys %mults){
  	if ($mults{$_}{worked} == 0){
   		print " $_ - $mults{$_}{longname}\n";
        $cnt++;
  	}
  }

  print "$cnt\n";