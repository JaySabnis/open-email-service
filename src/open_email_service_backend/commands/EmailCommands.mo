module EmailCommands {
    public type Timestamp = Int;

    public type SendEmailDTO = {
        to : Text;
        subject : ?Text;
        body : Text;
        attachmentIds : [Text];
        isReply : Bool;
        parentMailId : ?Text;
    };

    public type Email = {
        from : Text;
        to : Text;
        subject : ?Text;
        body : Text;
        attachmentIds : [Text];
        createdOn : Timestamp;
        isReply : Bool;
        parentMailId : ?Text;
    };

    public type FileResponseDTO = {
        fileId : Text;
        fileName : Text;
        size : Nat;
    };

    public type FileRequestDTO = {
        fileName : Text;
        contentType : Text;
        filedata : Blob;
    };
};
