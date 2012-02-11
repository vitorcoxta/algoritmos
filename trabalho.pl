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
use Error qw(:try);

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
#dbmopen(%dbm_seq, 'METER AQUI O CAMINHO DESEJADO PARA A LOCALIZACAO DA HASH COM AS SEQUENCIAS', 0666);

#TODO: Quando a interface estiver terminada, meter na opcao "sair" o close da connection às base de dados (close $dbh e dbmclose($dmb_seq))

main(1);
#blast();

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
    elsif($option == 9){
        interface("exit");
        dbmclose(%dbm_seq);
        #$dbh->disconnect;
        exit(0);
    }
}


sub database_operations{
    my $option = interface("database_operations", 1, 0);
    if($option == 1){insertion();}
    elsif($option == 2){removal();}
    elsif($option == 3){modification();}
    elsif($option == 9){main(1);}
}


sub bioinformatics_operations{
    my $option = interface("bioinformatics_operations", 1, 0);
    if($option == 1){blast();}
    elsif($option == 2){motif();}
    elsif($option == 9){main(1);}
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
        my $gene_name = interface("ask_gene_name", 0);
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        my $date = interface("ask_date", 0);
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        my $is_circular = interface("ask_is_circular", 0, 0);
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        my @keywords;
        my $bool;
        ($bool, @keywords) = interface("ask_tag", 0);
        print "-------------------------------------------------------------------------------------------------------------------------\n";
        my $sequence = interface("ask_sequence", 0);
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
        my $alph= interface("ask_alphabet", 0);                       #Asks the alphabet
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
        #interface("successful_insertion", 1);
        #main(1);
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
        #Ineficiente porque faz o mesmo select 2 vezes, mas assim funciona... Deve ser porque nao pode fazer o fecthrow 2 vezes seguidas,
        #por isso tive de voltar a fazer o select...
        
        #The last argument tells ifit has the accession number (insertion from a file or from a remote DB) or the gene name (manual insertion)
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
                $dbh->do($sql);#my $result2 = 
                #if($result2) {print ("A insercao foi executada com sucesso\n");}
                #else {print ("Ocorreu um erro na insercao\n");}
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
        my $accession_number = interface("ask_accession_number", 1);
        remove($accession_number, "accession_number");
        interface("successful_removal", 1);
        main(1);
    }
    elsif($option == 2){
        my $gene_name = interface("ask_gene_name", 1);
        remove($gene_name, "gene_name");
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



sub display_modified{
    my (%modified) = @_;
    my $option = interface("ask_display_modified", 0, 0);
    my ($key, $answer);
    if($option == 1){
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
            $option2=interface("ask_accession_number", 1);
            print "-------------------------------------------------------------------------------------------------------------------------\n";
            
                try {   
                    $seq = $gb->get_Seq_by_acc($option2) || throw Bio::Root::Exception(print "ERRO: INVALID NUMBER!!");
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
                    $seq = $gb->get_Seq_by_version($option2) || throw Bio::Root::Exception(print "ERRO: INVALID NUMBER!!") # Vai buscar o number         
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




sub verify_accession{   #### Verifica se o Accession  number já existe na Base de Dados -----------   Se sim, retorna 0,  senao retorna 1
    my ($type) = @_;     
    my ($sql,$result);
    
    $sql = "SELECT accession_number FROM sequences WHERE accession_number='".$type."' and accession_version='".$type."';";
    $result = $dbh->prepare($sql);
    $result->execute();
    if($result->fetchrow_hashref()){
        return 0;
    }
    return 1;
}


sub verify_accession_in_file{   #### Verifica se o Accession  number já existe na Base de Dados -----------   Se sim, retorna 0,  senao retorna 1
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
        return 0;
    }
    return 1;
}


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
   
   $sql = "INSERT INTO sequences (id_specie, alphabet, authority, description, accession_number, gene_name, date, is_circular, length, format, seq_version)
                  VALUES ('".$id_specie."', '".$seq->alphabet."', '".$seq->authority."', '".$seq->desc."', '".$seq->accession."','".$seq->display_name."', '".$seq->get_dates."', '".$seq->is_circular."', '".$seq->length."', '".$form."', '".$seq->seq_version."');";
   }
   $dbh->do($sql);  ## INSERCAO NA BASE DADOS;
   $sql = "SELECT LAST_INSERT_ID()";
   $result = $dbh->prepare($sql);  ## SELECT DO ID DA ESPECIE INSERIDA
   $result->execute();

   @val = $result->fetchrow_array(); ## SELECT DO ID DA SEQUENCIA INSERIADA
   
    #$dbm_seq{$val[0]} = $seq;        
    
    return $val[0] ;  
}

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


sub blast{
    my $option = interface("ask_choose_type", 1);
    my ($acc_or_name, $id_sequence, $filename, $format, $seqio, $seq, $blast_type, $db, $blast, $result_blast);
    if($option == 1) {
        $acc_or_name = interface("ask_accession_number_no_check", 0);
        $id_sequence = get_id_sequence($acc_or_name, "accession_number");
    }
    else {
        $acc_or_name = interface("ask_gene_name_no_check", 0);
        $id_sequence = get_id_sequence($acc_or_name, "gene_name");
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
            print "\n\tMATCH TABLE\n\n";
            foreach $key (sort {$a <=> $b} (keys %match)){
                print " $key - ".(substr $match{$key}, 10)." - Positions: ";
                for $pos (@{$positions{$key}}){
                    print $pos."  ";
                }
                print "\n";
            }
            print "\n\n";
            $option = interface("ask_display_match", 0, 0);
            if($option == 1){
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

    #TODO: METER O HELP NA INTERFACE!
    
    if($type eq "welcome"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one!\n\n"}
        else {print "\t\t\tWELCOME TO CENASSAS. ALGUEM QUE ESCREVA ALGO AQUI, QUE TOU SEM IDEIAS!\n\n";}
        print "What do you want to do?\n\n 1 - Database operations\n 2 - Bioinformatics operations\n\n 8 - Help\n 9 - Exit\n\nAnswer: ";
        $option = <>;
        if($option == 1 or $option == 2 or $option == 9) {return $option;}
        else {interface("welcome", 1, 1);}
    }
    
    
    
    elsif($type eq "database_operations"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one!\n\n"}
        print "What do you want to do?\n\n 1 - Insertion of a sequence\n 2 - Removal of a sequence\n 3 - Modification of a sequence\n\n 8 - Help\n 9 - Go to main page\n\nAnswer: ";
        $option = <>;
        if($option == 1 or $option == 2 or $option == 3 or $option == 9) {return $option;}
        else {interface("database_operations", 1, 1);}
    }
    
    
    
    elsif($type eq "bioinformatics_operations"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one!\n\n"}
        print "What do you want to do?\n\n 1 - Run a BLAST\n 2 - Search for a motif\n\n 8 - Help\n 9 - Go to main page\n\nAnswer: ";
        $option = <>;
        if($option == 1 or $option == 2 or $option == 9) {return $option;}
        else {interface("bioinformatics_operations", 1, 1);}
    }
    
    
    
    elsif($type eq "ask_insertion_type"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one!\n\n";}
        print "Choose a way to insert a sequence: \n\n 1 - Manually\n 2 - From a file\n 3 - From a remote database\n\n 8 - Help\n 9 - Go to main page\n\nAnswer: ";
        $option = <>;
        if($option == 1 or $option == 2 or $option == 3 or $option == 9) {return $option;}
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
    
    
    
    elsif($type eq "ask_gene_name"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "This gene name is already in use! Please choose an unused one: "}
        else {print "Insert the gene name: ";}
        $answer = <>;
        chomp $answer;
        if (verify_gene_name($answer)) {interface("ask_gene_name", 0, 1);}
        else {return $answer;}
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
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the sequence: ";
        $answer = <>;
        chomp $answer;
        return $answer;
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
        if(!verify_accession_in_file($answer)) {interface("ask_file_path", 0, 1)}
        else {return $answer;}
    }
    
    
    
    elsif($type eq "ask_removal_type"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one!\n\n";}
        print "Choose a way to remove the sequence (ATTENTION! If there are more than 1 sequence with the same accession number or with the same name, ".
                "all of them will be deleted):\n\n 1 - By an accession number\n 2 - By a gene name\n\n 8 - Help\n 9 - Go to main page\n\nAnswer: ";
        $option = <>;
        if($option == 1 or $option == 2 or $option == 9) {return $option;}
        else {interface("ask_removal_type",1, 1);}
    }
    
    
    
    elsif($type eq "ask_accession_number"){
        my $existe=1;
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        do{
            
            if(!$existe) {print "\nERROR: EXISTING ACCESSION NUMBER IN DATABASE!!!\n"}
        print "Insert the accession number: ";
        $answer = <>;
        chomp $answer;
        $existe = verify_accession($answer);             #Verifica de o accesion number já existe na Base de Dados                                               
        }while(!$existe);
        return $answer;
    }
    
    
    
    elsif($type eq "ask_modification_type"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one!\n\n";}
        print "Choose a way to modify the sequence (ATTENTION: If there are more than 1 sequence with the same accession number or with the same name, ".
                "you can modify whatever you want):\n\n 1 - By an accession number\n 2 - By a gene name\n\n 8 - Help\n 9 - Go to main page\n\nAnswer: ";
        $option = <>;
        if($option == 1 or $option == 2 or $option == 9) {return $option;}
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
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the accession number: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    
    
    elsif($type eq "ask_gene_name_no_check"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the gene name: ";
        $answer = <>;
        chomp $answer;
        return $answer;
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
        else {print "Select the file you want to see from the MATCH TABLE: ";}
        $option = <>;
        return $option;
    }
    
    
    
    
    elsif($type eq "successful_blast"){
        #Here the $something has the FILE NAME of the file that blast() function created
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one: ";}
        else {print "Successful BLAST!!!\n\n The file ".(substr $something, 14)." has been created on the 'blast_results' directory. Do you want to see this file?\n\n 1 - Yes, I do\n 2 - No, I don't\n\nAnswer: ";}
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
    
    
    
    elsif($type eq "exit"){
       # print "METER AQUI AS CENAS DE DESPEDIDA DO JOAO. XAU AI!\n\n";
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "\t\n\nBioinformatics - \"Fetch the Sequence!\" \n\n Thank you for using our software! \n Have a nice day! :) \n\n\nPROPS PO PESSOAL!!!XD\n\n";

    }
}











