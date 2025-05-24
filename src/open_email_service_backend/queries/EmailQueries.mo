module EmailQueries {
    public type Timestamp = Int;

    public type EmailBodyResponseDTO = {
        id : Text;
        from : Text;
        to : Text;
        subject : Text;
        body : Text;
        attachments : ?[FileResponseDTO];
        createdOn : Timestamp;
        starred : Bool;
        readFlag : Bool;
        //add parent mail id for threading
    };

    public type FileResponseDTO = {
        fileId : Text;
        fileName : Text;
        size : Nat;
    };

    public type File = {
        fileId : Text;
        fileName : Text;
        contentType : Text;
        size : Nat;
        filedata : Blob;
    };

};
