use strict;
use Bio::Perl;
use Bio::Seq;
use Bio::SeqIO;
use Bio::Species;
use strict;
use warnings;
use DBI();
use DBD::mysql;
use Bio::Root::Exception;
use Bio::Tools::Run::RemoteBlast;
use Bio::Tools::SeqStats;
use Error qw(:try);
#------------------------DATABASE CONNECTIONS ON JOAO'S PC!-----------------------------
my $dbh = DBI->connect('dbi:mysql:alg','root','blabla1') or die "Connection Error: $DBI::errstr\n";
my %dbm_seq;
dbmopen(%dbm_seq, '/home/johnnovo/Documents/sequence', 0666);

#------------------------DATABASE CONNECTIONS ON VITOR'S PC!----------------------------
#my $dbh = DBI->connect('dbi:mysql:alg','root','5D311NC8') or die "Connection Error: $DBI::errstr\n";
#my %dbm_seq;
#dbmopen(%dbm_seq, '/home/cof91/Documents/Mestrado/1º ano/1º semestre/Bioinformática - Ciências Biológicas/Algoritmos e Tecnologias da Bioinformática/Trabalho/algoritmos/database/sequences', 0666);

#------------------------DATABASE CONNECTIONS ON JOSE'S PC!----------------------------
#my $dbh = DBI->connect('dbi:mysql:alg','root','') or die "Connection Error: $DBI::errstr\n";
#my %dbm_seq;
#dbmopen(%dbm_seq, 'METER AQUI O CAMINHO DESEJADO PARA A LOCALIZACAO DA HASH COM AS SEQUENCIAS', 0666);

#TODO: METER O HELP NA INTERFACE!
#TODO: FALAR COM O JOAO SOBRE A CENA DA INSERÇAO REMOTA, DO ACCESSION NUMBER E VERSION

main(1);



#------------------This is the main function------------------------------------
sub main{
    #my ($key, $val);
    #
    #while (($key, $val) = each %dbm_seq){
    #    print "$key - $val\n";
    #}
    
    my ($clear) = @_;
    my $option = interface("welcome", $clear, 0);
    if($option == 1){database_operations();}
    elsif($option == 2){bioinformatics_operations();}
    elsif($option==3){search_operations();}    
    elsif($option == 9){
        interface("exit");
        dbmclose(%dbm_seq);
        #$dbh->disconnect;
        exit(0);
    }
}


#----------------------This funtion will call the functions that operate with the database--------------------------------
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
    my ($option,$opt2) = interface("search_operations",1,0);
     if($option == 1){display_tags();}
    elsif($option == 2){display_species();}
    elsif($option == 3){display_sequences();}
    elsif($option == 4){display_search_sequences($opt2);}
    elsif($option == 9){main(1);}
}


sub display_search_sequences{
    
    my $option = @_;
    
    my  $sql = "Select id_sequence,sequences.accession_number,accession_version,alphabet,gene_name,length,description where ";

}








#-----------------------This funtion inserts a sequence in the database: manually, from a file or from a remote database----------------------
sub insertion {
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
        $answer = interface("ask_database", 1);   # Escolher a Base de Dados
        if ($answer ==1 or $answer ==2 or $answer ==3) { interface("generic_importation_begin",$answer); generic_importation($answer); }    # Escolheu :     GENBANK    
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
        #The last argument tells if it has the accession number (insertion from a file or from a remote DB) or the gene name (manual insertion)
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




#-----------------------This funtion will remove data from the table seq_tags------------------------------
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


#--------------------------This funtion will fetch the new information given by the user----------------------------------
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


#------------------------This funtion will update the info in the database and the hash------------------------------------
sub update_info{
    my ($seq, $id_sequence) = @_;
    my $sql = "UPDATE sequences SET gene_name='".$seq->display_id."', accession_number='".$seq->accession_number."', description='".$seq->desc."', alphabet='".
                     $seq->alphabet."', length='".length($seq->seq)."' WHERE id_sequence='".$id_sequence."'";
    $dbh->do($sql);
    my $seqio = Bio::SeqIO->new(-file => ">".$dbm_seq{$id_sequence});
    $seqio->write_seq($seq);
}


#-----------------------------This funtion displays the modified sequences table, and asks if the user want to see it on the program (with the 'pg' command)----------------------
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


#-----------------------This funtion inserts the sequence from a remote database----------------------------------
sub generic_importation{
    my($base)=@_;
    my ($option2, $format, $seq, $existe, $option, $gb, $seqio_obj, $result, $sql, $specie, $id_specie, $id_sequence, $id_tag, $form, $flag);         
    if ($base==2) {$option=1;}
    else {$option = interface ("ask_import"); }  ## Escolher tipo de importação - "Acession Number ou Version Number"
    
    $format = interface ("ask_format", 1);  ## Escolher Fasta ou Genbank
    
    ### CICLO PARA PROCURAR    
    $existe=1;
    if ($base==1) {
        $gb = Bio::DB::GenBank->new();      ## Iniciar ligação ao Genbank
    }
    elsif ($base==2) {$gb=Bio::DB::SwissProt->new();}
    else {$gb=Bio::DB::RefSeq->new();}
    do {

        if (!$existe)  {print "ERROR! Already existing Accession Number in DataBase!!\n\nPress Enter...";<>;$existe=1;}     
        if ($existe==2) {print "ERROR! Non existing Number in Remote DataBase!!\n\nPress Enter...";<>;$existe=1;}

        ##### Inserir Number para procura
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
        #    $existe = verify_version_number($option2);             #Verifica de o accesion number já existe na Base de Dados                                        
                                  
            if($existe==1){
                try {
                    $seq = $gb->get_Seq_by_version($option2) || throw Bio::Root::Exception(print "ERROR: INVALID NUMBER!!") # Vai buscar o number         
                }catch Bio::Root::Exception with {$existe=2};  
            }
        }
        
    }while(!$existe or $existe==2);

    $specie = interface("ask_specie");   #pede especie e de seguida grava
    print "-------------------------------------------------------------------------------------------------------------------------\n";
    $id_specie=insert_specie_importation($specie);
    if ($option==2) {$id_sequence = insert_sequence_importation($format,$id_specie,$seq,$option2);}
    else {$id_sequence = insert_sequence_importation($format,$id_specie,$seq);}

    my @lista;
    my $bool;
    ($bool, @lista) = interface("ask_tag", 0); #pergunta se quer tag, se quiser pode escolher uma das que já há, ou uma nova.
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


#---------------------This funtion verifies the accession version for the importation from a file-------------------------
# It returns 1 if it exists, and 0 if it doesn't
sub verify_accession_in_file{
    my ($file) = @_;     
    my ($sql,$result, $format);
    if(substr ($file, -5) eq "fasta") {return 1;}           #won't check because of the "unknown" accession_ numbers
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


#------------------This funtion verifies if the gene name already exists on the database----------------------
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
   
        $sql1 = "INSERT INTO species (specie) VALUES ('".$specie."');";   ## INSERÇÃO
        $dbh->do($sql1);

        $result2 = $dbh->prepare($sql);  ## SELECT DO ID DA ESPECIE INSERIDA
        $result2->execute();
    
        @val = $result2->fetchrow_array();
    }
       
    return $val[0];
}



#--------------------This function inserts the sequence for the insertion from remote databases------------------
sub insert_sequence_importation {
        
    my ($formato,$id_specie,$seq,$version)=@_;
    my ($sql,$form);        
    my  $result;
    my @val;
   
   if ($formato==1) {$form="fasta";}
   elsif ($formato==2){$form ="genbank";}
   else {$form="swiss";}
   
   if($version) {
   
   $sql = "INSERT INTO sequences (id_specie, alphabet, authority, description, accession_number,accession_version, gene_name, date, is_circular, length, format, seq_version)
                  VALUES ('".$id_specie."', '".$seq->alphabet."', '".$seq->authority."', '".$seq->desc."', '".$seq->accession."','".$version."', '".$seq->display_name."', '".$seq->get_dates."', '".$seq->is_circular."', '".$seq->length."', '".$form."', '".$seq->seq_version."');";
   }
   
   else {
   
   $sql = "INSERT INTO sequences (id_specie, alphabet, authority, description, accession_number,accession_version,gene_name, date, is_circular, length, format, seq_version)
                  VALUES ('".$id_specie."', '".$seq->alphabet."', '".$seq->authority."', '".$seq->desc."', '".$seq->accession."', '".$seq->accession."','".$seq->display_name."', '".$seq->get_dates."', '".$seq->is_circular."', '".$seq->length."', '".$form."', '".$seq->seq_version."');";
   }
   $dbh->do($sql);  ## INSERCAO NA BASE DADOS;
   $sql = "SELECT LAST_INSERT_ID()";
   $result = $dbh->prepare($sql);  ## SELECT DO ID DA ESPECIE INSERIDA
   $result->execute();

   @val = $result->fetchrow_array(); ## SELECT DO ID DA SEQUENCIA INSERIADA
   
    #$dbm_seq{$val[0]} = $seq;        
    
    return $val[0] ;  
}



#------------------This funtion displays the keywords table-----------------------------
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



#--------------------This funtion dysplays the species table-------------------------
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



#--------------------This funtion inserts the keywords on the database------------------------
sub insert_tag{
    
    my ($new_tag)=@_;
    my (@val,$sql,$result);
    
    $sql = "INSERT INTO tags (tag) VALUES ('".$new_tag."');"; ## Inserir Nova tag
    $dbh->do($sql);
    
    $sql = "SELECT id_tag FROM tags WHERE tag='".$new_tag."';";  ## Retorna o id da nova tag
    $result = $dbh->prepare($sql);
    $result->execute();    
    
    @val=$result->fetchrow_array();
    
    return $val[0];
}




#---------------------------This funtion verifies the version------------------------------
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



#------------------------This funtion runs a remote blast------------------------------
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


#----------------------This funtion gets the motif and calls the right funtions to serch it on the sequences on the database--------------------------
sub motif{
    my $motif = interface("ask_motif", 1);
    my ($match, $positions) = search_motif($motif);
    my %match = %$match;
    my %positions = %$positions;
    #print "MATCH\n\n";
    #while(my ($key, $val) = each %match){
    #    print "$key - $val\n";
    #}
    #print "\n\nPOSITIONS\n\n";
    #while(my ($key, $val) = each %positions){
    #    print "$key - ";
    #    for my $pos (@{$val}){
    #        print "$pos ";
    #    }
    #    print "\n";
    #}
    #<>;
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


#-----------------This funtion displays the match table and the positions where the motif was found, and asks if the user want to see it with the 'pg' command
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



#--------------------------This funtion will get the important info to get the statistics--------------------------------
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



#----------------------------This funtion will get the statistics into a file--------------------------------
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




#-------------------This funtion will add a new feature into a sequence-------------------------------
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

#sub display_sequences_by_acc{
    
   # my ($acce)=@_;
    
    #my $sql = "SELECT id_sequence,accession_number,accession_version,length,description FROM sequences WHERE accession_number = '".$acce."';";
    #my $result = $dbh->prepare($sql);
    #$result->execute();
    #while(my $row = $result->fetchrow_hashref()){
       # $id_sequence = $row->{id_sequence};
    #}
    
    
#}

sub translatee{
    
    my $option = interface("ask_translate_type",1,0);
    
    if($option==2) {
        
        my $option2 = interface("insert_manual_seq", 1);    
        open FILE, ">translations/temp.txt";
        print FILE translatione($option2);
        system 'pg temp.txt';
        close FILE;
        print "\nSUCCEFULL TRANSLATION!!!\n result on \"translation/temp.txt\" ";    
        print("\n(Press Enter)");
        <>;
    }
    
    if($option==1){
        
        my $id;        
        
        my $option = interface("give_id_sequence");
        
        my ($number,$flag) = interface("ask_accession_number_no_check");
        
        if($flag) {
            $id = get_id_sequence($number,"accession_number");
        }
        else  {$id=$number;}
        
        my $filename = $dbm_seq{$id};
        
        my $format = get_format($filename);
    
        my $seqio = Bio::SeqIO->new(-file => $filename, -format => $format);
        my $seq = $seqio->next_seq;
        my $accession = $seq->accession();
        $accession.="_$id";
        open FILE, ">translations/$accession.txt";
        print FILE translatione($seq->seq());
        close FILE;
        print "\nSUCCEFULL TRANSLATION!!!\n result on \"translation/$accession.txt\" ";    
        print("\n(Press Enter)");
        <>;
    }
    
      main(1);    
}

sub translatione{
    
    my ($sequencia) = @_;
    my $seq = Bio::Seq->new(-seq => $sequencia);
    
    return $seq->translate->seq;
}



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
            $existe = verify_accession($answer, "with");             #Verifica se o accesion number já existe na Base de Dados
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
        ##system $^O eq 'MSWin32' ? 'cls' : 'clear';
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
        
        if ($answer==2) {return (0,0);} ## DONT WANT TO ADD TAG
        
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        else {print "\n\n";}
        display_tags();  
        my @lista = interface('ask_keywords');
        #insert_tags(@lista);
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
        print "Do you want to use a sequence from the Database or Mannualy insert one?\n\n 1 - From Database\n 2 - Manually\n\nAnswer: ";
        $option=<>;
        if ($option==2 or $option==1) {return $option;}
        else {interface("ask_translate_type", 0, 1);}
                 
    }
    
    elsif($type eq "insert_manual_seq"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID SEQUENCE! Please choose a valid one: ";}
        print "Insert the Sequence: ";
        $_=<>;
        chomp $_;
        if(/[^atgcATCG]/) {interface("insert_manual_seq",0,1);}
        else {return $_;}
        
    }
    
    elsif($type eq "search_operations"){
        
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID SEQUENCE! Please choose a valid one: ";}
        print "Select the option you would like to do:\n\n 1- View Tags\n 2- View Species\n 3- View Sequences\n 4- Search Sequences\n\nAnswer: ";
        $_=<>;
        chomp $_;
        if($_==1) {return (1,0);}
        elsif($_== 2) {return (2,0);}
        elsif($_==3) {return (3,0);}        
        elsif ($_==4) {
            
            print "\n \nSelect the options which you want to use to search: \n 1- By tag\n 2- By Accession number\n 3- By Gene Name\n 4- By Specie\n\nAnswer: ";            
            $_=<>;
            return(4,$_);
        }
        
        interface("search_operations",1,1);
        
    }
        
    elsif($type eq "exit"){
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "\t\n\nBioinformatics - \"Fetch the Sequence!\" \n\n Thank you for using our software! \n Have a nice day! :) \n\n";

    }
}











