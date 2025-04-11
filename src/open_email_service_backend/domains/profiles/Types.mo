module{
     // Main Profile type
    public type Profile={
        id:Text;
        name:Text;
        surname:Text;
        description:?Text;
    };

    // Main error type variant
    public type ProfileError={
        #NotFound;
        #AlreadyExists;
        #InvalidData : Text ;
        #AnonymousCaller;
    };
    
    // Success/Error result type
    public type ProfileResult = {
        #ok ;
        #err : ProfileError;
    };

}