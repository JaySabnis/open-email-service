import List "mo:base/List";
import Text "mo:base/Text";
import Bool "mo:base/Bool";
import Blob "mo:base/Blob";

module {

    public type Timestamp = Int;

    public type Email = {
        from : Text;
        to : Text;
        subject : Text;
        body : Text;
        attachmentIds : [Text];
        createdOn : Timestamp;
        isReply : Bool;
        parentMailId : ?Text;
        //add parent mail id for threading
    };

    public type EmailResponseDTO = {
        id : Text;
        from : Text;
        to : Text;
        subject : Text;
        createdOn : Timestamp;
        starred : Bool;
        readFlag : Bool;
        //add parent mail id for threading
    };

    public type EmailThreadResponseDTO = {
       baseDto:EmailResponseDTO;
       hasUnreadReplies: Bool;
    };

    public type Thread={
        headMailId: Text;       // Points to the first message in thread
        replyMailIds: [Text];   // All replies in this thread
        isNewMailAdded:Bool;
    };

    public type EmailRegistry = {
        inbox : List.List<Text>;
        outbox : List.List<Text>;
        important : List.List<Text>;
        openedMails : List.List<Text>;
    };

    public type EmailErrors = {
        #NotFound;
        #AnonymousCaller;
        #InvalidRecipientAddress;
        #ErrorSelfTransfer;
    };

    public type File = {
        fileId : Text;
        fileName : Text;
        contentType : Text;
        size : Nat;
        filedata : Blob;
    };

    public type FileErrors = {
        #NotFound;
        #UnexpectedErrorOccured;
    };

};
