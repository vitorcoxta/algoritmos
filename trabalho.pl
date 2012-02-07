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

#TODO: Quando a interface estiver terminada, meter na opcao "sair" o close da connection às base de dados (close $dbh e dbmclose($dmb_seq))

main(1);

sub main{

    my ($clear) = @_;
    my $option = interface("welcome", $clear, 0);
    if($option == 1){insertion();}
    elsif($option == 2){removal();}
    elsif($option == 3){modification();}
    elsif($option == 9){
        interface("exit");
        dbmclose(%dbm_seq);
        #$dbh->disconnect;
        exit(0);
    }
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
        my @keywords = interface("ask_tag", 0);
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
        
        insert_specie($specie);
        insert_sequence_db($specie, $alphabet, $authority, $description, $gene_name, $date, $is_circular, $seq_length, $format, $seq_version);
        my $id_sequence = insert_tags(@keywords);
        insert_sequence($id_sequence, $sequence);
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
        
        if(substr ($path, -5) eq "fasta") {$format = "fasta";}
        elsif(substr ($path, -5) eq "swiss") {$format = "swiss";}
        elsif(substr ($path, -2) eq "gb") {$format = "genbank";}
        else {
            my $format_opt = interface("ask_format", 0, 0);
            if($format_opt == 1) {$format = "fasta";}
            elsif($format_opt == 2) {$format = "genbank";}
            elsif($format_opt == 3) {$format = "swiss";}
        }
        
        my $seq = $seqio->next_seq;
        my $alph= interface("ask_alphabet", 0);                       #Asks the alphabet
        my $alphabet;
        if($alph == 1) {$alphabet = "dna";}
        elsif($alph == 2) {$alphabet = "rna";}
        elsif($alph == 3) {$alphabet = "protein";}
        my $is_circular;
        if($seq->is_circular) {$is_circular = 1;}
        else {$is_circular = 0;}
        my @keywords;
        if($format eq "fasta"){
            @keywords = interface("ask_keywords", 0);
        }
        else{
            my @keywords_file = split /\s*;\s*/, $seq->keywords;
            @keywords = (@keywords_file, interface("ask_keywords", 0));
        }
        my $sequence = $seq->seq;
        my $seq_version;
        my $date;
        if($format eq "genbank" or $format eq "swiss"){
            $seq_version = $seq->seq_version;
            $date= ($seq->get_dates)[0];
        }
        else{
            $seq_version = interface("ask_seq_version", 0);
            $date= interface("ask_date", 0);
        }
        my $specie = interface("ask_specie", 0);               #Just to ask if the user wants to associate the sequence to any specie
        
        insert_specie($specie);
        insert_sequence_db($specie, $alphabet, $seq->authority, $seq->desc, $seq->display_id, $date, $is_circular, $seq->length, $format, $seq_version, $seq->accession_number());
        my $id_sequence = insert_tags(@keywords);
        insert_sequence($id_sequence, $sequence);
    }
    elsif($option == 3){
        my $answer;    
        $answer = interface("ask_database");   # Escolher a Base de Dados
        if ($answer ==1 or $answer ==2 or $answer ==3) { interface("generic_importation_begin",$answer); generic_importation($answer); }    # Escolheu :     GENBANK    
        else {insertion();}
    }
    elsif($option == 4){
        main(1);
    }
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
    my (@keywords) = @_;
    my $id_sequence;
    my $sql = "SELECT LAST_INSERT_ID()";
    my $result = $dbh->prepare($sql);
    $result->execute();
    while(my $row = $result->fetchrow_hashref()){
        $id_sequence = $row->{'LAST_INSERT_ID()'};
    }
    
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
    return $id_sequence;
}






#----------------Insert the sequence on a DBM----------------------------------------
sub insert_sequence{
    my ($id_sequence, $sequence) = @_;
    $dbm_seq{$id_sequence} = $sequence;
    print "A insercao foi executada com sucesso\n";             #TODO: depois de a interface estar pronta, ver se sera preciso isto
}





#--------------------This function indicates the right path to remove data from the database, depending from the user's decision------------------------------------
sub removal{
    my $option = interface("ask_removal_type", 1, 0);
    if($option == 1){
        my $accession_number = interface("ask_accession_number", 1);
        remove($accession_number, "accession_number");
    }
    elsif($option == 2){
        my $gene_name = interface("ask_gene_name", 1);
        remove($gene_name, "gene_name");
    }
    elsif($option == 3){
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
    if($option == 1){
        my $accession_number = interface("ask_accession_number", 1);
        modify($accession_number, "accession_number");
    }
    elsif($option == 2){
        my $gene_name = interface("ask_gene_name", 1);
        modify($gene_name, "gene_name");
    }
    elsif($option == 3){
        main(1);
    }
}



#----------------------This function will modify a sequence saved on the database----------------------
sub modify{
    my ($accession_number_or_gene_name, $type) = @_;
    my $sql = "SELECT id_sequence, gene_name, accession_number, description, alphabet, format FROM sequences WHERE $type='".$accession_number_or_gene_name."'";
    my $result = $dbh->prepare($sql);
    $result->execute();
    my $current = 0;
    my $format;
    while(my $row = $result->fetchrow_hashref()){
        $current += 1;
        if($row->{format} eq "genbank") {$format = "gb";}
        else{$format = $row->{format};}
        create_file($current, $result->rows, $row);
        interface("modify_sequence", 1, 0, $current, $result->rows, $format);
        my $seq = fetch_info($current, $result->rows, $format);
        update_info($seq, $row->{id_sequence});
        unlink("sequence".$current."in".$result->rows.".$format");
    }
}


#------------------------This function will create the file where the user will modify the data-----------------------------
sub create_file{
    my($current, $total, $row) = @_;
    my $seq = Bio::Seq->new(-seq => $dbm_seq{$row->{id_sequence}}, -display_id => $row->{gene_name}, -accession_number => $row->{accession_number}, -desc => $row->{description}, -alphabet => $row->{alphabet});
    my $seqio;
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
    $dbm_seq{$id_sequence} = $seq->seq;
}



sub generic_importation{
    my($base)=@_;
    my ($option2,$formato,$seq,$existe,$option,$gb,$seqio_obj,$result,$sql,$specie,$id_specie,$id_sequence,$id_tag);         
    if ($base==2) {$option=1;}
    else {$option = interface ("ask_import"); }  ## Escolher tipo de importação - "Acession Number ou Version Number"
    
    $formato = interface ("ask_format", 1);  ## Escolher Fasta ou Genbank
    
    ### CICLO PARA PROCURAR    
    $existe=1;
    if ($base==1) {
        $gb = Bio::DB::GenBank->new();      ## Iniciar ligação ao Genbank
    }
    elsif ($base==2) {$gb=Bio::DB::SwissProt->new();}
    else {$gb=Bio::DB::RefSeq->new();}
    do {
    
        if (!$existe)  {print "ERROR: Already existing Accession Number in DataBase!!\n\n";<>;$existe=1;}     
        if ($existe==2) {print "ERROR : Non existing Number in Remote DataBase!!\n\n";<>;$existe=1;}
        
        ##### Inserir Number para procura
        if ($option==1) {    
            $option2=interface("ask_accession_number");                                        
            chomp($option2); 
            $existe = verifica_accession($option2);             #Verifica de o accesion number já existe na Base de Dados                                                

             if ($existe==1) {   
                try {   
                    $seq = $gb->get_Seq_by_acc($option2) || throw Bio::Root::Exception(print "ERRO:INVALID NUMBER!!");
                }catch Bio::Root::Exception with {$existe=2};    
            }         
        }
                    
        elsif ($option==2) {
                
            $option2=interface("ask_version_number");                                        
            chomp($option2); 
        #    $existe = verifica_version_number($option2);             #Verifica de o accesion number já existe na Base de Dados                                        
                                  
            if($existe==1){
                try {
                    $seq = $gb->get_Seq_by_version($option2) || throw Bio::Root::Exception(print "ERRO:INVALID NUMBER!!") # Vai buscar o number         
                }catch Bio::Root::Exception with {$existe=2};  
            }
        }
        
        elsif($option == 9){
            insertion();
        }
    
        if($option==2 && $existe==1) {
                $existe=verifica_accession($seq->accession);
        }    
            
    }while(!$existe or $existe==2);
                 

    $specie = interface("ask_specie");   #pede especie e de seguida grava
    $id_specie=insert_specie_importation($specie);
 
    $id_sequence = insert_sequence_importation($formato,$id_specie,$seq);
 
    interface("ask_tag", 1); #pergunta se quer tag, se quiser pode escolher uma das que já há, ou uma nova.
     
    #if ($id_tag){insert_relation($id_sequence,$id_tag);}
 
    print "INSERCAO FEITA COM SUCESSO!!\n\n\n"; 
 
 
 
 ### Tipo de Ficheiro para Gravar###########################################
 
    $gb = Bio::DB::GenBank->new(-retrievaltype => 'tempfile' , -format => 'Fasta');     
     if ($formato==1) {$seqio_obj = Bio::SeqIO->new(-file => '>sequence.fasta', -format => 'fasta' ); }
     elsif($formato==2) {$seqio_obj = Bio::SeqIO->new(-file => '>sequence.gb', -format => 'genbank' );}
     else {$seqio_obj = Bio::SeqIO->new(-file => '>sequence.swiss', -format => 'swiss' );}
           
    ########################################################################
            
    $seqio_obj->write_seq($seq);

    print "---",$seq->length,"CENAS!!";
                
}




sub verifica_accession{   #### Verifica se o Accession  number já existe na Base de Dados -----------   Se sim, retorna 0,  senao retorna 1
    my ($type) = @_;     
    my ($sql,$result);
    
    $sql = "SELECT accession_number FROM sequences WHERE accession_number='".$type."'";
    $result = $dbh->prepare($sql);
    $result->execute();
    if($result->fetchrow_hashref()){
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
        
    my ($formato,$id_specie,$seq)=@_;
    my ($sql,$form);        
    my  $result;
    my @val;
   
   if ($formato==1) {$form="fasta";}
   elsif ($formato==2){$form ="genbank";}
   else {$form="swiss";}
   
   $sql = "INSERT INTO sequences (id_specie, alphabet, authority, description, accession_number, gene_name, date, is_circular, length, format, seq_version)
                  VALUES ('".$id_specie."', '".$seq->alphabet."', '".$seq->authority."', '".$seq->desc."', '".$seq->accession."', '".$seq->display_name."', '".$seq->get_dates."', '".$seq->is_circular."', '".$seq->length."', '".$form."', '".$seq->seq_version."');";
                  
   $dbh->do($sql);  ## INSERCAO NA BASE DADOS;
   $sql = "SELECT id_sequence FROM sequences WHERE accession_number='".$seq->accession."';";
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

sub insert_relation{
    my ($id_seq,$id_tag)=@_;
    print "----------------$id_seq,$id_tag-----------------";
    my $sql = "INSERT INTO seq_tags (id_sequence,id_tag) VALUES ('".$id_seq."','".$id_tag."');";
    $dbh->do($sql);
}




#------------------This function will have ALL the interface things-------------------
# - 1st argument: interface type (string)
# - 2nd argument: clear screen (boolean)
# - 3rd argument: invalid option (boolean)
# - 4th argument: current id_sequence of the modifiying sequence (just used for the option "modification")
# - 5th argument: total of modifying sequences (just used for the option "modification")
# - 6th argument: format of the file to create (just used for the option "modification")
sub interface {
    my ($type, $clear, $invalid, $current, $total, $format) = @_;
    my ($option, $answer);
    my @answer;

    
    if($type eq "welcome"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one!\n\n"}
        else {print "\t\t\tWELCOME TO CENASSAS. ALGUEM QUE ESCREVA ALGO AQUI, QUE TOU SEM IDEIAS!\n\n";}
        print "What do you want to do?\n\n 1 - Insertion of a sequence\n 2 - Removal of a sequence\n 3 - Modification of a sequence\n\n 8 - Help\n 9 - Exit\n\nAnswer: ";
        $option = <>;
        if($option == 1 or $option == 2 or $option == 3 or $option == 9) {return $option;}
        else {interface("welcome", 1, 1);}
    }
    
    
    
    elsif($type eq "ask_insertion_type"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one!\n\n";}
        print "Choose a way to insert a sequence: \n\n 1 - Manually\n 2 - From a file\n 3 - From a remote database\n\n 8 - Help\n 9 - Go back\n\nAnswer: ";
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
        if($invalid) {print "INVALID OPTION! Please choose a valid one! ";}
        else {print "Insert the alphabet\n\n 1 - dna\n 2 - rna\n 3 - protein\n";}
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
        print "Is it circular?\n\n 1 - Yes\n 2 - No\n\nAnswer: ";
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
        print "Select the format of the importation:\n\n 1 - Fasta\n 2 - Genbank\n 3 - Swissprot\n";    
        do{     
            print "Answer: ";
            $option = <>;
            
            if ($option == 1 or $option == 2 or $option==3 or $option == 9) {return $option;}
            else {print "\nERROR: INVALID OPTION! Please select one of the given options!\n";}
        } while(1);     
    }
    
    
    
    elsif($type eq "ask_file_path"){
        if($clear) {
            system $^O eq 'MSWin32' ? 'cls' : 'clear';
            print "Insert the file path: ";
        }
        else {print "FILE NOT FOUND! Insert a valid file path: ";}
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    
    
    
    elsif($type eq "ask_removal_type"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one!\n\n";}
        print "Choose a way to remove the sequence (ATTENTION! If there are more than 1 sequence with the same accession number or with the same name, ".
                "all of them will be deleted):\n\n 1 - By an accession number\n 2 - By a gene name\n\n 8 - Help\n 9 - Go back\n\nAnswer: ";
        $option = <>;
        if($option == 1 or $option == 2 or $option == 9) {return $option;}
        else {interface("ask_removal_type",1, 1);}
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
                "you can modify whatever you want):\n\n 1 - By an accession number\n 2 - By a gene name\n 8 - Help\n 9 - Go back\n\nAnswer: ";
        $option = <>;
        if($option == 1 or $option == 2 or $option == 9) {return $option;}
        else {interface("ask_modification_type",1, 1);}
    }
    
    
    
    elsif($type eq "modify_sequence"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Sequence $current in $total sequences ...\n\n";
        if($invalid) {print "INVALID OPTION! Please choose a valid one!\n\n";}
        print "The file sequence".$current."in".$total.".$format has been created. Go and modify whatever you want to. After all the changes are done, come back and enter \"ok\"".
                " (without quotes)\n";
        $answer = <>;
        chomp $answer;
        if($answer ne "ok") {interface("modify_sequence", 1, 1, $current, $total, $format);}
    }
    
    
    
    elsif($type eq "error_file_not_found"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "\t\t\tABORTED!\n\nAn error occured... The file could not be found...\n\n";
        main(0);
    }
    
    
    
    elsif ($type eq "ask_database"){
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "Which database you want to use to import:\n\n 1 - Genbank\n 2 - Swissprot \n 3 - RefSeq\n\n 9 - Go back\n\n";    
        do{     
        print "Answer: ";
        $option = <>;
        
        if ($option == 1 or $option == 2 or $option == 3 or $option == 9) {return $option;}
        else {print "\nERROR: INVALID OPTION! Please select one of the given options!\n";}    
    
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
        print "\n\nSelect the way you want to import:\n\n 1 - Accession Number\n 2 - Accession Version\n\n 9 - Go back\n\n";    
        do{     
        print "Answer: ";
        $option = <>;
        
        if ($option == 1 or $option == 2 or $option == 9) {return $option;}
        else {print "\nERROR: INVALID OPTION! Please select one of the given options!\n";}    
    
        } while(1);     
    }
    
    
    
    elsif ($type eq "ask_version_number"){
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "Please insert the Accession Version Number: \n";    
        print "Answer: ";
        $option = <>;
        return $option;
    }
    
    
    
    elsif($type eq "ask_tag"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        my $flag;
        do{
            $flag=1;
            print "Do you want to add a tags to the sequence?\n 1- Yes, i do.\n 2- No, i don't.\n\nAnswer: ";
            $answer = <>;
            chomp $answer;
            if ($answer!=1 and $answer!=2) {$flag=0;}
        }while(!$flag);
        
        if ($answer==2) {return 0;} ## DONT WANT TO ADD TAG
        
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        else {print "\n\n";}
        display_tags();  
        my @lista = interface('ask_keywords');
        insert_tags(@lista);
        return;    
    }
    
    
    
    elsif($type eq "exit"){
       # print "METER AQUI AS CENAS DE DESPEDIDA DO JOAO. XAU AI!\n\n";
        print "\t\n\nBioinformatics - \"Fetch the Sequence!\" \n\n Thank you for using our software! \n Have a nice day! :) \n\n\nPROPS PO PESSOAL!!!XD";
    }
}











