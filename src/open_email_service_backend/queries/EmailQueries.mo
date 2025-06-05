import AppEnums "../AppEnums";
module EmailQueries {
    public type Timestamp = Int;

    public type EmailResponseDTO = {
        id : Text;
        from : Text;
        to : Text;
        subject : Text;
        preview : Text;
        createdOn : Timestamp;
        starred : Bool;
        readFlag : Bool;
        //add parent mail id for threading
    };

    public type PaginationParams = {
        pageNumber : ?Nat;
        pageSize : ?Nat;
        sortOrder : AppEnums.SortOrder;
        filterBySender : ?Text;
        filterByRecipient : ?Text;
    };


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

    public type PaginatedEmailBodyResponseDTO = {
        currentPage : Nat;
        pageSize : Nat;
        totalItems : Nat;
        totalPages : Nat;
        data : [EmailResponseDTO];
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
