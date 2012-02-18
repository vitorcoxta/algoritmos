use strict;
use Bio::Perl;
use Bio::Seq;
use Bio::SeqIO;
use Bio::Species;
use strict;
use DBI();
use DBD::mysql;
use Bio::Root::Exception;
use Bio::Tools::Run::RemoteBlast;
use Bio::Tools::SeqStats;
use Error qw(:try);
use Bio::Restriction::EnzymeCollection;
use Bio::Restriction::Analysis;


#------------------------DATABASE CONNECTIONS ON JOAO'S PC!-----------------------------
#my $dbh = DBI->connect('dbi:mysql:alg','root','blabla1') or die "Connection Error: $DBI::errstr\n";
#my %dbm_seq;
#dbmopen(%dbm_seq, '/home/johnnovo/Documents/sequence', 0666);

#------------------------DATABASE CONNECTIONS ON VITOR'S PC!----------------------------
my $dbh = DBI->connect('dbi:mysql:alg','root','5D311NC8') or die "Connection Error: $DBI::errstr\n";
my %dbm_seq;
dbmopen(%dbm_seq, '/home/cof91/Documents/Mestrado/1º ano/1º semestre/Bioinformática - Ciências Biológicas/Algoritmos e Tecnologias da Bioinformática/Trabalho/algoritmos/database/sequences', 0666);

#------------------------DATABASE CONNECTIONS ON JOSE'S PC!----------------------------
#my $dbh = DBI->connect('dbi:mysql:alg','root','') or die "Connection Error: $DBI::errstr\n";
#my %dbm_seq;
#dbmopen(%dbm_seq, 'C:\Program Files', 0666);


#------------------------DATABASE CONNECTIONS ON TELMA'S PC!----------------------------
#my $dbh = DBI->connect('dbi:mysql:alg','root','') or die "Connection Error: $DBI::errstr\n";
#my %dbm_seq;
#dbmopen(%dbm_seq, 'C:\Program Files', 0666);

main(1);




#------------------This is the main function------------------------------------
sub main{
    my ($clear) = @_;
    my $option = interface("welcome", $clear, 0);
    if($option == 1){database_operations();}
    elsif($option == 2){bioinformatics_operations();}
    elsif($option==3){search_operations();}    
    elsif($option == 9){
        interface("exit");
        dbmclose(%dbm_seq);
        exit(0);
    }
}


#----------------------This function will call the functions that operate with the database--------------------------------
sub database_operations{
    my $option = interface("database_operations", 1, 0);
    if($option == 1){insertion();}
    elsif($option == 2){removal();}
    elsif($option == 3){modification();}
    elsif($option == 9){main(1);}
}



#----------------------------This function will call the functions that perform a bioinformatics job--------------------------
sub bioinformatics_operations{
    my $option = interface("bioinformatics_operations", 1, 0);
    if($option == 1){blast();}
    elsif($option == 2){motif();}
    elsif($option == 3){statistics();}
    elsif($option == 4){features();}
    elsif($option == 5){translatee();}
    elsif($option == 9){main(1);}
}



#----------------------------This function will call the functions to perform searchs in the database--------------------------
sub search_operations{
    my $option = interface("search_operations",1,0);
    system $^O eq 'MSWin32' ? 'cls' : 'clear';
    if($option == 1){display_tags();}
    elsif($option == 2){display_species();}
    elsif($option == 3){display_all_sequences();}
    elsif($option == 4){display_search_sequences();}
    elsif($option == 9){main(1);}
    interface("waiting_enter");
    main(1);
}




#-----------------------This function inserts a sequence in the database: manually, from a file or from a remote database----------------------
sub insertion{
    my $option = interface("ask_insertion_type", 1, 0);
    if($option == 1) {
        #----------Asks user for useful information---------------
        my $authority = interface("ask_authority",1);
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        my $alph= interface("ask_alphabet", 0);
        my $alphabet;
        if($alph == 1) {$alphabet = "dna";}
        elsif($alph == 2) {$alphabet = "rna";}
        elsif($alph == 3) {$alphabet = "protein";}
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        my $description = interface("ask_description", 0);
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        my $gene_name = interface("ask_gene_name_insertion", 0);
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        my $date = interface("ask_date", 0);
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        my $is_circular = interface("ask_is_circular", 0, 0);
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        my @keywords;
        my $bool;
        ($bool, @keywords) = interface("ask_tag", 0);
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        my $sequence = interface("ask_sequence", 0, 0, $alphabet);
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        my $seq_version = interface("ask_seq_version", 0);
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        my $specie = interface("ask_specie", 0);
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        my $format_opt = interface("ask_format", 0, 0);
        my $format;
        if($format_opt == 1) {$format = "fasta";}
        elsif($format_opt == 2) {$format = "genbank";}
        elsif($format_opt == 3) {$format = "swiss";}
        my $seq_length = length($sequence);
        my $seq = Bio::Seq->new(-seq => $sequence, -id => $gene_name, -alphabet => $alphabet, -is_circular => $is_circular);
        
        insert_specie($specie);
        insert_sequence_db($specie, $alphabet, $authority, $description, $gene_name, $date, $is_circular, $seq_length, $format, $seq_version);
        my $id_sequence = insert_tags($bool, @keywords);
        insert_sequence($id_sequence, $seq, $format, 0);
        my $see = interface("successful_insertion", 1, 0, $id_sequence);
        if($see == 1) {
            print "-------------------------------------------------------------------------------------------------------------------------\n";
            system "pg ".$dbm_seq{$id_sequence};
        }
        main(1);
    }
    elsif($option == 2) {
        #----------Gets useful information from the file or asks to user if the file doesn't have it---------------
        my ($path, $seqio, $format);
        my $clear = 1;
        do{
            $path = interface("ask_file_path", $clear);
            try{
                $seqio = Bio::SeqIO->new(-file => $path);
            } catch Bio::Root::Exception with {$clear = 0;}
        } while(!$seqio);
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        $format = get_format($path);
        
        my $seq = $seqio->next_seq;
        my $alph= interface("ask_alphabet", 0);
        my $alphabet;
        if($alph == 1) {$alphabet = "dna";}
        elsif($alph == 2) {$alphabet = "rna";}
        elsif($alph == 3) {$alphabet = "protein";}
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        my $is_circular;
        if($seq->is_circular) {$is_circular = 1;}
        else {$is_circular = 0;}
        my (@keywords, @keywords_file, @key);
        my $bool;
        if($format eq "fasta"){
            ($bool, @keywords) = interface("ask_tag", 0);
        }
        else{
            my @keywords_file = split /\s*;\s*/, $seq->keywords;
            ($bool, @key) = interface("ask_tag", 0);
            @keywords = (@keywords_file, @key);
        }
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        my $sequence = $seq->seq;
        my $seq_version;
        my $date;
        if($format eq "genbank" or $format eq "swiss"){
            $seq_version = $seq->seq_version;
            $date= ($seq->get_dates)[0];
        }
        else{
            $seq_version = interface("ask_seq_version", 0);
            print "-------------------------------------------------------------------------------------------------------------------------\n";
            $date= interface("ask_date", 0);
            print "-------------------------------------------------------------------------------------------------------------------------\n";
        }
        my $specie = interface("ask_specie", 0);               #Just to ask if the user wants to associate the sequence to any specie
        
        insert_specie($specie);
        insert_sequence_db($specie, $alphabet, $seq->authority, $seq->desc, $seq->display_id, $date, $is_circular, $seq->length, $format, $seq_version, $seq->accession_number());
        my $id_sequence = insert_tags($bool, @keywords);
        insert_sequence($id_sequence, $seq, $format, 1);
        my $see = interface("successful_insertion", 1, 0, $id_sequence);
        if($see == 1) {
            print "-------------------------------------------------------------------------------------------------------------------------\n";
            system "pg ".$dbm_seq{$id_sequence};
        }
        main(1);
    }
    elsif($option == 3){
        my $answer;    
        $answer = interface("ask_database", 1);   # Choose the database
        if ($answer ==1 or $answer ==2 or $answer ==3) { interface("generic_importation_begin",$answer); generic_importation($answer); }
        else {insertion();}
    }
    elsif($option == 9){
        main(1);
    }
}


#--------------------This function gets the format of a file-----------------------------------
sub get_format{
    my ($path) = @_;
    my $format;
    if(substr ($path, -5) eq "fasta") {$format = "fasta";}
    elsif(substr ($path, -5) eq "swiss") {$format = "swiss";}
    elsif(substr ($path, -2) eq "gb") {$format = "genbank";}
    else {
        my $format_opt = interface("ask_format", 0, 0);
        if($format_opt == 1) {$format = "fasta";}
        elsif($format_opt == 2) {$format = "genbank";}
        elsif($format_opt == 3) {$format = "swiss";}
        print "-------------------------------------------------------------------------------------------------------------------------\n";
    }
    return $format;
}



#-----------------Verifies if the inserted specie already exists on database. If it already exists, doesn't try to insert it---------------
sub insert_specie{
    my ($specie) = @_;
    my ($row, $id_sequence);
    my $sql = "SELECT id_specie FROM species WHERE specie='".$specie."'";
    my $result = $dbh->prepare($sql);
    $result->execute();
    if(!($result->fetchrow_hashref())){
        $sql = "INSERT INTO species (specie) VALUES ('".$specie."')";
        $dbh->do($sql);
    }
}






#-------------------Insert the sequence----------------------
sub insert_sequence_db{
    my ($specie, $alphabet, $authority, $description, $gene_name, $date, $is_circular, $seq_length, $format, $seq_version, $accession_number) = @_;
    my $sql = "SELECT id_specie FROM species WHERE specie='".$specie."'";
    my $result = $dbh->prepare($sql);
    $result->execute();
    while(my $row = $result->fetchrow_hashref()){
        $sql = "INSERT INTO sequences (id_specie, alphabet, authority, description, accession_number, gene_name, date, is_circular, length, format, seq_version) VALUES ('"
                   .$row->{'id_specie'}."', '".$alphabet."', '".$authority."', '".$description."', '".$accession_number."', '".$gene_name."', '".$date."', '".$is_circular."', '$seq_length', '"
                   .$format."', '".$seq_version."')";
        $dbh->do($sql);
    }
}





#-------------------Insert the tags and returns the $id_sequence------------------------------
sub insert_tags{
    my ($bool, @keywords) = @_;
    my $id_sequence;
    my $sql = "SELECT LAST_INSERT_ID()";
    my $result = $dbh->prepare($sql);
    $result->execute();
    while(my $row = $result->fetchrow_hashref()){
        $id_sequence = $row->{'LAST_INSERT_ID()'};
    }
    
    if ($bool == 1) {
        for my $keyword (@keywords){
            #-------------Verifies if the inserted tags already exist on database. If they already exist, doesn't try to insert them-----------
            $sql = "SELECT id_tag FROM tags WHERE tag='".$keyword."'";
            $result = $dbh->prepare($sql);
            $result->execute();
            if(!($result->fetchrow_hashref())){
                $sql = "INSERT INTO tags (tag) VALUES ('".$keyword."')";
                $dbh->do($sql);
            }
            
            $sql = "SELECT id_tag FROM tags WHERE tag='".$keyword."'";
            $result = $dbh->prepare($sql);
            $result->execute();
            
            #--------------Insert the tuple id_sequence - id_tag on seq_tags table------------------------
            while(my $row = $result->fetchrow_hashref()){
                $sql = "INSERT INTO seq_tags (id_sequence, id_tag) VALUES ('".$id_sequence."', '".$row->{'id_tag'}."')";
                $dbh->do($sql);
            }
        }
    }
    return $id_sequence;
}






#----------------Insert the sequence on a DBM----------------------------------------
# 1st argument - sequence id
# 2nd argument - Bio::Seq object, with the sequence
# 3rd argument - file format
# 4rd argument - flag that tells if the name of the file will have the gene_name or the accession_number
sub insert_sequence{
    my ($id_sequence, $seq, $format, $with_accession) = @_;
    my ($filename,$seqio, $form);
    if($format eq "genbank") {$form = "gb";}
    else {$form = $format;}
    if($with_accession) {$filename = "sequences/".$seq->accession_number."_".$id_sequence.".".$form;}
    else {$filename = "sequences/".$seq->display_id."_".$id_sequence.".".$form;}
    $dbm_seq{$id_sequence} = $filename;
    $seqio = Bio::SeqIO->new(-file => ">".$filename, -format => $format);
    $seqio->write_seq($seq);
}





#--------------------This function indicates the right path to remove data from the database, depending from the user's decision------------------------------------
sub removal{
    my $option = interface("ask_removal_type", 1, 0);
    if($option == 1){
        my ($accession_number_or_id_sequence, $flag) = interface("ask_accession_number_no_check", 1);
        if($flag) {remove($accession_number_or_id_sequence, "accession_number");}
        else {remove($accession_number_or_id_sequence, "id_sequence");}
        interface("successful_removal", 1);
        main(1);
    }
    elsif($option == 2){
        my ($gene_name_or_id_sequence, $flag) = interface("ask_gene_name_no_check", 1);
        if($flag) {remove($gene_name_or_id_sequence, "gene_name");}
        else {remove($gene_name_or_id_sequence, "id_sequence");}
        interface("successful_removal", 1);
        main(1);
    }
    elsif($option == 9){
        main(1);
    }
}




#-------------------This function deletes a sequence from the database------------------------------------
sub remove{
    my ($accession_number_or_gene_name, $type) = @_;
    my $sql = "SELECT id_sequence FROM sequences WHERE $type='".$accession_number_or_gene_name."'";
    my $result = $dbh->prepare($sql);
    $result->execute();
    while(my $row = $result->fetchrow_hashref()){
        unlink $dbm_seq{$row->{'id_sequence'}};
        delete $dbm_seq{$row->{'id_sequence'}};             #Deletes the sequence from the Hash Table dbm_seq
        remove_seq_tags($row->{'id_sequence'});
    }
    $sql = "DELETE FROM sequences WHERE $type='".$accession_number_or_gene_name."'";
    $dbh->do($sql);
}




#-----------------------This function will remove data from the table seq_tags------------------------------
sub remove_seq_tags{
    my ($id_sequence) = @_;
    my $sql = "DELETE FROM seq_tags WHERE id_sequence = '".$id_sequence."'";
    $dbh->do($sql);
}



#----------------------This function indicates the right path to modify data from the database, depending from the user's decision----------------------
sub modification{
    my $option = interface("ask_modification_type", 1, 0);
    my %modified;
    if($option == 1){
        my $accession_number = interface("ask_accession_number", 1);
        %modified = modify($accession_number, "accession_number");
        interface("successful_modification", 1);
        display_modified(%modified);
        main(1);
    }
    elsif($option == 2){
        my $gene_name = interface("ask_gene_name", 1);
        %modified = modify($gene_name, "gene_name");
        interface("successful_modification", 1);
        display_modified(%modified);
        main(1);
    }
    elsif($option == 9){
        main(1);
    }
}



#----------------------This function will modify a sequence saved on the database----------------------
sub modify{
    my ($accession_number_or_gene_name, $type) = @_;
    my %modified;
    my $sql = "SELECT id_sequence, gene_name, accession_number, accession_version,description, alphabet, format FROM sequences WHERE $type='".$accession_number_or_gene_name."'";
    my $result = $dbh->prepare($sql);
    $result->execute();
    my $current = 0;
    my ($format, $seqio);
    
    while(my $row = $result->fetchrow_hashref()){
        $current++;
        if($row->{format} eq "genbank") {$format = "gb";}
        else{$format = $row->{format};}
        create_file($current, $result->rows, $row);
        interface("modify_sequence", 1, 0, $row->{id_sequence}, $current, $result->rows, $format);
        my $seq = fetch_info($current, $result->rows, $format);
        update_info($seq, $row->{id_sequence});
        unlink("sequence".$current."in".$result->rows.".$format");
        $modified{$current} = $row->{id_sequence};
    }
    return %modified;
}


#------------------------This function will create the file where the user will modify the data-----------------------------
sub create_file{
    my($current, $total, $row) = @_;
    my $seqio = Bio::SeqIO->new(-file => $dbm_seq{$row->{id_sequence}});
    my $seq = $seqio->next_seq;
    if($row->{format} eq "genbank"){
        $seqio = Bio::SeqIO->new(-file => ">sequence".$current."in".$total.".gb", -format => "genbank");
    }
    else{
        $seqio = Bio::SeqIO->new(-file => ">sequence".$current."in".$total.".$row->{format}", -format => $row->{format});
    }
    $seqio->write_seq($seq);
}


#--------------------------This function will fetch the new information given by the user----------------------------------
sub fetch_info{
    my ($current, $total, $format) = @_;
    my $seqio;
    do{
        try{
            $seqio = Bio::SeqIO->new(-file => "sequence".$current."in".$total.".$format");
        } catch Bio::Root::Exception with {
            interface("error_file_not_found", 1);
        }
    } while(!$seqio);
    my $seq = $seqio->next_seq;
    return($seq);
}


#------------------------This function will update the info in the database and the hash------------------------------------
sub update_info{
    my ($seq, $id_sequence) = @_;
    my $sql = "UPDATE sequences SET gene_name='".$seq->display_id."', accession_number='".$seq->accession_number."', description='".$seq->desc."', alphabet='".
                     $seq->alphabet."', length='".length($seq->seq)."' WHERE id_sequence='".$id_sequence."'";
    $dbh->do($sql);
    my $seqio = Bio::SeqIO->new(-file => ">".$dbm_seq{$id_sequence});
    $seqio->write_seq($seq);
}


#-----------------------------This function displays the modified sequences table, and asks if the user want to see it on the program (with the 'pg' command)----------------------
sub display_modified{
    my (%modified) = @_;
    my $option = interface("ask_display_modified", 0, 0);
    my ($key, $answer);
    while($option == 1){
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        print "\n\tMODIFIED FILES TABLE\n\n";
        foreach $key (sort {$a <=> $b} (keys %modified)){
            print " $key - ".(substr $dbm_seq{$modified{$key}}, 10)."\n";
        }
        print "\n";
        $answer = interface("ask_modified_table", 0, 0);
        while($answer < 1 or $answer > scalar(keys %modified)){
            $answer = interface("ask_modified_table", 0, 1);
        }
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        chomp $answer;
        system "pg ".$dbm_seq{$modified{$answer}};
        $option = interface("ask_display_modified", 1, 0);
    }
}


#-----------------------This function inserts the sequence from a remote database----------------------------------
sub generic_importation{
    my($base)=@_;
    my ($option2, $format, $seq, $existe, $option, $gb, $seqio_obj, $result, $sql, $specie, $id_specie, $id_sequence, $id_tag, $form, $flag);         
    if ($base==2) {$option=1;}
    else {$option = interface ("ask_import"); }  #hoose the type of importation - accession_number or accession_version
    
    $format = interface ("ask_format", 1);
    
    #Loop to search
    $existe=1;
    if ($base==1) {
        $gb = Bio::DB::GenBank->new();
    }
    elsif ($base==2) {$gb=Bio::DB::SwissProt->new();}
    else {$gb=Bio::DB::RefSeq->new();}
    do {

        if (!$existe)  {print "ERROR! Already existing Accession Number in DataBase!!\n\nPress Enter...";<>;$existe=1;}     
        if ($existe==2) {print "ERROR! Non existing Number in Remote DataBase!!\n\nPress Enter...";<>;$existe=1;}

        #Insert number to seach
        if ($option==1) {
            $flag = 1;
            $option2=interface("ask_accession_number_insertion", 1);
            print "-------------------------------------------------------------------------------------------------------------------------\n";
            
                try {   
                    $seq = $gb->get_Seq_by_acc($option2) || throw Bio::Root::Exception(print "ERROR: INVALID NUMBER!!");
                }catch Bio::Root::Exception with {$existe=2};    
                    
        }
        elsif ($option==2) {
            $flag = 0;
            $option2=interface("ask_version_number", 1);
            print "-------------------------------------------------------------------------------------------------------------------------\n";
            chomp($option2);
            
            if($existe==1){
                try {
                    $seq = $gb->get_Seq_by_version($option2) || throw Bio::Root::Exception(print "ERROR: INVALID NUMBER!!") # gets the number
                }catch Bio::Root::Exception with {$existe=2};  
            }
        }
        
    }while(!$existe or $existe==2);

    $specie = interface("ask_specie");   #asks the specie and then save it
    print "-------------------------------------------------------------------------------------------------------------------------\n";
    $id_specie=insert_specie_importation($specie);
    if ($option==2) {$id_sequence = insert_sequence_importation($format,$id_specie,$seq,$option2);}
    else {$id_sequence = insert_sequence_importation($format,$id_specie,$seq);}

    my @lista;
    my $bool;
    ($bool, @lista) = interface("ask_tag", 0); #asks if the user wants tag. if he does, he can choose some that exists or some new ones
    insert_tags($bool, @lista);
    if($format == 1) {$form = "fasta";}
    elsif($format == 2) {$form = "genbank";}
    else {$form = "swiss";}
    insert_sequence($id_sequence, $seq, $form, $flag);
    my $see = interface("successful_insertion", 1, 0, $id_sequence);
        if($see == 1) {
            print "-------------------------------------------------------------------------------------------------------------------------\n";
            system "pg ".$dbm_seq{$id_sequence};
        }
        main(1);
}



#-----------------------This function verifies if the accession version already exists-----------------------------
# It returns 0 if it doesn't exist, and if it exisits, returns the number of equal accessions
# 1st argument - the accession_number (and the accession version)
# 2nd argument - tells if it have to search with accession version or not
sub verify_accession{
    my ($type, $with) = @_;     
    my ($sql,$result);
    my $flag = 0;
    my $count = 0;
    if($with eq "with") {$sql = "SELECT accession_number FROM sequences WHERE accession_number='".$type."' and accession_version='".$type."';";}
    elsif($with eq "without") {$sql = "SELECT accession_number FROM sequences WHERE accession_number='".$type."';";}
    $result = $dbh->prepare($sql);
    $result->execute();
    if($result->fetchrow_hashref()){
        return 1;
    }
    return 0;
}


#-----------------------------This function counts the number of sequences that have the same accession number or the same gene name---------------------------
sub count_accession_or_name{
    my ($accession_number_or_gene_name, $type) = @_;
    my $count = 0;
    my $sql = "SELECT id_sequence FROM sequences WHERE $type='".$accession_number_or_gene_name."';";
    my $result = $dbh->prepare($sql);
    $result->execute();
    while(my $row = $result->fetchrow_hashref()){
        $count++;
    }
    return $count;
}

#---------------------This function verifies the accession version for the importation from a file-------------------------
# It returns 1 if it exists, and 0 if it doesn't
sub verify_accession_in_file{
    my ($file) = @_;     
    my ($sql,$result, $format);
    if(substr ($file, -5) eq "fasta") {return 0;}           #won't check because of the "unknown" accession_ numbers
    elsif(substr ($file, -5) eq "swiss") {$format = "swiss";}
    elsif(substr ($file, -2) eq "gb") {$format = "genbank";}
    my $seqio = Bio::SeqIO->new(-file => "$file", -format => $format);
    my $seq = $seqio->next_seq;
    $sql = "SELECT accession_number FROM sequences WHERE accession_number='".$seq->accession_number."'";
    $result = $dbh->prepare($sql);
    $result->execute();
    if($result->fetchrow_hashref()){
        return 1;
    }
    return 0;
}


#------------------This function verifies if the gene name already exists on the database----------------------
# It returns 1 if it exists, and 0 if it doesn't
sub verify_gene_name{   
    my ($gene_name) = @_;
    my $sql = "SELECT gene_name FROM sequences WHERE gene_name = '".$gene_name."'";
    my $result = $dbh->prepare($sql);
    $result->execute();    
    if(!($result->fetchrow_hashref())){
        return 0;
    }
    return 1;
}


#--------------------This function inserts the specie for the insertion from remote databases------------------
sub insert_specie_importation{
    my ($specie) = @_;
    my @val;
    my $sql = "SELECT id_specie FROM species WHERE specie='".$specie."';";    
    my $sql1;    
    my $result2;
    my $result = $dbh->prepare($sql);
    $result->execute();
    if(!(@val=$result->fetchrow_array())){
        $sql1 = "INSERT INTO species (specie) VALUES ('".$specie."');";   #insertion
        $dbh->do($sql1);
        $result2 = $dbh->prepare($sql);  #select of the id of the inserted specie
        $result2->execute();
        @val = $result2->fetchrow_array();
    }
    return $val[0];
}



#--------------------This function inserts the sequence for the insertion from remote databases------------------
sub insert_sequence_importation {
    my ($format,$id_specie,$seq,$version)=@_;
    my ($sql,$form);        
    my  $result;
    my @val;
   if ($format==1) {$form="fasta";}
   elsif ($format==2){$form ="genbank";}
   else {$form="swiss";}
   
   if($version) {
   $sql = "INSERT INTO sequences (id_specie, alphabet, authority, description, accession_number,accession_version, gene_name, date, is_circular, length, format, seq_version)
                  VALUES ('".$id_specie."', '".$seq->alphabet."', '".$seq->authority."', '".$seq->desc."', '".$seq->accession."','".$version."', '".$seq->display_name."', '".$seq->get_dates."', '".$seq->is_circular."', '".$seq->length."', '".$form."', '".$seq->seq_version."');";
   }
   else {
   $sql = "INSERT INTO sequences (id_specie, alphabet, authority, description, accession_number,accession_version,gene_name, date, is_circular, length, format, seq_version)
                  VALUES ('".$id_specie."', '".$seq->alphabet."', '".$seq->authority."', '".$seq->desc."', '".$seq->accession."', '".$seq->accession."','".$seq->display_name."', '".$seq->get_dates."', '".$seq->is_circular."', '".$seq->length."', '".$form."', '".$seq->seq_version."');";
   }
   $dbh->do($sql);  #insertion on the database
   $sql = "SELECT LAST_INSERT_ID()";
   $result = $dbh->prepare($sql);  #select of the id of the inserted specie
   $result->execute();
   @val = $result->fetchrow_array(); #select of the id of the inserted sequence
    return $val[0] ;  
}




#---------------------------This function verifies the version------------------------------
sub verify_version{
    my ($version)=@_;
    my ($flag,$result,$sql,@val);
    $sql = "Select accession_version from sequences;";
    $result = $dbh->prepare($sql);
    $result->execute();
    while(@val=$result->fetchrow_array()){  
        if($version eq $val[0]) {return 0;}
    }
    return 1;
}



#------------------------This function runs a remote blast------------------------------
sub blast{
    my $option = interface("ask_choose_type", 1);
    my ($acc_or_name, $flag, $id_sequence, $filename, $format, $seqio, $seq, $blast_type, $db, $blast, $result_blast);
    if($option == 1) {
        ($acc_or_name, $flag) = interface("ask_accession_number_no_check", 0);
        if($flag) {$id_sequence = get_id_sequence($acc_or_name, "accession_number");}
        else {$id_sequence = $acc_or_name;}
    }
    else {
        ($acc_or_name, $flag) = interface("ask_gene_name_no_check", 0);
        if($flag) {$id_sequence = get_id_sequence($acc_or_name, "gene_name");}
        else {$id_sequence = $acc_or_name;}
    }
    print "-------------------------------------------------------------------------------------------------------------------------\n";
    $filename = $dbm_seq{$id_sequence};
    $format = get_format($filename);
    
    $seqio = Bio::SeqIO->new(-file => $filename, -format => $format);
    $seq = $seqio->next_seq;
    $option = interface("ask_blast_type", 0);
    if ($option == 1) {$blast_type = "blastp";}
    elsif ($option == 2) {$blast_type = "blastn";}
    elsif ($option == 3) {$blast_type = "blastx";}
    elsif ($option == 4) {$blast_type = "tblastn";}
    else {$blast_type = "tblastx";}
    
    if ($blast_type eq "blastp" or $blast_type eq "blastx") {
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        $option = interface("ask_database_protein", 0);
        if($option == 1) {$db = "refseq_protein";}
        elsif($option == 2) {$db = "swissprot";}
    }
    elsif($blast_type eq "blastn") {$db = "refseq_genomic";}
    else{$db = "refseq_rna";}
    
    my $waiting = 1;
    $blast = Bio::Tools::Run::RemoteBlast->new(-prog => $blast_type, -data => $db);
    $result_blast = $blast->submit_blast($seq);
    print STDERR "\n\nWaiting" if ($waiting >0);
    while (my @rids = $blast->each_rid){
        foreach my $rid (@rids) {
            my $rc;
            do {
                print STDERR "." if ($waiting > 0);
                sleep 2;
            } while (!( $rc = $blast -> retrieve_blast ($rid)));
            my $result = $rc->next_result();
            if($format eq "genbank") {$filename = substr $filename, 10, -3;}
            else {$filename = substr $filename, 10, -6;}
            $filename = "blast_results/$filename"."_".$blast_type."_".$db.".txt";
            $blast->save_output($filename);
            $blast->remove_rid($rid);
        }
    }
    my $see = interface("successful_blast", 1, 0, $filename);
    if($see == 1) {
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        system "pg $filename";
    }
        main(1);
}


#-------------------------This function will get the id_sequence in the database----------------------------------------
sub get_id_sequence{
    my ($acc_or_name, $type) = @_;
    my ($sql, $id_sequence);
    if($type eq "accession_number") {$sql = "SELECT id_sequence FROM sequences WHERE accession_number = '".$acc_or_name."'"}
    elsif($type eq "gene_name") {$sql = "SELECT id_sequence FROM sequences WHERE gene_name = '".$acc_or_name."'"}
    my $result = $dbh->prepare($sql);
    $result->execute();
    while(my $row = $result->fetchrow_hashref()){
        $id_sequence = $row->{id_sequence};
    }
    return $id_sequence;
}


#----------------------This function gets the motif and calls the right functions to serch it on the sequences on the database--------------------------
sub motif{
    my $motif = interface("ask_motif", 1);
    my ($match, $positions) = search_motif($motif);
    my %match = %$match;
    my %positions = %$positions;
    display_match($match, $positions);
    main(1);
}



#----------------------This function will search a motif in all the sequences--------------------------------
sub search_motif{
    my ($motif) = @_;
    my ($key, $val, $seqio, $seq, $insert);
    my $count = 0;
    my $found = 1;
    my (%match, %positions);
    
    while (($key, $val) = each %dbm_seq){
        $insert = 1;
        if ($found) {$count++;}
        $found = 0;
        $seqio = Bio::SeqIO->new(-file => "<".$val, -format => get_format($val));
        $seq = $seqio->next_seq;
        $_ = $seq->seq;
        while(/$motif/g){
            $found = 1;
            if ($insert){
                $match{$count} = $val;
                $insert = 0;
            }
            push @{$positions{$count}}, (length $`);
        }
    }
    return (\%match, \%positions);
}


#-----------------This function displays the match table and the positions where the motif was found, and asks if the user want to see it with the 'pg' command---------------------
sub display_match{
    my ($match, $positions) = @_;
    my %match = %$match;
    my %positions = %$positions;
    my ($key, $answer, $option, $pos, $flag);
    my $size_hash = scalar (keys %match);
    
    if ($size_hash == 0){
        interface("no_match", 1);
        main(1);
    }
    else{
        do {
            $flag = 0;
            print "-------------------------------------------------------------------------------------------------------------------------\n";
            print "\n\tMATCH TABLE AND POSITIONS\n\n";
            foreach $key (sort {$a <=> $b} (keys %match)){
                print " $key - ".(substr $match{$key}, 10)." - Positions: ";
                for $pos (@{$positions{$key}}){
                    print $pos."  ";
                }
                print "\n-----------\n";
            }
            print "\n\n";
            $option = interface("ask_display_match", 0, 0);
            if($option == 1){
                print "-------------------------------------------------------------------------------------------------------------------------\n";
                print "\n\tMATCH TABLE\n\n";
                foreach $key (sort {$a <=> $b} (keys %match)){
                    print " $key - ".(substr $match{$key}, 10)."\n";
                }
                print "\n";
                do{
                    $answer = interface("ask_match_table", 0, $flag);
                    $flag = 1;
                } while ($answer < 1 or $answer > $size_hash);
                print "-------------------------------------------------------------------------------------------------------------------------\n";
                chomp $answer;
                system "pg ".$match{$answer};
            }
            elsif($option == 2){
                return;
            }
        } while (1);
    }
}



#--------------------------This function will get the important info to get the statistics--------------------------------
sub statistics{
    my $option = interface("ask_choose_type", 1);
    my ($answer, $flag, $type, $id_sequence, $format, $filename, $seqio, $seq, $seq_stats);
    
    if($option == 1){
        $type = "accession_number";
        ($answer, $flag) = interface("ask_accession_number_no_check", 1);
        if($flag) {$id_sequence = get_id_sequence($answer, $type);}
        else {$id_sequence = $answer;}
    }
    elsif($option == 2){
        $type = "gene_name";
        ($answer, $flag) = interface("ask_gene_name_no_check", 1);
        if($flag) {$id_sequence = get_id_sequence($answer, $type);}
        else {$id_sequence = $answer;}
    }
    
    $format = get_format($dbm_seq{$id_sequence});
    if($format eq "genbank") {$filename = "statistics/".(substr $dbm_seq{$id_sequence}, 10, -2)."txt";}
    else {$filename = "statistics/".(substr $dbm_seq{$id_sequence}, 10, -5)."txt";}
    
    $seqio = Bio::SeqIO->new(-file => $dbm_seq{$id_sequence}, -format => $format);
    $seq = $seqio->next_seq;
    
    get_statistics_into_file($filename, $seq);
    my $see = interface("successful_statistics", 1, 0, $filename);
    if($see == 1) {
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        system "pg $filename";
    }
    main(1);
}



#----------------------------This function will get the statistics into a file--------------------------------
sub get_statistics_into_file{
    my($filename, $seq) = @_;
    
    open FILE, ">".$filename;
    
    my $seq_stats = Bio::Tools::SeqStats->new(-seq => $seq);
    my $monomers = $seq_stats->count_monomers;
    print FILE "MONOMERS\n\n";
    foreach my $base (sort keys %$monomers){
        print FILE "\tThe base $base has ".$$monomers{$base}." monomers\n";
    }
    print FILE "-------------------------------------------------------------------------------------------------------------------------\n";
    if($seq->alphabet eq "dna" or $seq->alphabet eq "rna"){
        my $codons = $seq_stats->count_codons;
        print FILE "CODONS\n\n";
        foreach my $base (sort keys %$codons){
            print FILE "\tThe base $base has ".$$codons{$base}." codons\n";
        }
    }
    else{
        my $hyd = $seq_stats->hydropathicity;
        print FILE "HYDROPATHICITY\n\n\tThe hydropathicity is $hyd\n";
    }
    print FILE "-------------------------------------------------------------------------------------------------------------------------\n";
    my $mol = $seq_stats->get_mol_wt;
    print FILE "MOLECULAR WEIGHT\n\n\tThe molecular weight is between ".$$mol[0]." mol and ".$$mol[1]." mol\n";
    close FILE;
}




#-------------------This function will add a new feature into a sequence-------------------------------
sub features{
    my $option = interface("ask_choose_type", 1, 0);
    my ($type, $answer, $flag, $id_sequence, $format, $filename, $seqio_read, $seqio_write, $seq);
    
    if($option == 1){
        $type = "accession_number";
        ($answer, $flag) = interface("ask_accession_number_no_check", 1);
        if($flag) {$id_sequence = get_id_sequence($answer, $type);}
        else {$id_sequence = $answer;}
    }
    elsif($option == 2){
        $type = "gene_name";
        ($answer, $flag) = interface("ask_gene_name_no_check", 1);
        if($flag) {$id_sequence = get_id_sequence($answer, $type);}
        else {$id_sequence = $answer;}
    }
    $format = get_format($dbm_seq{$id_sequence});
    if($format eq "fasta") {interface("error_feature", 1);}
    else{
        $seqio_read = Bio::SeqIO->new(-file => "<".$dbm_seq{$id_sequence}, -format => $format);
        $seq = $seqio_read->next_seq;
        
        my $start = interface("ask_feature_start", 1);
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        my $end = interface("ask_feature_end");
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        my $strand = interface("ask_feature_strand");
        if($strand == 2) {$strand = -1;}
        elsif($strand == 3) {$strand = 0;}
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        my $primary = interface("ask_feature_primary");
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        my $source = interface("ask_feature_source");
        
        $seqio_write = Bio::SeqIO->new(-file => ">".$dbm_seq{$id_sequence}, -format => $format);;
        $seq->add_SeqFeature(new Bio::SeqFeature::Generic(-start => $start, -end => $end, -strand => $strand, -primary => $primary, -source => $source));
        $seqio_write->write_seq($seq);
        
        my $see = interface("successful_feature", 1, 0, (substr $dbm_seq{$id_sequence}, 10));
        if($see == 1) {
            print "-------------------------------------------------------------------------------------------------------------------------\n";
            system "pg ".$dbm_seq{$id_sequence};
        }
    }
    main(1);
}




#--------------------------------This function translates a DNA sequence-----------------------------------------
sub translatee{
    my $option = interface("ask_translate_type",1,0);
    my $filename_translation;
    
    if($option == 2) {
        $filename_translation = "translations/temp.txt";
        my $option2 = interface("insert_manual_seq", 1);    
        write_translatione($option2, $filename_translation);
    }
    
    elsif($option == 1){
        my $option = interface("ask_choose_type", 1);
        my ($acc_or_name, $flag, $id);
        if($option == 1) {
            ($acc_or_name, $flag) = interface("ask_accession_number_no_check", 0);
            if($flag) {$id = get_id_sequence($acc_or_name, "accession_number");}
            else {$id = $acc_or_name;}
        }
        else {
            ($acc_or_name, $flag) = interface("ask_gene_name_no_check", 0);
            if($flag) {$id = get_id_sequence($acc_or_name, "gene_name");}
            else {$id = $acc_or_name;}
        }
        
        my $filename = $dbm_seq{$id};
        my $format = get_format($filename);
        my $seqio = Bio::SeqIO->new(-file => $filename, -format => $format);
        my $seq = $seqio->next_seq;
        my $accession = $seq->accession();
        $accession .= "_$id";
        $filename_translation = "translations/$accession.txt";
        write_translatione($seq->seq(), $filename_translation);
    }
    
    my $see = interface("successful_translation", 1, 0, $filename_translation);
    if($see == 1) {
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        system "pg $filename_translation";
    }
    main(1);    
}



#------------------------------This function writes the 6 ORF's in the translation file----------------------------------------
sub write_translatione{
    my ($sequence, $filename_translation) = @_;
    open FILE, ">$filename_translation";
    for (my $i = 0; $i < 3; $i++){
        print FILE ($i+1)."ª ORF:\n";
        print FILE translatione($sequence, 0, $i);
        print FILE "\n\n";
    }
    for (my $i = 0; $i < 3; $i++){
        print FILE ($i+4)."ª ORF:\n";
        print FILE translatione($sequence, 1, $i);
        print FILE "\n\n";
    }
    close FILE;
}




#-----------------------------------This function calls the 'translate' operation---------------------------------------
sub translatione{
    my ($sequencia, $is_reversed, $i) = @_;
    my $seq = Bio::Seq->new(-seq => $sequencia);
    if($is_reversed){return $seq->revcom->translate(-frame => $i)->seq;}
    else {return $seq->translate(-frame => $i)->seq;}
}




#------------------This function displays the keywords table-----------------------------
sub display_tags{
    my ($result,$sql,@val);
    $sql = "Select * from tags ORDER BY id_tag;";
    print "\tKEYWORDS TABLE\n\n";
    $result = $dbh->prepare($sql);
    $result->execute();
    while(@val=$result->fetchrow_array()){  
        print "  KEYWORD = $val[1]\n";
    }
    print "\n";
    return;
}




#--------------------This function dysplays the species table-------------------------
sub display_species{
    my ($sql,$result,@val);
    $sql = "Select * from species";
    print "\tSPECIES TABLE\n\n";
    $result = $dbh->prepare($sql);
    $result->execute();
    while(@val=$result->fetchrow_array()){  
        print "  KEYWORD = $val[1]\n";
    }
    print "\n";
    return;
}





#--------------------This function dysplays the sequences table-------------------------
sub display_sequences{
    my ($result) = @_;
    my $flag = 1;
    print "\n\tSEQUENCES TABLE\n\n";
    while (my $row = $result->fetchrow_hashref){
        $flag = 0;
        print "\tID of the sequence - ".$row->{id_sequence}."\n\tAccession number - ".$row->{accession_number}."\n\tAccession version - ".$row->{accession_version}."\n\tGene name - "
                .$row->{gene_name}."\n\tAlphabet - ".$row->{alphabet}."\n\tDescription - ".$row->{description}."\n\tLength - ".$row->{length}."\n\n";
    }
    if($flag){
        print "There are no sequences on the database!\n\n"
    }
}





#------------------------------This function displays a table with the information about all the sequences on the database-----------------------------------------
sub display_all_sequences{
    my $sql = "SELECT id_sequence, accession_number, accession_version, gene_name, alphabet, description, length FROM sequences;";
    my $result = $dbh->prepare($sql);
    $result->execute();
    display_sequences($result);
}




#-------------------------This function displays sequences that have a specific property, asking what kind of property--------------------------------------------------
sub display_search_sequences{
    my $option = interface("ask_search_option", 1);
    
    if($option == 1){display_sequences_by_keyword();}
    elsif($option == 2){display_sequences_by_accession_number();}
    elsif($option == 3){display_sequences_by_gene_name();}
    elsif($option == 4){display_sequences_by_specie();}
}



#---------------------------This function displays the sequences with a determined keyword----------------------------------------------
sub display_sequences_by_keyword{
    system $^O eq 'MSWin32' ? 'cls' : 'clear';
    display_tags();
    my $keyword = interface("ask_keyword");
    my  $sql = "SELECT sequences.id_sequence, accession_number, accession_version, gene_name, alphabet, description, length FROM sequences, tags, seq_tags WHERE tags.tag = '".
                      $keyword."' AND tags.id_tag = seq_tags.id_tag AND seq_tags.id_sequence = sequences.id_sequence;";
    my $result = $dbh->prepare($sql);
    $result->execute();
    display_sequences($result);
}



#---------------------------This function displays the sequences with a determined accession number----------------------------------------------
sub display_sequences_by_accession_number{
    my $accession_number = interface("ask_accession_number", 1);
    my  $sql = "SELECT id_sequence, accession_number, accession_version, gene_name, alphabet, description, length FROM sequences WHERE accession_number = '$accession_number';";
    my $result = $dbh->prepare($sql);
    $result->execute();
    display_sequences($result);
}




#---------------------------This function displays the sequences with a determined gene name----------------------------------------------
sub display_sequences_by_gene_name{
    my $gene_name = interface("ask_gene_name", 1);
    my  $sql = "SELECT id_sequence, accession_number, accession_version, gene_name, alphabet, description, length FROM sequences WHERE gene_name = '$gene_name';";
    my $result = $dbh->prepare($sql);
    $result->execute();
    display_sequences($result);
}




#---------------------------This function displays the sequences with a determined specie----------------------------------------------
sub display_sequences_by_specie{
    my $specie = interface("ask_specie", 1);
    my  $sql = "SELECT id_sequence, accession_number, accession_version, gene_name, alphabet, description, length FROM sequences, species WHERE specie = '$specie' AND "
                      ."species.id_specie = sequences.id_specie;";
    my $result = $dbh->prepare($sql);
    $result->execute();
    display_sequences($result);
}




#---------------------------This function displays all the accession numbers or all the gene names, if there are more that 1 sequence with the same accession number or gene name--------------------
sub display_accessions_or_names{
    my ($accession_number_or_gene_name, $type) = @_;
    my %accessions_or_names = get_accessions_or_names($accession_number_or_gene_name, $type);
    
    my ($sql, $result);
    if($type eq "accession_number") {print "\nThere are more than 1 sequence with the indicated accession number:\n\n\tACCESSION NUMBERS TABLE\n\n";}
    elsif($type eq "gene_name") {print "\nThere are more than 1 sequence with the indicated gene name:\n\n\tGENE NAMES TABLE\n\n";}
    foreach my $key (sort {$a <=> $b} (keys %accessions_or_names)){
        print " $key:\n";
        if($type eq "accession_number") {$sql = "SELECT accession_version, description, length, gene_name FROM sequences WHERE id_sequence = '".$accessions_or_names{$key}."';";}
        elsif($type eq "gene_name") {$sql = "SELECT accession_number, accession_version, description, length FROM sequences WHERE id_sequence = '".$accessions_or_names{$key}."';";}
        my $result = $dbh->prepare($sql);
        $result->execute();
        while(my $row = $result->fetchrow_hashref()){
            if($type eq "accession_number") {print "\tAccession version - ".$row->{accession_version}."\n\tGene name - ".$row->{gene_name}."\n\tDescription - ".$row->{description}."\n\tLength of the sequence - ".$row->{length}."\n";}
            elsif($type eq "gene_name") {print "\tAccession number - ".$row->{accession_number}."\n\tAccession version - ".$row->{accession_version}."\n\tDescription - ".$row->{description}."\n\tLength of the sequence - ".$row->{length}."\n";}
        }
    }
    
    print "\nChoose a sequence: ";
    my $answer = <>;
    while($answer < 1 or $answer > scalar(keys %accessions_or_names)){
        print "INVALID OPTION! Please choose a valid one: ";
        $answer = <>;
    }
    chomp $answer;
    return $accessions_or_names{$answer};
}





#--------------------------------------This function gets all the id_sequences with the same accession_numbers or with the same gene_name---------------------------
sub get_accessions_or_names{
    my ($accession_number_or_gene_name, $type) = @_;
    my $count = 0;
    my %accessions_or_names;
    
    my $sql = "SELECT id_sequence FROM sequences WHERE $type = '".$accession_number_or_gene_name."';";
    my $result = $dbh->prepare($sql);
    $result->execute();
    
    while(my $row = $result->fetchrow_hashref()){
        $count++;
        $accessions_or_names{$count} = $row->{id_sequence};
    }
    return %accessions_or_names;
}





#------------------This function will have ALL the interface things-------------------
# - 1st argument: interface type (string)
# - 2nd argument: clear screen (boolean)
# - 3rd argument: invalid option (boolean)
# - 4th argument: something that might be useful (like id_sequence, a file name, etc.)
# - 5th argument: current id_sequence of the modifiying sequence (just used for the option "modification")
# - 6th argument: total of modifying sequences (just used for the option "modification")
# - 7th argument: format of the file to create (just used for the option "modification")
sub interface {
    my ($type, $clear, $invalid, $something, $current, $total, $format) = @_;
    my ($option, $answer);
    my @answer;
    
    if($type eq "welcome"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one!\n\n"}
        else {print "\t\t\t===================WELCOME TO \"FETCH THE SEQUENCE\"!=================== \n\n\t\t\t\t\t\tEnjoy This Software! :D\n\n";}
        print "What do you want to do?\n\n 1 - Database operations\n 2 - Bioinformatics operations\n 3 - Views and Searches\n\n 8 - Help\n 9 - Exit\n\nAnswer: ";
        $option = <>;
        if($option == 8){
            system $^O eq 'MSWin32' ? 'cls' : 'clear';
            print "HELP:\nThis is the main page of \"Fetch the Sequence\". This software is seperated in 2 types of operations: database operations and bioinformatics operations. In the first"
                    ." one, you can do operations in the database, like insert new sequences, remove or modify sequences. In the second one, you can do bioinformatics operations, like run a "
                    ."BLAST, search for a motif, obtain statistical information, add features to a sequence and translate a sequence.\n\n\n";
            interface("welcome");
        }
        elsif($option == 1 or $option == 2 or  $option==3 or $option == 9) {return $option;}
        else {interface("welcome", 1, 1);}
    }
    
    
    
    elsif($type eq "database_operations"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one!\n\n"}
        print "What do you want to do?\n\n 1 - Insertion of a sequence\n 2 - Removal of a sequence\n 3 - Modification of a sequence\n\n 8 - Help\n 9 - Go to main page\n\nAnswer: ";
        $option = <>;
        if($option == 8){
            system $^O eq 'MSWin32' ? 'cls' : 'clear';
            print "HELP:\nHere you can choose the desired database operation: insert a new sequence, remove an existing sequence or modify an existing sequence.\n\n\n";
            interface("database_operations");
        }
        elsif($option == 1 or $option == 2 or $option == 3 or $option == 9) {return $option;}
        else {interface("database_operations", 1, 1);}
    }
    
    
    
    elsif($type eq "bioinformatics_operations"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one!\n\n"}
        print "What do you want to do?\n\n 1 - Run a BLAST\n 2 - Search for a motif\n 3 - Obtain statistical information about a sequence\n 4 - Add a new feature in a sequence\n 5 - Translate a sequence\n\n 8 - Help\n 9 - Go to main page\n\nAnswer: ";
        $option = <>;
        if($option == 8){
            system $^O eq 'MSWin32' ? 'cls' : 'clear';
            print "HELP:\nHere you can choose the desired bioinformatic operation: run a BLAST, search for a motif, obtain statistical information, add a new feature or translate a sequence.\n\n\n";
            interface("bioinformatics_operations");
        }
        elsif($option == 1 or $option == 2 or $option == 3 or $option == 4 or $option == 9 or $option == 5) {return $option;}
        else {interface("bioinformatics_operations", 1, 1);}
    }
    
    
    
    elsif($type eq "ask_insertion_type"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one!\n\n";}
        print "Choose a way to insert a sequence: \n\n 1 - Manually\n 2 - From a file\n 3 - From a remote database\n\n 8 - Help\n 9 - Go to main page\n\nAnswer: ";
        $option = <>;
        if($option == 8){
            system $^O eq 'MSWin32' ? 'cls' : 'clear';
            print "HELP:\nHere you can choose the insertion type: you can insert a new sequence manually (the program will ask for useful information about the sequence), intert from a file"
                    ." that you have on your machine (in the 'fasta', 'genbank' or 'swiss' format), or insert from a remote database (you have to be connected to the Internet).\n\n\n";
            interface("ask_insertion_type");
        }
        elsif($option == 1 or $option == 2 or $option == 3 or $option == 9) {return $option;}
        else {interface("ask_insertion_type", 1, 1);}
    }
    
    
    
    elsif($type eq "ask_authority"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the authority: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    
    
    
    elsif($type eq "ask_alphabet"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one: ";}
        else {print "Insert the alphabet\n\n 1 - dna\n 2 - rna\n 3 - protein\n\nAnswer: ";}
        $answer = <>;
        chomp $answer;
        if($answer == 1 or $answer == 2 or $answer == 3) {return $answer;}
        else {interface("ask_alphabet", 0, 1);}
    }
    
    
    
    elsif($type eq "ask_description"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the description: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    
    
    
    elsif($type eq "ask_gene_name_insertion"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "This gene name is already in use! Please choose an unused one: "}
        else {print "Insert the gene name: ";}
        $answer = <>;
        chomp $answer;
        if (verify_gene_name($answer)) {interface("ask_gene_name_insertion", 0, 1);}
        else {return $answer;}
    }
    
    
    
    elsif($type eq "ask_gene_name"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the gene name: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    
    
    
    elsif($type eq "ask_date"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one! ";}
        print "Insert the date: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    
    
    
    elsif($type eq "ask_is_circular"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one: ";}
        else {print "Is it circular?\n\n 1 - Yes\n 2 - No\n\nAnswer: ";}
        $answer = <>;
        chomp $answer;
        if($answer == 1) {
            $answer = 1;
            return $answer;
        }
        elsif($answer == 2) {
            $answer = 0;
            return $answer;
        }
        else{interface("ask_is_circular", 0, 1);}
    }
    
    
    
    elsif($type eq "ask_keywords"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the keywords (seperated by ','): ";
        $answer = <>;
        chomp $answer;
        @answer = split /\s*,\s*/, $answer;
        return @answer;
    }
    
    
    
    elsif($type eq "ask_keywords_file"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the keywords, in addition to the possible keywords on the file (seperated by ','): ";
        $answer = <>;
        chomp $answer;
        @answer = split /\s*,\s*/, $answer;
        return @answer;
    }
    
    
    
    elsif($type eq "ask_keyword"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the keyword: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    
    
    
    elsif($type eq "ask_sequence"){
        #Here, the $something will have the ALPHABET of the sequence
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID SEQUENCE! Please insert a valid one: "}
        else {print "Insert the sequence: ";}
        $_ = <>;
        chomp;
        if($something eq "dna") {
            if(/[^atgcATCG]/){interface("ask_sequence", 0, 1, $something);}
        }
        elsif($something eq "rna"){
            if(/[^augcAUCG]/){interface("ask_sequence", 0, 1, $something);}
        }
        elsif($something eq "protein"){
            if(/[^avlipmfwgstcnqydekrhAVLIPMFWGSTCNQYDEKRH]/){interface("ask_sequence", 0, 1, $something);}
        }
        return $_;
    }
    
    
    
    elsif($type eq "ask_seq_version"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the version of this sequence: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    
    
    
    elsif($type eq "ask_specie"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        display_species();
        print "Insert the specie: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }


    
    
    elsif ($type eq "ask_format"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Select the format of the sequence:\n\n 1 - Fasta\n 2 - Genbank\n 3 - Swissprot\n\nAnswer: ";    
        do{     
            $option = <>;
            
            if ($option == 1 or $option == 2 or $option==3) {return $option;}
            else {print "INVALID OPTION! Please choose a valid one:  ";}
        } while(1);     
    }
    
    
    
    elsif($type eq "ask_file_path"){
        if($clear) {
            system $^O eq 'MSWin32' ? 'cls' : 'clear';
            print "Insert the file path: ";
        }
        elsif(!$clear and $invalid) {print "ERROR: EXISTING ACCESSION NUMBER IN DATABASE!!! Insert the file path: "}
        else {print "FILE NOT FOUND! Insert a valid file path: ";}
        $answer = <>;
        chomp $answer;
        if(verify_accession_in_file($answer)) {interface("ask_file_path", 0, 1)}
        else {return $answer;}
    }
    
    
    
    elsif($type eq "ask_removal_type"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one!\n\n";}
        print "Choose a way to remove the sequence:\n\n 1 - By an accession number\n 2 - By a gene name\n\n 8 - Help\n 9 - Go to main page\n\nAnswer: ";
        $option = <>;
        if($option == 8){
            system $^O eq 'MSWin32' ? 'cls' : 'clear';
            print "HELP:\nHere you can choose the removal type: you can remove by giving the accession number or giving the gene name.\n\n\n";
            interface("ask_removal_type");
        }
        elsif($option == 1 or $option == 2 or $option == 9) {return $option;}
        else {interface("ask_removal_type",1, 1);}
    }
    
    
    
    elsif($type eq "ask_accession_number_insertion"){
        my $existe=0;
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        do{
            if($existe) {print "\nERROR: EXISTING ACCESSION NUMBER IN DATABASE!!!\n"}
            print "Insert the accession number: ";
            $answer = <>;
            chomp $answer;
            $existe = verify_accession($answer, "with");             #verifies if the accession_number already exists on the database
        }while($existe);
        return $answer;
    }
    
    
    
    elsif($type eq "ask_accession_number"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the accession number: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    
    
    
    elsif($type eq "ask_modification_type"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one!\n\n";}
        print "Choose a way to modify the sequence (ATTENTION: If there are more than 1 sequence with the same accession number or with the same name, ".
                "you can modify whatever you want):\n\n 1 - By an accession number\n 2 - By a gene name\n\n 8 - Help\n 9 - Go to main page\n\nAnswer: ";
        $option = <>;
        if($option == 8){
            system $^O eq 'MSWin32' ? 'cls' : 'clear';
            print "HELP:\nHere you can choose the modification type: you can modify by giving the accession number or giving the gene name. If there are more than 1 sequence with the"
                    ." same accession number or gene name, it will be possible to edit all of them, some of them or just one.\n\n\n";
            interface("ask_modification_type");
        }
        elsif($option == 1 or $option == 2 or $option == 9) {return $option;}
        else {interface("ask_modification_type",1, 1);}
    }
    
    
    
    elsif($type eq "modify_sequence"){
        #Here, the $something is NOT used
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Sequence $current in $total sequences ...\n\n";
        if($invalid) {print "INVALID OPTION! Please choose a valid one!\n\n";}
        print "The file sequence".$current."in".$total.".$format has been created in the directory of this program. Go and modify whatever you want to. After all the changes are done".
                ", come back and enter \"ok\" (without quotes)\n";
        $answer = <>;
        chomp $answer;
        if($answer ne "ok") {interface("modify_sequence", 1, 1, $something, $current, $total, $format);}
    }
    
    
    
    elsif($type eq "error_file_not_found"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "\t\t\tABORTED!\n\nAn error occured... The file could not be found...\n\n";
        main(0);
    }
    
    
    
    elsif ($type eq "ask_database"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Which database you want to use to import:\n\n 1 - Genbank\n 2 - Swissprot \n 3 - RefSeq\n\nAnswer: ";    
        do{
            $option = <>;
            
            if ($option == 1 or $option == 2 or $option == 3) {return $option;}
            else {print "INVALID OPTION! Please choose a valid one: ";}    
    
        } while(1);
    }
    
    
    
    elsif ($type eq "generic_importation_begin"){
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        if ($clear==1) {print "Welcome to the GenBank Importation Interface!!\n"; }
        elsif($clear==2) {print "Welcome to the SwissProt Importation Interface!!\n";}
        else {print "Welcome to the RefSeq Importation Interface!!\n";}
    }
    
    
    
    elsif ($type eq "ask_import"){
        print "\n\nSelect the way you want to import:\n\n 1 - Accession Number\n 2 - Accession Version\n\nAnswer: ";    
        do{     
            $option = <>;
            
            if ($option == 1 or $option == 2) {return $option;}
            else {print "INVALID OPTION! Please choose a valid one: ";}    
    
        } while(1);     
    }
    
    
    
    elsif ($type eq "ask_version_number"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        
        my $flag=1;
        do{
        if (!$flag) {print "ERROR: Existing Accesion Version on DATABASE! ";}
        print "Please insert the Accession Version Number: ";
        $option = <>;
        chomp $option;
        $flag=verify_version($option);
        }while(!$flag);
        return $option;
    }
    
    
    
    elsif($type eq "ask_tag"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        my $flag;
        my $flag2 = 0;
        do{
            $flag=1;

            if($flag2) {print "INVALID OPTION! Please choose a valid one: ";}
            else {print "Do you want to add a tag  to the sequence?\n\n 1- Yes, I do\n 2- No, I don't\n\nAnswer: ";}
            $answer = <>;
            chomp $answer;
            if ($answer!=1 and $answer!=2) {$flag=0; $flag2=1;}
        }while(!$flag);
        
        if ($answer==2) {return (0,0);} #don't want to add tags
        
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        else {print "\n\n";}
        display_tags();  
        my @lista = interface('ask_keywords');
        return (1, @lista);
    }
    
    
    elsif($type eq "ask_choose_type"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if ($invalid) {print "INVALID OPTION! Please choose a valid one: ";}
        else {print "How do you want to choose the sequence?\n\n 1 - By accession number\n 2 - By gene name\n\nAnswer: ";}
        $option = <>;
        if($option == 1 or $option == 2) {return $option;}
        else {interface("ask_choose_type", 0, 1);}
    }
    
    
    elsif($type eq "ask_accession_number_no_check"){
        #This part returns 2 values. The 2nd one is a boolean: if it is 1, then the 1st one is a accession_number; if it is 0, then the 1st one is a id_sequence
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "The accession number indicated doesn't exists on the database! Choose an existing one: "}
        else {print "Insert the accession number: ";}
        $answer = <>;
        chomp $answer;
        if(verify_accession($answer, "without")){
            my $accessions = count_accession_or_name($answer, "accession_number");
            if($accessions == 1) {return ($answer, 1);}
            elsif($accessions > 1) {return (display_accessions_or_names($answer, "accession_number"), 0);}
        }
        else {interface("ask_accession_number_no_check", 0, 1);}
    }
    
    
    
    elsif($type eq "ask_gene_name_no_check"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "The gene name indicated doesn't exists on the database! Choose an existing one: "}
        print "Insert the gene name: ";
        $answer = <>;
        chomp $answer;
        if(verify_gene_name($answer)) {
            my $names = count_accession_or_name($answer, "gene_name");
            if($names == 1) {return ($answer, 1);}
            elsif($names > 1) {return (display_accessions_or_names($answer, "gene_name"), 0);}
        }
        else {interface("ask_gene_name_no_check", 0, 1);}
    }
    
    
    
    
    elsif($type eq "ask_blast_type"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if ($invalid) {print "INVALID OPTION! Please choose a valid one: ";}
        else {print "What kind of BLAST you want to try?\n\n 1 - blastp\n 2 - blastn\n 3 - blastx\n 4 - tblastn\n 5 - tblastx\n\nAnswer: ";}
        $option = <>;
        if($option == 1 or $option == 2 or $option == 3 or $option == 4 or $option == 5) {return $option;}
        else {interface("ask_blast_type", 0, 1);}
    }
    
    
    
    elsif ($type eq "ask_database_protein"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Which database you want to use to import:\n\n 1 - RefSeq\n 2 - Swissprot\n\nAnswer: ";
        do{
            $option = <>;
            
            if ($option == 1 or $option == 2) {return $option;}
            else {print "INVALID OPTION! Please choose a valid one: ";}
        } while(1);
    }
    
    
    
    elsif($type eq "successful_insertion"){
        #Here, the $something has the ID_SEQUENCE
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one: ";}
        else {print "Successful insertion!!!\n\nThe file ".(substr $dbm_seq{$something}, 10)." has been created on the 'sequences' directory. Do you want to see this file?\n\n 1 - Yes, I do\n 2 - No, I don't"
                ."\n\nAnswer: ";}
        $option = <>;
        if ($option == 1 or $option == 2) {return $option;}
        else {interface("successful_insertion", 0, 1);}
    }
    
    
    
    elsif($type eq "successful_removal"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Successful removal!!!\n\n\nPress Enter...";
        <>;
    }
    
    
    
    elsif($type eq "successful_modification"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Successful modification!!!\n\n";
    }
    
    
    elsif($type eq "ask_display_modified"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one: ";}
        else {print "Some file(s) was(were) modified in the 'sequences' directory. Do you want to see them?\n\n 1 - Yes, I do\n 2 - No, I don't\n\nAnswer: ";}
        $option = <>;
        if($option == 1 or $option == 2) {return $option;}
        else {interface("ask_display_modified", 0, 1);}
    }
    
    
    
    elsif($type eq "ask_modified_table"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one: ";}
        else {print "Select the file you want to see: ";}
        $option = <>;
        return $option;
    }
    
    
    
    elsif($type eq "ask_display_match"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one: ";}
        else {print "This table show the sequences where the motif was found. Do you want to see them?\n\n 1 - Yes, I do\n 2 - No, I don't\n\nAnswer: ";}
        $option = <>;
        if($option == 1 or $option == 2) {return $option;}
        else {interface("ask_display_match", 0, 1);}
    }
    
    
    
    elsif($type eq "ask_match_table"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one: ";}
        else {print "Select the file you want to see: ";}
        $option = <>;
        return $option;
    }
    
    
    
    
    elsif($type eq "successful_blast"){
        #Here the $something has the FILE NAME of the file that blast() function created
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one: ";}
        else {print "Successful BLAST!!!\n\nThe file ".(substr $something, 14)." has been created on the 'blast_results' directory. Do you want to see this file?\n\n 1 - Yes, I do\n 2 - No, I don't\n\nAnswer: ";}
        $option = <>;
        if ($option == 1 or $option == 2) {return $option;}
        else {interface("successful_blast", 0, 1);}
    }
    
    
    
    elsif($type eq "ask_motif"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the motif that you want to find: ";
        $answer = <>;
        chomp $answer;
        return uc($answer);
    }
    
    
    
    elsif($type eq "no_match"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "The motif was not found in any sequence on the database!\n\nPress Enter...";
        <>;
    }
    
    
    
    
    elsif($type eq "successful_statistics"){
        #Here the $something has the FILE NAME of the file that statistics() function created
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one: ";}
        else {print "Statistics created successfully!!!\n\nThe file ".(substr $something, 11)." has been created on the 'statistics' directory. Do you want to see this file?\n\n 1 - Yes, I do\n 2 - No, I don't\n\nAnswer: ";}
        $option = <>;
        if ($option == 1 or $option == 2) {return $option;}
        else {interface("successful_statistics", 0, 1);}
    }
    

    
    elsif($type eq "error_feature"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "ERROR! The sequence selected is in the 'fasta' format, and this format doesn't support features...\n\nPress Enter...";
        <>;
    }
    
    
    
    elsif($type eq "ask_feature_start"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the number of the start monomer of the feature: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    
    
    
    elsif($type eq "ask_feature_end"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the number of the ending monomer of the feature: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    
    
    
    elsif($type eq "ask_feature_end"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the number of the ending monomer of the feature: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    
    
    
    elsif($type eq "ask_feature_strand"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one: ";}
        else {print "The new feature is in which direction?\n\n 1 - 5' -> 3'\n 2 - 3' -> 5'\n 3 - Doesn't matter\n\nAnswer: ";}
        $option = <>;
        if ($option == 1 or $option == 2 or $option == 3) {return $option;}
        else {interface("ask_feature_strand", 0, 1);}
    }
    
    
    elsif($type eq "ask_feature_primary"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the primary tag of the feature: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    
    
    
    elsif($type eq "ask_feature_source"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the source tag of the feature: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    
    
    
    elsif($type eq "successful_feature"){
        #Here, the $something has the FILE NAME of the sequence
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one: ";}
        else {print "The new feature was added successfully!!!\n\nThe file $something has been updated on the 'sequences' directory. Do you want to see this file?\n\n 1 - Yes, I do\n 2 - No, I don't"
                ."\n\nAnswer: ";}
        $option = <>;
        if ($option == 1 or $option == 2) {return $option;}
        else {interface("successful_feature", 0, 1);}
    }
    
    
    
    
    elsif($type eq "ask_translate_type"){
        
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one: ";}
        print "Do you want to use a sequence from the database or manually insert one?\n\n 1 - From database\n 2 - Manually\n\nAnswer: ";
        $option=<>;
        if ($option==1 or $option==2) {return $option;}
        else {interface("ask_translate_type", 0, 1);}
                 
    }
    
    elsif($type eq "insert_manual_seq"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID SEQUENCE! Please choose a valid one: ";}
        print "Insert the DNA sequence: ";
        $_=<>;
        chomp $_;
        if(/[^atgcATCG]/) {interface("insert_manual_seq",0,1);}
        else {return $_;}
        
    }
    
    
    
    elsif($type eq "successful_translation"){
        #Here, the $something has the FILE NAME of the created translation file
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one: ";}
        else {print "Successful translation!!!\n\nThe file ".(substr $something, 13)." has been created on the 'translations' directory. Do you want to see this file?\n\n 1 - Yes, I do\n 2 - No, I don't\n\nAnswer: ";}
        $option = <>;
        if ($option == 1 or $option == 2) {return $option;}
        else {interface("successful_blast", 0, 1);}
    }
    
    
    
    
    elsif($type eq "search_operations"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one: ";}
        else {print "Select the option you would like to do:\n\n 1 - View keywords\n 2 - View species\n 3 - View sequences\n 4 - Search sequences\n\n 8 - Help\n 9 - Go to main page\n\nAnswer: ";}
        $option=<>;
        if($option == 1 or $option == 2 or $option== 3 or $option == 4 or $option == 9) {return $option;}
        elsif($option == 8){
            system $^O eq 'MSWin32' ? 'cls' : 'clear';
            print "HELP:\nHere, you can view some information from the database: you can view all the keywords, all species, all the sequences or some sequences with a specific property.\n\n\n";
            interface("search_operations");
        }
        else {interface("search_operations",0,1);}
    }
    
    
    
    elsif($type eq "ask_search_option"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one: ";}
        else {print "Select the options which you want to use to search:\n\n 1 - By keywords\n 2 - By accession number\n 3 - By gene name\n 4 - By specie\n\n 8 - Help\n 9 - Go to main page\n\nAnswer: ";}
        $option=<>;
        if($option == 1 or $option == 2 or $option == 3 or $option == 4 or $option == 9) {return $option;}
        elsif($option == 8){
            system $^O eq 'MSWin32' ? 'cls' : 'clear';
            print "HELP:\nHere, you can view the sequences that have a specific property. You can select them choosing some keywords, accession number, gene name or by specie.\n\n\n";
            interface("ask_search_option");
        }
        else {interface("ask_search_option", 0, 1);}
    }
    
    
    elsif($type eq "waiting_enter"){
        print "\n\nPress Enter...";
        <>;
    }
    
    
        
    elsif($type eq "exit"){
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "\t\n\nBioinformatics - \"Fetch the Sequence!\" \n\n Thank you for using our software! \n Have a nice day! :) \n\n";

    }
}




__END__


=head1 I<MAIN FUNCTIONS>

=head2 MAIN

This is the main function of this software. This function indicates the right path according to what the users wants to do.

B<USAGE:>
main($clear);

The argument that it receives is a flag to tell if it is suppose or not to clear the screen.


=head2 DATABASE_OPERATIONS

This function calls the functions that operate with the database.

B<USAGE:>
database_operations();


=head2 BIOINFORMATICS_OPERATIONS

This function just calls the right functions to perform a bioinformatics job.

B<USAGE:>
bioinformatics_operations();


=head2 SEARCH_OPERATIONS

This function calls the functions to perform searchs in the database.

B<USAGE:>
search_operations();








=head1 I<INSERTION FUNCTIONS>

=head2 INSERTION

This function inserts a sequence in the database: manually, from a file or from a remote database.

B<USAGE:>
insertion();


=head2 INSERT_SPECIE

This function verifies if the inserted specie already exists on database. If it already exists, doesn't try to insert it.

B<USAGE:>
insert_specie($specie);

The argument is a string with the specie to insert on the database.


=head2 INSERT_SEQUENCE_DB

This function inserts the sequence informations into the database.

B<USAGE:>
insert_sequence_db($specie, $alphabet, $authority, $description, $gene_name, $date, $is_circular, $seq_length, $format, $seq_version, $accession_number);

The arguments are:

=over 12

=item - $specie:
 
string with the specie;

=item - $alphabet:

string with the alphabet of the sequence ("dna", "rna" or "protein");

=item - $authority:

string with the authority of the sequence;

=item - $description:

string with the description of the sequence;

=item - $gene_name:

string with the gene name;
 
=item - $date:

string with the date;
 
=item - $is_circular:
 
boolean to tell if the sequence is circular (1) or not (0);
 
=item - $seq_length:
 
int with the length of the sequence;
 
=item - $format:

string with the format of the sequence ("fasta", "genbank" or "swiss");
 
=item - $seq_version:

string with the version of the sequence;
 
=item - $accession_number:

string with the accession number of the sequence.

=back


=head2 INSERT_TAGS

This function inserts the tags on the database, and returns id of the sequence (id auto incremented on the database).

B<USAGE:>
insert_tags($flag, @keywords);

The arguments that this function receives are:

=over 12

=item - $flag:

boolean to teel if the user wants to add keywords or not;
 
=item - @keywords:

list of strings, that are the key_words;

=back

B<RETURNS:>
The id of the sequence (id auto incremented on the database).


=head2 INSERT_SEQUENCE

This function inserts the sequence on a DBM hash.

B<USAGE:>
insert_sequence($id_sequence, $seq, $format, $with_accession);

The arguments are:

=over 12

=item - $id_sequence:

int with the id of the sequence (id auto incremented on the database);
 
=item - $seq:

Bio::Seq object, with the information aboout the sequence;
 
=item - $format:

string with the format of the sequence;
 
=item - $with_accession:

flag to tell if the sequence has an accession number (in other words, if it was inserted form a file or from a remote database, and in this case the sequence file name will have the accession number), or if it doesn't (in other words, if the sequence was inserted manually, and in this case the sequence file name will have the gene name).

=back


=head2 GENERIC_IMPORTATION

This function inserts the sequence from a remote database.

B<USAGE:>
generic_importation($db);

The argument is a string with the database where the sequence comes from.


=head2 INSERT_SPECIE_IMPORTATION

This function inserts the specie for the insertion from remote databases.

B<USAGE:>
insert_specie_importation($specie);

The argument is a string with the specie to be inserted.

B<RETURNS:>
The id of the sequence from the database.


=head2 INSERT_SEQUENCE_IMPORTATION

This function inserts the sequence for the insertion from remote databases.

B<USAGE:>
insert_sequence_importation($format,$id_specie,$seq,$version);

The arguments are:

=over 12

=item - $format:

string with the file format ("fasta", "genbank" or "swiss");
 
=item - $id_specie:

int with the id of the specie (id auto incremented on the database);

=item - $seq:

Bio::Seq object with the sequence information;
 
=item - $version:

flag that tells if the Bio::Seq has an accession version to be inserted (1) or not (0);

=back








=head1 I<REMOVAL FUNCTIONS>

=head2 REMOVAL

This function indicates the right path to remove data from the database, depending from the user's decision.

B<USAGE:>
removal();


=head2 REMOVE

This function deletes a sequence from the database and from the DBM hash (including from the folder 'sequences').

B<USAGE:>
remove($accession_number_or_gene_name, $type);

The arguments are:

=over 12

=item - $accession_number_or_gene_name:

string with the accession number or with the gene name (depending if the sequence has an accession number or a gene name);
 
=item - $type:

string that tells if the previous argument is an accession number (and it has the value "accession_number") or a gene name (and it has the value "gene_name").

=back


=head2 REMOVE_SEQ_TAGS

This function will remove data from the table seq_tags on the database.

B<USAGE:>
remove_seq_tags($id_sequence);

This function receives the id of the sequence on the database.







=head1 I<MODIFICATION FUNCTIONS>

=head2 MODIFICATION

This function indicates the right path to modify data from the database, depending from the user's decision.

B<USAGE:>
modification();


=head2 MODIFY

This function modifies a sequence saved on the database.

B<USAGE:>
modify($accession_number_or_gene_name, $type);

The arguments are:

=over 12

=item - $accession_number_or_gene_name:

string with the accession number or with the gene name (depending if the sequence has an accession number or a gene name);
 
=item - $type:

string that tells if the previous argument is an accession number (and it has the value "accession_number") or a gene name (and it has the value "gene_name").

=back

B<RETURNS:>
An hash with the name of the files to be modified.


=head2 CREATE_FILE

This function creates the file where the user will modify the data.

B<USAGE:>
create_file($current, $total, $row);

The arguments are:

=over 12

=item - $current:

int that indicates the current file (e.g. 1 (current) in 3 (total) files);
 
=item - $total:

int that indicates the total of files to be modified;

=item - $row:

Reference to an hash with the data that comes from the database.

=back


=head2 FETCH_INFO

This function fetches the new information given by the user from the modified files.

B<USAGE:>
fetch_info($current, $total, $format);

The arguments are:

=over 12

=item - $current:

int that indicates the current file (e.g. 1 (current) in 3 (total) files);
 
=item - $total:

int that indicates the total of files to be modified;

=item - $row:

Reference to an hash with the data that comes from the database.

=back

B<RETURNS:>
A Bio::Seq object with the information from the file.


=head2 UPDATE_INFO

This function updates the info modified by the user in the database and the DBM hash.

B<USAGE:>
update_info($seq, $id_sequence);

The arguments are:

=over 12

=item - $seq:

Bio::Seq object with the information about the sequence;

=item - $id_sequence:

int with the id of the sequence from the database.

=back


=head2 DISPLAY_MODIFIED

This function displays the modified sequences table, and asks if the user want to see it on the program (with the 'pg' linux command).

B<USAGE:>
display_modified(%modified);

The argument is an hash with the names of the files that are going to be modified.





=head1 I<BLAST FUNCTIONS>

=head2 BLAST

This is the function that runs a remote blast. It can run a blastp, blastn, blastx, tblastn or tblastx.

B<USAGE:>
blast();







=head1 I<MOTIF FUNCTIONS>

=head2 MOTIF

This function gets the motif and calls the right functions to serch it on the sequences on the database.

B<USAGE:>
motif();


=head2 SEARCH_MOTIF

This function searches for a motif in all the sequences of the database.

B<USAGE:>
search_motif($motif);

The argument is a string with the motif (sequece) to be searched in all the sequences.

B<RETURNS:>
References for two hashes: one contains the sequences which the motif matches, and the other have a list with the positions where the motif was found for each sequence that had matched.


=head2 DISPLAY_MATCH

This function displays the match table and the positions where the motif was found, and asks if the user want to see it with the 'pg' linux command.

B<USAGE:>
display_match($match, $positions);

The arguments are:

=over 12

=item - $match:

reference for an hash that has all the sequences where the motif was found;

=item - $positions:

reference for an hash that has a list with all the positions where the motif was found for all the sequences in the hash before.

=back








=head1 I<STATISTICS FUNCTIONS>

=head2 STATISTICS

This function will get the important information from the sequences to get some statistic information.

B<USAGE:>
statistics();


=head2 GET_STATISTICS_INTO_FILE

This function writes statistics into a file, so the user can use it for whatever he wants.

B<USAGE:>
get_statistics_into_file($filename, $seq);

The arguments are:

=over 12

=item - $filename:

string with the filename of the file where the statistics are going to be written;

=item - $seq:

Bio::Seq object with the information about the sequence.

=back








=head1 I<FEATURES FUNCTIONS>

=head2 FEATURES

This function adds a new feature into a sequence.

B<USAGE:>
features();







=head1 I<TRANSLATION FUNCTIONS>

=head2 TRANSLATEE

This function translates a DNA sequence.

B<USAGE:>
translatee();


=head2 WRITE_TRANSLATIONE

This function writes the 6 ORF's in the translation file.

B<USAGE:>
write_translatione($sequence, $filename_translation);

The arguments are:

=over 12

=item - $sequence:

string with the sequence to be translated;

=item - $filename_translation:

string with the translation filename.

=back


=head2 TRANSLATIONE

This function calls the 'translate' operation for the 6 ORF's.

B<USAGE:>
translatione($sequence, $is_reversed, $i);

The arguments are:

=over 12

=item - $sequence:

string with the sequence to be translated;

=item - $is_reversed:

flag that tells if it is supposed to translate the reversed sequence;

=item - $i:

int with the frame, to translate with the correct ORF.

=back








=head1 I<SEARCH FUNTIONS>


=head2 DISPLAY_TAGS

This function displays in the screen a keywords table.

B<USAGE:>
display_tags();


=head2 DISPLAY_SPECIES

This function dysplays in the screen a species table.

B<USAGE:>
display_species();


=head2 DISPLAY_SEQUENCES

This function dysplays in the screen a sequences table.

B<USAGE:>
display_sequences($result);

The argument is the result from a SELECT statement, done againt the database.


=head2 DISPLAY_ALL_SEQUENCES

This function displays a table with the information about all the sequences on the database.

B<USAGE:>
display_all_sequences();


=head2 DISPLAY_SEARCH_SEQUENCES

This function displays sequences that have a specific property, asking what kind of property.

B<USAGE:>
display_search_sequences();


=head2 DISPLAY_SEQUENCES_BY_KEYWORD

This function displays the sequences with a determined keyword.

B<USAGE:>
display_sequences_by_keyword();


=head2 DISPLAY_SEQUENCES_BY_ACCESSION_NUMBER

This function displays the sequences with a determined accession number.

B<USAGE:>
display_sequences_by_accession_number();


=head2 DISPLAY_SEQUENCES_BY_GENE_NAME

This function displays the sequences with a determined gene name.

B<USAGE:>
display_sequences_by_gene_name();


=head2 DISPLAY_SEQUENCES_BY_SPECIE

This function displays the sequences with a determined specie.

B<USAGE:>
display_sequences_by_specie();


=head2 DISPLAY_ACCESSIONS_OR_NAMES

This function displays all the accession numbers or all the gene names, if there are more that 1 sequence with the same accession number or gene name.

B<USAGE:>
display_accessions_or_names();

B<RETURNS:>
The id of the sequence selected (auto incremented id from the database).





=head1 I<AUXILIAR FUNCTIONS>

=head2 GET_FORMAT

This function is capable of obtain the format of a file.

B<USAGE:>
get_format($path);

The argument that it receives is the filename/path to the file.

B<RETURNS:>
The file format.


=head2 GET_ID_SEQUENCE

This function will get the id of the sequence in the database.

B<USAGE:>
get_id_sequence($acc_or_name, $type);

The arguments are:

=over 12

=item - $acc_or_name:

string with the accession number or with the gene name (depending if the sequence has an accession number or a gene name);
 
=item - $type:

string that tells if the previous argument is an accession number (and it has the value "accession_number") or a gene name (and it has the value "gene_name").

=back

B<RETURNS:>
The id of the sequence (auto incremented id from the database).


=head2 VERIFY_ACCESSION

This function verifies if the accession version already exists on the database.

B<USAGE:>
verify_accession($type, $with);

The arguments are:

=over 12

=item - $type:

string with the accession number or the accession version;

=item - $with:

string that says if it is to search by accession number AND accession version (and it has the value "with") or just to search by the accession number (and it has the value "wothout").

=back

B<RETURNS:>
A boolean that tells if the accession number already existis (1) or not (0).


=head2 VERIFY_VERSION

This function verifies if an accession version already exists.

B<USAGE:>
verify_version($version);

The argument is a string with the accession version already exists.

B<RETURNS:>
A boolean that tells if the accession version already exists (0) or not (1);


=head2 COUNT_ACCESSION_OR_NAME

This function counts the number of sequences that have the same accession number or the same gene name.

B<USAGE:>
count_accession_or_name($accession_number_or_gene_name, $type);

The arguments are:

=over 12

=item - $accession_number_or_gene_name:

string with the accession number or with the gene name (depending if the sequence has an accession number or a gene name);
 
=item - $type:

string that tells if the previous argument is an accession number (and it has the value "accession_number") or a gene name (and it has the value "gene_name").

=back

B<RETURNS:>
int with the number of equals accession numbers or gene names.


=head2 VERIFY_ACCESSION_IN_FILE

This function verifies if the accession version already exists for the importation from a file.

B<USAGE:>
verify_accession_in_file($file);

The argument is the filename/path to the file.

B<RETURNS:>
A boolean that tells if the accession number already existis (1) or not (0).


=head2 VERIFY_GENE_NAME

This function verifies if the gene name already exists on the database.

B<USAGE:>
verify_gene_name($gene_name);

The argument is a string with the gene name.

B<RETURNS:>
A boolean that tells if the gene name already existis (1) or not (0).


=head2 GET_ACCESSIONS_OR_NAMES

This function gets all the id of the sequences with the same accession numbers or with the same gene name.

B<USAGE:>
get_accessions_or_names($accession_number_or_gene_name, $type)

The arguments are:

=over 12

=item - $accession_number_or_gene_name:

string with the accession number or with the gene name (depending if the sequence has an accession number or a gene name);
 
=item - $type:

string that tells if the previous argument is an accession number (and it has the value "accession_number") or a gene name (and it has the value "gene_name").

=back

B<RETURNS:>
An hash with the id of the sequences with the same accession numbers or with the same gene name (auto incremented if from the database).


=head2 INTERFACE

This function has all the interface of the program.

B<USAGE:>
interface($type, $clear, $invalid, $something, $current, $total, $format);

The arguments are:

=over 12

=item - $type:

string with the type of the interface (e.g. "welcome", "ask_alphabet", etc.);
 
=item - $clear:

flag that tells if it is supposed to clear or not the screen;

=item - $invalid:

flag that tells if it should appear an invalid warning (like when choosing an invalid option.);
 
=item - $something:

value that can contain anything useful for the operation (e.g., for the interface "ask_sequence", this value has the alphabet of the sequence; fot the interface "successful_insertion", this value has the id of the sequence on the database; etc.);

=item - $current:

int that tells the current sequence (just for the ",modification" operation);
 
=item - $total:

int that tells the total number of sequences (just for the ",modification" operation);

=item - $format:

string with the sequence format (just for the ",modification" operation).

=back