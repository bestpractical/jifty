=head1 DESCRIPTION


State 1:

    
    User
        Name, Rank, FileNo

    Group
        Name



State 2:



    User
        Name, Department

    News
        Summary, Body

    Participant
        Name, Rank, SerialNo
        



Upgrade rules:

    Rename User to Participants
    Rename Participants.FileNo to Participants.SerialNo


    Create table 

    Remove table Group






    Upgrade:

        Remove Group
        Add User
        Add News
        Rename Users to Participants
        Rename Participants FileNo to SerialNo 


