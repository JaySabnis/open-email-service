module ProfileQueries {
    public type Timestamp = Int;

    public type Profile = {
        id : Principal;
        name : Text;
        surname : Text;
        userAddress : Text;
        status : ?Text;
        description : ?Text;
        profileImage : ?Blob;
        createdOn : Timestamp;
        modifiedOn : Timestamp;
    };

    public type ProfileInfo={
        id:Principal;
        name:Text;
        surname:Text;
        profileImage:?Blob;
    }

};
