##############  This program will be called if the length of fragment is longer than fasta sequence

our %AA3TO1 = qw(ALA A ASN N CYS C GLN Q HIS H LEU L MET M PRO P THR T TYR Y ARG R ASP D GLU E GLY G ILE I LYS K PHE F SER S TRP W VAL V);
our %AA1TO3 = reverse %AA3TO1;


## /scratch/jh7x3/multicom/tools/pulchra304/pulchra /storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/new_simulated_map_20190831/2GZ4-C/new_results/2GZ4.pdb

## /scratch/jh7x3/multicom/tools/scwrl4/Scwrl4 -i /storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/new_simulated_map_20190831/2GZ4-C/new_results/2GZ4.rebuilt.pdb -o  /storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/new_simulated_map_20190831/2GZ4-C/new_results/2GZ4_scwrl.pdb


# perl /storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/new_simulated_map_20190831/2GZ4-C/new_results/generate_alignment.pl  /storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/new_simulated_map_20190831/2GZ4-C/new_results/2GZ4.pdb /storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/new_simulated_map_20190831/2GZ4-C/new_results/2GZ4-C.fasta  /storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/new_simulated_map_20190831/2GZ4-C/new_results 10


# /scratch/jh7x3/multicom/tools/TMscore 2D.pdb ../input/2GZ4-C.pdb


# cd /scratch/jh7x3/multicom/tools/SBROD

# ./assess_protein /storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/new_simulated_map_20190831/2GZ4-C/new_results/Models/*pdb > /storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/new_simulated_map_20190831/2GZ4-C/new_results/Models/score.txt


# perl /storage/htc/bdm/jh7x3/DeepRank/src/scripts/sort_deep_qa_score.pl  /storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/new_simulated_map_20190831/2GZ4-C/new_results/Models/score.txt /storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/new_simulated_map_20190831/2GZ4-C/new_results/Models/score_new.txt



use List::Util qw(shuffle);

if (@ARGV != 4)
{
	die "Error: need seven parameters: domain_list, domain model folder, query file(fasta), target id, output dir, modeller path, model number. \n";
}
#### 
$input_pdb = shift @ARGV;
$fasta_file = shift @ARGV;
$outputfolder = shift @ARGV;
$proc_num = shift @ARGV;

-d $outputfolder || `mkdir $outputfolder`;
#get query name and sequence 
open(FASTA, $fasta_file) || die "Error: can't read fasta file $fasta_file.\n";
@content = <FASTA>;
$target_id = shift @content;
chomp $target_id;
$qseq = shift @content;
chomp $qseq;
close FASTA;



#rewrite fasta file if it contains lower-case letter
if ($qseq =~ /[a-z]/)
{
	print "There are lower case letters in the input file. Convert them to upper case.\n";
	$qseq = uc($qseq);
	open(FASTA, ">$outputfolder/$target_id.fasta") || die "Error: can't rewrite fasta file.\n";
	print FASTA "$target_id\n$qseq\n";
	close FASTA;
}

 
if ($target_id =~ /^>/)
{
	$target_id = substr($target_id, 1); 
}
else
{
	die "Error: fasta foramt error.\n"; 
}




#####  (1) initialize sequence in fragment for forward

`cp $input_pdb $outputfolder/input.pdb`;
`/scratch/jh7x3/multicom/tools/pulchra304/pulchra -c -s $outputfolder/input.pdb`;

$init_pdb = "$outputfolder/input.pdb";
if(!(-e "$outputfolder/input.rebuilt.pdb"))
{
  $init_pdb = "$outputfolder/input.pdb";
}else{

  `/scratch/jh7x3/multicom/tools/scwrl4/Scwrl4 -i $outputfolder/input.rebuilt.pdb -o  $outputfolder/input_scwrl.pdb`;
  if(!(-e "$outputfolder/input_scwrl.pdb"))
  {
    $init_pdb = "$outputfolder/input.rebuilt.pdb";
  }else{
    $init_pdb = "$outputfolder/input_scwrl.pdb";
  }
}

open OUTPDB, ">$outputfolder/temp0.pdb" or die "ERROR! Could not open $outputfolder/temp0.pdb\n";

open INPUTPDB, "$init_pdb" or die "ERROR! Could not open $init_pdb";
my @lines_PDB = <INPUTPDB>;
close INPUTPDB;

@PDB_temp=();
foreach (@lines_PDB) {
	$line = $_;
	chomp $line;
	next if $line !~ m/^ATOM/;

	$atomCounter = parse_pdb_row($line,"anum");
	$atomtype = parse_pdb_row($line,"aname");
	$resname = parse_pdb_row($line,"rname");
	$chainid = parse_pdb_row($line,"chain");
	$resCounter = parse_pdb_row($line,"rnum");
  $this_rchain = $chainid;
 
  if($atomtype eq 'CA')
  {
    push @PDB_temp,$line;
  }
  
  if($resCounter<=length($qseq))
  {
    $newresname = $AA1TO3{substr($qseq,$resCounter-1,1)};
  }
  
  $x = parse_pdb_row($line,"x");
  $y = parse_pdb_row($line,"y");
  $z = parse_pdb_row($line,"z");

	my $rnum_string = sprintf("%4s", $resCounter);
	my $anum_string = sprintf("%5s", $atomCounter);
	my $atomtype = sprintf("%4s", $atomtype);
	my $x = sprintf("%8s", $x);
	my $y = sprintf("%8s", $y);
	my $z = sprintf("%8s", $z);
	my $row = "ATOM  ".$anum_string.$atomtype."  ".$newresname." ".$chainid.$rnum_string."    ".$x.$y.$z."\n";
	print OUTPDB $row;
}
print OUTPDB "END\n";
close OUTPDB;




#####  (2) initialize sequence in reverse fragment

open OUTPDB, ">$outputfolder/input_r.pdb" or die "ERROR! Could not open $outputfolder/input_r.pdb\n";

@PDB_temp = reverse(@PDB_temp);
$Ca_index = 0;
$atom_index=0;
foreach (@PDB_temp) {
	$line = $_;
	chomp $line;
	next if $line !~ m/^ATOM/;
	$atomCounter = parse_pdb_row($line,"anum");
	$atomtype = parse_pdb_row($line,"aname");
	$resname = parse_pdb_row($line,"rname");
	$chainid = parse_pdb_row($line,"chain");
	$resCounter = parse_pdb_row($line,"rnum");
  $this_rchain = $chainid;
  next if $atomtype != 'CA';
  
  $Ca_index++;
  $atom_index++;
   
 
  $x = parse_pdb_row($line,"x");
  $y = parse_pdb_row($line,"y");
  $z = parse_pdb_row($line,"z");
	
	my $rnum_string = sprintf("%4s", $Ca_index);
	my $anum_string = sprintf("%5s", $atom_index);
	my $atomtype = sprintf("%4s", $atomtype);
	my $x = sprintf("%8s", $x);
	my $y = sprintf("%8s", $y);
	my $z = sprintf("%8s", $z);
	my $row = "ATOM  ".$anum_string.$atomtype."  ".$resname." ".$chainid.$rnum_string."    ".$x.$y.$z."\n";
	print OUTPDB $row;
}
print OUTPDB "END\n";
close OUTPDB;


`/scratch/jh7x3/multicom/tools/pulchra304/pulchra -c -s $outputfolder/input_r.pdb`;

$init_pdb = "$outputfolder/input_r.pdb";
if(!(-e "$outputfolder/input_r.rebuilt.pdb"))
{
  $init_pdb = "$outputfolder/input_r.pdb";
}else{

  `/scratch/jh7x3/multicom/tools/scwrl4/Scwrl4 -i $outputfolder/input_r.rebuilt.pdb -o  $outputfolder/input_r_scwrl.pdb`;
  if(!(-e "$outputfolder/input_r_scwrl.pdb"))
  {
    $init_pdb = "$outputfolder/input_r.rebuilt.pdb";
  }else{
    $init_pdb = "$outputfolder/input_r_scwrl.pdb";
  }
}

open OUTPDB, ">$outputfolder/temp0_r.pdb" or die "ERROR! Could not open $outputfolder/temp0_r.pdb\n";

open INPUTPDB, "$outputfolder/input_r_scwrl.pdb" or die "ERROR! Could not open $outputfolder/input_r_scwrl.pdb";
my @lines_PDB = <INPUTPDB>;
close INPUTPDB;

@PDB_temp=();
foreach (@lines_PDB) {
	$line = $_;
	chomp $line;
	next if $line !~ m/^ATOM/;

	$atomCounter = parse_pdb_row($line,"anum");
	$atomtype = parse_pdb_row($line,"aname");
	$resname = parse_pdb_row($line,"rname");
	$chainid = parse_pdb_row($line,"chain");
	$resCounter = parse_pdb_row($line,"rnum");
  $this_rchain = $chainid;
  
  if($resCounter<=length($qseq))
  {
    $newresname = $AA1TO3{substr($qseq,$resCounter-1,1)};
  }
  
  $x = parse_pdb_row($line,"x");
  $y = parse_pdb_row($line,"y");
  $z = parse_pdb_row($line,"z");

	my $rnum_string = sprintf("%4s", $resCounter);
	my $anum_string = sprintf("%5s", $atomCounter);
	my $atomtype = sprintf("%4s", $atomtype);
	my $x = sprintf("%8s", $x);
	my $y = sprintf("%8s", $y);
	my $z = sprintf("%8s", $z);
	my $row = "ATOM  ".$anum_string.$atomtype."  ".$newresname." ".$chainid.$rnum_string."    ".$x.$y.$z."\n";
	print OUTPDB $row;
}
print OUTPDB "END\n";
close OUTPDB;





##### (3) rebuild side-chain according to new aa

$init_pdb = "$outputfolder/temp0.pdb";

`/scratch/jh7x3/multicom/tools/scwrl4/Scwrl4 -i $outputfolder/temp0.pdb -o  $outputfolder/temp0_scwrl.pdb`;
if(!(-e "$outputfolder/temp0_scwrl.pdb"))
{
  $init_pdb = "$outputfolder/temp0.pdb";
}else{
  $init_pdb = "$outputfolder/temp0_scwrl.pdb";
}


$init_pdb_reverse = "$outputfolder/temp0_r.pdb";

`/scratch/jh7x3/multicom/tools/scwrl4/Scwrl4 -i $outputfolder/temp0_r.pdb -o  $outputfolder/temp0_r_scwrl.pdb`;
if(!(-e "$outputfolder/temp0_r_scwrl.pdb"))
{
  $init_pdb_reverse = "$outputfolder/temp0_r.pdb";
}else{
  $init_pdb_reverse = "$outputfolder/temp0_r_scwrl.pdb";
}



open INPUTPDB, "$init_pdb" or die "ERROR! Could not open $init_pdb\n";

@lines_PDB = <INPUTPDB>; 
close INPUTPDB;
$pdb_seq="";
$pdb_record = ();
$this_rchain="";
foreach (@lines_PDB) {
	next if $_ !~ m/^ATOM/;
	next unless (parse_pdb_row($_,"aname") eq "CA");
	$this_rchain = parse_pdb_row($_,"chain");
	$rname = $AA3TO1{parse_pdb_row($_,"rname")};
	$rnum = parse_pdb_row($_,"rnum");
  if(exists($pdb_record{"$this_rchain-$rname-$rnum"}))
  {
    next;
  }else{
    $pdb_record{"$this_rchain-$rname-$rnum"} = 1;
  }
  
  $pdb_seq .= $rname;
}

print "PDB_seq: ".length($pdb_seq)."\n";
print "fas_seq: ".length($qseq)."\n";
print "$pdb_seq\n$qseq\n";


##### (4) generate alignment

$n_gaps = length($pdb_seq) - length($qseq);

-d "$outputfolder/Alignments" || `mkdir $outputfolder/Alignments/`;
-d "$outputfolder/Atoms" || `mkdir $outputfolder/Atoms/`;
-d "$outputfolder/Models" || `mkdir $outputfolder/Models/`;

`cp $init_pdb $outputfolder/Atoms/aaaaA.atm`;
`cp $init_pdb_reverse $outputfolder/Atoms/aaaaB.atm`;
chdir("$outputfolder/Atoms");
#`gzip -f aaaaA.atom`; 
#`gzip -f aaaaB.atom`; 

=pod
##### (5) self modeling

$pir_file = $outputfolder . "/Atoms/temp0.pir";
open(PIR, ">$pir_file") || die "can't create pir file $pir_file.\n";
$dlen = length($pdb_seq);
print PIR "C;cover size:X; local alignment length=X (original info = aaaaA	X	X	0	0)\n";
print PIR ">P1;aaaaA\n";
print PIR "structureX:aaaaA: 1: $this_rchain: $dlen: : : :3.00: \n"; 
print PIR "$pdb_seq*\n\n";

print PIR "C;query_length:X num_of_temps:X cover_ratio:X cover:X not_cover:X\n"; 
print PIR ">P1;temp0_refine\n";
print PIR " : : : : : : : : : \n";
print PIR "$pdb_seq*\n";
close PIR; 

#print "\nUse Modeller to refine...\n";
#print("perl /scratch/jh7x3/multicom/tools/Domain_assembly/scripts/pir2ts_energy_9v16.pl /scratch/jh7x3/multicom/tools/modeller-9.16/bin/mod9.16 $outputfolder/Atoms $outputfolder $pir_file 1\n"); 
#system("perl /scratch/jh7x3/multicom/tools/Domain_assembly/scripts/pir2ts_energy_9v16.pl /scratch/jh7x3/multicom/tools/modeller-9.16/bin/mod9.16  $outputfolder/Atoms $outputfolder $pir_file 1"); 

-d "$outputfolder/mtmg_refine/" || `mkdir $outputfolder/mtmg_refine/`;

print "\nUse MTMG to refine...\n";
print "/storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/New_sequence_mapping_jiealgo/scripts/MTMG/mtmg $outputfolder/Atoms/ temp0.pir temp0_refine $outputfolder/mtmg_refine/ /storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/New_sequence_mapping_jiealgo/scripts/MTMG/ /storage/htc/bdm/jh7x3/DeepRank/tools/R-3.2.0/bin/ 0 d\n";
system("/storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/New_sequence_mapping_jiealgo/scripts/MTMG/mtmg $outputfolder/Atoms/ temp0.pir temp0_refine $outputfolder/mtmg_refine/ /storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/New_sequence_mapping_jiealgo/scripts/MTMG/ /storage/htc/bdm/jh7x3/DeepRank/tools/R-3.2.0/bin/ 0 d");



$pir_file = $outputfolder . "/Atoms/temp0_r.pir";
open(PIR, ">$pir_file") || die "can't create pir file $pir_file.\n";
$dlen = length($pdb_seq);
print PIR "C;cover size:X; local alignment length=X (original info = aaaaB	X	X	0	0)\n";
print PIR ">P1;aaaaB\n";
print PIR "structureX:aaaaB: 1: $this_rchain: $dlen: : : :3.00: \n"; 
print PIR "$pdb_seq*\n\n";

print PIR "C;query_length:X num_of_temps:X cover_ratio:X cover:X not_cover:X\n"; 
print PIR ">P1;temp0_r_refine\n";
print PIR " : : : : : : : : : \n";
print PIR "$pdb_seq*\n";
close PIR; 

#print "\nUse Modeller to refine...\n";
#print("perl /scratch/jh7x3/multicom/tools/Domain_assembly/scripts/pir2ts_energy_9v16.pl /scratch/jh7x3/multicom/tools/modeller-9.16/bin/mod9.16 $outputfolder/Atoms $outputfolder $pir_file 1\n"); 
#system("perl /scratch/jh7x3/multicom/tools/Domain_assembly/scripts/pir2ts_energy_9v16.pl /scratch/jh7x3/multicom/tools/modeller-9.16/bin/mod9.16  $outputfolder/Atoms $outputfolder $pir_file 1"); 



-d "$outputfolder/mtmg_R_refine/" || `mkdir $outputfolder/mtmg_R_refine/`;

print "\nUse MTMG to refine...\n";
print "/storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/New_sequence_mapping_jiealgo/scripts/MTMG/mtmg $outputfolder/Atoms/ temp0_r.pir temp0_r_refine $outputfolder/mtmg_R_refine/ /storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/New_sequence_mapping_jiealgo/scripts/MTMG/ /storage/htc/bdm/jh7x3/DeepRank/tools/R-3.2.0/bin/ 0 d\n";
system("/storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/New_sequence_mapping_jiealgo/scripts/MTMG/mtmg $outputfolder/Atoms/ temp0_r.pir temp0_r_refine $outputfolder/mtmg_R_refine/ /storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/New_sequence_mapping_jiealgo/scripts/MTMG/ /storage/htc/bdm/jh7x3/DeepRank/tools/R-3.2.0/bin/ 0 d");



if(-e "$outputfolder/mtmg_refine/temp0_refine.pdb")
{
  `cp $outputfolder/mtmg_refine/temp0_refine.pdb $outputfolder/Atoms/aaaa.atom`;
}
if(-e "$outputfolder/mtmg_R_refine/temp0_r_refine.pdb")
{
  `cp $outputfolder/mtmg_R_refine/temp0_r_refine.pdb $outputfolder/Atoms/fragment_reverse.atom`;
}

chdir("$outputfolder/Atoms");
#`gzip -f fragment.atom`; 
#`gzip -f fragment_reverse.atom`; 
=cut

##### (6) Generate alignments for forward direction
chdir($outputfolder);


$shell_dir = "$outputfolder/sh_src";
-d $shell_dir || `mkdir $shell_dir`;


@running_files = ();
for($epoch=1;$epoch<=100;$epoch++)
{
  print "############### Forward Epoch: $epoch\n\n";
  ##### insert gap randomly into sequence
  $newseq = $qseq;
  print "Insert gaps in position";
  for($i=0;$i<$n_gaps;$i++)
  {
    $s_len = length($newseq);
    $pos = 0 + int(rand($s_len));
    print " $pos";
    $newseq = substr($newseq,0,$pos).'-'.substr($newseq,$pos);
  }
  print "\n\n";
  -d "$outputfolder/Alignments/temp_$epoch/" || `mkdir $outputfolder/Alignments/temp_$epoch/`;

  `cp $outputfolder/Atoms/aaaaA.atm $outputfolder/Alignments/temp_$epoch/`;
  $pir_file = "$outputfolder/Alignments/temp_$epoch/align.pir";
  open(PIR, ">$pir_file") || die "can't create pir file $pir_file.\n";
  $dlen = length($pdb_seq);
  print PIR "C;cover size:X; local alignment length=X (original info = aaaaA	X	X	0	0)\n";
  print PIR ">P1;aaaaA\n";
  print PIR "structureX:aaaaA: 1: $this_rchain: $dlen: : : : : \n"; 
  print PIR "$pdb_seq*\n\n";
  
  print PIR "C;query_length:X num_of_temps:X cover_ratio:X cover:X not_cover:X\n"; 
  print PIR ">P1;temp_$epoch\n";
  print PIR " : : : : : : : : : \n";
  print PIR "$newseq*\n";
  close PIR; 
  

	open(RUNFILE,">$shell_dir/temp_$epoch.sh") || die "Failed to write $shell_dir/temp_$epoch.sh\n\n";
	`touch $shell_dir/temp_$epoch.sh.queued`;
	print RUNFILE "#!/bin/bash\n\n";
	print RUNFILE "mv $shell_dir/temp_$epoch.sh.queued $shell_dir/temp_$epoch.sh.running\n\n";
	print RUNFILE "\nprintf \"Use MTMG to refine...\"\n";

	print RUNFILE "mkdir -p $outputfolder/Alignments/temp_$epoch/mtmg_refine/\n\n";
  print RUNFILE "printf \"/storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/New_sequence_mapping_jiealgo/scripts/MTMG/mtmg $outputfolder/Alignments/temp_$epoch/ align.pir temp_$epoch $outputfolder/Alignments/temp_$epoch/mtmg_refine/ /storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/New_sequence_mapping_jiealgo/scripts/MTMG/ /storage/htc/bdm/jh7x3/DeepRank/tools/R-3.2.0/bin/ 0 d\"\n\n";
	print RUNFILE "/storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/New_sequence_mapping_jiealgo/scripts/MTMG/mtmg $outputfolder/Alignments/temp_$epoch/ align.pir temp_$epoch $outputfolder/Alignments/temp_$epoch/mtmg_refine/ /storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/New_sequence_mapping_jiealgo/scripts/MTMG/ /storage/htc/bdm/jh7x3/DeepRank/tools/R-3.2.0/bin/ 0 d\n\n";
    print RUNFILE "cp $outputfolder/Alignments/temp_$epoch/mtmg_refine/temp_$epoch.pdb $outputfolder/Models\n\n";

	print RUNFILE "mv $shell_dir/temp_$epoch.sh.running $shell_dir/temp_$epoch.sh.done";
	close RUNFILE;

  push @running_files,"$shell_dir/temp_$epoch.sh";
}


for($epoch=1;$epoch<=50;$epoch++)
{
  print "############### Forward Epoch: $epoch\n\n";
  ##### insert gap randomly in N/C terminal
  $newseq = $qseq;
  print "Insert gaps in position";
  if($epoch == 1)
  {
    for($i=0;$i<$n_gaps;$i++)
    {
      $s_len = length($newseq);
      $pos = 0;
      $newseq = substr($newseq,0,$pos).'-'.substr($newseq,$pos);
    }
  }elsif($epoch == 2)
  {
    for($i=0;$i<$n_gaps;$i++)
    {
      $s_len = length($newseq);
      $pos = $s_len;
      $newseq = substr($newseq,0,$pos).'-'.substr($newseq,$pos);
    }
  }else{
    for($i=0;$i<$n_gaps;$i++)
    {
      $s_len = length($newseq);
      @two_ter = ();
      
      push @two_ter,0;
      push @two_ter,$s_len;
      $pos = 0 + $two_ter[int(rand(2))];
      print " $pos";
      $newseq = substr($newseq,0,$pos).'-'.substr($newseq,$pos);
    }
  }
  print "\n\n";
  -d "$outputfolder/Alignments/temp_NC_$epoch/" || `mkdir $outputfolder/Alignments/temp_NC_$epoch/`;

  `cp $outputfolder/Atoms/aaaaA.atm $outputfolder/Alignments/temp_NC_$epoch/`;
  $pir_file = "$outputfolder/Alignments/temp_NC_$epoch/align.pir";
  open(PIR, ">$pir_file") || die "can't create pir file $pir_file.\n";
  $dlen = length($pdb_seq);
  print PIR "C;cover size:X; local alignment length=X (original info = aaaaA	X	X	0	0)\n";
  print PIR ">P1;aaaaA\n";
  print PIR "structureX:aaaaA: 1: $this_rchain: $dlen: : : : : \n"; 
  print PIR "$pdb_seq*\n\n";
  
  print PIR "C;query_length:X num_of_temps:X cover_ratio:X cover:X not_cover:X\n"; 
  print PIR ">P1;temp_NC_$epoch\n";
  print PIR " : : : : : : : : : \n";
  print PIR "$newseq*\n";
  close PIR; 
  

	open(RUNFILE,">$shell_dir/temp_NC_$epoch.sh") || die "Failed to write $shell_dir/temp_NC_$epoch.sh\n\n";
	`touch $shell_dir/temp_NC_$epoch.sh.queued`;
	print RUNFILE "#!/bin/bash\n\n";
	print RUNFILE "mv $shell_dir/temp_NC_$epoch.sh.queued $shell_dir/temp_NC_$epoch.sh.running\n\n";
	print RUNFILE "\nprintf \"Use MTMG to refine...\"\n";

	print RUNFILE "mkdir -p $outputfolder/Alignments/temp_NC_$epoch/mtmg_refine/\n\n";
  print RUNFILE "printf \"/storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/New_sequence_mapping_jiealgo/scripts/MTMG/mtmg $outputfolder/Alignments/temp_NC_$epoch/ align.pir temp_NC_$epoch $outputfolder/Alignments/temp_NC_$epoch/mtmg_refine/ /storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/New_sequence_mapping_jiealgo/scripts/MTMG/ /storage/htc/bdm/jh7x3/DeepRank/tools/R-3.2.0/bin/ 0 d\"\n\n";
	print RUNFILE "/storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/New_sequence_mapping_jiealgo/scripts/MTMG/mtmg $outputfolder/Alignments/temp_NC_$epoch/ align.pir temp_NC_$epoch $outputfolder/Alignments/temp_NC_$epoch/mtmg_refine/ /storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/New_sequence_mapping_jiealgo/scripts/MTMG/ /storage/htc/bdm/jh7x3/DeepRank/tools/R-3.2.0/bin/ 0 d\n\n";
    print RUNFILE "cp $outputfolder/Alignments/temp_NC_$epoch/mtmg_refine/temp_NC_$epoch.pdb $outputfolder/Models\n\n";

	print RUNFILE "mv $shell_dir/temp_NC_$epoch.sh.running $shell_dir/temp_NC_$epoch.sh.done";
	close RUNFILE;

  push @running_files,"$shell_dir/temp_NC_$epoch.sh";
}

for($epoch=1;$epoch<=100;$epoch++)
{
  print "############### Backward Epoch: $epoch\n\n";
  ##### insert gap randomly into sequence
  $newseq = $qseq;
  print "Insert gaps in position";
  for($i=0;$i<$n_gaps;$i++)
  {
    $s_len = length($newseq);
    $pos = 0 + int(rand($s_len));
    print " $pos";
    $newseq = substr($newseq,0,$pos).'-'.substr($newseq,$pos);
  }
  print "\n\n";
  
  -d "$outputfolder/Alignments/temp_r_$epoch/" || `mkdir $outputfolder/Alignments/temp_r_$epoch/`;
  
  `cp $outputfolder/Atoms/aaaaB.atm $outputfolder/Alignments/temp_r_$epoch/`;
  
  $pir_file = "$outputfolder/Alignments/temp_r_$epoch/align.pir";
  open(PIR, ">$pir_file") || die "can't create pir file $pir_file.\n";
  $dlen = length($pdb_seq);
  print PIR "C;cover size:X; local alignment length=X (original info = aaaaB	X	X	0	0)\n";
  print PIR ">P1;aaaaB\n";
  print PIR "structureX:aaaaB: 1: $this_rchain: $dlen: : : : : \n"; 
  print PIR "$pdb_seq*\n\n";
  
  print PIR "C;query_length:X num_of_temps:X cover_ratio:X cover:X not_cover:X\n"; 
  print PIR ">P1;temp_r_$epoch\n";
  print PIR " : : : : : : : : : \n";
  print PIR "$newseq*\n";
  close PIR; 
  
	open(RUNFILE,">$shell_dir/temp_r_$epoch.sh") || die "Failed to write $shell_dir/temp_r_$epoch.sh\n\n";
	`touch $shell_dir/temp_r_$epoch.sh.queued`;
	print RUNFILE "#!/bin/bash\n\n";
	print RUNFILE "mv $shell_dir/temp_r_$epoch.sh.queued $shell_dir/temp_r_$epoch.sh.running\n\n";
	print RUNFILE "\nprintf \"Use MTMG to refine...\"\n";

	print RUNFILE "mkdir -p $outputfolder/Alignments/temp_r_$epoch/mtmg_refine/\n\n";
  print RUNFILE "printf \"/storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/New_sequence_mapping_jiealgo/scripts/MTMG/mtmg $outputfolder/Alignments/temp_r_$epoch/ align.pir temp_r_$epoch $outputfolder/Alignments/temp_r_$epoch/mtmg_refine/ /storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/New_sequence_mapping_jiealgo/scripts/MTMG/ /storage/htc/bdm/jh7x3/DeepRank/tools/R-3.2.0/bin/ 0 d\"\n\n";
	print RUNFILE "/storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/New_sequence_mapping_jiealgo/scripts/MTMG/mtmg $outputfolder/Alignments/temp_r_$epoch/ align.pir temp_r_$epoch $outputfolder/Alignments/temp_r_$epoch/mtmg_refine/ /storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/New_sequence_mapping_jiealgo/scripts/MTMG/ /storage/htc/bdm/jh7x3/DeepRank/tools/R-3.2.0/bin/ 0 d\n\n";
    print RUNFILE "cp $outputfolder/Alignments/temp_r_$epoch/mtmg_refine/temp_r_$epoch.pdb $outputfolder/Models\n\n";

	print RUNFILE "mv $shell_dir/temp_r_$epoch.sh.running $shell_dir/temp_r_$epoch.sh.done\n\n";
	close RUNFILE;

  push @running_files,"$shell_dir/temp_r_$epoch.sh";
}

for($epoch=1;$epoch<=50;$epoch++)
{
  print "############### Backward Epoch: $epoch\n\n";
  ##### insert gap randomly in N/C terminal
  $newseq = $qseq;
  print "Insert gaps in position";
  if($epoch == 1)
  {
    for($i=0;$i<$n_gaps;$i++)
    {
      $s_len = length($newseq);
      $pos = 0;
      $newseq = substr($newseq,0,$pos).'-'.substr($newseq,$pos);
    }
  }elsif($epoch == 2)
  {
    for($i=0;$i<$n_gaps;$i++)
    {
      $s_len = length($newseq);
      $pos = $s_len;
      $newseq = substr($newseq,0,$pos).'-'.substr($newseq,$pos);
    }
  }else{
    for($i=0;$i<$n_gaps;$i++)
    {
      $s_len = length($newseq);
      @two_ter = ();
      
      push @two_ter,0;
      push @two_ter,$s_len;
      $pos = 0 + $two_ter[int(rand(2))];
      print " $pos";
      $newseq = substr($newseq,0,$pos).'-'.substr($newseq,$pos);
    }
  }
  
  print "\n\n";
  
  -d "$outputfolder/Alignments/temp_r_NC_$epoch/" || `mkdir $outputfolder/Alignments/temp_r_NC_$epoch/`;
  
  `cp $outputfolder/Atoms/aaaaB.atm $outputfolder/Alignments/temp_r_NC_$epoch/`;
  
  $pir_file = "$outputfolder/Alignments/temp_r_NC_$epoch/align.pir";
  open(PIR, ">$pir_file") || die "can't create pir file $pir_file.\n";
  $dlen = length($pdb_seq);
  print PIR "C;cover size:X; local alignment length=X (original info = aaaaB	X	X	0	0)\n";
  print PIR ">P1;aaaaB\n";
  print PIR "structureX:aaaaB: 1: $this_rchain: $dlen: : : : : \n"; 
  print PIR "$pdb_seq*\n\n";
  
  print PIR "C;query_length:X num_of_temps:X cover_ratio:X cover:X not_cover:X\n"; 
  print PIR ">P1;temp_r_NC_$epoch\n";
  print PIR " : : : : : : : : : \n";
  print PIR "$newseq*\n";
  close PIR; 
  
	open(RUNFILE,">$shell_dir/temp_r_NC_$epoch.sh") || die "Failed to write $shell_dir/temp_r_NC_$epoch.sh\n\n";
	`touch $shell_dir/temp_r_NC_$epoch.sh.queued`;
	print RUNFILE "#!/bin/bash\n\n";
	print RUNFILE "mv $shell_dir/temp_r_NC_$epoch.sh.queued $shell_dir/temp_r_NC_$epoch.sh.running\n\n";
	print RUNFILE "\nprintf \"Use MTMG to refine...\"\n";

	print RUNFILE "mkdir -p $outputfolder/Alignments/temp_r_NC_$epoch/mtmg_refine/\n\n";
  print RUNFILE "printf \"/storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/New_sequence_mapping_jiealgo/scripts/MTMG/mtmg $outputfolder/Alignments/temp_r_NC_$epoch/ align.pir temp_r_NC_$epoch $outputfolder/Alignments/temp_r_NC_$epoch/mtmg_refine/ /storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/New_sequence_mapping_jiealgo/scripts/MTMG/ /storage/htc/bdm/jh7x3/DeepRank/tools/R-3.2.0/bin/ 0 d\"\n\n";
	print RUNFILE "/storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/New_sequence_mapping_jiealgo/scripts/MTMG/mtmg $outputfolder/Alignments/temp_r_NC_$epoch/ align.pir temp_r_NC_$epoch $outputfolder/Alignments/temp_r_NC_$epoch/mtmg_refine/ /storage/htc/bdm/jh7x3/Cryo_em_paper/paper_version_20190817/New_sequence_mapping_jiealgo/scripts/MTMG/ /storage/htc/bdm/jh7x3/DeepRank/tools/R-3.2.0/bin/ 0 d\n\n";
    print RUNFILE "cp $outputfolder/Alignments/temp_r_NC_$epoch/mtmg_refine/temp_r_NC_$epoch.pdb $outputfolder/Models\n\n";

	print RUNFILE "mv $shell_dir/temp_r_NC_$epoch.sh.running $shell_dir/temp_r_NC_$epoch.sh.done\n\n";
	close RUNFILE;

  push @running_files,"$shell_dir/temp_r_NC_$epoch.sh";
}


##### (7) Generate models

foreach $file_path (sort @running_files)
{
	## check the running jobs
	$min_elaps=0;
	while(1)
	{
		opendir(DIR,"$shell_dir") || die "Failed to open directory $shell_dir\n";
		@out_files = readdir(DIR);
		closedir(DIR);
		
		$running_num = 0;
		foreach $check_file (sort @out_files)
		{
			if($check_file eq '.' or $check_file eq '..' or substr($check_file,length($check_file)-8) ne '.running')
			{
				next;
			}
			$running_num++;
		}
		if($running_num<$proc_num)
		{
			last;
		}
		sleep(60);
		$min_elaps++;
		if($min_elaps > 60)
		{
			last; # move to next;
		}
	}
	
	if(!(-e substr($file_path,0,length($file_path)-3).".done"))
	{
		print "run test $file_path\n";
		system("sh $file_path &> $file_path.log &");
	}else{
		print "$file_path has been done\n";
		$queue_file = substr($file_path,0,length($file_path)-3).".queued";
		if(-e $queue_file)
		{
			`rm $queue_file`;
		}
	}
	
	$running_jobs=0;
	$processed_jobs=0;
	opendir(DIR,"$shell_dir") || die "Failed to open directory $shell_dir\n";
	@out_files = readdir(DIR);
	closedir(DIR);
	foreach $check_file (sort @out_files)
	{
		if($check_file eq '.' or $check_file eq '..')
		{
			next;
		}
		if(substr($check_file,length($check_file)-5) eq '.done')
		{
			$processed_jobs++;
		}
		if(substr($check_file,length($check_file)-8) eq '.running')
		{
			$running_jobs++;
		}
	}
	$remain_jobs = @running_files-$processed_jobs-$running_jobs;
	print "Current running jobs ($running_num), processed jobs ($processed_jobs), unprocessed jobs ($remain_jobs)\n\n";
	sleep(5);
}

#### check if all files have finished
print "#### check if all files have finished\n";

while(1)
{

	opendir(DIR,"$shell_dir") || die "Failed to open directory $shell_dir\n";
	@out_files = readdir(DIR);
	closedir(DIR);

  $running_num = 0;
  foreach $check_file (sort @out_files)
  {
  	if($check_file eq '.' or $check_file eq '..' or substr($check_file,length($check_file)-3) eq '.sh')
  	{
  		next;
  	}
   
    if(substr($check_file,length($check_file)-8) eq '.running' or substr($check_file,length($check_file)-7) eq '.queued')
    {
  	  $running_num++;
    }
  }
  
  if($running_num>0)
  {
    print "$running_num jobs are still running, please wait\n";
  }else{
    print "All training jobs are done\n\n";
    last;
  }
  
  sleep(60*5);
  
}







###################  convert coord back to fragment


sub generate_gaps
{
	my $gnum = $_[0]; 	
	my $gaps = "";
	my $i;
	for ($i = 0; $i < $gnum; $i++)
	{
		$gaps .= "-"; 
	}
	return $gaps; 
}



sub parse_pdb_row{
	my $row = shift;
	my $param = shift;
	my $result;
	$result = substr($row,6,5) if ($param eq "anum");
	$result = substr($row,12,4) if ($param eq "aname");
	$result = substr($row,16,1) if ($param eq "altloc");
	$result = substr($row,17,3) if ($param eq "rname");
	$result = substr($row,22,5) if ($param eq "rnum");
	$result = substr($row,21,1) if ($param eq "chain");
	$result = substr($row,30,8) if ($param eq "x");
	$result = substr($row,38,8) if ($param eq "y");
	$result = substr($row,46,8) if ($param eq "z");
	die "Invalid row[$row] or parameter[$param]" if (not defined $result);
	$result =~ s/\s+//g;
	return $result;
}