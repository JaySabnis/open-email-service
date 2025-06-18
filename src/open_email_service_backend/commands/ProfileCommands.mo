module ProfileCommands {
    public type Timestamp = Int;

    public type CreateProfileDTO = {
        name : Text;
        surname : Text;
        userAddress : Text;
        status : ?Text;
        description : ?Text;
        profileImage : ?Blob;
    };

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

    public type UpdateProfileDTO = {
        name : ?Text;
        surname : ?Text;
        status : ?Text;
        description : ?Text;
        profileImage : ?Blob;
    };
};
